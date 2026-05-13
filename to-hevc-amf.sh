#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: to-hevc-amf.sh
# Description: Converts video files to HEVC (H.265) format using FFmpeg and AMD GPU (hevc_amf).
# Requirements: FFmpeg with hevc_amf support and AMD GPU.
# Usage: to-hevc-amf.sh -i input.mp4
# Options:
#   -i, --input       Input video file (required)
#   -q, --quality     Quality level (CRF) for output video (default: 28)
#   -w, --width       Width of output video (default: original width)
#   -h, --height      Height of output video (default: original height)
#   --copy-date       Copy the modification date from input to output file
#   --lossless        Encode video in lossless mode
# ------------------------------------------------------------------------------

set -e

# Default values
quality=28
width=-2
height=-2
copy_date=false
lossless=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-i | --input)
		input_file="$2"
		shift 2
		;;
	-q | --quality)
		quality="$2"
		shift 2
		;;
	-w | --width)
		width="$2"
		shift 2
		;;
	-h | --height)
		height="$2"
		shift 2
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

# Scale filter
if [[ $width -gt 0 || $height -gt 0 ]]; then
	scale_filter="-vf scale=w=${width}:h=${height}"
else
	scale_filter=""
fi

# Quality or lossless flag
if $lossless; then
	quality_str="-rc cqp -qp_i 0 -qp_p 0"
else
	quality_str="-rc cqp -qp_i $quality -qp_p $quality"
fi

# Run ffmpeg
ffmpeg -i "$input_file" \
	-c:v hevc_amf $scale_filter -quality quality $quality_str \
	-c:a aac -movflags +faststart "$output_file"

# Copy date if needed
if $copy_date; then
	touch -r "$input_file" "$output_file"
fi

echo "✅ Conversion complete: $output_file"
