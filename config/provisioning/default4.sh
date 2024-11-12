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
    "https://github.com/projetosTherion/TherionMariGold" #atualizado versao mais recente
    "https://github.com/projetosTherion/TherionIPAdapter"
    "https://github.com/projetosTherion/TherionSDUpscale"
    "https://github.com/projetosTherion/TherionSaveImageReal"
    "https://github.com/projetosTherion/TherionEssentials"
    "https://github.com/projetosTherion/TherionInspire"
)

CHECKPOINT_MODELS=(
    #"https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt"
    #"https://drive.google.com/uc?id=1fNW8zJYQuEh9uCjhk-H7fvJfyEWoEkPQ"
    "https://drive.google.com/uc?id=1vBVb9aTwHBZi7JCzcD3HTQqpjr1YFivg" #novo
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
    #"https://drive.google.com/uc?id=18E6aLDT0x9zwyjiAhyY1Ww7IJI467ZWv" #canny
    
    #novos
    "https://drive.google.com/uc?id=1HMFsqU9gK8cKKm5efwWtOvNF7RXo7Q_y"
    "https://drive.google.com/uc?id=1OylT27QTcraiRdOTsQe04rH81lFz3Lxr"
    "https://drive.google.com/uc?id=1ZchTWFwLjyy3CRAUoh143odhZMr_ukgB"
    "https://drive.google.com/uc?id=1NMqlMcIL0OGha32SW8nVhoWkNbP8tp-v"

)


CLIPVISION_MODELS=(
    "https://drive.google.com/uc?id=1NbNcy3CXzDeHOLKGPTD2C4htjYzCv8TA"
)
IPADAPTER_MODELS=(
    #"https://drive.google.com/uc?id=1uO4xV1JAh3BLv1lwaliCBTKZgliUPZ3c"
    "https://drive.google.com/uc?id=1tL6pipwEcKDmmF-LQOd7zysY4jJXQ9CS" #novo
    
    

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
    micromamba -n comfyui run pip install rclone --upgrade
    rclone config create gdrive drive --config $RCLONE_CONFIG_PATH
    
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
    local remote="gdrive"
    local file_id
    local file_name
    local file_path

    if [[ $1 == *"drive.google.com"* ]]; then
        file_id=$(echo $1 | grep -oP '(?<=id=)[^&]+' | head -1)

        declare -A file_map=(
            ["19TTVhBNwkCXa7Emoo_lW3TIJ1P3I2Ybp"]="ttplanetSDXLControlnet_v20Fp16.safetensors"
            #["1fNW8zJYQuEh9uCjhk-H7fvJfyEWoEkPQ"]="Arcseed_V0.2.safetensors"
            ["13N0zrQjuOzo6TEKTHtASqm11GhDWOEMQ"]="LoraModelDepth.safetensors"
            #["18E6aLDT0x9zwyjiAhyY1Ww7IJI467ZWv"]="LoraModelCanny.safetensors"
            ["1I7r_L1JX0g0QVQbj0y0Otjekux4kO1fr"]="swift_srgan_2x.pth"
            ["1NbNcy3CXzDeHOLKGPTD2C4htjYzCv8TA"]="clipvis_ViT-H_1.5_.safetensors"
            #["1uO4xV1JAh3BLv1waliCBTKZgliUPZ3c"]="ip-adapter-plus_sdxl_vit-h.bin"

            #novos
            ["1vBVb9aTwHBZi7JCzcD3HTQqpjr1YFivg"]="Arcseed_1.5.V0.3.safetensors"
            ["1tL6pipwEcKDmmF-LQOd7zysY4jJXQ9CS"]="ip-adapter-plus_sdxl_vit-h.bin"
            ["1HMFsqU9gK8cKKm5efwWtOvNF7RXo7Q_y"]="controlnet11Models_scribble.safetensors"
            ["1OylT27QTcraiRdOTsQe04rH81lFz3Lxr"]="controlnet11Models_scribble.yaml"
            ["1NMqlMcIL0OGha32SW8nVhoWkNbP8tp-v"]="controlnet11Models_depht.safetensors"
            ["1ZchTWFwLjyy3CRAUoh143odhZMr_ukgB"]="controlnet11Models_depht.yaml"
        )

        file_name="${file_map[$file_id]}"
        file_path="$2/$file_name"

        [[ ! -d $2 ]] && mkdir -p "$2"

        echo "Downloading $file_name from Google Drive to $file_path"
        rclone copy "$remote:$file_id" "$file_path" --config $RCLONE_CONFIG_PATH || echo "Erro ao baixar o arquivo $file_name"
    else
        file_name=$(basename "$1")
        file_path="$2/$file_name"

        [[ ! -d $2 ]] && mkdir -p "$2"

        echo "Downloading $file_name to $file_path"
        wget -O "$file_path" "$1" || echo "Erro ao baixar o arquivo $file_name"
    fi
}


# Baixar e configurar o script monitor_comfyui.sh
function download_monitor_script() {
    local url="https://raw.githubusercontent.com/projetosTherion/CLIModels/main/config/provisioning/monitor_comfyui4.sh"
    local destination="/workspace/monitor_comfyui4.sh"
    
    echo "Baixando o script monitor_comfyui.sh..."
    if wget -O "$destination" "$url"; then
        echo "Script baixado com sucesso."
        chmod +x "$destination"
        "$destination" & # Executa o script em segundo plano
    else
        echo "Erro ao baixar o script monitor_comfyui.sh."
        exit 1
    fi
}

provisioning_start

# Chame a função para baixar e executar o monitor
download_monitor_script
