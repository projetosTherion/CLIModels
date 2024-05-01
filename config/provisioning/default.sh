#!/bin/bash

# Dependências: wget, git, conda

PYTHON_PACKAGES=(
    # "opencv-python==4.7.0.72"  # Exemplo de pacote Python, descomente e ajuste conforme necessário
)

NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager",
    "https://github.com/yolain/ComfyUI-Easy-Use",
    "https://github.com/Fannovel16/comfyui_controlnet_aux",
    "https://github.com/kijai/ComfyUI-Marigold",
    "https://github.com/LykosAI/ComfyUI-Inference-Core-Nodes",
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus",
    "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111"
)

CHECKPOINT_MODELS=(
    "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt",
    "https://drive.google.com/uc?id=1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"
)

LORA_MODELS=(
    # Exemplo: "https://drive.google.com/uc?id=YOUR_FILE_ID"
)

VAE_MODELS=(
    "https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors",
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors",
    "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors"
)

ESRGAN_MODELS=(
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth",
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth",
    "https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth"
)

CONTROLNET_MODELS=(
    "https://github.com/cubiq/ComfyUI_IPAdapter_plus",
    "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/sai_xl_canny_256lora.safetensors?download=true",
    "https://drive.google.com/uc?id=1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6",
    "https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors?download=true",
    "https://huggingface.co/openai/clip-vit-large-patch14/resolve/main/model.safetensors?download=true"
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    echo "Starting provisioning..."
    provisioning_get_nodes
    provisioning_install_python_packages
    provisioning_get_models "ckpt" "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models "lora" "${LORA_MODELS[@]}"
    provisioning_get_models "controlnet" "${CONTROLNET_MODELS[@]}"
    provisioning_get_models "vae" "${VAE_MODELS[@]}"
    provisioning_get_models "esrgan" "${ESRGAN_MODELS[@]}"
    echo "Provisioning complete."
}

function provisioning_get_nodes() {
    echo "Getting nodes..."
    for repo in "${NODES[@]}"; do
        dir=$(basename "$repo")
        path="/opt/ComfyUI/custom_nodes/${dir}"
        if [[ -d $path ]]; then
            echo "Updating node: ${dir}..."
            (cd "$path" && git pull)
        else
            echo "Cloning node: ${dir}..."
            git clone "${repo}" "${path}"
        fi
        if [[ -f "${path}/requirements.txt" ]]; then
            echo "Installing requirements for ${dir}..."
            conda install --yes --file "${path}/requirements.txt"
        fi
    done
}

function provisioning_install_python_packages() {
    if [[ ${#PYTHON_PACKAGES[@]} -gt 0 ]]; then
        echo "Installing Python packages..."
        conda install --yes "${PYTHON_PACKAGES[@]}"
    fi
}

function provisioning_get_models() {
    local category="$1"
    shift
    local models=("$@")
    local dir="${WORKSPACE}/storage/stable_diffusion/models/${category}"
    mkdir -p "$dir"
    echo "Downloading models to ${dir}..."
    for url in "${models[@]}"; do
        if ! provisioning_download "${url}" "${dir}"; then
            echo "Failed to download model from ${url}"
        fi
    done
}

function provisioning_download() {
    local url="$1"
    local dir="$2"
    wget -q --show-progress --continue --directory-prefix="$dir" "$url"
    return $?
}

provisioning_start
