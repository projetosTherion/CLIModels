#!/bin/bash

# Este arquivo será chamado em init.sh

APT_PACKAGES=(
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)

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
    "https://drive.google.com/uc?id=1PgfTfGlqU_zed_VdXoylKV_Fnx4xkl9b" #Arcseed_V0.2.safetensors
    "https://drive.google.com/uc?id=1zwWi3VyAX59xmBKROdiPBykcEqi_4Q4r" #Arcseed_1.5.V0.3.safetensors
)

LORA_MODELS=(
    #"https://drive.google.com/uc?id=1J-fWHtny3MvBMKrTPSiXcv7mG24qQz6B"
)

VAE_MODELS=(
    #"https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors"
)

ESRGAN_MODELS=(
    #"https://drive.google.com/uc?id=1j6s83jYW1c7Yu6Ys4XuhRymxqIyexPOB"
    "https://drive.google.com/uc?id=1MjkXyL861JqfgvRJw6hcmTYf8EgqXK4C" #swift_srgan_2x.pth
)

CONTROLNET_MODELS=(
    "https://drive.google.com/uc?id=1nPYHH9c0uFhx4x0L3E9KPEwMCqTfq0Dz" #ttplanetSDXLControlnet_v20Fp16.safetensors
    "https://drive.google.com/uc?id=1mM8jf_BTZ04uuW_7RxLtFl0_LO79Jrf1" #LoraModelDepth.safetensors
    "https://drive.google.com/uc?id=1zSaUPooORUfV6BMTmC0etS7aJfzx-ycQ" #control-lora-canny-rank256.safetensors
    #novos
    "https://drive.google.com/uc?id=12NBsbX0wBeZ5tvSyErJyD6tRl9A-Wju4" #controlnet11Models_scribble.safetensors
    "https://drive.google.com/uc?id=1Jen7mv1xnSdi3TKD1Q_gI6w3c6LHMA7W" #controlnet11Models_scribble.yaml
    "https://drive.google.com/uc?id=17xFkFBbYFVn03rRawEN1DU3P1971FWCe" #controlnet11Models_depht.yaml
    "https://drive.google.com/uc?id=19z5qYZR714nrwbQZsIGjFMgsJkE8IxU7" #controlnet11Models_depth.safetensors
    "https://drive.google.com/uc?id=1njInc6dTpTP7qlP-ijZzQ1S4ibFondIe" #LoraModelScribble.safetensors
    "https://drive.google.com/uc?id=1uLZEmV9kCtpVyobRDRxEXwnDjp2burqc" #extra_details.safetensors
    
)


CLIPVISION_MODELS=(
    "https://drive.google.com/uc?id=1RGUNbPKhs0BNQ4wkRQYmES9e45rni2ba" #clipvis_ViT-H_1.5_.safetensors
)

IPADAPTER_MODELS=(
    #"https://drive.google.com/uc?id=1tL6pipwEcKDmmF-LQOd7zysY4jJXQ9CS"
    "https://drive.google.com/uc?id=1Rzo3UxYd0Ksl2LwKKJpDfmNRa0Fp1Jj3" #ip-adapter-plus_sdxl_vit-h.bin
    "https://drive.google.com/uc?id=1rH2mLAKPZY-BPo5_UoT7y-_l7XUdr2yp" #ip-adapter-plus_sd15.safetensors
    
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
     if [[ ! -d /opt/environments/python ]]; then 
        export MAMBA_BASE=true
    fi
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh comfyui

    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
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

function pip_install() {
    if [[ -z $MAMBA_BASE ]]; then
            "$COMFYUI_VENV_PIP" install --no-cache-dir "$@"
        else
            micromamba run -n comfyui pip install --no-cache-dir "$@"
        fi
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip_install ${PIP_PACKAGES[@]}
    fi
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
                   pip_install -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip_install -r "${requirements}"
            fi
        fi
    done
}


function provisioning_install_python_packages() {
    pip_install gdown --upgrade
    [[ ${#PYTHON_PACKAGES[@]} -gt 0 ]] && pip_install "${PYTHON_PACKAGES[@]}"
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
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
            ["1nPYHH9c0uFhx4x0L3E9KPEwMCqTfq0Dz"]="ttplanetSDXLControlnet_v20Fp16.safetensors" 
            ["1PgfTfGlqU_zed_VdXoylKV_Fnx4xkl9b"]="Arcseed_V0.2.safetensors" 
            ["1mM8jf_BTZ04uuW_7RxLtFl0_LO79Jrf1"]="LoraModelDepth.safetensors" 
            ["1MjkXyL861JqfgvRJw6hcmTYf8EgqXK4C"]="swift_srgan_2x.pth" 
            ["1RGUNbPKhs0BNQ4wkRQYmES9e45rni2ba"]="clipvis_ViT-H_1.5_.safetensors" 
            ["1zwWi3VyAX59xmBKROdiPBykcEqi_4Q4r"]="Arcseed_1.5.V0.3.safetensors" 
            ["1Rzo3UxYd0Ksl2LwKKJpDfmNRa0Fp1Jj3"]="ip-adapter-plus_sdxl_vit-h.bin" 
            ["1rH2mLAKPZY-BPo5_UoT7y-_l7XUdr2yp"]="ip-adapter-plus_sd15.safetensors" 
            ["12NBsbX0wBeZ5tvSyErJyD6tRl9A-Wju4"]="controlnet11Models_scribble.safetensors" 
            ["1Jen7mv1xnSdi3TKD1Q_gI6w3c6LHMA7W"]="controlnet11Models_scribble.yaml" 
            ["19z5qYZR714nrwbQZsIGjFMgsJkE8IxU7"]="controlnet11Models_depth.safetensors" 
            ["17xFkFBbYFVn03rRawEN1DU3P1971FWCe"]="controlnet11Models_depht.yaml" 
            ["1zSaUPooORUfV6BMTmC0etS7aJfzx-ycQ"]="control-lora-canny-rank256.safetensors" 
            ["1uLZEmV9kCtpVyobRDRxEXwnDjp2burqc"]="extra_details.safetensors" 
            ["1njInc6dTpTP7qlP-ijZzQ1S4ibFondIe"]="LoraModelScribble.safetensors" 
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


# # Baixar e configurar o script monitor_comfyui.sh
# function download_monitor_script() {
#     local url="https://raw.githubusercontent.com/projetosTherion/CLIModels/main/config/provisioning/monitor_comfyui3.sh"
#     local destination="/workspace/monitor_comfyui3.sh"
    
#     echo "Baixando o script monitor_comfyui3.sh..."
#     if wget -O "$destination" "$url"; then
#         echo "Script baixado com sucesso."
#         chmod +x "$destination"
#         "$destination" & # Executa o script em segundo plano
#     else
#         echo "Erro ao baixar o script monitor_comfyui3.sh."
#         exit 1
#     fi
# }

 provisioning_start

# # Chame a função para baixar e executar o monitor
# download_monitor_script
