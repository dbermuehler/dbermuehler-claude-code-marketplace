#!/usr/bin/env bash
# Extract a YouTube video transcript using curl, jq, and standard Unix tools.
# No Python, uv, or pip required.
#
# Usage:  extract_transcript.sh <youtube-url>
# Output: SUCCESS: /tmp/youtube-transcript-<id>.txt
#         ERROR:   <human-readable message>

set -uo pipefail

# ── helpers ───────────────────────────────────────────────────────────────────

extract_video_id() {
    local url="$1"
    local re_short='youtu\.be/([a-zA-Z0-9_-]{11})'
    local re_watch='[?&]v=([a-zA-Z0-9_-]{11})'
    local re_path='youtube\.com/(embed|shorts)/([a-zA-Z0-9_-]{11})'
    if   [[ "$url" =~ $re_short ]]; then echo "${BASH_REMATCH[1]}"
    elif [[ "$url" =~ $re_watch ]]; then echo "${BASH_REMATCH[1]}"
    elif [[ "$url" =~ $re_path  ]]; then echo "${BASH_REMATCH[2]}"
    fi
}

fmt_ts() {
    local s="$1" h m r
    h=$(( s / 3600 )); m=$(( (s % 3600) / 60 )); r=$(( s % 60 ))
    (( h > 0 )) && printf "%02d:%02d:%02d" $h $m $r || printf "%02d:%02d" $m $r
}

# ── argument handling ─────────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
    echo "ERROR: No YouTube URL provided"
    echo "Usage: extract_transcript.sh <youtube-url>"
    exit 1
fi

VIDEO_ID=$(extract_video_id "$1")
if [[ -z "$VIDEO_ID" ]]; then
    echo "ERROR: Could not extract video ID from: $1"
    echo ""
    echo "Supported formats:"
    echo "  https://youtube.com/watch?v=VIDEO_ID"
    echo "  https://youtu.be/VIDEO_ID"
    echo "  https://youtube.com/embed/VIDEO_ID"
    echo "  https://youtube.com/shorts/VIDEO_ID"
    exit 1
fi

# ── step 1: fetch the YouTube watch page & extract innertube API key ──────────

PAGE=$(curl -s -L --compressed --max-time 30 \
    -H "Accept-Language: en-US" \
    "https://www.youtube.com/watch?v=${VIDEO_ID}" 2>/dev/null)

if [[ -z "$PAGE" ]]; then
    echo "ERROR: Failed to fetch YouTube page for video ID: $VIDEO_ID"
    exit 1
fi

# Handle EU consent page: set consent cookie and re-fetch
if printf '%s' "$PAGE" | grep -q 'action="https://consent.youtube.com/s"'; then
    CONSENT_V=$(printf '%s' "$PAGE" | grep -o 'name="v" value="[^"]*"' | head -1 | sed 's/name="v" value="//; s/"$//')
    if [[ -n "$CONSENT_V" ]]; then
        PAGE=$(curl -s -L --compressed --max-time 30 \
            -H "Accept-Language: en-US" \
            -b "CONSENT=YES+${CONSENT_V}" \
            "https://www.youtube.com/watch?v=${VIDEO_ID}" 2>/dev/null)
    fi
fi

API_KEY=$(printf '%s' "$PAGE" | grep -o '"INNERTUBE_API_KEY":"[^"]*"' | head -1 | sed 's/"INNERTUBE_API_KEY":"//; s/"$//')

if [[ -z "$API_KEY" ]]; then
    # Check for IP block (captcha)
    if printf '%s' "$PAGE" | grep -q 'class="g-recaptcha"'; then
        echo "ERROR: YouTube is blocking this request with a captcha. Try again later or from a different IP."
        exit 1
    fi
    echo "ERROR: Could not extract API key from YouTube page. The page structure may have changed."
    exit 1
fi

# ── step 2: POST to innertube player API to get caption track URLs ────────────

PLAYER_JSON=$(curl -s -L --compressed --max-time 30 \
    -H "Accept-Language: en-US" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{
        "context": {
            "client": {
                "clientName": "ANDROID",
                "clientVersion": "20.10.38"
            }
        },
        "videoId": "'"${VIDEO_ID}"'"
    }' \
    "https://www.youtube.com/youtubei/v1/player?key=${API_KEY}" 2>/dev/null)

if [[ -z "$PLAYER_JSON" ]]; then
    echo "ERROR: InnerTube API request failed for video ID: $VIDEO_ID"
    exit 1
fi

# Check playability status
PLAY_STATUS=$(printf '%s' "$PLAYER_JSON" | jq -r '.playabilityStatus.status // empty')
if [[ "$PLAY_STATUS" != "OK" ]]; then
    PLAY_REASON=$(printf '%s' "$PLAYER_JSON" | jq -r '.playabilityStatus.reason // "Unknown reason"')
    echo "ERROR: Video not playable (ID: $VIDEO_ID) — $PLAY_REASON"
    exit 1
fi

# Extract caption track URLs; prefer manual captions (kind != "asr") over auto-generated
CAPTION_URL=$(printf '%s' "$PLAYER_JSON" | jq -r '
    .captions.playerCaptionsTracklistRenderer.captionTracks
    | if . == null then empty
      else
        (map(select(.kind != "asr")) | if length > 0 then .[0].baseUrl else null end)
        // (.[0].baseUrl // empty)
      end
    ' | sed 's/&fmt=srv3//')

if [[ -z "$CAPTION_URL" ]]; then
    echo "ERROR: No captions available for video ID: $VIDEO_ID"
    echo "The video may not have transcripts enabled (manual or auto-generated)."
    exit 1
fi

# ── step 3: fetch the transcript XML ─────────────────────────────────────────

XML=$(curl -s -L --compressed --max-time 30 \
    -H "Accept-Language: en-US" \
    "$CAPTION_URL" 2>/dev/null)

if [[ -z "$XML" ]] || ! printf '%s' "$XML" | grep -q '<text'; then
    echo "ERROR: Transcript download failed or returned no content for: $VIDEO_ID"
    exit 1
fi

# ── parse and write transcript ────────────────────────────────────────────────

OUTPUT="/tmp/youtube-transcript-${VIDEO_ID}.txt"

{
    printf "# YouTube Transcript\n\n"
    printf "**Video ID:** %s\n" "$VIDEO_ID"
    printf "**URL:** https://www.youtube.com/watch?v=%s\n\n---\n\n" "$VIDEO_ID"

    # Each segment: <text start="N.N" dur="N.N">…</text>
    # Collapse to one line, split on </text>, parse each segment.
    printf '%s' "$XML" \
        | tr '\n' ' ' \
        | sed 's|</text>|\n|g' \
        | grep 'start="' \
        | while IFS= read -r seg; do
            start=$(printf '%s' "$seg" | grep -o 'start="[0-9.]*"' | sed 's/start="//; s/"//')
            [[ -z "$start" ]] && continue

            # Strip XML tags, decode HTML entities (order matters: &amp; first for double-encoding)
            text=$(printf '%s' "$seg" \
                | sed \
                    -e 's/<[^>]*>//g' \
                    -e 's/&amp;/\&/g' \
                    -e 's/&lt;/</g' \
                    -e 's/&gt;/>/g' \
                    -e "s/&#39;/'/g" \
                    -e 's/&quot;/"/g' \
                    -e "s/&#x27;/'/g" \
                    -e 's/\\n/ /g' \
                    -e 's/^[[:space:]]*//' \
                    -e 's/[[:space:]]*$//')

            [[ -z "$text" ]] && continue

            printf "[%s] %s\n" "$(fmt_ts "${start%.*}")" "$text"
        done
} > "$OUTPUT"

line_count=$(wc -l < "$OUTPUT")
if (( line_count < 8 )); then
    echo "ERROR: Transcript appears to be empty for video ID: $VIDEO_ID"
    exit 1
fi

echo "SUCCESS: $OUTPUT"
