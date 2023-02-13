#!/usr/bin/env bash

function confirm() {
    local prompt="$1"
    local default=${2:-Y}
    local exit_on_no=${3:-false}

    if [[ "$default" == "Y" ]]; then
        choice="Y/n"
    elif [[ "$default" == "N" ]]; then
        choice="y/N"
    else
        choice="y/n"
    fi
    echo -n "$prompt [$choice] " >&2
    read answer

    [[ "$answer" == "" ]] && answer="$default"
    
    case "$answer" in
        Y|y)
            return 0
            ;;
        N|n)
            if $exit_on_no; then
                echo "Exit!" >&2
                exit 1
            else
                return 1
            fi
            ;;
        *)
            echo "Invalid response." >&2
            return confirm "$prompt" "$default" "$exit_on_no"
            ;;
    esac
}

function run_script() {
    local source=$1
    local script=${2:-$HOME/.scripts/"$(basename "${source%.*}")"_"$(basename "$(dirname "$source")")".sh}

    mkdir -p "$(dirname "$scripts")"
    curl -sSL $source --output $script
    chmod +x "$script"
    "$script"
}

run_script https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/PADD/install.sh
run_script https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/nginx-proxy-manager/install.sh
run_script https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/heimdall/install.sh
run_script https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/speedtest/install.sh

# TODO: node-exporter
# TODO: OpenCanary

echo "It is recommended that you do a full reboot."
if confirm "Do you want to Reboot now " "N"; then
    sudo shutdown -r now
fi
