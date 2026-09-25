#!/usr/bin/env python3
"""Rebuild archive/news_article_counts.csv in one pass (no jq-per-file)."""
import csv
import json
import os
import sys

BASE = os.getcwd()
ARCHIVE_DIR = os.path.join(BASE, "../archive")
OUTPUT_FILE = os.path.join(ARCHIVE_DIR, "news_article_counts.csv")


def main():
    counts = {}
    for root, _dirs, files in os.walk(ARCHIVE_DIR):
        if "articles.json" not in files:
            continue
        rel = os.path.relpath(root, ARCHIVE_DIR)
        parts = rel.split(os.sep)
        if len(parts) != 2:
            continue
        newspaper, date = parts
        try:
            with open(os.path.join(root, "articles.json")) as fp:
                data = json.load(fp)
            n = len(data) if isinstance(data, list) else 0
        except (OSError, ValueError):
            continue
        counts[(date, newspaper)] = counts.get((date, newspaper), 0) + n
    with open(OUTPUT_FILE, "w", newline="") as fp:
        w = csv.writer(fp, lineterminator="\n")
        w.writerow(["Date", "Newspaper", "ArticleCount"])
        for (date, newspaper) in sorted(counts):
            w.writerow([date, newspaper, counts[(date, newspaper)]])
    print(f"Table generated and saved to {OUTPUT_FILE}")


if __name__ == "__main__":
    sys.exit(main())
