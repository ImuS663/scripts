#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: to-hevc-cuda.sh
# Description: Converts video files to HEVC (H.265) format using FFmpeg and NVIDIA GPU (hevc_nvenc).
# Requirements: FFmpeg with hevc_nvenc support and NVIDIA GPU with CUDA.
# Usage: to-hevc-cuda.sh -i input.mp4
# ------------------------------------------------------------------------------

set -e

# Default values
quality=28
width=-2
height=-2
native_decode=false
copy_date=false
lossless=false

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
    --native-decode)
      native_decode=true
      shift
      ;;
    --copy-date)
      copy_date=true
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
output_dir="$input_dir/output"
output_file="$output_dir/$input_name.mp4"

mkdir -p "$output_dir"

# HW acceleration and scale type
if $native_decode; then
  hwaccel=""
  scale_type="scale"
else
  hwaccel="-hwaccel cuda"
  scale_type="scale_cuda"
fi

# Scale filter
if [[ $width -gt 0 || $height -gt 0 ]]; then
  scale_filter="-vf ${scale_type}=w=${width}:h=${height}"
else
  scale_filter=""
fi

# Quality or lossless flag
if $lossless; then
  quality_str="-tune:v lossless"
else
  quality_str="-tune:v uhq -rc:v vbr -cq:v $quality -b:v 0"
fi

# Run ffmpeg
ffmpeg $hwaccel -hwaccel_output_format cuda -i "$input_file" \
  -c:v hevc_nvenc $scale_filter -preset:v p7 $quality_str \
  -c:a aac -movflags +faststart "$output_file"

# Copy date if needed
if $copy_date; then
  touch -r "$input_file" "$output_file"
fi

echo "✅ Conversion complete: $output_file"