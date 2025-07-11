#!/bin/bash

# Define the test directory
TEST_DIR="./test"

# Create the test directory if it doesn't exist
mkdir -p "$TEST_DIR"

echo "Creazione di file di test nella directory: $TEST_DIR"

# Function to create a dummy video file
create_dummy_video() {
    local filename="$1"
    local duration="$2" # in seconds
    local resolution="$3" # e.g., 640x480
    local color="$4" # e.g., red, blue, black

    echo "Creazione: $filename (${duration}s, ${resolution}, ${color})"
    ffmpeg -y -f lavfi -i "color=${color}:s=${resolution}:d=${duration}" -c:v libx264 -pix_fmt yuv420p "$TEST_DIR/$filename"
}

# Create some dummy video files
create_dummy_video "test_video_1.mp4" 5 "640x480" "red"
create_dummy_video "test_video_2.mkv" 10 "1280x720" "blue"
create_dummy_video "test video 3 with spaces.avi" 7 "800x600" "green"

# Create a file that might cause conversion issues (e.g., zero size or corrupted)
# For simplicity, let's create a zero-byte file to simulate a potential failure case
touch "$TEST_DIR/test_video_4_fail.mp4"
echo "File creato: $TEST_DIR/test_video_4_fail.mp4 (simula un file corrotto/vuoto)"


echo "Creazione file di test completata."
