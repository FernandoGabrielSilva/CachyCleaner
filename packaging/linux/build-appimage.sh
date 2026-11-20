#!/usr/bin/env bash
# Build an AppImage from a PyInstaller one-folder bundle.
# Requirements: pyinstaller, appimagetool (in PATH or downloaded automatically).
# Usage: build-appimage.sh [--skip-build]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

SKIP_BUILD="${1:-}"
if [[ "${SKIP_BUILD}" != "--skip-build" ]]; then
  echo "==> Building with PyInstaller..."
  python3 -m PyInstaller CachyCleaner.spec --noconfirm --distpath dist
fi

ARCH="${ARCH:-$(uname -m)}"
APPDIR="dist/CachyCleaner.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -a dist/CachyCleaner/. "$APPDIR/usr/bin/"
cp packaging/linux/AppRun "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp packaging/linux/CachyCleaner.desktop "$APPDIR/CachyCleaner.desktop"
cp app/assets/icon.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/CachyCleaner.png"
cp app/assets/icon.png "$APPDIR/CachyCleaner.png"

APPIMAGETOOL="$(command -v appimagetool || true)"
if [[ -z "$APPIMAGETOOL" ]]; then
  echo "==> Downloading appimagetool for ${ARCH}..."
  APPIMAGETOOL="appimagetool-${ARCH}.AppImage"
  curl -fsSL -o "$APPIMAGETOOL" \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"
  chmod +x "$APPIMAGETOOL"
fi

echo "==> Generating AppImage for ${ARCH}..."
"$APPIMAGETOOL" "$APPDIR" "CachyCleaner-1.0.0-${ARCH}.AppImage"
echo "==> Done: CachyCleaner-1.0.0-${ARCH}.AppImage"
