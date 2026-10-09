#!/bin/bash

# audio-denoise.sh - Automate audio extraction and merging for noise reduction workflows.
# Recommended for use with Adobe Podcast (https://podcast.adobe.com/enhance)

function show_help() {
    echo "Usage:"
    echo "  $0 extract <video_file>                  - Extract audio from video without re-encoding"
    echo "  $0 merge <video_file> <audio_file>      - Merge enhanced audio back into video"
    echo ""
    echo "Examples:"
    echo "  $0 extract VID_2026.mp4"
    echo "  $0 merge VID_2026.mp4 VID_2026_enhanced.wav"
}

if [[ $# -lt 2 ]]; then
    show_help
    exit 1
fi

COMMAND=$1
INPUT_FILE=$2

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

case $COMMAND in
    extract)
        OUTPUT_AUDIO="${INPUT_FILE%.*}_audio.m4a"
        echo "Extracting audio to $OUTPUT_AUDIO..."
        ffmpeg -i "$INPUT_FILE" -vn -c:a copy "$OUTPUT_AUDIO"
        echo "Done! Upload this file to Adobe Podcast."
        ;;
    merge)
        if [[ $# -lt 3 ]]; then
            echo "Error: Missing audio file for merging."
            exit 1
        fi
        AUDIO_FILE=$3
        if [[ ! -f "$AUDIO_FILE" ]]; then
            echo "Error: Audio file '$AUDIO_FILE' not found."
            exit 1
        fi
        
        OUTPUT_VIDEO="${INPUT_FILE%.*}_denoised.mp4"
        echo "Merging $INPUT_FILE and $AUDIO_FILE into $OUTPUT_VIDEO..."
        # Stream copy video, encode PCM/WAV audio to high-quality AAC for MP4 container compatibility
        ffmpeg -y -i "$INPUT_FILE" -i "$AUDIO_FILE" -c:v copy -c:a aac -b:a 256k -map 0:v:0 -map 1:a:0 "$OUTPUT_VIDEO"
        echo "Done! Final video: $OUTPUT_VIDEO"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
