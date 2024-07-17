#!/bin/bash

LOG_FILE="/var/log/supervisor/comfyui.log"
WORKFLOW_JSON_PATH="${WORKSPACE}start.json"
PUBLIC_IPADDR=${PUBLIC_IPADDR}
VAST_TCP_PORT_8188=${VAST_TCP_PORT_8188}
GOOGLE_DRIVE_FILE_ID="1d0qOyMw0GxuXmVwM3DQFGvcSN89yOYk9"

# Função para baixar o arquivo JSON do Google Drive
function download_workflow_json() {
    local file_id="$1"
    local destination="$2"
    echo "Baixando o arquivo start.json do Google Drive..."
    wget --no-check-certificate "https://docs.google.com/uc?export=download&id=${file_id}" -O "${destination}"
}

# Função para verificar se o ComfyUI está pronto
function is_comfyui_ready() {
    tail -n 50 "$LOG_FILE" | grep -q "Running on http://"
}

# Função para verificar se o ComfyUI está em execução
check_comfyui() {
    curl -s --head http://${PUBLIC_IPADDR}:${VAST_TCP_PORT_8188} | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
    return $?
}

# Função para enviar o payload JSON
function send_payload() {
    local comfyui_url="http://${PUBLIC_IPADDR}:${VAST_TCP_PORT_8188}/prompt"
    echo "Enviando payload JSON para $comfyui_url..."
    curl -X POST -H "Content-Type: application/json" -d @"$WORKFLOW_JSON_PATH" "$comfyui_url"
}

echo "Iniciando o monitoramento do ComfyUI..."

# Loop para verificar se o ComfyUI está pronto e baixar o arquivo start.json
while true; do
    if check_comfyui; then
        echo "ComfyUI está pronto."
        if [ ! -f $WORKFLOW_JSON_PATH ]; then
            download_workflow_json "$GOOGLE_DRIVE_FILE_ID" "$WORKFLOW_JSON_PATH"
            if [[ $? -ne 0 ]]; then
                echo "Erro ao baixar o arquivo start.json do Google Drive."
                exit 1
            fi
            echo "Arquivo start.json baixado com sucesso."
        fi
        break
    else
        echo "ComfyUI ainda não está pronto. Verificando novamente em 5 segundos..."
        sleep 5
    fi
done

# Loop de monitoramento
while true; do
    if is_comfyui_ready; then
        echo "ComfyUI está pronto. Enviando payload JSON..."
        send_payload
        if [[ $? -eq 0 ]]; then
            echo "Payload JSON enviado com sucesso!"
        else
            echo "Erro ao enviar payload JSON."
        fi
        break
    else
        echo "ComfyUI ainda não está pronto. Verificando novamente em 5 segundos..."
    fi
    sleep 5
done

echo "Monitoramento do ComfyUI encerrado."
