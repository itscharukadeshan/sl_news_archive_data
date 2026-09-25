#!/usr/bin/env python3
"""Rebuild the README summary table in one pass (no jq-per-file)."""
import datetime
import json
import os
import sys

BASE = os.getcwd()
ARCHIVE_DIR = os.path.join(BASE, "../archive")
README_FILE = os.path.join(BASE, "../README.md")

PREVIEW_URL = "https://itscharukadeshan.github.io/sl_news_archive_data/news_chart_by_newspaper.html"
LIVE_DEMO_URL = "https://lovely-frangipane-97c43f.netlify.app/"


def count_articles(path):
    try:
        with open(path) as fp:
            data = json.load(fp)
        return len(data) if isinstance(data, list) else 0
    except (OSError, ValueError):
        return 0


def main():
    today = datetime.date.today().isoformat()
    tz = datetime.timezone(datetime.timedelta(hours=5, minutes=30))
    now = datetime.datetime.now(tz).strftime("%a %b %d %T %z %Y")
    lines = [
        "## News Archive Summary\n",
        "\n",
        f"Summary Report as of {now}\n",
        "\n",
        "| News paper         | Today's Articles | Total Articles |\n",
        "|--------------------|------------------|----------------|\n",
    ]
    total_today = total_all = 0
    for key in sorted(os.listdir(ARCHIVE_DIR)):
        key_dir = os.path.join(ARCHIVE_DIR, key)
        if not os.path.isdir(key_dir):
            continue
        today_count = total_count = 0
        for date in sorted(os.listdir(key_dir)):
            f = os.path.join(key_dir, date, "articles.json")
            if os.path.isfile(f):
                n = count_articles(f)
                total_count += n
                if date == today:
                    today_count += n
        total_today += today_count
        total_all += total_count
        lines.append(f"| {key}               | {today_count}          | {total_count}        |\n")
    lines.append(f"| **Total** | **{total_today}** | **{total_all}** |\n")
    lines.append("\n")
    lines.append("### Links & Previews\n")
    lines.append(f"\U0001f310 [Live Demo Web App]({LIVE_DEMO_URL})\n")
    lines.append("\n")
    lines.append(f"\U0001f517 [View Interactive Chart]({PREVIEW_URL})\n")
    content = "".join(lines)
    with open(README_FILE) as fp:
        readme = fp.read()
    idx = readme.find("## News Archive Summary")
    readme = readme[:idx] if idx != -1 else readme
    # echo -e "$SUMMARY_CONTENT" >> : content (ends with \n) + one more \n
    with open(README_FILE, "w") as fp:
        fp.write(readme + content + "\n")
    print("README.md updated with News Archive Summary, Live Demo, and preview URL at the bottom.")


if __name__ == "__main__":
    sys.exit(main())
