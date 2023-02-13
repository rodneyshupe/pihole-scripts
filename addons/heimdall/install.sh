#!/usr/bin/env bash

DEFAULT_APP_PORT=7080
DEFAULT_APP_PORT_SSL=7443

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

function create_env() {
    local ENV_FILE="${1:-$HOME/.config/docker/heimdall/.env}"
    local APP_PORT=${2:-$DEFAULT_APP_PORT}
    local APP_PORT_SSL=${3:-$DEFAULT_APP_PORT_SSL}

    local INSTALL_USER="$USER"

    # Ensure directory exists for .env file
    mkdir -p "$(dirname "$ENV_FILE")"

    # Create .env file
    echo "# Enviorment vaiables created using user $USER" >"$ENV_FILE"
    echo "PUID=$(id -u $INSTALL_USER)" >>"$ENV_FILE"
    echo "PGID=$(id -g $INSTALL_USER)" >>"$ENV_FILE"
    echo "TZ=$(timedatectl | grep 'Time zone' | awk '{print $3}')" >>"$ENV_FILE"
    echo "APPDATA_ROOT=$HOME/.config/docker" >>"$ENV_FILE"
    echo "APP_PORT=$APP_PORT" >>"$ENV_FILE"
    echo "APP_PORT_SSL=$APP_PORT_SSL" >>"$ENV_FILE"
}

function install_heimdall() {
    local INSTALL_USER="$USER"
    local CONFIG_PATH="$HOME/.config/docker/heimdall"

    local APP_PORT=80
    local APP_PORT_SSL=443
    if port_in_use $APP_PORT; then
        echo "Port $APP_PORT is in use. Select a new HTTP port for Heimdall."
        APP_PORT=$(get_port $DEFAULT_APP_PORT)
    fi
    echo "Using HTTP port $APP_PORT"

    if port_in_use $APP_PORT_SSL; then
        echo "Port $APP_PORT_SSL is in use. Select a new HTTPS port for Heimdall."
        APP_PORT_SSL=$(get_port $DEFAULT_APP_PORT_SSL)
    fi
    echo "Using HTTPS port $APP_PORT_SSL"

    mkdir -p $CONFIG_PATH/data
    # Create .env file
    local ENV_FILE="$CONFIG_PATH/.env"
    create_env "$ENV_FILE" $APP_PORT $APP_PORT_SSL

    curl -sSL https://raw.githubusercontent.com/rodneyshupe/pihole-addons/main/heimdall/docker-compose.yml --output $CONFIG_PATH/docker-compose.yml


    pwd=$PWD
    cd "$CONFIG_PATH"
    docker-compose up -d
    cd $pwd
}

echo "About to install the container for Heimdall"
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
        install_heimdall
    fi
fi
