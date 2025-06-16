#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    echo "worker-comfyui: Starting ComfyUI"
    python /comfyui/main.py --disable-auto-launch --disable-metadata --listen &

    # sleep for 10 seconds
    sleep 25

    if python starter.py; then
        echo "worker-comfyui: Starter script completed successfully, starting handler"
        python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
    else
        echo "worker-comfyui: Starter script failed, not starting handler"
        exit 1
    fi
else
    echo "worker-comfyui: Starting ComfyUI"
    python /comfyui/main.py --disable-auto-launch --disable-metadata &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi