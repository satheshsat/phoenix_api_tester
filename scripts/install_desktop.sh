#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
USER_HOME="${HOME:-/home/sathesh}"

ICON_SRC="$ROOT_DIR/linux/runner/resources/icons"
APP_ICON="$ROOT_DIR/linux/runner/resources/app_icon.png"
DESKTOP_SRC="$ROOT_DIR/linux/phoenix.api.tester.desktop"

# 1. Install hicolor icons
for size in 16x16 24x24 32x32 48x48 64x64 128x128 256x256 512x512; do
  DEST_DIR="$USER_HOME/.local/share/icons/hicolor/$size/apps"
  mkdir -p "$DEST_DIR"
  if [ -f "$ICON_SRC/$size/apps/phoenix.api.tester.png" ]; then
    cp -f "$ICON_SRC/$size/apps/phoenix.api.tester.png" "$DEST_DIR/phoenix.api.tester.png"
  fi
done

# 2. Install pixmaps fallback
mkdir -p "$USER_HOME/.local/share/pixmaps"
if [ -f "$APP_ICON" ]; then
  cp -f "$APP_ICON" "$USER_HOME/.local/share/pixmaps/phoenix.api.tester.png"
fi

# 3. Install desktop launcher
mkdir -p "$USER_HOME/.local/share/applications"
if [ -f "$DESKTOP_SRC" ]; then
  # Determine executable path: release bundle > debug bundle > command
  EXEC_PATH="$ROOT_DIR/build/linux/x64/release/bundle/phoenix_api_tester"
  if [ ! -f "$EXEC_PATH" ]; then
    EXEC_PATH="$ROOT_DIR/build/linux/x64/debug/bundle/phoenix_api_tester"
  fi
  if [ ! -f "$EXEC_PATH" ]; then
    EXEC_PATH="phoenix_api_tester"
  fi

  sed "s|^Exec=.*|Exec=$EXEC_PATH|g" "$DESKTOP_SRC" > "$USER_HOME/.local/share/applications/phoenix.api.tester.desktop"
  chmod +x "$USER_HOME/.local/share/applications/phoenix.api.tester.desktop"
fi

# 4. Update desktop and icon databases
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$USER_HOME/.local/share/applications" || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "$USER_HOME/.local/share/icons/hicolor" || true

echo "Linux desktop icon and launcher installed successfully!"

