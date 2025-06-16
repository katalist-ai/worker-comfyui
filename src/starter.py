import asyncio
import json
import logging
import os
import uuid
import random

import requests
import websockets
from fastapi import FastAPI

current_dir = os.path.dirname(os.path.abspath(__file__))


logger = logging.getLogger("uvicorn")
logger.setLevel(logging.DEBUG)

app = FastAPI()

comfy_url_template = "http://{}:8188/prompt"
ws_uri_template = "ws://{}:8188/ws?clientId={}"


async def await_workflow_completion(prompt_id: str, hostaddr: str, client_id: str):
    uri = ws_uri_template.format(hostaddr, client_id)
    async with websockets.connect(uri, max_size=2**25) as ws:
        while True:
            try:
                out = await asyncio.wait_for(ws.recv(), timeout=300)
            except asyncio.TimeoutError:
                logger.debug("ERROR StartupScript Timeout Error")
                raise Exception("Timeout Error")

            if isinstance(out, str):
                message = json.loads(out)
                if message["type"] == "executing":
                    data = message["data"]
                    if data["node"] is None and data["prompt_id"] == prompt_id:
                        break  # Execution is done
    return True


async def call_workflow(workflow: dict):
    req_id = str(uuid.uuid4())
    headers = {"Content-Type": "application/json"}
    p = {"prompt": workflow, "client_id": req_id}
    logger.debug("0 Sending startup prompt to comfy")
    response = requests.post(comfy_url_template.format("localhost"), json=p, headers=headers)
    if response.status_code == 200:
        logger.debug("1 prompt sent to comfy successfully")
        res = response.json()
        prompt_id = res["prompt_id"]
        is_done = await await_workflow_completion(prompt_id, "localhost", req_id)
        if is_done:
            logger.debug("2 Workload finished")
            return "OK"
        else:
            raise ValueError("Failed to receive results")
    else:
        logger.debug("ERROR prompt failed to send to comfy")
        raise ValueError("Prompt failed to send to comfy")


@app.get("/starter_from_workflow")
async def start_from_workflow():
    print("STARTING TEST PROMPT")
    wf = open(os.path.join(current_dir, 'start_workflow.json')).read().replace("2194132211258", str(random.randint(0, 1000000)))
    wf_json = json.loads(wf)
    res = await call_workflow(workflow=wf_json)
    return res



async def main():
    await start_from_workflow()


if __name__=='__main__':
    asyncio.run(start_from_workflow())
