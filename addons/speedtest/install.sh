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

echo "About to install Speedtest CLI."
if confirm "Do you want to continue?" "N"; then
    echo "Install Prerequisites"
    curl -sSL https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash

    echo "Install Speedtest CLI"
    sudo apt update && sudo apt install -y speedtest >/dev/null
fi