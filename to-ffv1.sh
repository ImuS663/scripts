#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: to-ffv1.sh
# Description: Converts video files to FFV1 format using FFmpeg and ffv1 lib.
# Requirements: FFmpeg with ffv1 support.
# Usage: to-ffv1.sh -i input.mp4
# Options:
#   -i, --input       Input video file (required)
#   -w, --width       Output video width (default: original width)
#   -h, --height      Output video height (default: original height)
#   --copy-date       Copy the modification date from the input file to the output file
# ------------------------------------------------------------------------------

set -e

# Default values
width=-2
height=-2
copy_date=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      input_file="$2"
      shift 2
      ;;
    -w|--width)
      width="$2"
      shift 2
      ;;
    -h|--height)
      height="$2"
      shift 2
      ;;
    --copy-date)
      copy_date=true
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      echo "Unexpected argument: $1"
      exit 1
      ;;
  esac
done

# Validate input
if [[ -z "$input_file" || ! -f "$input_file" ]]; then
  echo "Error: --input is required and must point to a valid file."
  exit 1
fi

input_dir="$(dirname "$input_file")"
input_base="$(basename "$input_file")"
input_name="${input_base%.*}"
output_dir="$input_dir/output"
output_file="$output_dir/$input_name.mkv"

mkdir -p "$output_dir"

# Scale filter
if [[ $width -gt 0 || $height -gt 0 ]]; then
  scale_filter="-vf scale=w=${width}:h=${height}"
else
  scale_filter=""
fi

# Run ffmpeg
ffmpeg -i "$input_file" -c:v ffv1 $scale_filter -c:a aac -movflags +faststart "$output_file"

# Copy date if needed
if $copy_date; then
  touch -r "$input_file" "$output_file"
fi

echo "✅ Conversion complete: $output_file"