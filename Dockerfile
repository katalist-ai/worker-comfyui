# Stage 1: Base image with common dependencies
FROM pytorch/pytorch:2.7.0-cuda12.6-cudnn9-runtime as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# # Prefer binary wheels over source distributions for faster pip installations
 ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git, essential build tools, and other necessary system libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    ffmpeg \
    libsndfile1 

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv

# Install comfy-cli
RUN uv pip install comfy-cli --system

# Install ComfyUI
RUN /usr/bin/yes | comfy --workspace /comfyui install --version 0.3.13 --cuda-version 12.6 --nvidia

# Change working directory to ComfyUI
WORKDIR /comfyui

# Support for the network volume
ADD src/extra_model_paths.yaml ./


# Stage 2: Download custom nodes
FROM alpine/git:2.36.2 as download

ARG ENVTYPE

WORKDIR /comfyui

# Copy the clone script
COPY clone.sh /clone.sh
RUN chmod +x /clone.sh

# Add models to ComfyUI models directory
ADD data/runpod-volume/models/ /tmp/models/
RUN rm -rf /comfyui/models && mv /tmp/models /comfyui/models

# Community extensions
# RUN . /clone.sh ComfyUI_IPAdapter_plus https://github.com/cubiq/ComfyUI_IPAdapter_plus.git f904b4c3c3adbda990f32b90eb52e1924467c9ef # Line commented out by user
RUN . /clone.sh comfyui-tooling-nodes https://github.com/Acly/comfyui-tooling-nodes.git e27580efcd9ef67427c853e6f671315e91b6786b
RUN . /clone.sh PulId https://github.com/cubiq/PuLID_ComfyUI.git 4e1fd4024cae77a0c53edb8ecc3c8ee04027ebef
RUN . /clone.sh wlsh-nodes https://github.com/wallish77/wlsh_nodes.git 97807467bf7ff4ea01d529fcd6e666758f34e3c1
RUN . /clone.sh depth-anythhing-v2 https://github.com/kijai/ComfyUI-DepthAnythingV2.git e8dd1c4b12cc039dd363c17c9599c54500ecfdfe
RUN . /clone.sh ComfyUI-GGUF https://github.com/city96/ComfyUI-GGUF 5875c52f59baca3a9372d68c43a3775e21846fe0
RUN . /clone.sh bitsandbytes-nf4 https://github.com/comfyanonymous/ComfyUI_bitsandbytes_NF4.git 72f439164a7eb2e4e30bb780d69cd33be2b3ae8d
RUN . /clone.sh comfyui_controlnet_aux https://github.com/katalist-ai/comfyui_controlnet_aux.git 0bd9c891fc06d2e4b0d5f065955ad2c443d4bf7d
RUN . /clone.sh pulid-flux https://github.com/katalist-ai/ComfyUI_PuLID_Flux_ll.git fbb1d5f38daade7ce314e6a8432e0a08cc0c22ec
RUN . /clone.sh ComfyUI-Impact-Pack https://github.com/ltdrdata/ComfyUI-Impact-Pack 092310bc8f1116a8e237e8fe142c853281903a96
RUN . /clone.sh ComfyUI-Impact-Subpack https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git 74db20c95eca152a6d686c914edc0ef4e4762cb8
RUN . /clone.sh ComfyUI-Florence https://github.com/kijai/ComfyUI-Florence2.git de485b65b3e1b9b887ab494afa236dff4bef9a7e
RUN . /clone.sh Comfy-WaveSpeed https://github.com/chengzeyi/Comfy-WaveSpeed.git 16ec6f344f8cecbbf006d374043f85af22b7a51d

# Katalist custom extensions
RUN . /clone.sh comfyui-nsfw-detection https://github.com/katalist-ai/comfyUI-nsfw-detection 94291ebcd9b9aee2c1996c22dc1404009ceb4bc4
RUN . /clone.sh katalist-comfy-tools https://github.com/katalist-ai/comfy-tools.git 2dc2167b581935df8c264d1401133ae61a56782a
RUN . /clone.sh FaceAnalysis https://github.com/cubiq/ComfyUI_FaceAnalysis 98708e1e1916b0cfe3335f61aa63c5b749088bb9

# Stage 3: Final image
FROM base AS final

# Copy custom nodes from download stage
COPY --from=download /custom_nodes/ /comfyui/custom_nodes/

# Install custom node dependencies in base image
WORKDIR /comfyui
RUN for dir in custom_nodes/*; do \
        if [ -f "$dir/requirements.txt" ]; then \
            echo "Installing requirements for $dir" && \
            python -m pip install -r "$dir/requirements.txt"; \
        fi; \
        if [ -f "$dir/install.py" ]; then \
            echo "Running install.py for $dir" && \
            python "$dir/install.py"; \
        fi; \
    done

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    opencv-python-headless \
    onnxruntime \
    insightface==0.7.3 \
    dlib-bin==19.24.6 \
    facexlib --use-pep517 \
    ftfy fvcore omegaconf \
    xformers==0.0.30 \
    ultralytics==8.3.59 \
    segment_anything==1.0.0 \
    onnxruntime-openvino==1.20.0 \
    transformers==4.48.2

# RUN comfy node install ComfyUI_PuLID_Flux_ll

# Go back to the root
WORKDIR /

# Install Python runtime dependencies for the handler
RUN uv pip install runpod requests websocket-client --system

# Add application code and scripts
ADD src/start.sh handler.py test_input.json ./
ADD src/starter.py ./
ADD src/start_workflow.json ./
RUN chmod +x /start.sh

# Set the default command to run when starting the container
CMD ["/start.sh"]
