#!/bin/bash

# Este arquivo será chamado em init.sh

PYTHON_PACKAGES=(
    "diffusers==0.28.0"
    "huggingface_hub==0.14.1"
    # "opencv-python==4.7.0.72"
)

NODES=(
    "https://github.com/projetosTherion/TherionManager"
    "https://github.com/projetosTherion/TherionEasy"
    "https://github.com/projetosTherion/TherionControl"
    "https://github.com/projetosTherion/TherionMariGold"
    "https://github.com/projetosTherion/TherionIPAdapter"
    "https://github.com/projetosTherion/TherionSDUpscale"
    "https://github.com/projetosTherion/TherionSaveImageReal"
    "https://github.com/projetosTherion/TherionEssentials"
    "https://github.com/projetosTherion/TherionInspire"
)


CHECKPOINT_MODELS=(
    #"https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt"
    "https://drive.google.com/uc?id=1fNW8zJYQuEh9uCjhk-H7fvJfyEWoEkPQ"
    "https://drive.google.com/uc?id=1MmB0X9GZxqoVwf3M3yhYQxvWpjjFgrBq" #novo
)

LORA_MODELS=(
    #"https://drive.google.com/uc?id=1J-fWHtny3MvBMKrTPSiXcv7mG24qQz6B"
)

VAE_MODELS=(
    #"https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors"
)

ESRGAN_MODELS=(
    #"https://drive.google.com/uc?id=1j6s83jYW1c7Yu6Ys4XuhRymxqIyexPOB"
    "https://drive.google.com/uc?id=1I7r_L1JX0g0QVQbj0y0Otjekux4kO1fr"
)

CONTROLNET_MODELS=(
    "https://drive.google.com/uc?id=19TTVhBNwkCXa7Emoo_lW3TIJ1P3I2Ybp"
    "https://drive.google.com/uc?id=13N0zrQjuOzo6TEKTHtASqm11GhDWOEMQ"
    #"https://drive.google.com/uc?id=18E6aLDT0x9zwyjiAhyY1Ww7IJI467ZWv"

    #novos
    "https://drive.google.com/uc?id=1x7g9sVIKuEw2wVMF1PiAHVFWCHecaQTJ"
    "https://drive.google.com/uc?id=1ShX6D-RKcbke9Ykvyoq7NfuBQUaKs9RZ"
    "https://drive.google.com/uc?id=1_rewirKccBw5b1OAT4mhd43AeFxtfdBa"
    "https://drive.google.com/uc?id=1KuT_cTj7NnbZlSfMKTGuCaoW5m3Yby5l"
    "https://drive.google.com/uc?id=121idUQS79HKNlQKrk4hePTIYVLonP1P2"
)

CLIPVISION_MODELS=(
    "https://drive.google.com/uc?id=1NbNcy3CXzDeHOLKGPTD2C4htjYzCv8TA"
)

IPADAPTER_MODELS=(
   # "https://drive.google.com/uc?id=1uO4xV1JAh3BLv1lwaliCBTKZgliUPZ3c"
    "https://drive.google.com/uc?id=1XhbbbEoOKUvXRgN6tDc7SV2aN11dt0kq" #novo
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
      DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_nodes
    provisioning_install_python_packages
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/ckpt" "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/lora" "${LORA_MODELS[@]}"
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/controlnet" "${CONTROLNET_MODELS[@]}"
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/vae" "${VAE_MODELS[@]}"
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/esrgan" "${ESRGAN_MODELS[@]}"
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/clip_vision" "${CLIPVISION_MODELS[@]}"
    provisioning_get_models "${WORKSPACE}/storage/stable_diffusion/models/ipadapter" "${IPADAPTER_MODELS[@]}"
    provisioning_print_end
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="/opt/ComfyUI/custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                (cd "$path" && git pull)
                [[ -e $requirements ]] && micromamba -n comfyui run ${PIP_INSTALL} -r "$requirements"
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive || { echo "Erro ao clonar o repositório: ${repo}"; continue; }
            [[ -e $requirements ]] && micromamba -n comfyui run ${PIP_INSTALL} -r "$requirements"
        fi

        # Verifique as dependências manualmente para repos específicos
        [[ "$dir" == "TherionIPAdapter" ]] && micromamba -n comfyui run pip install numpy opencv-python torch
    done
}

function provisioning_install_python_packages() {
    micromamba -n comfyui run pip install wget --upgrade
    [[ ${#PYTHON_PACKAGES[@]} -gt 0 ]] && micromamba -n comfyui run ${PIP_INSTALL} ${PYTHON_PACKAGES[*]}
}

function provisioning_get_models() {
    local dir="$1"
    shift
    mkdir -p "$dir"
    local models=("$@")

    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        models=("${models[0]}")
    fi

    printf "Downloading %s model(s) to %s...\n" "${#models[@]}" "$dir"
    for url in "${models[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]] && printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
}

function provisioning_print_end() {
    printf "\nProvisioning complete: Web UI will start now\n\n"
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    local file_name
    local file_path

    # Verifica se o wget está instalado; se não, instala automaticamente
    if ! command -v wget &> /dev/null; then
        echo "wget não encontrado. Instalando wget..."
        micromamba -n comfyui run ${PIP_INSTALL} wget
    fi

    file_name="${1##*/}"
    file_path="$2/$file_name"

    # Caso a URL seja do Google Drive, converte para o formato correto
    if [[ "$1" =~ ^https://drive.google.com ]]; then
        echo "Ajustando URL do Google Drive para o formato de download direto..."

        # Extrai o ID do arquivo do Google Drive
        local file_id=$(echo "$1" | sed 's/.*id=\([^&]*\).*/\1/')

        # Configura a URL para o download direto
        local download_url="https://drive.google.com/uc?export=download&id=${file_id}"

        # Baixa o arquivo, lidando com a confirmação de download
        wget --no-check-certificate --quiet --show-progress --https-only --timestamping \
            --content-disposition -O "$file_path" "$download_url"
        
        # Se o arquivo de confirmação do Google Drive for necessário, é necessário outro passo:
        if [[ ! -f "$file_path" ]]; then
            echo "Tentando novamente, porque o Google Drive precisa de confirmação do download..."
            wget --no-check-certificate --quiet --show-progress --https-only --timestamping \
                --content-disposition -O "$file_path" "$download_url&confirm=t"
        fi
    else
        # Para outras URLs, apenas faz o download diretamente
        wget -q --show-progress --https-only --timestamping -P "$2" "$1"
    fi
}


# Baixar e configurar o script monitor_comfyui.sh
function download_monitor_script() {
    local url="https://raw.githubusercontent.com/projetosTherion/CLIModels/main/config/provisioning/monitor_comfyui2.sh"
    local destination="/workspace/monitor_comfyui2.sh"
    
    echo "Baixando o script monitor_comfyui2.sh..."
    if wget -O "$destination" "$url"; then
        echo "Script baixado com sucesso."
        chmod +x "$destination"
        "$destination" & # Executa o script em segundo plano
    else
        echo "Erro ao baixar o script monitor_comfyui2.sh."
        exit 1
    fi
}

provisioning_start

# Chame a função para baixar e executar o monitor
download_monitor_script
