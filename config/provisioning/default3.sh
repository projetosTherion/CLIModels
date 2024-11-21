#!/bin/bash

# Python packages to install
PYTHON_PACKAGES=(
    "diffusers==0.28.0"
    "huggingface_hub==0.14.1"
)

# Node repositories to clone/update
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

# Models to download
CHECKPOINT_MODELS=(
    "https://drive.google.com/uc?id=1nUILIbv4Tqi6L6zqYYnFspKjD1qqdpOr"
    "https://drive.google.com/uc?id=1MmB0X9GZxqoVwf3M3yhYQxvWpjjFgrBq"
)

CONTROLNET_MODELS=(
    "https://drive.google.com/uc?id=1QmgZFXkJoHNDiBVK8EqjmVeunbtDW9m6"
    "https://drive.google.com/uc?id=1J-fWHtny3MvBMKrTPSiXcv7mG24qQz6B"
)

# Function to install Python dependencies
function install_dependencies() {
    echo "Installing dependencies from requirements.txt..."
    if [[ -f "requirements.txt" ]]; then
        micromamba -n comfyui run pip install -r requirements.txt
    fi

    echo "Installing additional Python packages..."
    micromamba -n comfyui run pip install "${PYTHON_PACKAGES[@]}"
}

# Function to download files
function download_file() {
    local url=$1
    local dest_dir=$2
    local file_name=$3

    [[ ! -d $dest_dir ]] && mkdir -p "$dest_dir"

    if [[ $url == "drive.google.com" ]]; then
        local file_id=$(echo "$url" | grep -oP '(?<=id=)[^&]+')
        echo "Downloading from Google Drive: $file_name"
        wget --no-check-certificate "https://drive.google.com/uc?export=download&id=$file_id" -O "$dest_dir/$file_name"
    else
        echo "Downloading from URL: $file_name"
        wget -O "$dest_dir/$file_name" "$url"
    fi
}

# Function to clone or update node repositories
function get_nodes() {
    local base_dir="/opt/ComfyUI/custom_nodes"
    for repo in "${NODES[@]}"; do
        local dir_name=$(basename "$repo")
        local dir_path="$base_dir/$dir_name"
        if [[ -d $dir_path ]]; then
            echo "Updating node: $dir_name"
            (cd "$dir_path" && git pull)
        else
            echo "Cloning node: $dir_name"
            git clone "$repo" "$dir_path"
        fi
    done
}

# Function to download models
function get_models() {
    local dest_dir=$1
    shift
    for model_url in "$@"; do
        local file_name=$(basename "$model_url" | sed 's/\?.*//')
        download_file "$model_url" "$dest_dir" "$file_name"
    done
}

# Main provisioning function
function provisioning_start() {
    echo "Starting provisioning..."

    # Step 1: Install dependencies
    install_dependencies

    # Step 2: Clone or update node repositories
    get_nodes

    # Step 3: Download models
    echo "Downloading models..."
    get_models "/storage/stable_diffusion/models/ckpt" "${CHECKPOINT_MODELS[@]}"
    get_models "/storage/stable_diffusion/models/controlnet" "${CONTROLNET_MODELS[@]}"
}

# Start provisioning
provisioning_start
