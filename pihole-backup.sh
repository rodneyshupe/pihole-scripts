#!/usr/bin/env bash

SCRIPT_NAME=$0

backup_path="/mnt/storage/backups/pihole"
backup_file_base="pihole_backup_"
backup_file="$backup_file_base$(date +"%Y-%m-%d").tar.gz"

FLAG_CLEANUP=1

function usage {
    echo "Usage: ${SCRIPT_NAME} [options] [container list]"
    if [ $# -eq 0 ] || [ -z "$1" ]; then
        echo "  -b|--backup-path /path/to/backups    path to store backup"
        echo "  -f|--filename    filename.tar.gz     use supplied filename"
        echo "  -h|--help                            Display help"
    fi
}

function parse_arguments () {
    while (( "$#" )); do
        case "$1" in
            -b|--backup-path)
                shift
                backup_path="$1"
                shift
                ;;
             -f|--filename)
                shift
                backup_file="$1"
                FLAG_CLEANUP=0
                shift
                ;;
            -h|--help)
                echo "$(usage)"
                shift
                exit 0
                ;;
            -*|--*=) # unsupported flags
                echo "ERROR: Unsupported flag $1" >&2
                echo "$(usage)" >&2
                exit 1
                ;;
            *) # preserve positional arguments
                echo "ERROR: Unsupported optional argument $1" >&2
                echo "$(usage)" >&2
                exit 1
                ;;
        esac
    done
}

parse_arguments $@

echo "Creating pihole backup ($backup_file)..."
pihole -a -t "$backup_file"
echo "Moving backup to $backup_path"
sudo cp "$backup_file" "$backup_path" && rm "$backup_file"
if [ $FLAG_CLEANUP -eq 1 ]; then
    # Get a list of all the backup files in the directory
    files=($(ls $backup_path/$backup_file_base*.tar.gz | sort -r))

    # Remove all but the 3 most recent files
    for ((i=3; i<${#files[@]}; i++)); do
        rm "${files[i]}"
    done
fi