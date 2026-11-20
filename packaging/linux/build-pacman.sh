#!/usr/bin/env bash
# Build an Arch/CachyOS pacman package (.pkg.tar.zst) from a PyInstaller bundle.
# Requirements: bsdtar (libarchive-tools), zstd.
# Usage: build-pacman.sh [--skip-build]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

VERSION="1.0.0"
ARCH="${ARCH:-x86_64}"
BUNDLE="dist/CachyCleaner"
PKGNAME="cachycleaner"
PKGVER="${VERSION}-1"
OUT="${PKGNAME}-${PKGVER}-${ARCH}.pkg.tar.zst"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [[ "${1:-}" != "--skip-build" ]]; then
  echo "==> Building with PyInstaller..."
  python3 -m PyInstaller CachyCleaner.spec --noconfirm --distpath dist
fi

if [[ ! -d "$BUNDLE" ]]; then
  echo "error: bundle not found at $BUNDLE" >&2
  exit 1
fi

echo "==> Staging package tree..."
mkdir -p "$STAGE/usr/lib/CachyCleaner" \
         "$STAGE/usr/bin" \
         "$STAGE/usr/share/applications" \
         "$STAGE/usr/share/icons/hicolor/256x256/apps"

cp -a "$BUNDLE/." "$STAGE/usr/lib/CachyCleaner/"
ln -s /usr/lib/CachyCleaner/CachyCleaner "$STAGE/usr/bin/cachycleaner"
cp packaging/linux/CachyCleaner.desktop "$STAGE/usr/share/applications/"
cp app/assets/icon.png "$STAGE/usr/share/icons/hicolor/256x256/apps/CachyCleaner.png"

INSTALLED_SIZE="$(du -sb "$STAGE" | cut -f1)"
BUILDDATE="$(date +%s)"

cat > "$STAGE/.PKGINFO" <<EOF
pkgname = ${PKGNAME}
pkgbase = ${PKGNAME}
pkgver = ${PKGVER}
pkgdesc = Modern, safe system cleaner for caches, temporary files and junk
url = https://github.com/FernandoGabrielSilva/CachyCleaner
builddate = ${BUILDDATE}
packager = Fernando Gabriel Silva
size = ${INSTALLED_SIZE}
arch = ${ARCH}
license = MIT
depend = glibc
depend = gcc-libs
depend = libglvnd
depend = libxkbcommon
depend = xcb-util-cursor
EOF

echo "==> Generating .MTREE..."
( cd "$STAGE" && bsdtar -czf .MTREE --format=mtree \
    --options='!all,use-set,type,uid,gid,mode,time,size,md5,sha256,link' \
    .PKGINFO usr )

echo "==> Packing ${OUT}..."
( cd "$STAGE" && bsdtar --zstd -cf "$ROOT/${OUT}" .PKGINFO .MTREE usr )

echo "==> Done: ${OUT}"
