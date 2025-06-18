FROM alpine/git:2.36.2 as download


ARG ENVTYPE

COPY clone.sh /clone.sh

# extensions

# Extensions from the community - manual update to the latest version
RUN . /clone.sh ComfyUI_IPAdapter_plus https://github.com/cubiq/ComfyUI_IPAdapter_plus.git f904b4c3c3adbda990f32b90eb52e1924467c9ef
RUN . /clone.sh comfyui-tooling-nodes https://github.com/Acly/comfyui-tooling-nodes.git e27580efcd9ef67427c853e6f671315e91b6786b
RUN . /clone.sh was-node-suite-comfyui https://github.com/WASasquatch/was-node-suite-comfyui.git 33534f2e48682ddcf580436ea39cffc7027cbb89
RUN . /clone.sh ComfyUI-Advanced-ControlNet https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git f6adc32937413b46ee0b489d03eb539e6999d7e1
RUN . /clone.sh rgthree-comfy https://github.com/rgthree/rgthree-comfy.git a20c9aeebe79107cada750979d65ce1a72e5516a
RUN . /clone.sh comfyui_controlnet_aux https://github.com/katalist-ai/comfyui_controlnet_aux.git 0bd9c891fc06d2e4b0d5f065955ad2c443d4bf7d
RUN . /clone.sh masquerade-nodes-comfyui https://github.com/BadCafeCode/masquerade-nodes-comfyui.git 69a944969c29d1c63dfd62eb70a764bceb49473d
RUN . /clone.sh ComfyUI_essentials https://github.com/cubiq/ComfyUI_essentials.git b773e94e6b9376b787cda0db88a17aa4ffc7e2c1
RUN . /clone.sh PulId https://github.com/cubiq/PuLID_ComfyUI.git 4e1fd4024cae77a0c53edb8ecc3c8ee04027ebef
RUN . /clone.sh wlsh-nodes https://github.com/wallish77/wlsh_nodes.git 97807467bf7ff4ea01d529fcd6e666758f34e3c1
RUN . /clone.sh depth-anythhing-v2 https://github.com/kijai/ComfyUI-DepthAnythingV2.git e8dd1c4b12cc039dd363c17c9599c54500ecfdfe
RUN . /clone.sh ComfyUI-GGUF https://github.com/city96/ComfyUI-GGUF 5875c52f59baca3a9372d68c43a3775e21846fe0
RUN . /clone.sh bitsandbytes-nf4 https://github.com/comfyanonymous/ComfyUI_bitsandbytes_NF4.git 72f439164a7eb2e4e30bb780d69cd33be2b3ae8d
RUN . /clone.sh pulid-flux https://github.com/katalist-ai/ComfyUI_PuLID_Flux_ll.git fbb1d5f38daade7ce314e6a8432e0a08cc0c22ec

RUN if [ "$ENVTYPE" = "dev" ]; then \
  . /clone.sh ComfyUI-Manager https://github.com/ltdrdata/ComfyUI-Manager.git b6cb867a4c7be16bcf716f6a8f1a0e7d5270f178 && \
  . /clone.sh ComfyUI-Custom-Scripts https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git 3f2c021e50be2fed3c9d1552ee8dcaae06ad1fe5; \
  fi

# Our customized extensions - manual update to the latest version
RUN . /clone.sh comfyui-nsfw-detection https://github.com/katalist-ai/comfyUI-nsfw-detection 94291ebcd9b9aee2c1996c22dc1404009ceb4bc4
RUN . /clone.sh katalist-comfy-tools https://github.com/katalist-ai/comfy-tools.git 9b3936e41dd6d964b6fbe047c35fac7a34f3dcad
RUN . /clone.sh FaceAnalysis https://github.com/cubiq/ComfyUI_FaceAnalysis 98708e1e1916b0cfe3335f61aa63c5b749088bb9
RUN . /clone.sh ComfyUI-Impact-Pack https://github.com/ltdrdata/ComfyUI-Impact-Pack 092310bc8f1116a8e237e8fe142c853281903a96
RUN . /clone.sh ComfyUI-Impact-Subpack https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git 74db20c95eca152a6d686c914edc0ef4e4762cb8
RUN . /clone.sh ComfyUI-BRIA_AI-RMBG https://github.com/ZHO-ZHO-ZHO/ComfyUI-BRIA_AI-RMBG 827fcd63ff0cfa7fbc544b8d2f4c1e3f3012742d

# old currently unused extensions
# RUN . /clone.sh image-resize-comfyui https://github.com/palant/image-resize-comfyui ae5888637742ff1668b6cd32954ba48d81dbd39d
# RUN . /clone.sh ComfyUI-NSFW-Detection https://github.com/trumanwong/ComfyUI-NSFW-Detection.git 7dd97a29ccba1c273415352f135bfada332cd240
# RUN . /clone.sh ComfyUI-Inspire-Pack https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git 985f6a239b1aed0c67158f64bf579875ec292cb2
# RUN . /clone.sh comfyui-dynamicprompts https://github.com/adieyal/comfyui-dynamicprompts.git 3f2fff32358cf39e21b8b440ca87eac9a8e2bade
# RUN . /clone.sh ComfyUI-InstantID https://github.com/cubiq/ComfyUI_InstantID d8c70a0cd8ce0d4d62e78653674320c9c3084ec1
# RUN . /clone.sh PulID https://github.com/cubiq/PuLID_ComfyUI.git 145a5ef2746fbeb0aaf7165f28c83f851fda9a4c
# RUN . /clone.sh comfyui-inpaint-nodes https://github.com/Acly/comfyui-inpaint-nodes.git ed5a8b21bb416d59506fe5e58fc9a36be48f25fb

FROM pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime
ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=

RUN apt-get update && apt-get install -y git ffmpeg curl g++ build-essential && apt-get clean

# RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB && \
#     apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB && \
#     echo "deb https://apt.repos.intel.com/openvino/2024 ubuntu22 main" | tee /etc/apt/sources.list.d/intel-openvino-2024.list && \
#     apt update && \
#     apt install -y openvino-2024.1.0


ENV ROOT=/stable-diffusion
RUN --mount=type=cache,target=/root/.cache/pip \
  git clone https://github.com/comfyanonymous/ComfyUI.git ${ROOT} && \
  cd ${ROOT} && \
  git checkout master && \
  git reset --hard 9e1d301129db2507e6681a83d845186802e4ba22 && \
  pip install -r requirements.txt && \
  rm -rf .git

RUN apt-get update && apt-get install -y wget
WORKDIR /stable-diffusion/custom_nodes/ComfyUI-BRIA_AI-RMBG/RMBG-1.4/
RUN wget https://huggingface.co/briaai/RMBG-1.4/resolve/main/model.pth

WORKDIR ${ROOT}

COPY --from=download /custom_nodes/ ${ROOT}/custom_nodes/
WORKDIR custom_nodes
RUN --mount=type=cache,target=/root/.cache/pip \
  cd was-node-suite-comfyui && pip install -r requirements.txt && \
  cd ../ComfyUI-Advanced-ControlNet && pip install -r requirements.txt && \
  cd ../rgthree-comfy && pip install -r requirements.txt && \
  cd ../comfyui-nsfw-detection && pip install -r requirements.txt && \
  cd ../katalist-comfy-tools && pip install -r requirements.txt && \
  cd ../ComfyUI-Impact-Pack && python install.py && pip install -r requirements.txt && \
  cd ../ComfyUI-Impact-Subpack && pip install -r requirements.txt && \
  cd ../comfyui_controlnet_aux && pip install -r requirements.txt && \
  cd ../bitsandbytes-nf4 && pip install -r requirements.txt && \
  cd ../ComfyUI-GGUF && pip install -r requirements.txt && \
  cd ../pulid-flux && pip install -r requirements.txt
  # cd ../ComfyUI-NSFW-Detection && pip install -r requirements.txt
  # cd ../comfyui-dynamicprompts && python -m pip install -r requirements.txt && python install.py && \
  # cd ../ComfyUI-Manager && pip install -r requirements.txt && \

# add info
COPY . /docker/
RUN cp /docker/extra_model_paths.yaml ${ROOT}
RUN chmod u+x /docker/entrypoint.sh


# extensions

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install onnxruntime && \
  pip install insightface==0.7.3 && \
  pip install dlib-bin==19.24.6 && \
  pip install facexlib --use-pep517 && \
  pip install ftfy fvcore omegaconf && \
  pip install xformers==0.0.29.post1 && \
  pip install ultralytics==8.3.59 && \
  pip install segment_anything==1.0.0 && \
  pip install onnxruntime-openvino==1.20.0 && \
  pip install transformers==4.48.2

# Extensions extra (advanced git clones)
# RUN git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale --recursive

RUN mkdir -vp /data/input && mv /docker/character_imgs/* /data/input/
RUN rm -rf ${ROOT}/models && mv /docker/models/ ${ROOT}
# rename models/lora to models/loras
RUN mv ${ROOT}/models/lora ${ROOT}/models/loras

WORKDIR ${ROOT}
ENV NVIDIA_VISIBLE_DEVICES=all
ENV FAL_KEY=c97b08c2-d2f4-424e-9701-8853537af5f2:e2e889650afdc5abd9dcbdfe96834de3
ENV PYTHONPATH="${PYTHONPATH}:${PWD}" CLI_ARGS=""
EXPOSE 7860
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python -u main.py --listen --port 7860 ${CLI_ARGS}

