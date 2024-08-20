#!/bin/bash

# Set up environment variables
export DISPLAY=:99.0
export XAUTHORITY=~/.Xauthority
export TERM=xterm

sudo apt-get install -y --no-install-recommends \
    curl lib32gcc-s1 ca-certificates wget unzip x11vnc i3 xvfb

# Remove any existing Xvfb lock file
LOCK_FILE="/tmp/.X10-lock"
if [ -f "$LOCK_FILE" ]; then
  echo "Removing existing Xvfb lock file: $LOCK_FILE"
  rm -f "$LOCK_FILE"
fi

# Start Xvfb on display :99
echo "Starting Xvfb on display :99"
/usr/bin/Xvfb :99 -screen 0 1024x768x24 -ac &

# Wait for Xvfb to be ready
echo "Waiting for Xvfb to initialize..."
until xdpyinfo -display :99 &> /dev/null; do
  echo "Waiting for display to be ready..."
  sleep 1
done

# Start x11vnc
echo "Starting x11vnc on display :99"
/usr/bin/x11vnc -display :99 -rfbport 5900 -forever -ncache 10 -desktop StardewValley -cursor arrow -passwd "$VNC_PASS" -shared &

# Wait a moment for x11vnc to initialize
sleep 5

# Start i3 window manager
echo "Starting i3 window manager"
/usr/bin/i3 &

# Start the Stardew Valley application
echo "Starting Stardew Valley"
exec ./StardewValley
