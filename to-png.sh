#!/bin/bash

# ------------------------------------------------------------------------------
# Script Name: to-png.sh
# Description: Converts image files to PNG format using FFmpeg and png lib.
# Requirements: FFmpeg with png support.
# Usage: to-png.sh -i input.jpg
#        to-png.sh -i *.jpg
# Options:
#   -i, --input       One or more input files  (required)
#   -w, --width       Width of the output PNG (default: original width)
#   -h, --height      Height of the output PNG (default: original height)
#   --copy-date       Copy the modification date from the input file to the output file
#   --recompress      Re-encode files already in the target format in place
#   --remove          Remove the input file after conversion
# ------------------------------------------------------------------------------

set -e

# Default values
width=-2
height=-2
copy_date=false
recompress=false
remove=false
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
	--recompress)
		recompress=true
		shift
		;;
	--remove)
		remove=true
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
	scale_filter=(-vf "scale=${width}:${height}")
else
	scale_filter=()
fi

convert() {
	local input_file="$1"
	local input_dir input_base input_name input_ext tmp_file output_file in_place=false

	input_dir="$(dirname "$input_file")"
	input_base="$(basename "$input_file")"
	if [[ "$input_base" == ?*.* ]]; then
		input_name="${input_base%.*}"
		input_ext="${input_base##*.}"
	else
		input_name="$input_base"
		input_ext=""
	fi
	input_ext="${input_ext,,}"
	output_file="$input_dir/$input_name.png"
	tmp_file="$input_dir/$input_name.tmp.png"

	if $recompress && [[ "$input_ext" == "png" ]]; then
		in_place=true
		output_file="$input_file"
	fi

	if ! $in_place && [[ -e "$output_file" ]]; then
		echo "⏭️  Skipping (output exists): $output_file"
		return 0
	fi

	current_output="$tmp_file"

	# Run ffmpeg
	ffmpeg -i "$input_file" -c:v png "${scale_filter[@]}" "$tmp_file" || {
		rm -f "$tmp_file"
		current_output=""
		return 1
	}

	# In place: keep the original if recompression didn't help
	if $in_place && (($(stat -c%s "$tmp_file") >= $(stat -c%s "$input_file"))); then
		rm -f "$tmp_file"
		current_output=""
		echo "⏭️  Already optimal, kept original: $input_file"
		return 0
	fi

	# Copy date if needed
	if $copy_date; then
		touch -r "$input_file" "$tmp_file"
	fi

	mv "$tmp_file" "$output_file"
	current_output=""

	# Remove input file if needed
	if $remove && [[ "$input_file" -ef "$output_file" ]]; then
		echo "⚠️  Input and output are the same file, not removing: $input_file"
	elif $remove; then
		rm "$input_file"
	fi

	echo "✅ Conversion complete: $output_file"
}

failed=0
for f in "${input_files[@]}"; do
	if [[ ! -f "$f" ]]; then
		echo "⚠️  Skipping (not a file): $f"
		continue
	fi
	if ! convert "$f"; then
		echo "❌ Failed: $f"
		failed=$((failed + 1))
	fi
done

[[ $failed -eq 0 ]] || exit 1
