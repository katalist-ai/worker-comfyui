# Stage 1: Base image with common dependencies
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu22.04 AS base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1
# Speed up some cmake builds
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python, git, essential build tools, and other necessary system libraries
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    python3-dev \
    build-essential \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    ffmpeg \
    libsndfile1 \
    && ln -sf /usr/bin/python3.11 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip

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

# Community extensions
# RUN . /clone.sh ComfyUI_IPAdapter_plus https://github.com/cubiq/ComfyUI_IPAdapter_plus.git f904b4c3c3adbda990f32b90eb52e1924467c9ef # Line commented out by user
RUN . /clone.sh comfyui-tooling-nodes https://github.com/Acly/comfyui-tooling-nodes.git e27580efcd9ef67427c853e6f671315e91b6786b
RUN . /clone.sh PulId https://github.com/cubiq/PuLID_ComfyUI.git 4e1fd4024cae77a0c53edb8ecc3c8ee04027ebef
RUN . /clone.sh wlsh-nodes https://github.com/wallish77/wlsh_nodes.git 97807467bf7ff4ea01d529fcd6e666758f34e3c1
RUN . /clone.sh depth-anythhing-v2 https://github.com/kijai/ComfyUI-DepthAnythingV2.git e8dd1c4b12cc039dd363c17c9599c54500ecfdfe
RUN . /clone.sh ComfyUI-GGUF https://github.com/city96/ComfyUI-GGUF 5875c52f59baca3a9372d68c43a3775e21846fe0
RUN . /clone.sh bitsandbytes-nf4 https://github.com/comfyanonymous/ComfyUI_bitsandbytes_NF4.git 72f439164a7eb2e4e30bb780d69cd33be2b3ae8d
RUN . /clone.sh pulid-flux https://github.com/katalist-ai/ComfyUI_PuLID_Flux_ll.git 8b9e00ca412ce3a6a2d9abe0c30d0f4b82e69ba0


# Katalist custom extensions
RUN . /clone.sh comfyui-nsfw-detection https://github.com/katalist-ai/comfyUI-nsfw-detection 94291ebcd9b9aee2c1996c22dc1404009ceb4bc4
RUN . /clone.sh katalist-comfy-tools https://github.com/katalist-ai/comfy-tools.git 9b3936e41dd6d964b6fbe047c35fac7a34f3dcad

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
RUN chmod +x /start.sh

# Set the default command to run when starting the container
CMD ["/start.sh"]
