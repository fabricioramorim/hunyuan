#!/bin/bash
set -e # Exit on error

# Garante que o script está iniciando em um diretório válido
cd /

# 🔎 Procura um comando Python válido (python3 é preferido)
PYTHON_CMD=""
if command -v python3 &> /dev/null
then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null
then
    PYTHON_CMD="python"
else
    echo "⚠️ Python 3 não encontrado. Tentando instalar com apt-get..."
    apt-get update && apt-get install -y python3 python3-pip
    
    # Re-verifica após a instalação
    if command -v python3 &> /dev/null
    then
        PYTHON_CMD="python3"
        echo "✅ Python 3 instalado com sucesso."
    else
        echo "❌ Erro fatal: A instalação do Python falhou ou apt-get não está disponível."
        exit 1
    fi
fi

echo "✅ Usando $PYTHON_CMD para scripts Python."

# Checa se os arquivos existem no workspace, copia da raiz se não
if [ ! -f "/workspace/download-files.sh" ]; then
    echo "🔄 Copiando download-files.sh para o workspace"
    if [ -f "/download-files.sh" ]; then
        cp /download-files.sh /workspace/
        chmod +x /workspace/download-files.sh
        echo "✅ download-files.sh copiado para o workspace"
    else
        echo "❌ download-files.sh não encontrado no diretório raiz"
    fi
fi

if [ ! -f "/workspace/files.txt" ]; then
    echo "🔄 Copiando files.txt para o workspace"
    if [ -f "/files.txt" ]; then
        cp /files.txt /workspace/
        echo "✅ files.txt copiado para o workspace"
    else
        echo "❌ files.txt não encontrado no diretório raiz"
    fi
fi


echo "⭐⭐⭐⭐⭐   TUDO PRONTO - INICIANDO COMFYUI ⭐⭐⭐⭐⭐"

# Muda para o diretório do ComfyUI e inicia o servidor em segundo plano
cd /workspace/ComfyUI
$PYTHON_CMD main.py --listen --port 8188 --enable-cors-header $COMFYUI_EXTRA_ARGS &

echo "🖼️ Iniciando Infinite Image Browser..."
# Muda para o diretório do Image Browser e inicia o servidor em segundo plano
cd /workspace/sd-webui-infinite-image-browsing
$PYTHON_CMD app.py --port=8181 --extra_paths /workspace/ComfyUI/output --host=0.0.0.0 &

# Mantém o contêiner em execução
wait -n
