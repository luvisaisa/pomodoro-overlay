#!/bin/bash
# build-app.sh
# Build standalone macOS app bundle from Swift Package Manager project

set -e

echo "🔨 Building Pomodoro Overlay..."

# Clean previous builds
rm -rf .build/release
rm -rf PomodoroOverlay.app

# Build release binary
swift build -c release

# Create app bundle structure
mkdir -p PomodoroOverlay.app/Contents/MacOS
mkdir -p PomodoroOverlay.app/Contents/Resources

# Copy binary
cp .build/release/PomodoroOverlay PomodoroOverlay.app/Contents/MacOS/

# Copy Info.plist
cp Resources/Info.plist PomodoroOverlay.app/Contents/

echo "✅ App bundle created: PomodoroOverlay.app"
echo ""
echo "To run:"
echo "  open PomodoroOverlay.app"
echo ""
echo "To install:"
echo "  cp -r PomodoroOverlay.app /Applications/"
