#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: media-check.sh
# Description: Check media files on errors using FFmpeg.
# Requirements: FFmpeg with ffprove.
# Usage: media-check.sh *.mp4
# ------------------------------------------------------------------------------

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Symbols
CHECK="\u2714"
BALLOT_X="\u2718"

CLEAN="\033[K"

# If no arguments → show usage
if [[ $# -eq 0 ]]; then
	echo "Usage: $0 <files>"
	exit 1
fi

for file in "$@"; do
	# Skip if not a file
	if [[ ! -f "$file" ]]; then
		continue
	fi

	err=$(ffprobe -v error -i "$file" 2>&1)

	if [[ -n "$err" ]]; then
		# ✘ Cross Mark for errors
		echo -e "\r$CLEAN$RED$BALLOT_X$RESET $file"
	else
		# ✔ Check Mark for success (no newline to keep it snappy)
		echo -ne "\r$CLEAN$GREEN$CHECK$RESET $file"
	fi
done

echo -e "\nDone!"
