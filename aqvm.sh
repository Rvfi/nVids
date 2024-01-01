#!/bin/bash

if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "ffmpeg and ffprobe are required but could not be found.  Please install them."
    exit
fi

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 [audio_file] [logo_image] [--use_img_generation] [--dont-remove-files]"
    exit
fi

audio_file="$1"
logo_image="$2"
use_image_generation="$3"
output_file="output.mp4"

title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=nw=1:nk=1 "$audio_file")
artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=nw=1:nk=1 "$audio_file")

# If title is empty, use filename (without extension) as title
# Use bash string manipulation to remove extension
if [ -z "$title" ]; then
    title="${audio_file%.*}"
fi

# Extract album art from the audio file
ffmpeg -i "$audio_file" -an -c:v png album_art.png

# Check if album art extraction was successful
if [ ! -f album_art.png ]; then
    # Copy gradient.png for a blank background
    cp gradient.png album_art.png

    # Optionally use DALL-E
    if [ "$use_image_generation" = "--use-img-generation" ]; then

        # Sanitize it because it's going to be used in a JSON string
        title_sanitized=$(echo "$title" | sed 's/[!@#\$%^&*()]//g')

        echo "DALL-E Prompt: $title_sanitized"

        imageResponse=$(curl -s https://api.openai.com/v1/images/generations \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{ 
            \"model\": \"dall-e-3\",
            \"prompt\": \"$title_sanitized\", 
            \"n\": 1, 
            \"size\": \"1024x1024\" 
        }")

        # Use to debug any errors
        echo $imageResponse

        # "Parse" JSON
        imageUrl=$(echo "$imageResponse" | awk '/"url":/ {print}' | cut -d\" -f4)

        # Download the image
        curl -s $imageUrl -o album_art.png
    fi
fi

# Calculate Integrated Loudness and Peak dB
lufs=$(ffmpeg -i "$audio_file" -af ebur128=framelog=verbose -f null - 2>&1 | awk '/I:/{print $2}')
peak=$(ffmpeg -i "$audio_file" -filter:a volumedetect -f null /dev/null 2>&1 | grep "max_volume" | awk -F: '{print $2}' | awk '{print $1}')

# Create text files with RMS and Peak dB values
echo "Integrated Loudness: $lufs LUFS" > lufs.txt
echo "Peak dB: $peak dB" > peak.txt

# Generate subtitle file with text
cat << EOF > text.srt
1
00:00:00,000 --> 00:59:10,000
$title
$artist
—
I-LUFS: $lufs LUFS
Peak: $peak dB
EOF

ffmpeg -y -loop 1 -i "$logo_image" -i "$audio_file" -i gradient.png -i album_art.png -i measurements.png -filter_complex "\
    [3:v]scale=480:480[bg]; \
    [2:v]scale=480:480[gradient]; \
    [bg][gradient]overlay[bg1]; \
    [0:v]scale=iw*0.2:ih*0.2[logo]; \
    [bg1][logo]overlay=10:10[t1]; \
    [t1]subtitles=text.srt:force_style='Alignment=5,MarginL=10,MarginV=40,FontSize=14,Outline=0,Fontname=Inter V'[t7]; \
    [1:a]showwaves=s=160x60:mode=p2p:colors=white:draw=full[waves]; \
    [1:a]showvolume=w=300:h=11:o=v:f=0:t=0:ds=log:v=0:dmc=0xffffffff:dm=2:m=p:c='0x80808080'[peakmeter]; \
    [1:a]showvolume=w=150:h=11:o=v:f=0:t=0:ds=log:v=0:dmc=0xffffffff:dm=0:m=r:c='0xffffffff'[rmsmeter]; \
    [peakmeter]crop=iw:150:0:0[peakmeter]; \
    [t7][waves]overlay=10:H-h-165[t8]; \
    [t8][peakmeter]overlay=10:H-h-10[t9]; \
    [t9][rmsmeter]overlay=10:H-h-10[t10]; \
    [4:v]scale=29x155[measurements]; \
    [t10][measurements]overlay=40:H-h-10" \
    -c:v libx264 -b:v 500k -pix_fmt yuv420p -c:a aac -b:a 96k -shortest "$output_file"


    
# Cleanup files (unless specified)
if [ "$4" != "--dont-remove-files" ]; then
    rm lufs.txt peak.txt text.srt album_art.png
fi
