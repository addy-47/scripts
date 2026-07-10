#!/usr/bin/env python3
"""
call-review.py - Extract audio from a client call video, transcribe in 5-min chunks,
translate everything to English, and produce a structured project brief via Gemini.

Usage:
    export GEMINI_API_KEY="your-api-key-here"
    python3 call-review.py ~/Downloads/client-call.mp4

Requirements:
    - Python 3.8+ (requests library)
    - ffmpeg (with libmp3lame encoder)
    - Gemini API key in GEMINI_API_KEY env variable
"""

import os
import sys
import json
import time
import base64
import argparse
import subprocess
import tempfile
import shutil
from pathlib import Path

import requests


# ── Configuration ──────────────────────────────────────────────────────────

MODEL = "gemini-2.5-flash-lite"
CHUNK_DURATION_SECONDS = 300  # 5 minutes
SLEEP_BETWEEN_CHUNKS = 1.5   # seconds, to avoid rate limits
RETRY_MAX = 2                # max attempts per chunk

SUPPORTED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".mkv", ".avi", ".webm", ".m4v"}


# ── API helpers ────────────────────────────────────────────────────────────

def gemini_request(api_key: str, contents: list, system_prompt: str = None) -> str:
    """Send a prompt to Gemini and return the response text. Handles inline audio data."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={api_key}"

    body = {"contents": [{"parts": contents}]}
    if system_prompt:
        body["system_instruction"] = {"parts": [{"text": system_prompt}]}

    resp = requests.post(url, json=body, timeout=120)
    if resp.status_code == 429:
        raise RuntimeError("Rate limited (429)")
    if resp.status_code != 200:
        detail = resp.text[:500] if resp.text else "(empty body)"
        raise RuntimeError(f"Gemini API returned {resp.status_code}: {detail}")

    data = resp.json()
    if "promptFeedback" in data and data["promptFeedback"].get("blockReason"):
        raise RuntimeError(f"Request blocked: {data['promptFeedback']['blockReason']}")

    candidates = data.get("candidates", [])
    if not candidates:
        raise RuntimeError("Gemini returned no candidates (empty response)")

    parts = candidates[0].get("content", {}).get("parts", [])
    if not parts:
        raise RuntimeError("Gemini response has no content parts")

    return parts[0].get("text", "")


# ── Phase 1: Preflight ────────────────────────────────────────────────────

def check_deps():
    """Verify external dependencies and environment."""
    errors = []

    # ffmpeg
    try:
        subprocess.run(["ffmpeg", "-version"], capture_output=True, check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        errors.append("ffmpeg not found. Install it via your package manager.")

    # requests
    try:
        import requests
    except ImportError:
        errors.append("Python 'requests' library not found. Run: pip install requests")

    # env var
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key:
        errors.append(
            "GEMINI_API_KEY environment variable is not set.\n"
            "  Run:  export GEMINI_API_KEY='your-key-here'"
        )

    if errors:
        print("❌ Preflight checks failed:\n", file=sys.stderr)
        for e in errors:
            print(f"  • {e}", file=sys.stderr)
        sys.exit(1)

    return api_key


def validate_video(path: str) -> Path:
    """Ensure the video file exists and is a recognised format."""
    p = Path(path).resolve()
    if not p.exists():
        print(f"❌ File not found: {path}", file=sys.stderr)
        sys.exit(1)
    if p.stat().st_size == 0:
        print(f"❌ File is empty: {path}", file=sys.stderr)
        sys.exit(1)
    if p.suffix.lower() not in SUPPORTED_VIDEO_EXTENSIONS:
        print(f"⚠ WARNING: '{p.suffix}' is not in the typical video extension list "
              f"{SUPPORTED_VIDEO_EXTENSIONS}. Proceeding anyway – ffmpeg will decide.", file=sys.stderr)
    return p


def get_video_duration(path: str) -> float:
    """Return duration in seconds via ffprobe."""
    result = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "csv=p=0", path],
        capture_output=True, text=True, check=True,
    )
    return float(result.stdout.strip())


# ── Phase 2: Audio extraction & chunking ──────────────────────────────────

def extract_and_chunk(video_path: str, temp_dir: str, duration: float) -> list[str]:
    """
    Extract audio from video and split into ~5-min MP3 chunks.
    Returns a sorted list of chunk file paths.
    """
    print("🎵 Extracting audio & splitting into 5-minute chunks...")

    output_pattern = os.path.join(temp_dir, "chunk_%03d.mp3")

    cmd = [
        "ffmpeg", "-y",
        "-i", video_path,
        "-vn",                              # drop video
        "-acodec", "libmp3lame",            # MP3 encoder
        "-ac", "1",                         # mono
        "-ar", "16000",                     # 16 kHz sample rate
        "-b:a", "64k",                      # 64 kbps bitrate
        "-f", "segment",
        "-segment_time", str(CHUNK_DURATION_SECONDS),
        "-reset_timestamps", "1",
        output_pattern,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("❌ ffmpeg failed:", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)

    # Gather chunks in order
    chunks = sorted(
        os.path.join(temp_dir, f)
        for f in os.listdir(temp_dir)
        if f.startswith("chunk_") and f.endswith(".mp3")
    )

    if not chunks:
        print("❌ ffmpeg produced no audio chunks. Check the video file for audio tracks.",
              file=sys.stderr)
        sys.exit(1)

    total_chunks = len(chunks)
    total_minutes = duration / 60
    print(f"✓ Created {total_chunks} chunk(s) from a {total_minutes:.0f}-minute call.")
    print()

    return chunks


# ── Phase 3: Transcription ────────────────────────────────────────────────

TRANSCRIPTION_SYSTEM = (
    "You are an expert transcriptionist and translator. Transcribe this audio from a "
    "client-project call with maximum accuracy.\n\n"
    "Rules:\n"
    "- Preserve EVERY word including hesitations, repetitions, and filler words.\n"
    "- If multiple speakers are distinguishable, label them as [Speaker A], [Speaker B], etc.\n"
    "- For unclear segments, use [unclear] and do NOT guess the content.\n"
    "- Preserve all numbers, dates, dollar amounts, technical terms, acronyms, "
    "and proper names exactly as spoken.\n"
    "- If the audio contains non-English speech, transcribe the original AND translate it.\n"
    "- Output ALL text in English. For non-English segments use the format:\n"
    "  [original: <original speech>] [english: <English translation>]\n"
    "- Do NOT summarize, paraphrase, or omit anything.\n"
    "- Note any decisions, action items, or commitments made during the segment."
)

TRANSCRIPTION_USER_TEMPLATE = (
    "Transcribe and translate this audio segment to English. "
    "This is segment {n} of {total}."
)


def transcribe_chunks(chunks: list[str], api_key: str) -> list[dict]:
    """Transcribe each chunk via Gemini. Returns list of {n, timestamp, text, success}."""
    results = []

    for i, chunk_path in enumerate(chunks):
        n = i + 1
        total = len(chunks)
        start_min = i * CHUNK_DURATION_SECONDS // 60
        start_sec = i * CHUNK_DURATION_SECONDS % 60
        end_min = (i + 1) * CHUNK_DURATION_SECONDS // 60
        end_sec = (i + 1) * CHUNK_DURATION_SECONDS % 60
        timestamp = f"{start_min:02d}:{start_sec:02d}–{end_min:02d}:{end_sec:02d}"

        print(f"  [{n:3d}/{total}] Transcribing {timestamp} ...", end=" ", flush=True)

        # Read + encode audio
        with open(chunk_path, "rb") as f:
            audio_b64 = base64.b64encode(f.read()).decode("utf-8")

        entry = {
            "chunk": n,
            "timestamp": timestamp,
            "segment_start_seconds": i * CHUNK_DURATION_SECONDS,
            "segment_end_seconds": (i + 1) * CHUNK_DURATION_SECONDS,
            "text": "",
            "success": False,
        }

        last_error = None
        for attempt in range(1, RETRY_MAX + 1):
            try:
                text = gemini_request(
                    api_key,
                    contents=[
                        {"inline_data": {"mime_type": "audio/mp3", "data": audio_b64}},
                        {"text": TRANSCRIPTION_USER_TEMPLATE.format(n=n, total=total)},
                    ],
                    system_prompt=TRANSCRIPTION_SYSTEM,
                )
                entry["text"] = text.strip()
                entry["success"] = True
                print("✓")
                break

            except RuntimeError as e:
                last_error = str(e)
                if "429" in str(e):
                    print(f"⏳ (rate limited, retry {attempt}/{RETRY_MAX})", end=" ", flush=True)
                    time.sleep(3 * attempt)
                else:
                    print(f"⚠ (attempt {attempt}/{RETRY_MAX} failed: {e})", end=" ", flush=True)
                    time.sleep(2)

        if not entry["success"]:
            entry["error"] = last_error or "Unknown error"
            print(f"✗ FAILED — {last_error}")

        results.append(entry)

        # Polite sleep between chunks
        if i < len(chunks) - 1:
            time.sleep(SLEEP_BETWEEN_CHUNKS)

    success_count = sum(1 for r in results if r["success"])
    print(f"\n✓ Transcribed {success_count}/{len(results)} chunks.\n")
    return results


# ── Phase 4: Summarization ────────────────────────────────────────────────

SUMMARY_SYSTEM = (
    "You are a senior project analyst. Your task is to analyse a full "
    "client-project call transcript and produce a comprehensive, structured brief "
    "for a developer who was NOT on the call. The developer will execute the "
    "project, so completeness and accuracy are critical. Missing any detail could "
    "cause misalignment with the client.\n\n"
    "Analyse the entire transcript below and extract every relevant detail. The "
    "transcript is segmented into 5-minute chunks with timestamps \u2014 use "
    "these to reference when specific topics were discussed.\n\n"
    "Structure your analysis under these mandatory sections (use exactly these "
    "headings in your response):\n\n"
    "## 1. PROJECT OVERVIEW\n"
    "One-paragraph high-level summary of what the project is.\n\n"
    "## 2. GOAL & OBJECTIVES\n"
    "What the client wants to achieve \u2014 business goals, success criteria, "
    "desired outcomes.\n\n"
    "## 3. SCOPE OF WORK\n"
    "What needs to be built or delivered \u2014 features, deliverables, phases, "
    "in-scope and out-of-scope items.\n\n"
    "## 4. CLIENT REQUIREMENTS\n"
    "Specific asks, preferences, tech stack preferences, design preferences, "
    "compliance or regulatory needs.\n\n"
    "## 5. TECHNICAL SPECIFICATIONS\n"
    "Any mentioned architectures, platforms, integrations, APIs, hosting, "
    "databases, performance or security requirements.\n\n"
    "## 6. TIMELINE & MILESTONES\n"
    "Deadlines, launch dates, sprint schedules, phase gates, when things are due.\n\n"
    "## 7. BLOCKERS & RISKS\n"
    "Issues raised, concerns, dependencies on third parties, unclear requirements, "
    "potential roadblocks.\n\n"
    "## 8. BUDGET / COST DISCUSSION\n"
    "Any financial figures mentioned, budget constraints, pricing discussions.\n\n"
    "## 9. STAKEHOLDERS\n"
    "Who was on the call, who are the decision-makers, points of contact.\n\n"
    "## 10. DECISIONS MADE\n"
    "Concrete agreements reached during the call.\n\n"
    "## 11. ACTION ITEMS\n"
    "Who is doing what and by when \u2014 reference the segment timestamp.\n\n"
    "## 12. OPEN QUESTIONS / UNRESOLVED\n"
    "Items explicitly noted as needing follow-up or clarification.\n\n"
    "## 13. KEY QUOTES\n"
    "Exact client phrasing that captures important requirements or concerns "
    "(reference segment).\n\n"
    "After the above sections, append:\n\n"
    "## \u26a0 RISK FLAGS\n"
    "A bullet list of anything that sounds ambiguous, contradictory, unrealistic, "
    "or potentially problematic.\n\n"
    "Format the entire response in clean Markdown. Use **bold** for key terms, "
    "and use `[Segment X \u2014 HH:MM]` references where appropriate."
)


def build_full_transcript(results: list[dict]) -> str:
    """Assemble all successful transcriptions into one labelled document."""
    parts = []
    for r in results:
        if r["success"] and r["text"].strip():
            parts.append(
                f"[SEGMENT {r['chunk']} — {r['timestamp']}]\n{r['text']}\n"
            )
        elif not r["success"]:
            parts.append(
                f"[SEGMENT {r['chunk']} — {r['timestamp']}]\n"
                f"[Transcription FAILED for this segment]\n"
            )

    if not parts:
        print("⚠ No transcriptions available to summarise.", file=sys.stderr)
        return ""

    return "\n".join(parts)


def summarize(transcript_text: str, api_key: str, video_name: str) -> str:
    """Send full transcript to Gemini for structured summary."""
    if not transcript_text.strip():
        return "No transcript content available to summarise."

    print("🧠 Generating structured summary (this may take 10\u201330 seconds)...")

    user_prompt = (
        f"The following is the full transcript of a client call about the project "
        f"named \"{video_name}\". Please produce the structured analysis as instructed.\n\n"
        f"{transcript_text}"
    )

    text = gemini_request(
        api_key,
        contents=[{"text": user_prompt}],
        system_prompt=SUMMARY_SYSTEM,
    )
    return text.strip()


# ── Phase 5: Output ───────────────────────────────────────────────────────

def write_outputs(results: list[dict], summary_text: str, base_name: str):
    """Write transcriptions.jsonl, summary.md, and summary.json."""
    # Transcriptions JSONL
    jsonl_path = Path.cwd() / f"{base_name}.transcriptions.jsonl"
    with open(jsonl_path, "w", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"✓ Saved: {jsonl_path.name}")

    # Summary markdown
    if summary_text:
        md_path = Path.cwd() / f"{base_name}.summary.md"
        with open(md_path, "w", encoding="utf-8") as f:
            f.write(summary_text)
        print(f"✓ Saved: {md_path.name}")

        # Summary JSON (same data, structured)
        summary_data = parse_summary_sections(summary_text)
        json_path = Path.cwd() / f"{base_name}.summary.json"
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(summary_data, f, ensure_ascii=False, indent=2)
        print(f"✓ Saved: {json_path.name}")
    else:
        print("⚠ No summary text to write.")

    print()


def parse_summary_sections(text: str) -> dict:
    """Naively parse markdown headings into a JSON dict for machine readability."""
    sections = {}
    current_section = None
    current_lines = []

    for line in text.split("\n"):
        if line.startswith("## "):
            if current_section:
                sections[current_section] = "\n".join(current_lines).strip()
            current_section = line.lstrip("# ").strip()
            current_lines = []
        else:
            current_lines.append(line)

    if current_section:
        sections[current_section] = "\n".join(current_lines).strip()

    return sections


# ── Main ──────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Extract audio, transcribe in 5-min chunks, and produce a "
                    "structured project brief from a client call video.",
        epilog="Example: python3 call-review.py ~/Downloads/client-call.mp4",
    )
    parser.add_argument("video", help="Path to the video file (mp4, mov, mkv, etc.)")
    args = parser.parse_args()

    # ── Phase 1: Preflight ──
    print("=" * 60)
    print("  Call Review — Audio Transcription & Summary Tool")
    print("=" * 60)
    print()

    api_key = check_deps()
    video_path = validate_video(args.video)
    duration = get_video_duration(str(video_path))

    total_minutes = duration / 60
    estimated_chunks = max(1, int(duration // CHUNK_DURATION_SECONDS) +
                           (1 if duration % CHUNK_DURATION_SECONDS else 0))
    print(f"Video:  {video_path.name}")
    print(f"Length: {total_minutes:.0f} min ({duration:.0f} s)")
    print(f"Chunks: ~{estimated_chunks} × {CHUNK_DURATION_SECONDS // 60} min")
    print(f"Model:  {MODEL}")
    print()

    # Create temp directory
    temp_dir = tempfile.mkdtemp(prefix="call-review-")

    try:
        # ── Phase 2: Extract & chunk ──
        chunks = extract_and_chunk(str(video_path), temp_dir, duration)
        actual_chunks = len(chunks)

        # ── Phase 3: Transcribe ──
        results = transcribe_chunks(chunks, api_key)

        # ── Phase 4: Summarize ──
        full_transcript = build_full_transcript(results)
        summary_text = summarize(full_transcript, api_key, video_path.stem)

        # ── Phase 5: Write outputs ──
        print()
        write_outputs(results, summary_text, video_path.stem)

        # Final summary
        success_count = sum(1 for r in results if r["success"])
        total_count = len(results)
        print("=" * 60)
        print(f"  ✅ Done — {success_count}/{total_count} chunks transcribed")
        if summary_text:
            print(f"  📄 Summary: {video_path.stem}.summary.md")
        print(f"  📄 Transcriptions: {video_path.stem}.transcriptions.jsonl")
        print("=" * 60)

    finally:
        # Clean up temp directory
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
