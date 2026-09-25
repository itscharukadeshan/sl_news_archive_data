#!/usr/bin/env python3
"""Organize scrape output JSON into archive/<source>/<date>/articles.json.

Replaces the old jq-subprocess-per-field implementation with a single pass:
checksums preloaded into sets, each output file read/written once.
Same inputs, outputs, and log format as before.
"""
import datetime
import glob
import json
import os
import re
import shutil
import sys

BASE = os.getcwd()  # scripts/ run from the scripts directory
DATA_DIR = os.path.join(BASE, "../")
OUTPUT_DIR = os.path.join(BASE, "../archive")
ARCHIVE_DIR = os.path.join(BASE, "../processed_data")
LOG_FILE = os.path.join(BASE, "../process_log.txt")

# Canonical directory per source. Aliases absorb API key renames so history
# never forks into parallel directories.
KEY_ALIASES = {
    "adaderana_sinhala": "adaderana-sinhala",
    "adaderana_tamil": "adaderana-tamil",
    "adaderana_english": "adaderana",
    "the_morning": "themorning",
    "daily_mirror": "dailymirror",
    "tamil_mirror": "tamilmirror",
    "economy_next": "economynext",
    "news_wire": "newswire",
}

FIELDS = ("title", "href", "byline", "timestamp", "url",
          "isoTimestamp", "baseUrl", "checkSum")


def log(fh, msg):
    fh.write(msg + "\n")


def main():
    current_date = datetime.date.today().isoformat()
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    added = duplicate = skipped = 0
    missing = {}
    # (key_dir, date) -> list of new entries; output cache to write once
    pending = {}
    outputs = {}

    with open(LOG_FILE, "a") as fh:
        log(fh, f"Process started at {datetime.datetime.now()}")
        files = sorted(glob.glob(os.path.join(DATA_DIR, "*.json")))
        for path in files:
            filename = os.path.basename(path)
            log(fh, f"Processing file: {filename}")
            # File backfilled scrapes under their own date (from the
            # filename), not the processing date.
            m = re.search(r"(\d{4}-\d{2}-\d{2})", filename)
            date_dir = os.path.join(
                ARCHIVE_DIR, m.group(1) if m else current_date)
            os.makedirs(date_dir, exist_ok=True)
            try:
                with open(path) as fp:
                    payload = json.load(fp)
            except (json.JSONDecodeError, OSError) as exc:
                log(fh, f"Could not parse {filename}: {exc}")
                continue
            for key, entry in payload.items():
                if not isinstance(entry, dict) or entry.get("success") is not True:
                    log(fh, f"Skipping key: {key} (success is false)")
                    continue
                data = entry.get("data") or []
                canon = KEY_ALIASES.get(key, key)
                key_dir = os.path.join(OUTPUT_DIR, canon)
                os.makedirs(key_dir, exist_ok=True)
                checksum_file = os.path.join(key_dir, "checksum.txt")
                urls_file = os.path.join(key_dir, "urls.txt")
                seen = set()
                if os.path.exists(checksum_file):
                    with open(checksum_file) as fp:
                        seen = {line.strip() for line in fp if line.strip()}
                for item in data:
                    if not isinstance(item, dict):
                        skipped += 1
                        continue
                    clean = {k: v for k, v in item.items()
                             if v is not None and v != ""}
                    title = str(clean.get("title", ""))
                    url = str(clean.get("url", ""))
                    check_sum = str(clean.get("checkSum", ""))
                    if not title or not url or not check_sum:
                        skipped += 1
                        for f in ("title", "url", "checkSum"):
                            if not clean.get(f):
                                missing[f] = missing.get(f, 0) + 1
                        log(fh, "Skipped entry with missing title, url, or checksum.")
                        continue
                    if check_sum in seen:
                        duplicate += 1
                        log(fh, f"Duplicate entry skipped for checksum: {check_sum}")
                        continue
                    seen.add(check_sum)
                    iso = str(clean.get("isoTimestamp", ""))
                    day = iso.split("T", 1)[0] if iso else current_date
                    entry_out = {f: str(clean.get(f, "")) for f in FIELDS}
                    pending.setdefault((key_dir, day), []).append(entry_out)
                    with open(checksum_file, "a") as fp:
                        fp.write(check_sum + "\n")
                    with open(urls_file, "a") as fp:
                        fp.write(url + "\n")
                    added += 1
                    log(fh, f"Added new entry for date: {day} in key: {canon}")
            dest = os.path.join(date_dir, filename)
            shutil.move(path, dest)
            log(fh, f"Moved {filename} to archive in {date_dir}")

        for (key_dir, day), entries in pending.items():
            day_dir = os.path.join(key_dir, day)
            os.makedirs(day_dir, exist_ok=True)
            out_file = os.path.join(day_dir, "articles.json")
            existing = []
            if os.path.exists(out_file):
                try:
                    with open(out_file) as fp:
                        existing = json.load(fp) or []
                except (json.JSONDecodeError, OSError):
                    existing = []
            existing.extend(entries)
            # jq-style canonical format: 2-space indent, raw UTF-8,
            # trailing newline — byte-compatible with old pipeline output.
            with open(out_file, "w", encoding="utf-8") as fp:
                json.dump(existing, fp, indent=2, ensure_ascii=False)
                fp.write("\n")

        log(fh, f"Process completed at {datetime.datetime.now()}")
        log(fh, "Summary:")
        log(fh, f"Added articles: {added}")
        log(fh, f"Duplicate entries: {duplicate}")
        log(fh, f"Skipped entries due to missing data: {skipped}")
        log(fh, "Missing data fields:")
        for k, v in missing.items():
            log(fh, f"  {k}: {v}")
    print(f"Processing complete! Added={added} duplicates={duplicate} "
          f"skipped={skipped}. Logs saved to '{LOG_FILE}'.")


if __name__ == "__main__":
    sys.exit(main())
