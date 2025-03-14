#!/bin/bash

# Instalação e configuração do rclone
micromamba -n comfyui run pip install rclone --upgrade

# Diretório onde o rclone.conf será copiado
RCLONE_CONFIG_PATH="/opt/micromamba/envs/comfyui/.config/rclone/rclone.conf"

# Copie o rclone.conf para o local correto
mkdir -p /opt/micromamba/envs/comfyui/.config/rclone
cp /caminho/para/seu/rclone.conf $RCLONE_CONFIG_PATH

# Verifique se o rclone está configurado corretamente
rclone listremotes --config $RCLONE_CONFIG_PATH

# Variáveis de ambiente e outras configurações
LOG_FILE="/var/log/supervisor/comfyui.log"
WORKFLOW_JSON_PATH="StarterV2.json"
PUBLIC_IPADDR=${PUBLIC_IPADDR}
VAST_TCP_PORT_8188=${VAST_TCP_PORT_8188}
GOOGLE_DRIVE_FILE_ID="1LmZ1-v6XKwqpwLT-pHqOmHop-rT0xBEX" # start
#https://drive.google.com/file/d/1LmZ1-v6XKwqpwLT-pHqOmHop-rT0xBEX/view?usp=sharing

# Função para baixar o arquivo JSON do Google Drive usando rclone
function download_workflow_json() {
    local file_id="$1"
    local destination="$2"
    local remote="gdrive"
    
    echo "Baixando o arquivo start.json do Google Drive usando rclone..."
    rclone copyto "${remote}:${file_id}" "${destination}" --drive-shared-with-me --drive-acknowledge-abuse --config $RCLONE_CONFIG_PATH
    
    if [[ $? -ne 0 ]]; then
        echo "Erro ao baixar o arquivo start.json do Google Drive."
        exit 1
    fi
    echo "Arquivo start.json baixado com sucesso."
}

# Função para verificar se o ComfyUI está pronto
function is_comfyui_ready() {
    tail -n 500 "$LOG_FILE" | grep -q "Prestartup times for custom nodes:"
}

# Função para verificar se o ComfyUI está em execução
check_comfyui() {
    curl -s --head http://${PUBLIC_IPADDR}:${VAST_TCP_PORT_8188} | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
    return $?
}

# Função para enviar o payload JSON
function send_payload() {
    local comfyui_url="http://${PUBLIC_IPADDR}:${VAST_TCP_PORT_8188}/prompt"
    local bearer_token="90d93ff52261c93690d6aad0a7a06c8da939ae2a5a39458349e6fc29ec3b61c0"
    
    echo "Enviando payload JSON para $comfyui_url..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $bearer_token" \
        -d @"$WORKFLOW_JSON_PATH" \
        "$comfyui_url")

    if [[ "$response" -ge 200 && "$response" -lt 300 ]]; then
        echo "Payload enviado com sucesso. Código de resposta: $response"
    else
        echo "Falha ao enviar payload. Código de resposta: $response"
    fi
    return 0
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

# Espera adicional para garantir que o ComfyUI esteja pronto
echo "Aguardando 10 segundos adicionais para garantir que o ComfyUI esteja totalmente inicializado..."
sleep 10

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
