#!/bin/bash
# Thin wrapper: organizing logic lives in process_json.py (single pass,
# stdlib only). Run from the scripts/ directory, same as before.
exec python3 "$(dirname "$0")/process_json.py"
