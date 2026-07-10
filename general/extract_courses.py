#!/usr/bin/env python3
"""
Extract all lesson content from Google Skills Rise 360 courses.
Data is embedded as base64 JSON in either index.html or runtime-data.js / locales/en.js.
"""

import json
import base64
import re
import urllib.request
import os
import sys
from pathlib import Path

COURSES = {
    "1_plan_change_mgmt": {
        "name": "1 - Plan Change Management for Gemini Enterprise Deployments",
        "url": "https://storage.googleapis.com/cloud-training/cls-html5-courses/P-MCFGED-I/content/index.html",
        "type": "inline_base64",  # base64 in __fetchCourse deserialize() call
    },
    "2_deploy_gemini_enterprise": {
        "name": "2 - Deploy the Gemini Enterprise App to Transform Enterprises",
        "url": "https://storage.googleapis.com/cloud-training/cls-html5-courses/P-DLGITD-I/content/runtime-data.js",
        "type": "jsonp_runtime",  # __jsonp("runtime-data.js","...")
    },
    "3_third_party_idp": {
        "name": "3 - Use a Third-Party Identity Provider with Workforce Identity Federation",
        "url": "https://storage.googleapis.com/cloud-training/cls-html5-courses/P-TPIWIF-A/content/runtime-data.js",
        "type": "jsonp_runtime",
    },
    "4_improve_agent_search": {
        "name": "4 - Improve Agent Search Results on Agent Platform",
        "url": "https://storage.googleapis.com/cloud-training/cls-html5-courses/P-ISAEAD-A/content/runtime-data.js",
        "type": "jsonp_runtime",
    },
    "5_model_armor": {
        "name": "5 - Model Armor: Securing AI Deployments",
        "url": "https://storage.googleapis.com/cloud-training/cls-html5-courses/T-MODARM-B/1.0/T-MODARM-B/locales/en.js",
        "type": "jsonp_locale",  # __resolveJsonp("course:en","...")
    },
}


def fetch_url(url):
    """Download content from URL."""
    print(f"  Fetching: {url}")
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = resp.read()
            # Try UTF-8 first
            try:
                return data.decode("utf-8")
            except:
                return data.decode("latin-1")
    except Exception as e:
        print(f"  ERROR fetching {url}: {e}")
        return None


def extract_base64_inline(html):
    """Extract base64 from: deserialize('...') in the HTML."""
    # Pattern: deserialize("BASE64_STRING")
    match = re.search(r'deserialize\s*\(\s*["\']([A-Za-z0-9+/=]+)["\']\s*\)', html)
    if match:
        return match.group(1)
    # Try single quotes
    match = re.search(r"deserialize\s*\(\s*[']([A-Za-z0-9+/=]+)[']\s*\)", html)
    if match:
        return match.group(1)
    return None


def extract_base64_jsonp(text, prefix_pattern="__jsonp"):
    """Extract base64 from JSONP like: __jsonp("name","BASE64")"""
    # Match __jsonp("name","BASE64") or __resolveJsonp("name","BASE64")
    match = re.search(
        r'(?:__jsonp|__resolveJsonp)\s*\(\s*["\'][^"\']+["\']\s*,\s*["\']([A-Za-z0-9+/=]+)["\']\s*\)',
        text,
    )
    if match:
        return match.group(1)
    return None


def decode_base64_json(b64_str):
    """Decode base64 string to JSON object."""
    try:
        # Add padding if needed
        padding = 4 - len(b64_str) % 4
        if padding != 4:
            b64_str += "=" * padding
        decoded = base64.b64decode(b64_str)
        return json.loads(decoded)
    except Exception as e:
        print(f"  ERROR decoding base64: {e}")
        return None


def extract_lesson_text(lesson_data):
    """Extract all text from a lesson's blocks/items."""
    lesson_type = lesson_data.get("type", "")
    title = lesson_data.get("title", "")
    description = lesson_data.get("description", "")
    position = lesson_data.get("position", 0)

    # Only process block-type lessons (not section dividers)
    if lesson_type != "blocks":
        return title, [], lesson_type, position

    texts = []

    if description:
        texts.append((f"Overview", strip_html(description)))

    # Items within a lesson (the main content blocks)
    items = lesson_data.get("items", [])
    for item in items:
        item_type = item.get("type", "")
        item_texts = []

        # The actual content is in item["items"][]
        sub_items = item.get("items", [])
        if sub_items:
            for sub in sub_items:
                parts = []

                # Heading
                heading = sub.get("heading", "")
                if heading:
                    parts.append(strip_html(heading))

                # Paragraph
                paragraph = sub.get("paragraph", "")
                if paragraph:
                    parts.append(strip_html(paragraph))

                # Text
                text = sub.get("text", "")
                if text:
                    if isinstance(text, list):
                        for t in text:
                            if isinstance(t, dict):
                                for val in t.values():
                                    if isinstance(val, str):
                                        parts.append(strip_html(val))
                            elif isinstance(t, str):
                                parts.append(strip_html(t))
                    elif isinstance(text, str):
                        parts.append(strip_html(text))

                # Value field
                value = sub.get("value", "")
                if value and isinstance(value, str):
                    parts.append(strip_html(value))

                if parts:
                    item_texts.append("\n".join(parts))

        # If no sub-items found, try other fields directly
        if not item_texts:
            parts = []
            for field in ["heading", "paragraph", "text", "value", "content", "description"]:
                val = item.get(field, "")
                if val:
                    if isinstance(val, list):
                        for v in val:
                            if isinstance(v, str):
                                parts.append(strip_html(v))
                    elif isinstance(val, str):
                        parts.append(strip_html(val))
            if parts:
                item_texts.append("\n".join(parts))

        if item_texts:
            block_label = item.get("title", "") or item_type.capitalize()
            texts.append((block_label, "\n\n".join(item_texts)))

    return title, texts, lesson_type, position


def strip_html(text):
    """Remove HTML tags from text."""
    if not text or not isinstance(text, str):
        return ""
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    # Decode common HTML entities
    text = text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    text = text.replace("&quot;", '"').replace("&#39;", "'")
    return text


def process_course(course_key, course_info):
    """Download, decode and extract all lesson content from a course."""
    print(f"\n{'='*70}")
    print(f"Processing: {course_info['name']}")
    print(f"{'='*70}")

    raw = fetch_url(course_info["url"])
    if not raw:
        return None

    # Extract base64
    b64_data = None
    if course_info["type"] == "inline_base64":
        b64_data = extract_base64_inline(raw)
    elif course_info["type"] in ("jsonp_runtime", "jsonp_locale"):
        b64_data = extract_base64_jsonp(raw)

    if not b64_data:
        print("  Could not extract base64 data!")
        # Debug: show first 500 chars
        print(f"  Raw starts: {raw[:200]}")
        return None

    print(f"  Base64 length: {len(b64_data)} chars")

    # Decode
    course_json = decode_base64_json(b64_data)
    if not course_json:
        return None

    # The structure is { "course": { ... } }
    course_data = course_json.get("course", course_json)
    course_title = course_data.get("title", course_info["name"])
    print(f"  Course title: {course_title}")

    # Extract lessons
    lessons = course_data.get("lessons", [])
    print(f"  Total lessons: {len(lessons)}")

    lesson_count = 0
    block_count = 0

    output = []
    output.append(f"# {course_title}")
    output.append("")

    for lesson in lessons:
        title, text_blocks, lesson_type, position = extract_lesson_text(lesson)

        # Skip empty sections
        if not text_blocks and not title:
            continue

        lesson_count += 1
        output.append(f"## {title}")
        if lesson_type:
            output.append(f"*Type: {lesson_type}*")
        output.append("")

        for block_title, block_text in text_blocks:
            if block_text.strip():
                block_count += 1
                if block_title:
                    output.append(f"### {block_title}")
                    output.append("")
                output.append(block_text)
                output.append("")

    output_text = "\n".join(output)
    print(f"  Extracted {lesson_count} lesson sections, {block_count} text blocks")

    return {
        "title": course_title,
        "text": output_text,
        "lesson_count": lesson_count,
        "block_count": block_count,
    }


def main():
    output_dir = Path("/home/addy/projects/scripts/general/course_content")
    output_dir.mkdir(exist_ok=True)

    all_results = []

    for key, info in COURSES.items():
        result = process_course(key, info)
        if result:
            all_results.append(result)
            # Save individual course
            filename = f"{key}.md"
            filepath = output_dir / filename
            filepath.write_text(result["text"])
            print(f"  Saved to: {filepath}")

    # Create combined file
    print(f"\n{'='*70}")
    print(f"COMBINED SUMMARY")
    print(f"{'='*70}")
    combined = []
    for r in all_results:
        combined.append(r["text"])

    combined_path = output_dir / "ALL_COURSES_COMBINED.md"
    combined_path.write_text("\n\n---\n\n".join(combined))
    print(f"\nAll courses saved to: {output_dir}")
    print(f"Combined file: {combined_path}")
    print(f"\nTotal courses processed: {len(all_results)}")
    print(f"Total lessons extracted: {sum(r['lesson_count'] for r in all_results)}")
    print(f"Total text blocks: {sum(r['block_count'] for r in all_results)}")


if __name__ == "__main__":
    main()
