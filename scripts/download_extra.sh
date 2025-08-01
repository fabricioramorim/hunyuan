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

# Exit immediately if SKIP_LORAS is set to true
if [ "${SKIP_LORAS:-false}" == "true" ]; then
    echo "**** SKIPPING LORA DOWNLOADS (SKIP_LORAS=true) ****"
else
    echo "**** DOWNLOADING EXTRA LORAS ****"

    # Listagem explícita dos arquivos LoRA para evitar erros de parsing
    declare -a LORAS_TO_DOWNLOAD=(
        "lora_name_1.safetensors" # Substitua com o nome real dos seus arquivos LoRA
        "lora_name_2.safetensors" # Adicione mais linhas conforme necessário
    )

    if [ ${#LORAS_TO_DOWNLOAD[@]} -eq 0 ]; then
        echo "⚠️ No LoRA files found to download. Please check the list in the script."
    else
        echo "--- LoRAs to download ---"
        for filename in "${LORAS_TO_DOWNLOAD[@]}"; do
            echo "- ${filename}" 
            download_if_not_exists "https://huggingface.co/datasets/oggimrm/HunyuanVideo/resolve/main/${filename}" \
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

    # Listagem explícita dos arquivos Checkpoint para evitar erros de parsing
    declare -a CHECKPOINTS_TO_DOWNLOAD=(
        "checkpoint_name_1.safetensors" # Substitua com o nome real dos seus arquivos Checkpoint
        "checkpoint_name_2.safetensors" # Adicione mais linhas conforme necessário
    )
    
    if [ ${#CHECKPOINTS_TO_DOWNLOAD[@]} -eq 0 ]; then
        echo "⚠️ No Checkpoint files found to download. Please check the list in the script."
    else
        echo "--- Checkpoints to download ---"
        for filename in "${CHECKPOINTS_TO_DOWNLOAD[@]}"; do
            echo "- ${filename}"
            download_if_not_exists "https://huggingface.co/datasets/oggimrm/HunyuanVideo/resolve/main/${filename}" \
                "${CHECKPOINTS_DIR}/${filename}"
        done
        echo "----------------------------------------"
    fi
fi

echo "✨ Download extra models completed successfully ✨"
