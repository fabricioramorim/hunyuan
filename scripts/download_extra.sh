#!/bin/bash
set -e

if [ "${SKIP_DOWNLOADS:-false}" == "true" ]; then
    echo "**** SKIPPING EXTRA MODEL DOWNLOADS (SKIP_DOWNLOADS=true) ****"
    exit 0
fi

MODEL_DIR="/workspace/ComfyUI/models"
LORA_DIR="${MODEL_DIR}/loras"
CHECKPOINTS_DIR="${MODEL_DIR}/checkpoints"

# Criar os diretórios se não existirem
mkdir -p "${LORA_DIR}"
mkdir -p "${CHECKPOINTS_DIR}"

# Função para baixar um arquivo se ele ainda não existir no destino
download_if_not_exists() {
    local url=$1
    local dest=$2
    local filename=$(basename "$dest")

    if [ ! -f "$dest" ]; then
        echo "📥 Starting download: $filename"
        # Usando wget com opções para mostrar progresso e com 5 retries
        wget -q --show-progress --tries=5 --timeout=30 "$url" -O "$dest"
        if [ $? -eq 0 ]; then
            echo "✨ Completed: $filename"
        else
            echo "❌ Error: Failed to download $filename. Check the URL or your connection."
            # Remove o arquivo parcialmente baixado
            rm -f "$dest"
            return 1
        fi
    else
        echo "✅ $filename already exists, skipping."
    fi
}

# URL base para download direto dos arquivos LoRA do Hugging Face
HUGGINGFACE_REPO="oggimrm/HunyuanVideo"
HUGGINGFACE_REPO_URL="https://huggingface.co/datasets/${HUGGINGFACE_REPO}"
HUGGINGFACE_API_URL="https://huggingface.co/api/datasets/${HUGGINGFACE_REPO}/tree/main"

# Exit immediately if SKIP_LORAS is set to true
if [ "${SKIP_LORAS:-false}" == "true" ]; then
    echo "**** SKIPPING LORA DOWNLOADS (SKIP_LORAS=true) ****"
else
    echo "**** DOWNLOADING EXTRA LORAS ****"
    
    # Usar a API do Hugging Face para listar arquivos de forma confiável
    # Filtrar por nomes que comecem com "Lora_" e terminem com ".safetensors"
    LORAS_TO_DOWNLOAD=$(curl -s "${HUGGINGFACE_API_URL}" | grep -oP '(?<="path":")[^"]*Lora_[^"]*\.safetensors' || true)

    if [ -z "$LORAS_TO_DOWNLOAD" ]; then
        echo "⚠️ No LoRA files found in the repository. Please check the URL or the file patterns."
    else
        echo "--- LoRAs to download ---"
        for filename in $LORAS_TO_DOWNLOAD; do
            echo "- ${filename}" 
            download_if_not_exists "${HUGGINGFACE_REPO_URL}/resolve/main/${filename}" \
                "${LORA_DIR}/${filename}"
        done
        echo "----------------------------------------"
    fi
fi

# Exit immediately if SKIP_CHECKPOINTS is set to true
if [ "${SKIP_CHECKPOINTS:-false}" == "true" ]; then
    echo "**** SKIPPING CHECKPOINT DOWNLOADS (SKIP_CHECKPOINTS=true) ****"
else
    echo "**** DOWNLOADING EXTRA CHECKPOINTS ****"

    # Usar a API do Hugging Face para listar arquivos de forma confiável
    # Filtrar por nomes que comecem com "Checkpoint_" e terminem com ".safetensors"
    CHECKPOINTS_TO_DOWNLOAD=$(curl -s "${HUGGINGFACE_API_URL}" | grep -oP '(?<="path":")[^"]*Checkpoint_[^"]*\.safetensors' || true)
    
    if [ -z "$CHECKPOINTS_TO_DOWNLOAD" ]; then
        echo "⚠️ No Checkpoint files found in the repository. Please check the URL or the file patterns."
    else
        echo "--- Checkpoints to download ---"
        for filename in $CHECKPOINTS_TO_DOWNLOAD; do
            echo "- ${filename}"
            download_if_not_exists "${HUGGINGFACE_REPO_URL}/resolve/main/${filename}" \
                "${CHECKPOINTS_DIR}/${filename}"
        done
        echo "----------------------------------------"
    fi
fi

echo "✨ Download extra models completed successfully ✨"
