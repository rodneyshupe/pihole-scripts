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

function install_padd() {
    curl -sSL https://install.padd.sh -o padd.sh
    sudo chmod +x ~/padd.sh
    sudo cp ~/padd.sh /usr/local/bin/padd
    if [[ "$USER" != "pihole" ]]; then
        sudo cp ~/padd.sh /home/pihole/padd.sh
        sudo chown pihole:pihole /home/pihole/padd.sh
    fi

    if confirm "Add auto start "; then
        if ! grep -q "padd.sh" /home/pihole/.bashrc; then
            curl -sSL https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/PADD/bashrc_snippet.sh | sudo tee -a /home/pihole/.bashrc
        fi
        if [ ! -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
            systemctl set-default multi-user.target
            ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
            curl -sSL https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/PADD/autologin.conf | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
        fi
    fi
}

echo "About to install PADD."
if confirm "Do you want to continue " "N"; then
    install_padd
    echo ""
    echo "For this to fully work a reboot will be required."
fi
