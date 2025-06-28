#!/bin/bash

# === CONFIG ===
REPO_URL="https://github.com/itscharukadeshan/sl_news_archive.git"
CLONE_DIR="sl_news_archive"
BROWSERLESS_PORT=3000
BROWSERLESS_API_KEY="your-api-key"
FLARESOLVERR_URL="http://localhost:8191/v1"
NODE_PORT=5000

# === STEP 1: Clone the Repo ===
echo "Cloning repository..."
git clone "$REPO_URL" "$CLONE_DIR" || {
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
  -e "TOKEN=$BROWSERLESS_API_KEY" \
  browserless/chrome

# === STEP 3: Create .env File ===
echo "Creating .env file..."
cat > .env <<EOF
BROWSERLESS_URL=http://localhost:$BROWSERLESS_PORT?token=$BROWSERLESS_API_KEY
BROWSERLESS_API_KEY=$BROWSERLESS_API_KEY
PORT=$NODE_PORT
FLARESOLVERR_URL=$FLARESOLVERR_URL
EOF

# === STEP 4: Install Dependencies ===
echo "Installing dependencies..."
npm install

# === STEP 5: Start the App ===
echo "Starting the Node app..."
npx ts-node src/server.ts &

# Wait for server to start
sleep 10

# === STEP 6: GET Request to /archive-all ===
echo "Making GET request to /archive-all"
curl "http://localhost:$NODE_PORT/archive-all"

