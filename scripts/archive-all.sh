#!/bin/bash

# === CONFIG ===
REPO_URL="https://github.com/itscharukadeshan/sl_news_archive.git"
CLONE_DIR="sl_news_archive"
BROWSERLESS_PORT=3000
BROWSERLESS_TOKEN="devtoken123"
NODE_PORT=3001

# === CLEANUP BEFORE START ===
echo "Cleaning up any existing processes..."

# Kill any running API server
pkill -f "node dist/server.js" || true

# Stop and remove existing browserless container if exists
docker rm -f browserless 2>/dev/null || true

# === STEP 1: Clone the Repo ===
echo "Cloning repository..."
git clone "$REPO_URL" "$CLONE_DIR" 2>/dev/null || {
  echo "Repo already exists or failed to clone"
}

cd "$CLONE_DIR" || {
  echo "Failed to enter project directory"
  exit 1
}

# === STEP 2: Pull & Run Browserless (via Docker) ===
echo "Pulling Browserless container..."
docker pull browserless/chrome

echo "Running Browserless..."
docker run -d \
  --name browserless \
  -p $BROWSERLESS_PORT:3000 \
  -e "TOKEN=$BROWSERLESS_TOKEN" \
  browserless/chrome

# === STEP 3: Create .env File ===
echo "Creating .env file..."
cat > .env <<EOF
BROWSERLESS_URL=ws://localhost:$BROWSERLESS_PORT?token=$BROWSERLESS_TOKEN
PORT=$NODE_PORT
EOF

# === STEP 4: Install Dependencies ===
echo "Installing dependencies..."
npm install

# === STEP 4b: Build ===
echo "Building..."
npm run build

# === STEP 5: Start the App ===
echo "Starting the Node app..."
PORT=$NODE_PORT nohup node dist/server.js > server.log 2>&1 &

APP_PID=$!
sleep 10

# === STEP 6: Trigger Archive with Retry ===
echo "Making GET request to /archive-all with retry..."

MAX_RETRIES=5
RETRY_DELAY=3
SUCCESS=0

for ((i=1; i<=MAX_RETRIES; i++)); do
  echo "Attempt $i..."
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$NODE_PORT/archive-all")
  
  if [ "$RESPONSE" -eq 200 ]; then
    echo "Request succeeded."
    SUCCESS=1
    break
  else
    echo "Request failed with status $RESPONSE. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
  fi
done

if [ "$SUCCESS" -ne 1 ]; then
  echo "Request to /archive-all failed after $MAX_RETRIES attempts."
fi

# === CLEANUP AFTER RUN ===
echo "Cleaning up..."

# Kill the Node app
kill $APP_PID 2>/dev/null || true

# Stop and remove Browserless container
docker rm -f browserless 2>/dev/null || true

echo "Done."
