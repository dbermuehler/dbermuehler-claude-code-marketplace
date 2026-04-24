---
name: audio-transcribe
description: >
  Transcribe audio files (mp3, wav, m4a, etc.) and podcast episodes to text using OpenAI's Whisper API.
  Use this skill whenever the user wants to transcribe audio, convert speech to text, get a transcript
  from a podcast episode, or work with audio recordings. Also use it when the user mentions a podcast URL
  or audio file and wants to know what's in it, summarize it, or extract information from spoken content.
disable-model-invocation: true
allowed-tools: Read, Write, Bash, WebFetch
argument-hint: <audio-file-or-url> [optional question about the content]
---

# Audio Transcription

Transcribes audio files and podcast episodes to text using OpenAI's Whisper API. Handles local files and URLs, with automatic chunking for files over 25MB.

## Usage

**Transcribe a local file:**
- `/audio-transcribe ~/recordings/meeting.mp3`
- `/audio-transcribe /path/to/interview.wav`

**Transcribe from a URL:**
- `/audio-transcribe https://example.com/podcast/episode.mp3`

**Transcribe and ask a question:**
- `/audio-transcribe ~/meeting.mp3 What action items were discussed?`
- `/audio-transcribe https://example.com/ep42.mp3 Summarize the main points`

## Instructions

1. **Parse arguments** — Extract the audio source from $ARGUMENTS. It can be a local file path or a URL. Any remaining text after the source is the user's question about the content.

2. **Locate scripts** — The helper scripts are in the `scripts/` subdirectory relative to this SKILL.md file.

3. **Check dependencies** — Verify `uv` is available:
   ```bash
   bash <SKILL_SCRIPTS_DIR>/check_dependencies.sh
   ```
   If this fails, display the error and stop.

4. **Resolve the OpenAI API key** — The transcription script needs `OPENAI_API_KEY` set. Check if it's already in the environment. If not, ask the user to set it.

5. **Resolve the audio source** — Determine whether $ARGUMENTS contains a URL or a local file path.
   - **URL**: If the user provided a podcast page URL (not a direct audio file link), use WebFetch to find the RSS feed or direct mp3 link first. Podcast hosting pages (Buzzsprout, Anchor, Spotify, Apple Podcasts, etc.) typically link to an RSS feed that contains enclosure URLs for each episode.
   - **Local file**: Verify the file exists.

6. **Run the transcription** —
   ```bash
   OPENAI_API_KEY="<key>" uv run --with openai --with httpx python <SKILL_SCRIPTS_DIR>/transcribe.py "<source>" -o /tmp/audio-transcript-output.txt
   ```
   The script handles downloading (for URLs), chunking (for large files), and calling the Whisper API.

7. **Read the transcript** — Use the Read tool to load `/tmp/audio-transcript-output.txt`.

8. **Present results:**
   - **If the user asked a question**: Answer it using the transcript content. Be thorough and reference specific parts of the transcript when relevant.
   - **If no question** (source only): Present a brief summary of the audio content, including the main topics covered. Let the user know they can ask follow-up questions.

9. **Follow-up** — The transcript remains in context for subsequent questions. The user can ask follow-up questions naturally without re-invoking the skill.

## Source Detection

The source argument can be:
- A local file path: `/path/to/file.mp3`, `~/recording.wav`, `./audio.m4a`
- A direct audio URL: `https://example.com/episode.mp3`
- A podcast page URL: `https://podcasts.apple.com/...`, `https://open.spotify.com/episode/...`, etc.

For podcast page URLs, resolve them to a direct audio file URL before passing to the script.

## Supported Formats

The Whisper API accepts: mp3, mp4, mpeg, mpga, m4a, wav, webm, ogg, flac.

## Error Handling

- Missing API key: Ask user to set `OPENAI_API_KEY`
- File not found: Show the path and suggest checking it
- Download failed (403/404): The host may be blocking automated downloads; suggest the user download the file manually
- API error (401): The API key is invalid or expired
- File too large and no ffmpeg: The script falls back to byte-level splitting automatically, but suggest installing ffmpeg for cleaner results

## Example Interactions

**User:** `/audio-transcribe ~/Downloads/interview.mp3`
**Response:** Transcribe the file, present a summary, invite questions.

**User:** `/audio-transcribe https://example.com/podcast/ep42.mp3 What were the key takeaways?`
**Response:** Transcribe the audio, answer the question with specific references.

**User (follow-up):** `Did they mention anything about pricing?`
**Response:** Search the transcript and provide a detailed answer.
