#!/usr/bin/env python3
"""Transcribe audio files using OpenAI's Whisper API.

Accepts a local file path or a URL.

Usage:
    python transcribe.py recording.mp3
    python transcribe.py https://example.com/episode.mp3
    python transcribe.py recording.mp3 -o output.txt
"""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import httpx
from openai import OpenAI

MAX_FILE_SIZE = 24 * 1024 * 1024  # 24MB to stay under the 25MB API limit
CHUNK_DURATION_S = 600  # 10 minutes per chunk


def get_api_key() -> str:
    key = os.environ.get("OPENAI_API_KEY")
    if not key:
        print("Error: OPENAI_API_KEY environment variable is not set.")
        sys.exit(1)
    return key


def download(url: str, dest: Path) -> None:
    print(f"Downloading {url} ...")
    headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"}
    with httpx.stream("GET", url, follow_redirects=True, timeout=120, headers=headers) as r:
        r.raise_for_status()
        with open(dest, "wb") as f:
            for chunk in r.iter_bytes(8192):
                f.write(chunk)
    size_mb = dest.stat().st_size / (1024 * 1024)
    print(f"Downloaded {size_mb:.1f} MB")


def split_with_ffmpeg(audio_path: Path, chunk_dir: Path) -> list[Path]:
    pattern = str(chunk_dir / "chunk_%03d.mp3")
    subprocess.run(
        ["ffmpeg", "-i", str(audio_path), "-f", "segment",
         "-segment_time", str(CHUNK_DURATION_S), "-c", "copy", pattern],
        check=True, capture_output=True,
    )
    return sorted(chunk_dir.glob("chunk_*.mp3"))


def split_by_bytes(audio_path: Path, chunk_dir: Path) -> list[Path]:
    data = audio_path.read_bytes()
    total = len(data)
    num_chunks = (total // MAX_FILE_SIZE) + 1
    chunk_size = total // num_chunks

    chunks = []
    for i in range(num_chunks):
        start = i * chunk_size
        end = total if i == num_chunks - 1 else (i + 1) * chunk_size
        chunk_path = chunk_dir / f"chunk_{i:03d}.mp3"
        chunk_path.write_bytes(data[start:end])
        chunks.append(chunk_path)
    return chunks


def transcribe_file(client: OpenAI, audio_path: Path) -> str:
    with open(audio_path, "rb") as f:
        result = client.audio.transcriptions.create(model="whisper-1", file=f)
    return result.text


def transcribe(audio_path: Path) -> str:
    client = OpenAI(api_key=get_api_key())
    file_size = audio_path.stat().st_size
    size_mb = file_size / (1024 * 1024)
    print(f"Transcribing {audio_path.name} ({size_mb:.1f} MB)...")

    if file_size <= MAX_FILE_SIZE:
        return transcribe_file(client, audio_path)

    has_ffmpeg = shutil.which("ffmpeg") is not None

    if has_ffmpeg:
        print("File exceeds 25MB, splitting into chunks with ffmpeg...")
    else:
        print("File exceeds 25MB and ffmpeg is not installed.")
        print("Falling back to byte-level splitting (install ffmpeg for cleaner splits)...")

    with tempfile.TemporaryDirectory() as chunk_dir:
        if has_ffmpeg:
            chunks = split_with_ffmpeg(audio_path, Path(chunk_dir))
        else:
            chunks = split_by_bytes(audio_path, Path(chunk_dir))

        transcripts = []
        for idx, chunk in enumerate(chunks, 1):
            chunk_mb = chunk.stat().st_size / (1024 * 1024)
            print(f"  Transcribing chunk {idx}/{len(chunks)} ({chunk_mb:.1f} MB)...")
            transcripts.append(transcribe_file(client, chunk))

    return "\n\n".join(transcripts)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Transcribe audio using OpenAI Whisper API")
    parser.add_argument("source", help="Local audio file path or URL")
    parser.add_argument("-o", "--output", help="Output transcript file path")
    args = parser.parse_args()

    source = args.source
    is_url = source.startswith("http://") or source.startswith("https://")

    if is_url:
        suffix = Path(source.split("?")[0]).suffix or ".mp3"
        tmp = Path(tempfile.mktemp(suffix=suffix))
        try:
            download(source, tmp)
            audio_path = tmp
            default_output = "transcript.txt"
        except Exception:
            tmp.unlink(missing_ok=True)
            raise
    else:
        audio_path = Path(source).expanduser().resolve()
        if not audio_path.exists():
            print(f"Error: file not found: {audio_path}")
            sys.exit(1)
        default_output = audio_path.with_suffix(".txt").name
        tmp = None

    try:
        transcript = transcribe(audio_path)
    finally:
        if tmp:
            tmp.unlink(missing_ok=True)

    output_path = Path(args.output) if args.output else Path(default_output)
    output_path.write_text(transcript, encoding="utf-8")
    print(f"\nTranscript saved to {output_path}")
    print(f"Length: {len(transcript):,} characters")


if __name__ == "__main__":
    main()
