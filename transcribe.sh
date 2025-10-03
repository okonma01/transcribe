#!/bin/bash
set -e

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: ./transcribe.sh <YOUTUBE_URL>"
    exit 1
fi

URL="$1"
OUTPUT_DIR="output"
TEMP_DIR="temp"

# Create directories
mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

echo "=== Step 1: Downloading audio from YouTube ==="
# Download audio as mp3 using yt-dlp
yt-dlp -x --audio-format mp3 -o "$TEMP_DIR/audio.%(ext)s" "$URL"

echo "=== Step 2: Splitting audio into stems using spleeter ==="
# Use Python 3.7 for spleeter
if [ ! -d "$TEMP_DIR/venv37" ]; then
    python3.7 -m venv "$TEMP_DIR/venv37" 2>/dev/null || python3 -m venv "$TEMP_DIR/venv37"
    source "$TEMP_DIR/venv37/bin/activate"
    pip install --quiet spleeter
    deactivate
fi
source "$TEMP_DIR/venv37/bin/activate"
spleeter separate -p spleeter:2stems -o "$TEMP_DIR" "$TEMP_DIR/audio.mp3"
deactivate

echo "=== Step 3: Transcribing vocals using faster-whisper ==="
# Use Python 3.9 for faster-whisper
if [ ! -d "$TEMP_DIR/venv39" ]; then
    python3.9 -m venv "$TEMP_DIR/venv39" 2>/dev/null || python3 -m venv "$TEMP_DIR/venv39"
    source "$TEMP_DIR/venv39/bin/activate"
    pip install --quiet faster-whisper
    deactivate
fi
source "$TEMP_DIR/venv39/bin/activate"

# Create transcription script
cat > "$TEMP_DIR/transcribe.py" << 'EOF'
from faster_whisper import WhisperModel

model = WhisperModel("small", device="cpu", compute_type="int8")
segments, info = model.transcribe("temp/audio/vocals.wav", beam_size=5)

print(f"Detected language '{info.language}' with probability {info.language_probability}")

with open("output/transcription.txt", "w") as f:
    for segment in segments:
        f.write(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}\n")
        print(f"[{segment.start:.2f}s -> {segment.end:.2f}s] {segment.text}")

print("\nTranscription saved to output/transcription.txt")
EOF

python "$TEMP_DIR/transcribe.py"
deactivate

echo "=== Complete! ==="
echo "Transcription saved to: $OUTPUT_DIR/transcription.txt"

# Cleanup temp audio files (keep venvs for reuse)
rm -f "$TEMP_DIR/audio.mp3"
rm -rf "$TEMP_DIR/audio"
rm -f "$TEMP_DIR/transcribe.py"
