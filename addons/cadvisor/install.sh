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

function port_in_use() {
    port=$1

    # Check for any service
    if sudo lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
      return 0
    else
      return 1
    fi
}

function get_port() {
    local default_port=${1:-$DEFAULT_APP_PORT}
    local port
    while true; do
        echo -n "Enter port new number [$default_port]: " >&2
        read port
        port=${port:-$default_port}
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            if [ "$port" -eq 80 ] || [ "$port" -eq 443 ]; then
                echo "Port 80 and 443 are not allowed." >&2
            else
                if port_in_use $port; then
                    echo "Port $port is in use. Please choose another port." >&2
                else
                    echo -e -n "Selected port: $port\nIs this the correct port? [Y/n]" >&2
                    read answer
                    case "$answer" in
                        Y|y|"")
                            break
                            ;;
                        N|n)
                            continue
                            ;;
                        *)
                            echo "Invalid response." >&2
                            ;;
                    esac
                fi
            fi
        else
            echo "Invalid port number. Please enter a number." >&2
        fi
    done
    echo "$port"
}

function install_docker() {
    sudo apt install -y docker-compose
    sudo systemctl start docker

    sudo groupadd docker
    sudo usermod -aG docker ${USER}

    sudo gpasswd -a pi docker
    sudo gpasswd -a $USER docker

    sudo chown "$USER":"$USER" "$HOME/.docker" -R
    sudo chmod g+rwx "$HOME/.docker" -R

    echo "Need to relogin"
    su -s ${USER}

    #docker run hello-world
}

function install_cadvisor() {
    local CONFIG_PATH="$HOME/.config/docker/cadvisor"

    curl -sSL https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/cadvisor/docker-compose.yml --output $CONFIG_PATH/docker-compose.yml

    pwd=$PWD
    cd "$CONFIG_PATH"
    docker-compose up -d
    cd $pwd

    # TODO: Add:
    #           cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
    #       to /boot/cmdline.txt
}

echo "About to install the container for cAdvisor"
if confirm "Do you want to continue?" "N"; then
    if ! $(docker-compose -v >/dev/null 2>&1) ; then
        echo "Docker needs to be installed."
        echo ""
        if confirm "Do you want to continue?"; then
            install_docker
            echo ""
            echo "Reboot required. Once complete rerun the script."
            echo ""
            confirm "Do you want to continue?" true
            sudo shutdown --reboot now
        fi
    else
        install_cadvisor
    fi
fi

