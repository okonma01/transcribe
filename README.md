# transcribe
YouTube link -> Download audio -> Split vocals -> STT -> Song Lyrics

## Overview
Automated workflow to transcribe lyrics from YouTube videos by:
1. Downloading audio from YouTube as MP3
2. Separating vocals using Spleeter (Python 3.7)
3. Transcribing vocals using faster-whisper (Python 3.9)

## Requirements
- `yt-dlp` or `youtube-dl` (for audio download)
- `ffmpeg` (for audio processing)
- Python 3.7 (for spleeter)
- Python 3.9 (for faster-whisper)

## Usage
```bash
./transcribe.sh <YOUTUBE_URL>
```

## Output
Transcription will be saved to `output/transcription.txt` with timestamps.
