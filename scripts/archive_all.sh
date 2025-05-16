#!/bin/bash

set -e

# Define variables
DOCKER_NAME="browserless"
TOKEN="6R0W53R135510"
DEV_DIR="/home/charuka/Web_dev/sl_news_archive"
ARCHIVE_DIR="/home/charuka/Web_dev/sl_news_archive_data"
DATA_DIR="$DEV_DIR/src/data"
PORT=3020

# Cleanup function to run on exit
cleanup() {
  echo "Cleaning up..."
  if [[ -n "$NPM_PID" ]]; then
    kill "$NPM_PID" 2>/dev/null || echo "Dev server already stopped"
  fi
  docker stop $DOCKER_NAME 2>/dev/null || echo "Docker container already stopped"
}
trap cleanup EXIT

# Start browserless Docker container
echo "Starting Browserless Docker container..."
docker run --rm -d -p 3000:3000 -e "TOKEN=$TOKEN" --name $DOCKER_NAME ghcr.io/browserless/chromium

# Navigate to project directory
cd "$DEV_DIR" || { echo "Directory $DEV_DIR not found"; exit 1; }

# Start npm dev server in background
echo "Starting dev server..."
npm run start &
NPM_PID=$!

# Wait for services to initialize
echo "Waiting for services to start..."
sleep 10

# Send request
echo "Sending request to archive endpoint..."
curl "http://localhost:$PORT/archive-all"

# Move JSON files
echo "Moving JSON files to archive data directory..."
mkdir -p "$ARCHIVE_DIR"
mv "$DATA_DIR"/*.json "$ARCHIVE_DIR" 2>/dev/null || echo "No JSON files to move."

echo "Done."
