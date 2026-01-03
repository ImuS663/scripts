#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: media-info.sh
# Description: Read media files short info using FFmpeg.
# Requirements: FFmpeg with ffprove.
# Usage: media-info.sh *.mp4
# ------------------------------------------------------------------------------

# Colors
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

# If no arguments → show usage
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <files>"
    exit 1
fi

for file in "$@"; do
    # Skip if not a file
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}$file is not a file, skipping${RESET}"
        continue
    fi
    
    echo -ne "${GREEN}${file}${RESET}: "

    info=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,codec_name -of default=noprint_wrappers=1 -of csv=s=x:p=0 "$file")

    # Skip if ffprobe failed
    if [[ -z "$info" ]]; then
        echo -e "${RED}error reading file${RESET}"
        continue
    fi

    codec="${info%%x*}"
    rest="${info#*x}"
    width="${rest%%x*}"
    height="${rest#*x}"

    if (( width > height )); then
        orient="horizontal"
    elif (( height > width )); then
        orient="vertical"
    else
        orient="square"
    fi

    echo -e "(${YELLOW}${codec}${RESET}) ${width}x${height} [${BLUE}${orient}${RESET}]"
done