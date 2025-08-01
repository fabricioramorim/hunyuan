#!/bin/bash
set -euo pipefail

# Exit immediately if SKIP_DOWNLOADS is set to true
if [ "${SKIP_DOWNLOADS:-false}" == "true" ]; then
    echo "SKIP_DOWNLOADS is set to true, skipping model downloads"
    exit 0
fi

MODEL_DIR="/ComfyUI/models"
mkdir -p ${MODEL_DIR}/{unet,text_encoders,clip_vision,vae,loras}

# Function to format file size (already present, keeping it)
format_size() {
    local size="${1:-0}"
    if [ "$size" -eq 0 ]; then
        echo "unknown size"
        return
    fi
    if [ "$size" -ge 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $size/1073741824}") GB"
    elif [ "$size" -ge 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $size/1048576}") MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$(awk "BEGIN {printf \"%.1f\", $size/1024}") KB"
    else
        echo "${size} B"
    fi
}

# New function to download file with retries and better error handling
download_file() {
    local url="$1"
    local dest="$2"
    local filename=$(basename "$dest")
    local model_type=$(basename $(dirname "$dest"))
    local max_retries=5
    local retry_count=0

    # Check if the file already exists and is not empty
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "✅ $filename already exists and is not empty in $model_type, skipping."
        return 0
    fi

    echo "📥 Starting download: $filename"
    
    while [ $retry_count -lt $max_retries ]; do
        echo "⏳ Download attempt $((retry_count + 1)) of $max_retries..."
        
        # Use wget with a simpler progress bar and check for non-zero exit code
        if wget --progress=dot:mega -O "$dest.tmp" "$url"; then
            # Check if the downloaded file is not empty
            if [ -s "$dest.tmp" ]; then
                mv "$dest.tmp" "$dest"
                echo "✨ Completed: $filename"
                return 0
            else
                echo "⚠️ Downloaded file is empty. Retrying..."
                rm -f "$dest.tmp"
            fi
        else
            echo "⚠️ wget command failed. Retrying..."
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "🔄 Waiting 5 seconds before retrying..."
            sleep 5
        fi
    done

    echo "❌ Failed to download $filename after $max_retries attempts."
    rm -f "$dest.tmp"
    return 1
}

echo "🚀 Starting model downloads..."

# Define download tasks with their respective directories
declare -A downloads=(
    ["${MODEL_DIR}/unet/hunyuan_video_720_cfgdistill_bf16.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_720_cfgdistill_bf16.safetensors"
    ["${MODEL_DIR}/loras/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_FastVideo_720_fp8_e4m3fn.safetensors"
    ["${MODEL_DIR}/text_encoders/Long-ViT-L-14-GmP-SAE-TE-only.safetensors"]="https://huggingface.co/zer0int/LongCLIP-SAE-ViT-L-14/resolve/main/Long-ViT-L-14-GmP-SAE-TE-only.safetensors"
    ["${MODEL_DIR}/text_encoders/llava_llama3_fp8_scaled.safetensors"]="https://huggingface.co/Comfy-Org/HunyuanVideo_repackaged/resolve/main/split_files/text_encoders/llava_llama3_fp8_scaled.safetensors"
    ["${MODEL_DIR}/vae/hunyuan_video_vae_bf16.safetensors"]="https://huggingface.co/Kijai/HunyuanVideo_comfy/resolve/main/hunyuan_video_vae_bf16.safetensors"
    ["${MODEL_DIR}/clip_vision/clip-vit-large-patch14.safetensors"]="https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors"
)

download_success=true
total_files=${#downloads[@]}
current_file=1

for dest in "${!downloads[@]}"; do
    url="${downloads[$dest]}"
    echo -e "\n📦 Processing file $current_file of $total_files"
    if ! download_file "$url" "$dest"; then
        download_success=false
        echo "⚠️ Failed to download $(basename "$dest") - continuing with other downloads"
    fi
    current_file=$((current_file + 1))
done

echo -e "\n🔍 Verifying downloads..."
verification_failed=false

# Re-checking all files after downloads
for dest in "${!downloads[@]}"; do
    dir=$(basename $(dirname "$dest"))
    file=$(basename "$dest")
    full_path="$MODEL_DIR/$dir/$file"
    
    if [ -f "$full_path" ]; then
        size=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path")
        if [ "$size" -eq 0 ]; then
            echo "❌ Error: $file is empty in $dir directory"
            verification_failed=true
        else
            formatted_size=$(format_size "$size")
            echo "✅ $file verified successfully in $dir directory ($formatted_size)"
        fi
    else
        echo "❌ Error: $file is missing from $dir directory"
        verification_failed=true
    fi
done

if [ "$download_success" = true ] && [ "$verification_failed" = false ]; then
    echo -e "\n✨ All models downloaded and verified successfully"
    exit 0
else
    echo -e "\n⚠️ Some models failed to download or verify"
    exit 1
fi
