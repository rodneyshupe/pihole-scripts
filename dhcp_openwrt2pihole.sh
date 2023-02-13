#!/bin/bash

# Function to process each host configuration block
function process_config_block() {
    local config_block="$1"
    local block_type="${2:-host}"

    local name=""
    local mac=""
    local ip=""
    local dns=""

    local line=""
    while read line; do
        if [[ "$line" == "option "* ]]; then
            key=$(echo $line | awk '{split($0,a," "); print a[2]}')
            value=$(echo $line | awk '{split($0,a," "); print a[3]}' | sed -e "s/'//g" -e 's/"//g')

            case "$key" in
                "name" ) name="$value" ;;
                "mac"  ) mac="$value" ;;
                "ip"   ) ip="$value" ;;
                "dns"  ) dns="$value" ;;
            esac
            value=""
        fi
    done <<< "$config_block"

    if [ "$blocktype" == "host" ]; then
        if [ -z "$dns" ] || [ -z "$mac" ] || ([ -z "$name" ] && [ -z "$ip" ]); then
            [ -z "$mac" ] && mac="<unknown>"
            [ -z "$ip" ] && ip="<unknown>"
            [ -z "$name" ] && name="<unknown>"
            echo "# dhcp-host=${mac^^},$ip,$name"
        else
            echo "$(echo "dhcp-host=${mac^^},$ip,$name" | sed -e 's/,,/,/g')"
        fi
    elif [ "$blocktype" == "domain" ]; then
        if [ ! -z "$name" ] && [ ! -z "$ip" ]; then
            #echo "$ip $name"
        fi
    fi
}

function remove_duplicate_hostnames() {
  local file="$1"

  # Create a new file without duplicates
  awk -F, '{if (!seen[$NF]++) {print} else {print "#"$0}}' "$file" > "$file.new"

  # Replace the original file with the new one
  mv "$file.new" "$file"
}

function process_openwrt_file() {
    local dhcp_config_file="$1"
    # Read the input file line by line
    local config_block=""
    local adding_to_block=0
    local line=""
    local block_type=""
    while read line; do
        if [[ "$line" == "config "* ]]; then
            if [ ! -z "$config_block" ]; then
                process_config_block "$(echo -e "$config_block")" "$block_type"
                config_block=""
                block_type=""
            fi
            if [[ "$line" == "config host" ]]; then
                adding_to_block=1
                block_type="host"
            else [[ "$line" == "config domain" ]]; then
                adding_to_block=1
                block_type="domain"
            else
                adding_to_block=0
                block_type=""
            fi
        fi
        if [ $adding_to_block -eq 1 ] && [ ! -z "$line" ]; then
            config_block="$config_block\n$line"
        fi
    done < "$dhcp_config_file"

    # Process the last host configuration block if there is one
    if [ ! -z "$config_block" ]; then
        process_config_block "$(echo -e "$config_block")" "$block_type"
    fi
}

# Open the input file
openwrt_dhcp_config_file="openwrt_dhcp.conf"
if [ ! -f "$openwrt_dhcp_config_file" ]; then
    echo "Error: input file $openwrt_dhcp_config_file does not exist."
    exit 1
else
    process_openwrt_file "$openwrt_dhcp_config_file" > pihole-static-dhcp.conf
    remove_duplicate_hostnames pihole-static-dhcp.conf
fi

