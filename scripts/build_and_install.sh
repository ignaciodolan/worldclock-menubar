#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="WorldClockMenuBar"
BUILD_CONFIG="release"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

echo "Building $APP_NAME ($BUILD_CONFIG)..."
swift build --package-path "$ROOT_DIR" -c "$BUILD_CONFIG"

BINARY_PATH="$ROOT_DIR/.build/$BUILD_CONFIG/$APP_NAME"
if [ ! -f "$BINARY_PATH" ]; then
    echo "Build failed: binary not found at $BINARY_PATH" >&2
    exit 1
fi

echo "Assembling app bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

echo "Code-signing (ad-hoc)..."
codesign --force --sign - "$APP_BUNDLE"

echo "Installing to $INSTALL_PATH..."
if [ -d "$INSTALL_PATH" ]; then
    rm -rf "$INSTALL_PATH"
fi
cp -R "$APP_BUNDLE" "$INSTALL_PATH"

echo "Done. Launch with: open \"$INSTALL_PATH\""
