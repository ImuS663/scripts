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

	# Reset per-file state
	codec='' width='' height=''

	# Keep only the first value of each key (ffprobe may emit the stream twice
	# when a tmcd track reference / stream group is present)
	while IFS='=' read -r key val; do
		case "$key" in
		codec_name) codec="${codec:-$val}" ;;
		width) width="${width:-$val}" ;;
		height) height="${height:-$val}" ;;
		esac
	done < <(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of default=nw=1 "$file" 2>/dev/null)

	# Skip if ffprobe failed
	if [[ -z "$codec" || ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ ]]; then
		echo -e "${RED}error reading file${RESET}${reason:+ ($reason)}"
		continue
	fi

	if ((width > height)); then
		orient="horizontal"
	elif ((height > width)); then
		orient="vertical"
	else
		orient="square"
	fi

	echo -e "(${YELLOW}${codec}${RESET}) ${width}x${height} [${BLUE}${orient}${RESET}]"
done
