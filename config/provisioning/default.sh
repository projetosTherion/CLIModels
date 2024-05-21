#!/bin/bash

# Este arquivo será chamado em init.sh

PYTHON_PACKAGES=(
    # "opencv-python==4.7.0.72"
)

NODES=(
    "https://github.com/projetosTherion/TherionManager"
    "https://github.com/projetosTherion/TherionEasy"
    "https://github.com/projetosTherion/TherionControl"
    "https://github.com/projetosTherion/TherionMariGold"
    "https://github.com/projetosTherion/TherionIPAdapter"
)

CHECKPOINT_MODELS=(
    #"https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt"
    "https://drive.google.com/uc?id=1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"
)

LORA_MODELS=(
    # "https://civitai.com/api/download/models/16576"
)

VAE_MODELS=(
   #"https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors"
   
)

ESRGAN_MODELS=(
    #"https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth"
   
)

CONTROLNET_MODELS=(
    "https://drive.google.com/uc?id=1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_nodes
    provisioning_install_python_packages
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
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
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                    micromamba -n comfyui run ${PIP_INSTALL} -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                micromamba -n comfyui run ${PIP_INSTALL} -r "${requirements}"
            fi
        fi
    done
}

function provisioning_install_python_packages() {
 micromamba -n comfyui run pip install gdown --upgrade
    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        micromamba -n comfyui run ${PIP_INSTALL} ${PYTHON_PACKAGES[*]}
    fi
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift
    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("$1")
    fi
    
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}

# Download from $1 URL to $2 file path
# Download from $1 URL to $2 file path
function provisioning_download() {
    local gdown_path="/opt/micromamba/envs/comfyui/bin/gdown"  # Caminho completo para o gdown

    if [[ $1 == *"drive.google.com"* ]]; then
        local file_id=$(echo $1 | grep -oP '(?<=id=)[^&]+' | head -1)
        
        # Mapeamento de IDs para nomes de arquivos
        declare -A file_map
        file_map["1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6"]="ttplanetSDXLControlnet_v20Fp16.safetensors"
        file_map["1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"]="Arcseed_V0.2.safetensors"

        local file_name="${file_map[$file_id]}"
        local file_path="$2/$file_name"

        if [[ ! -d $2 ]]; then
            echo "Diretório de destino $2 não existe. Criando diretório..."
            mkdir -p "$2"
        fi

        echo "Downloading $file_name from Google Drive to $file_path"
        $gdown_path "https://drive.google.com/uc?id=$file_id" -O "$file_path"
        echo "Download concluído: $file_path"
    else
        local file_name=$(basename "$1")
        local file_path="$2/$file_name"

        if [[ ! -d $2 ]]; then
            echo "Diretório de destino $2 não existe. Criando diretório..."
            mkdir -p "$2"
        fi

        echo "Using wget to download $file_name to $file_path"
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
        echo "Download concluído: $file_path"
    fi
}


provisioning_start
