#!/bin/bash
# Author: KC99 / Language: Bash
# Description: Automates the source and destination paths when opening veracrypt file containers
# ======================= Start-Code =======================
SRC=$1
BASE_PATH="/mnt/veracrypt"
COUNT=1
while true; do
    DES="${BASE_PATH}${COUNT}"
    # 1. Check if the directory exists
    if [ ! -d "$DES" ]; then
        echo "Directory $DES does not exist. Creating it now..."
        sudo mkdir -p "$DES"
        echo "SUCCESS: $DES is now available for mounting."
        break
    fi
    # 2. If it exists, check if it's an active mountpoint
    if mountpoint -q "$DES"; then
        echo "Slot $DES is currently ACTIVE. Moving to next slot..."
        ((COUNT++))
    else
        echo "Slot $DES exists but is NOT active. It is available for use."
        break
    fi
done
MAP="/dev/mapper/veracrypt${COUNT}"
echo Source...........: $SRC
echo Destination......: $DES
echo Mapper...........: $MAP
veracrypt --text --mount "$SRC" "$DES"
read -p "Enter to dismount..."
veracrypt -d "$DES"
exit
