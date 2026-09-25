#!/bin/bash
# Thin wrapper: table logic lives in generate_table.py (single pass,
# stdlib only). Run from the scripts/ directory, same as before.
exec python3 "$(dirname "$0")/generate_table.py"
