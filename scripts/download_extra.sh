#!/bin/bash
set -e

if [ "${SKIP_DOWNLOADS:-false}" == "true" ]; then
    echo "SKIP_DOWNLOADS is set to true, skipping model downloads"
    exit 0
fi

MODEL_DIR="/workspace/ComfyUI/models"
LORA_DIR="${MODEL_DIR}/loras"
CHECKPOINTS_DIR="${MODEL_DIR}/checkpoints"

mkdir -p "${MODEL_DIR}/loras"
mkdir -p "${MODEL_DIR}/checkpoints"

# Função para baixar um arquivo se ele ainda não existir no destino
download_if_not_exists() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")

    if [ ! -f "$dest" ]; then
        echo "BAIXANDO -- $filename..."
        wget -q --show-progress "$url" -O "$dest"
        if [ $? -eq 0 ]; then
            echo "CONCLUÍDO $filename com sucesso"
        else
            echo "FALHA ao baixar $filename. Verifique a URL ou sua conexão."
        fi
    else
        echo "$filename já existe, pulando download"
    fi
}

# URL base para download direto dos arquivos LoRA do Hugging Face
HUGGINGFACE_LORA_BASE_URL="https://huggingface.co/datasets/oggimrm/HunyuanVideo/resolve/main/"
# URL para navegar no repositório do Hugging Face (usada para listar os arquivos)
HUGGINGFACE_LORA_REPO_BROWSE_URL="https://huggingface.co/datasets/oggimrm/HunyuanVideo/tree/main"

# Exit immediately if SKIP_LORAS is set to true
if [ "${SKIP_LORAS:-false}" == "true" ]; then
    echo "SKIP_LORAS is set to true, skipping model downloads"
    exit 0
else
    echo "Buscando arquivos Lora .safetensors no repositório HunyuanVideo..."

    LORAS_TO_DOWNLOAD=$(curl -s "$HUGGINGFACE_LORA_REPO_BROWSE_URL" | grep -oP 'href="[^"]+Lora+\.safetensors"' | sed -E 's/href="([^"]+)"/\1/' | xargs -n 1 basename)

    if [ -z "$LORAS_TO_DOWNLOAD" ]; then
        echo "Nenhum arquivo .safetensors encontrado no repositório. Verifique a URL ou a estrutura da página."
    else
        echo "--- LoRAs encontrados no repositório ---"
        for filename in $LORAS_TO_DOWNLOAD; do
            echo "- ${filename}" 
            download_if_not_exists "${HUGGINGFACE_LORA_BASE_URL}${filename}" \
                "${LORA_DIR}/${filename}"
        done
        echo "----------------------------------------"
    fi
    echo "Checkpoints dinamicos baixados com sucesso."
fi

# Exit immediately if SKIP_CHECKPOINTS is set to true
if [ "${SKIP_CHECKPOINTS:-false}" == "true" ]; then
    echo "SKIP_CHECKPOINTS is set to true, skipping model downloads"
    exit 0
else
    echo "Buscando arquivos Checkpoint .safetensors no repositório HunyuanVideo..."

    CHECKPOINTS_TO_DOWNLOAD=$(curl -s "$HUGGINGFACE_LORA_REPO_BROWSE_URL" | grep -oP 'href="[^"]+\.safetensors"' | sed -E 's/href="([^"]+)"/\1/' | xargs -n 1 basename)

    if [ -z "$CHECKPOINTS_TO_DOWNLOAD" ]; then
        echo "Nenhum arquivo .safetensors encontrado no repositório. Verifique a URL ou a estrutura da página."
    else
        echo "--- Checkpoints encontrados no repositório ---"
        for filename in $CHECKPOINTS_TO_DOWNLOAD; do
            echo "- ${filename}"
            download_if_not_exists "${HUGGINGFACE_LORA_BASE_URL}${filename}" \
                "${CHECKPOINTS_DIR}/${filename}"
        done
        echo "----------------------------------------"
    fi

    echo "Checkpoints dinamicos baixados com sucesso."
fi
