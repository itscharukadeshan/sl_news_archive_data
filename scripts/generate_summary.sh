#!/bin/bash
# Thin wrapper: summary logic lives in generate_summary.py (single pass,
# stdlib only). Run from the scripts/ directory, same as before.
exec python3 "$(dirname "$0")/generate_summary.py"
