#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: to-webp.sh
# Description: Converts image files to WEBP format using FFmpeg and libwebp_anim.
# Requirements: FFmpeg with libwebp_anim support.
# Usage: to-webp.sh -i input.png
# Options:
#   -i, --input       Input image file (required)
#   -q, --quality     Quality of the output WEBP (default: 98)
#   -w, --width       Width of the output WEBP (default: original width)
#   -h, --height      Height of the output WEBP (default: original height)
#   --copy-date       Copy the modification date from the input file to the output file
#   --lossless        Use lossless compression (overrides quality)
#   --remove          Remove the input file after conversion
# ------------------------------------------------------------------------------

set -e

# Default values
quality=98
width=-2
height=-2
copy_date=false
lossless=false
remove=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      input_file="$2"
      shift 2
      ;;
    -q|--quality)
      quality="$2"
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
    --remove)
      remove=true
      shift
      ;;
    --lossless)
      lossless=true
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
output_file="$input_dir/$input_name.webp"

# Scale filter
if [[ $width -gt 0 || $height -gt 0 ]]; then
  scale_filter="-vf scale=${width}:${height}"
else
  scale_filter=""
fi

# Quality or lossless flag
if $lossless; then
  quality_str="-lossless 1 -compression_level 6"
else
  quality_str="-quality $quality"
fi

# Run ffmpeg
ffmpeg -i "./$input_file" -c:v libwebp_anim $scale_filter -loop 0 $quality_str "$output_file"

# Copy date if needed
if $copy_date; then
  touch -r "$input_file" "$output_file"
fi

# Remove input file if needed
if $remove; then
  rm "$input_file"
fi

echo "✅ Conversion complete: $output_file"