#!/usr/bin/env bash
set -eo pipefail

# Video and music sources
video='【東方】Bad Apple!! ＰＶ【影絵】.mp4'
music='2025 (Bad Apple x u i a oiiaoiia cat) adjusted.opus'

# Constants for timing calculations
frame_rate=30
beats_per_bar=4
frames_per_beat=13
frames_per_bar=$((frames_per_beat * beats_per_bar))
silence_beats=3  # Silence at the start
silence_frames=$((silence_beats * frames_per_beat))
output="bad cat v3.7.mkv"

# Cleanup previous results, but keep in/* and out/*
rm -r res/*.png || :
mkdir -p res in out

# Function to prevent redundant processing
_once_n=0
once_for() {
    condition=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --) shift; break;;
            *) condition+=("$1"); shift;;
        esac
    done
    condition="$(sha256sum <<< "${condition[@]}" | sha256sum)"
    if ! [[ x"$condition $*" == x"$(cat .once_$_once_n 2>/dev/null)" ]]; then
        echo + "${@@Q}"
        "$@"
        echo "$condition $*" > .once_$_once_n
    fi
    let _once_n+=1
}

# Ensure res_new is populated with initial GIF frames
mkdir -p res_new
once_for ~/Downloads/cat-oiiaoiia-cat.gif -- ffmpeg -i ~/Downloads/cat-oiiaoiia-cat.gif -vf "crop=100:100, setpts=PTS-STARTPTS" -start_number 0 res_new/%d.png

# Function to generate GIF frames dynamically
# Arguments: $1 = number of spinning frames (default: 5)
generate_gif_frames() {
    local spin_frames=$1
    local stand_frames=$((13 - spin_frames))

    echo "Generating GIF frames: $stand_frames standing, $spin_frames spinning"

    rm -rf res/*
    mkdir -p res

    # Ensure res_new contains the expected frames
    if [ ! -f "res_new/0.png" ]; then
        echo "Error: res_new does not contain extracted frames! Exiting."
        exit 1
    fi

    # Copy standing frames from res_new (starting from 0)
    if [ $stand_frames -ne 0 ]; then
      for i in $(seq 0 $((stand_frames - 1))); do
          if [ -f "res_new/0.png" ]; then
              cp "res_new/0.png" "res/$i.png"
          else
              echo "Warning: Missing standing frame res_new/0.png"
          fi
      done
    fi
    
    # Copy spinning frames from res_new (ensuring exactly 13 frames in total)
    local res_frame_count=$(ls res | wc -l)
    while [[ $res_frame_count -lt 13 ]]; do
      for i in $(seq 13 18); do
          if [ "$res_frame_count" -ge 13 ]; then
              break
          fi
          if [ -f "res_new/$i.png" ]; then
              cp "res_new/$i.png" "res/$res_frame_count.png"
              res_frame_count=$((res_frame_count + 1))
          else
              echo "Warning: Missing spinning frame res_new/$i.png"
          fi
      done
    done

    # Verify frame count after copying
    local final_frame_count=$(ls res | wc -l)
    if [ "$final_frame_count" -ne 13 ]; then
        echo "Error: Incorrect number of frames in res ($final_frame_count instead of 13). Exiting."
        ls res
        exit 1
    fi
}

# Define function to call `amogus` for a section based on bars
process_section() {
    local start_bar=$1
    local end_bar=$2
    local spinning_frames=$3
    local sprite_repeat=${4:-2}  # Default SFRC = 2

    # Convert bars to frame numbers, ensuring frame continuity
    local start_frame=$((silence_frames + start_bar * frames_per_bar))
    local end_frame=$((silence_frames + end_bar * frames_per_bar + frames_per_bar - 1))

    # Generate appropriate GIF frames before processing
    generate_gif_frames "$spinning_frames"
    
    echo "Processing section: Bars $start_bar to $end_bar (Spinning Frames: $spinning_frames)"
    echo "Frame range: $start_frame-$end_frame"

    for i in $(seq $start_frame $end_frame); do
      if [ ! -f "in/img_$i.png" ]; then
          echo "Error: Video frame $i is missing! Exiting."
          exit 1
      fi
    done
    for i in {0..12}; do
      if [ ! -f "res/$i.png" ]; then
        echo "Error: GIF frame $i is missing! Exiting."
        exit 1
      fi
    done
    
    once_for `eval echo in/img_{$start_frame..$end_frame}.png` res/{0..13}.png -- ./amogus Col "$start_frame" "$end_frame" "$sprite_repeat" 0 13
    echo
}

# Extract video frames (once)
once_for "$video" -- ffmpeg -r $frame_rate -i "$video" -vf "elbg=8" in/img_%d.png

# Call `amogus` for different sections using bars instead of frames
for i in `seq 1 $silence_frames`; do cp in/img_$i.png out/img_$i.png; done
process_section   0  15  5 # Intro (no singing, fewer spinning frames)
process_section  16  39 13 # Mid-section (normal singing, intense spinning)
process_section  40  46 10 # Refrain (singing with hi-hats, intense spinning with extra standing frame)
process_section  47  63  5 # Top (change manner + prepare for drop)
process_section  64  70 13 # Drop (just spin; cats are vibing)
process_section  71 119  5 # Final section (Too lazy to add anything meaningful)
process_section 120 124  0 # Outro (Spinning jing-jang)

## Preview video before final assembly
#ffmpeg -r $frame_rate -i out/img_%d.png -i "$music" -vcodec libx264 -acodec copy -map 0:v:0 -map 1:a:0 -crf 15 -pix_fmt yuv420p -f matroska - \
#  | ffmpeg -i - -vf "drawtext=fontfile=Arial.ttf: text='%{frame_num}': start_number=1: x=(w-tw)/2: y=h-(2*lh): fontcolor=black: fontsize=20: box=1: boxcolor=white: boxborderw=5" -c:a copy -f matroska - \
#  | mpv -

# Assemble final video with FFmpeg
once_for out/* -- ffmpeg -r $frame_rate -i out/img_%d.png -i "$music" -vcodec libx264 -acodec copy \
    -map 0:v:0 -map 1:a:0 -crf 15 -pix_fmt yuv420p -y "$output"

echo "Processing complete: $output"

