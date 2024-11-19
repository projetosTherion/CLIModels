#!/bin/bash

# Este arquivo será chamado em init.sh

PYTHON_PACKAGES=(
    "diffusers==0.28.0"
    #"transformers==4.32.0"
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
    "https://drive.google.com/uc?id=1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"
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
    "https://drive.google.com/uc?id=1xHZspe7h_P-KwSbCunMyfGJpKM1a3Ooo"
)

CONTROLNET_MODELS=(
    "https://drive.google.com/uc?id=1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6"
    "https://drive.google.com/uc?id=1J-fWHtny3MvBMKrTPSiXcv7mG24qQz6B"
    "https://drive.google.com/uc?id=1oXZrJSVG4aAz9hGZeDMI6ccewc_n_EuL"
    #novos
    "https://drive.google.com/uc?id=1x7g9sVIKuEw2wVMF1PiAHVFWCHecaQTJ"
    "https://drive.google.com/uc?id=1ShX6D-RKcbke9Ykvyoq7NfuBQUaKs9RZ"
    "https://drive.google.com/uc?id=1_rewirKccBw5b1OAT4mhd43AeFxtfdBa"
    "https://drive.google.com/uc?id=1KuT_cTj7NnbZlSfMKTGuCaoW5m3Yby5l"
    "https://drive.google.com/uc?id=121idUQS79HKNlQKrk4hePTIYVLonP1P2"
)

CLIPVISION_MODELS=(
    "https://drive.google.com/uc?id=1-Lkm7VX783d_jikdYu2wyK-huy0jR90j"
)

IPADAPTER_MODELS=(
    #"https://drive.google.com/uc?id=1tL6pipwEcKDmmF-LQOd7zysY4jJXQ9CS"
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
                [[ -e $requirements ]] && pip install -r "$requirements"
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive || { echo "Erro ao clonar o repositório: ${repo}"; continue; }
            [[ -e $requirements ]] && pip install -r "$requirements"
        fi

        [[ "$dir" == "TherionIPAdapter" ]] && pip install numpy opencv-python torch
    done
}

function provisioning_install_python_packages() {
    pip install gdown --upgrade
    [[ ${#PYTHON_PACKAGES[@]} -gt 0 ]] && pip install "${PYTHON_PACKAGES[@]}"
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
    local gdown_path="/opt/environments/python/comfyui/bin/gdown"
    local url="$1"
    local dest_dir="$2"
    local file_id=""
    local file_name=""
    local file_path=""

    # Verificar se o destino existe; criar se necessário
    [[ ! -d $dest_dir ]] && mkdir -p "$dest_dir"

    if [[ $url == *"drive.google.com"* ]]; then
        # Extraindo o ID do arquivo do Google Drive
        file_id=$(echo "$url" | grep -oP '(?<=id=)[^&]+' | head -1)

        # Mapeando o nome do arquivo pelo ID (opcional)
        declare -A file_map=(
            ["1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6"]="ttplanetSDXLControlnet_v20Fp16.safetensors"
            ["1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"]="Arcseed_V0.2.safetensors"
            ["1J-fWHtny3MvBMKrTPSiXcv7mG24qQz6B"]="LoraModelDepth.safetensors"
            ["1xHZspe7h_P-KwSbCunMyfGJpKM1a3Ooo"]="swift_srgan_2x.pth"
            ["1-Lkm7VX783d_jikdYu2wyK-huy0jR90j"]="clipvis_ViT-H_1.5_.safetensors"
            ["1MmB0X9GZxqoVwf3M3yhYQxvWpjjFgrBq"]="Arcseed_1.5.V0.3.safetensors"
            ["1XhbbbEoOKUvXRgN6tDc7SV2aN11dt0kq"]="ip-adapter-plus_sdxl_vit-h.bin"
            ["1x7g9sVIKuEw2wVMF1PiAHVFWCHecaQTJ"]="controlnet11Models_scribble.safetensors"
            ["1ShX6D-RKcbke9Ykvyoq7NfuBQUaKs9RZ"]="controlnet11Models_scribble.yaml"
            ["1KuT_cTj7NnbZlSfMKTGuCaoW5m3Yby5l"]="controlnet11Models_depht.safetensors"
            ["1_rewirKccBw5b1OAT4mhd43AeFxtfdBa"]="controlnet11Models_depht.yaml"
        )

        file_name="${file_map[$file_id]}"
        file_path="$2/$file_name"

        [[ ! -d $2 ]] && mkdir -p "$2"

        echo "Downloading $file_name from Google Drive to $file_path"
        $gdown_path "https://drive.google.com/uc?id=$file_id" -O "$file_path" || echo "Erro ao baixar o arquivo $file_name"
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
    local url="https://raw.githubusercontent.com/projetosTherion/CLIModels/main/config/provisioning/monitor_comfyui.sh"
    local destination="/workspace/monitor_comfyui.sh"
    
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
