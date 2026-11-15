#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: to-hevc-vulkan.sh
# Description: Converts video files to HEVC (H.265) format using FFmpeg and hevc_vulkan.
# Requirements: FFmpeg with Vulkan support.
# Usage: to-hevc-vulkan.sh -i input.mp4
#        to-hevc-vulkan.sh -i *.mp4
# Options:
#   -i, --input       One or more input files (required)
#   -q, --quality     Quality level (CQ) for output video (default: 28)
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
input_files=()
current_output=""

# Remove partial output on Ctrl+C / termination
trap '[[ -n $current_output ]] && rm -f "$current_output"; exit 130' INT TERM

# Parse arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
	-i | --input)
		shift
		# Collect all following args until the next option
		while [[ $# -gt 0 && "$1" != -* ]]; do
			input_files+=("$1")
			shift
		done
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
if [[ ${#input_files[@]} -eq 0 ]]; then
	echo "Error: --input is required (one or more files)."
	exit 1
fi

# Scale filter
if [[ $width -gt 0 || $height -gt 0 ]]; then
	scale_filter=(-vf "scale_vulkan=w=${width}:h=${height},hwupload")
else
	scale_filter=(-vf hwupload)
fi

# Quality or lossless flag
if $lossless; then
	quality_str=(-tune lossless)
else
	quality_str=(-qp "$quality")
fi

convert() {
	local input_file="$1"
	local input_dir input_base input_name output_dir output_file

	input_dir="$(dirname "$input_file")"
	input_base="$(basename "$input_file")"
	input_name="${input_base%.*}"
	output_dir="$input_dir/output"
	output_file="$output_dir/$input_name.mp4"

	# Never overwrite (also covers a.mp4 + a.mkv collisions)
	if [[ -e "$output_file" ]]; then
		echo "⏭️  Skipping (output exists): $output_file"
		return 0
	fi

	mkdir -p "$output_dir"

	current_output="$output_file"

	local ffmpeg_command=(ffmpeg -init_hw_device vulkan=vk:0 -hwaccel vulkan -hwaccel_output_format vulkan -i "$input_file"
		-c:v hevc_vulkan "${scale_filter[@]}" -rc_mode cqp "${quality_str[@]}"
		-usage transcode -tune hq
		-c:a aac -movflags +faststart "$output_file")

	current_output="$output_file"

	# Run ffmpeg
	if command -v systemd-inhibit >/dev/null 2>&1; then
		systemd-inhibit --what=sleep:idle --why="Converting $input_base to HEVC" "${ffmpeg_command[@]}" || {
			rm -f "$output_file"
			current_output=""
			return 1
		}
	else
		"${ffmpeg_command[@]}" || {
			rm -f "$output_file"
			current_output=""
			return 1
		}
	fi

	current_output=""

	# Copy date if needed
	if $copy_date; then
		touch -r "$input_file" "$output_file"
	fi

	echo "✅ Conversion complete: $output_file"
}

failed=0
for f in "${input_files[@]}"; do
	if [[ ! -f "$f" ]]; then
		echo "⚠️  Skipping (not a file): $f"
		continue
	fi
	# Skip results of previous runs
	if [[ "$(basename "$(dirname "$f")")" == "output" ]]; then
		echo "⏭️  Skipping output file: $f"
		continue
	fi
	if ! convert "$f"; then
		echo "❌ Failed: $f"
		failed=$((failed + 1))
	fi
done

[[ $failed -eq 0 ]] || exit 1
