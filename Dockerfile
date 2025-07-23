# Dockerfile

# =============================================================================
# 1) BUILDER STAGE
# =============================================================================
# Usamos a imagem base CUDA para o ambiente de build
FROM nvidia/cuda:12.9.1-runtime-ubuntu22.04 AS builder # Corrigido: 'AS' em maiúsculas

# Instala dependências de build e Python/pip
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        build-essential \
        curl \
        gcc \
        g++ \
        make \
        cmake \
        ca-certificates \
        python3.10 \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Define variáveis de ambiente para Python
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CC=gcc \
    CXX=g++

# Clona ComfyUI (apenas o código-fonte; o ambiente final será criado na próxima etapa)
WORKDIR /
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
RUN git clone https://github.com/zanllp/sd-webui-infinite-image-browsing.git


# =============================================================================
# 2) FINAL STAGE
# =============================================================================
# Usamos a imagem base CUDA para o ambiente de execução
FROM nvidia/cuda:12.9.1-devel-ubuntu22.04

# Instala dependências de runtime e Python/pip
RUN apt-get update && \
    # Pre-aceita a EULA da fonte Microsoft
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        ffmpeg \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgl1-mesa-glx \
        curl \
        openssh-server \
        nodejs \
        npm \
        build-essential \
        nvidia-cuda-dev \
        gcc \
        g++ \
        ca-certificates \
        dos2unix \
        libegl1 \
        libegl-mesa0 \
        libgles2-mesa-dev \
        libglvnd0 \
        libglx0 \
        libopengl0 \
        x11-xserver-utils \
        ttf-mscorefonts-installer \
        fonts-liberation \
        fonts-dejavu \
        fontconfig \
        python3.10 \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Define variáveis de ambiente OpenGL
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics
ENV DISPLAY=:99

# Define variáveis de ambiente para compilação
ENV CC=gcc \
    CXX=g++

# Atualiza pip
RUN pip install --no-cache-dir --upgrade pip

# Instala PyTorch para CUDA
RUN pip install --no-cache-dir torch torchvision torchaudio && \
    pip cache purge # Limpa o cache do pip após a instalação do PyTorch

# Copia ComfyUI da etapa builder
COPY --from=builder /ComfyUI /ComfyUI

# Instala requisitos do ComfyUI
WORKDIR /ComfyUI
RUN pip install --no-cache-dir -r requirements.txt && \
    pip cache purge # Limpa o cache do pip após a instalação dos requisitos do ComfyUI

# Instala outros pacotes Python
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook \
    ipykernel \
    ipywidgets \
    jupyter_server \
    jupyterlab_widgets \
    triton \
    sageattention \
    safetensors \
    aiohttp \
    accelerate \
    pyyaml \
    torchsde \
    opencv-python \
    gdown && \
    pip cache purge # Limpa o cache do pip após a instalação de outros pacotes

# Clona custom nodes
WORKDIR /ComfyUI/custom_nodes
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    git clone https://github.com/facok/ComfyUI-HunyuanVideoMultiLora.git && \
    git clone https://github.com/sipherxyz/comfyui-art-venture.git && \
    git clone https://github.com/theUpsider/ComfyUI-Logic.git && \
    git clone https://github.com/Smirnov75/ComfyUI-mxToolkit.git && \
    git clone https://github.com/alt-key-project/comfyui-dream-project.git && \
    git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon.git && \
    git clone https://github.com/ShmuelRonen/ComfyUI-ImageMotionGuider.git && \
    git clone https://github.com/BlenderNeko/ComfyUI_Noise.git && \
    git clone https://github.com/chrisgoringe/cg-noisetools.git && \
    git clone https://github.com/cubiq/ComfyUI_essentials.git && \
    git clone https://github.com/chrisgoringe/cg-use-everywhere.git && \
    git clone https://github.com/TTPlanetPig/Comfyui_TTP_Toolset.git && \
    git clone https://github.com/pharmapsychotic/comfy-cliption.git && \
    git clone https://github.com/darkpixel/darkprompts.git && \
    git clone https://github.com/Koushakur/ComfyUI-DenoiseChooser.git && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    git clone https://github.com/giriss/comfy-image-saver.git && \
    git clone https://github.com/11dogzi/Comfyui-ergouzi-Nodes.git && \
    git clone https://github.com/jamesWalker55/comfyui-various.git && \
    git clone https://github.com/JPS-GER/ComfyUI_JPS-Nodes.git && \
    git clone https://github.com/M1kep/ComfyLiterals.git && \
    git clone https://github.com/welltop-cn/ComfyUI-TeaCache.git && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    git clone https://github.com/chengzeyi/Comfy-WaveSpeed.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/crystian/ComfyUI-Crystools.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    git clone https://github.com/kijai/ComfyUI-HunyuanVideoWrapper.git && \
    git clone https://github.com/TinyTerra/ComfyUI_tinyterraNodes.git && \
    git clone https://github.com/SKBv0/ComfyUI_SKBundle.git && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/evanspearman/ComfyMath.git && \
    git clone https://github.com/BlueprintCoding/ComfyUI_AIDocsClinicalTools.git && \
    git clone https://github.com/logtd/ComfyUI-HunyuanLoom.git && \
    git clone https://github.com/pollockjj/ComfyUI-MultiGPU.git && \
    git clone https://github.com/Amorano/Jovimetrix.git && \
    git clone https://github.com/Stability-AI/stability-ComfyUI-nodes.git && \
    git clone https://github.com/DoctorDiffusion/ComfyUI-MediaMixer.git && \
    git clone https://github.com/kijai/ComfyUI-VideoNoiseWarp.git && \
    git clone https://github.com/spacepxl/ComfyUI-Image-Filters.git


# Instala requisitos para custom nodes (se houver)
RUN for dir in */; do \
    if [ -f "${dir}requirements.txt" ]; then \
        echo "Installing requirements for ${dir}..." && \
        pip install --no-cache-dir -r "${dir}requirements.txt" || true; \
    fi \
    done && \
    pip cache purge # Limpa o cache do pip após a instalação dos requisitos dos custom nodes


# Copia arquivos de workflow
COPY comfy-workflows/*.json /ComfyUI/user/default/workflows/

# Copia sd-webui da etapa builder
COPY --from=builder /sd-webui-infinite-image-browsing /sd-webui-infinite-image-browsing

# Instala requisitos do sd-webui
WORKDIR /sd-webui-infinite-image-browsing
RUN pip install --no-cache-dir -r requirements.txt && \
    pip cache purge # Limpa o cache do pip após a instalação dos requisitos do sd-webui

# Copia todos os scripts
COPY scripts/*.sh /

# Copia arquivos para o diretório raiz do contêiner
COPY manage-files/download-files.sh /
COPY manage-files/files.txt /

# Cria a estrutura de diretórios do workspace
RUN mkdir -p /workspace

# Copia arquivos para o diretório workspace
COPY manage-files/download-files.sh /workspace/
COPY manage-files/files.txt /workspace/

# Converte e dá permissão de execução aos scripts
RUN dos2unix /*.sh && \
    dos2unix /workspace/*.sh && \
    chmod +x /*.sh && \
    chmod +x /workspace/*.sh

CMD ["/start.sh"]
