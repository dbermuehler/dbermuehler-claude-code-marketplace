---
name: yt-transcript
description: Extract and analyze YouTube video transcripts
disable-model-invocation: true
allowed-tools: Read, Write, Bash
argument-hint: <youtube-url> [optional question about the video]
---

# YouTube Video Analysis

Extracts transcripts from YouTube videos and answers questions about their content.

## Usage

**Extract transcript only:**
- `/yt-transcript https://youtube.com/watch?v=VIDEO_ID`
- `/yt-transcript https://youtu.be/VIDEO_ID`

**Extract and answer question:**
- `/yt-transcript https://youtube.com/watch?v=VIDEO_ID What are the main topics discussed?`
- `/yt-transcript Can you summarize this video? https://youtu.be/VIDEO_ID`
- `/yt-transcript https://youtube.com/watch?v=VIDEO_ID Does the speaker mention anything about AI?`

After extraction, the user can ask follow-up questions about the video content.

## Instructions

1. **Parse arguments** - Extract the YouTube URL from $ARGUMENTS (it can appear anywhere in the text). The rest of the text is the user's question (if provided).

2. **Locate scripts** - The helper scripts are in the `scripts/` subdirectory relative to this SKILL.md file.

3. **Check dependencies** - Verify `curl` and `jq` are available:
   ```bash
   bash <SKILL_SCRIPTS_DIR>/check_dependencies.sh
   ```
   If this fails, display the error message and stop.

4. **Extract transcript** - Run:
   ```bash
   bash <SKILL_SCRIPTS_DIR>/extract_transcript.sh "<YOUTUBE_URL>"
   ```
   The script outputs either:
   - `SUCCESS: /tmp/youtube-transcript-{video_id}.txt` - transcript saved
   - `ERROR: <message>` - extraction failed

5. **Handle extraction errors** - If extraction fails, display the error message to the user with helpful guidance.

6. **Read transcript** - Use the Read tool to load the transcript file from the path provided by the script.

7. **Present results:**
   - **If user asked a question** (text beyond the URL): Answer their question using the transcript content. Be thorough and reference specific timestamps when relevant.
   - **If no question** (URL only): Present a brief summary of the video including title, duration, and main topics. Let the user know they can ask questions about the content.

8. **Enable follow-up discussion** - The transcript remains in context for subsequent questions. User can ask follow-up questions naturally without re-invoking the skill.

## URL Detection

YouTube URLs can appear anywhere in the arguments and may be in these formats:
- `https://youtube.com/watch?v=VIDEO_ID`
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://youtube.com/embed/VIDEO_ID`
- `https://youtube.com/shorts/VIDEO_ID`

Use regex or string matching to extract the URL from the arguments text.

## Error Handling

If extraction fails:
- Invalid URL → Show supported formats
- No transcript available → Explain captions are required
- Private/unavailable video → Cannot access
- Rate limited or bot-blocked → YouTube may be blocking the request; suggest trying again later

## Example Interactions

**User:** `/yt-transcript https://youtube.com/watch?v=dQw4w9WgXcQ`
**Response:** Extract transcript, provide summary, invite questions.

**User:** `/yt-transcript What is this video about? https://youtu.be/dQw4w9WgXcQ`
**Response:** Extract transcript, answer the question with specific details.

**User (follow-up):** `What happens at the 2 minute mark?`
**Response:** Reference transcript around [02:00] timestamp, provide detailed answer.
