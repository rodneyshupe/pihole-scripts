#!/usr/bin/env sh

function export() {
    MODE=${1:-dhcp}
    INPUT=${2:-openwrt_dhcp}

    IN_HOST=0; IN_DOMAIN=0
    MAC=""; IP=""; NAME=""

    while read -r FILE_LINE; do
        read -a parts <<< "$FILE_LINE"
        if [[ "${parts[0]}" == "config" ]]; then
            if [ $IN_HOST -eq 1 ]; then
                if [ ! -z $MAC ] && [ ! -z $IP ] && [ ! -z $NAME ]; then
                    if [[ "$MODE" == "dhcp" ]]; then
                        echo "dhcp-host=$MAC,$IP,$NAME" | sed -e "s/'//g" | sed -e 's/"//g'
                    elif [[ "$MODE" == "all" ]]; then
                        echo "$IP $NAME" | sed -e "s/'//g" | sed -e 's/"//g'
                    fi
                fi
            elif [ $IN_DOMAIN -eq 1 ]; then
                if [ ! -z $IP ] && [ ! -z $NAME ]; then 
                    if [[ "$MODE" == "hosts" ]] || [[ "$MODE" == "all" ]]; then
                        echo "$IP $NAME" | sed -e "s/'//g" | sed -e 's/"//g'
                    fi
                fi
            fi
            if [[ "${parts[1]}" == "host" ]]; then
                IN_HOST=1
                IN_DOMAIN=0
            elif [[ "${parts[1]}" == "domain" ]]; then
                IN_HOST=0
                IN_DOMAIN=1
            else
                IN_HOST=0
                IN_DOMAIN=0
            fi
            MAC=""; IP=""; NAME=""
        elif [[ "${parts[0]}" == "option" ]]; then
            case "${parts[1]}" in
                "mac")
                    MAC="${parts[2]}"
                    ;;
                "ip")
                    IP="${parts[2]}"
                    ;;
                "name")
                    NAME="${parts[2]}"
                    ;;
            esac
        #else
            #echo "DEBUG: ----"
            #for element in "${parts[@]}"; do
            #    echo "DEBUG: $element"
            #done
            #echo "DEBUG: ----"
        fi
    done < "$INPUT"

}
