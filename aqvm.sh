#!/bin/bash

if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "ffmpeg and ffprobe are required but could not be found.  Please install them."
    exit
fi

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 [audio_file] [logo_image] [font_file]"
    exit
fi

audio_file="$1"
logo_image="$2"
font_file="$3"
output_file="output.mp4"

title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=nw=1:nk=1 "$audio_file")
artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=nw=1:nk=1 "$audio_file")

# If title is empty, use filename (without extension) as title
if [ -z "$title" ]; then
    title=$(basename "$audio_file")
fi

# Calculate Integrated Loudness and Peak dB
lufs=$(ffmpeg -i "$audio_file" -af ebur128=framelog=verbose -f null - 2>&1 | awk '/I:/{print $2}')
peak=$(ffmpeg -i "$audio_file" -filter:a volumedetect -f null /dev/null 2>&1 | grep "max_volume" | awk -F: '{print $2}' | awk '{print $1}')

# Create text files with RMS and Peak dB values
echo "Integrated Loudness: $lufs LUFS" > lufs.txt
echo "Peak dB: $peak dB" > peak.txt

ffmpeg -y -loop 1 -i "$logo_image" -i "$audio_file" -filter_complex "\
    color=c=black:s=480x480[canvas]; \
    [0:v]scale=iw*0.2:ih*0.2[logo]; \
    [canvas][logo]overlay=10:10[bg]; \
    [bg]drawtext=fontfile=$font_file:fontsize=18:fontcolor=white:x=10:y=h-380:text='$title'[t1]; \
    [t1]drawtext=fontfile=$font_file:fontsize=18:fontcolor=white:x=10:y=h-350:text='$artist'[t2]; \
    [t2]drawtext=fontfile=$font_file:fontsize=18:fontcolor=white:x=10:y=h-320:text='Do not redistribute.'[t3]; \
    [t3]drawtext=fontfile=$font_file:fontsize=18:fontcolor=white:x=10:y=h-290:textfile=lufs.txt:reload=1[t4]; \
    [t4]drawtext=fontfile=$font_file:fontsize=18:fontcolor=white:x=10:y=h-260:textfile=peak.txt:reload=1[t5]; \
    [t5]drawtext=fontfile=$font_file:fontsize=18:fontcolor=white:x=10:y=h-230:text='%{pts\:hms}'" \
    -c:v libx264 -b:v 1M -pix_fmt yuv420p -c:a aac -b:a 128k -shortest "$output_file"
    
# Cleanup the text files
rm lufs.txt peak.txt