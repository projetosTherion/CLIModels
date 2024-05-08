#!/bin/bash

# Este arquivo será chamado em init.sh

PYTHON_PACKAGES=(
    # "opencv-python==4.7.0.72"
)

NODES=(
    "https://github.com/projetosTherion/TherionManager",
    "https://github.com/projetosTherion/TherionEasy",
    "https://github.com/projetosTherion/TherionControl",
    "https://github.com/projetosTherion/TherionMariGold",
    "https://github.com/projetosTherion/TherionIPAdapter"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt",
    "https://drive.google.com/uc?id=1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"
)

LORA_MODELS=(
    # "https://civitai.com/api/download/models/16576"
)

VAE_MODELS=(
   "https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors",
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors",
    "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"
)

ESRGAN_MODELS=(
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth",
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth",
    "https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth",
    "https://huggingface.co/lokCX/4x-Ultrasharp/blob/main/4x-UltraSharp.pth"
)

CONTROLNET_MODELS=(
    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_canny_256lora.safetensors?download=true",
    "https://huggingface.co/TTPlanet/TTPLanet_SDXL_Controlnet_Tile_Realistic/resolve/main/TTPLANET_Controlnet_Tile_realistic_v2_fp16.safetensors?download=true",
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors?download=true",
    "https://drive.google.com/uc?id=1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6"
)

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
    provisioning_print_end
}

function build_extra_get_nodes() {
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
    # Instala ou atualiza o gdown
    micromamba -n comfyui run pip install gdown --upgrade

    # Imprime a versão do gdown para verificar se está instalado
    echo "Verificando a instalação do gdown..."
    $gdown_path --version  # Usando o caminho completo para evitar qualquer problema de PATH

    if [ ${#PYTHON_PACKAGES[@]} -gt 0 ]; then
        micromamba -n comfyui run pip install ${PYTHON_PACKAGES[*]}
    fi
}

function build_extra_get_models() {
    if [[ -n $2 ]]; then
        dir="$1"
        mkdir -p "$dir"
        shift
        arr=("$@")
        
        printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
        for url in "${arr[@]}"; do
            printf "Downloading: %s\n" "${url}"
            build_extra_download "${url}" "${dir}"
            printf "\n"
        done
    fi
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

function provisioning_download() {
    local gdown_path="/opt/micromamba/envs/comfyui/bin/gdown"  # Caminho completo para o gdown
    wget -nv -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1" > "$2/wget_$(basename $1).log" 2>&1
    
    if [[ $1 == *"drive.google.com"* ]]; then
        local file_id=$(echo $1 | grep -oP '(?<=id=)[^&]+' | head -1)
        $gdown_path "https://drive.google.com/uc?id=$file_id" -O "$2/$(basename $file_id)" > "$2/gdown_${file_id}.log" 2>&1 
    fi
}



provisioning_start
