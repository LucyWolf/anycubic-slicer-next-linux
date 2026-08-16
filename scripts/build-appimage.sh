#!/usr/bin/env bash
# Builds a self-contained AppImage from Anycubic's official .deb.
# No system packages, no sudo, no pacman/apt conflicts — everything the app
# needs ships inside the AppImage itself.
#
# Adapted from thecalamityjoe87/anycubic-slicer-next-packages
# (https://github.com/thecalamityjoe87/anycubic-slicer-next-packages),
# wired into this repo's own version-check/CI pipeline.
set -euo pipefail

PACKAGES_URL="https://cdn-universe-slicer.anycubic.com/prod/dists/noble/main/binary-amd64/Packages"
BASE_URL="https://cdn-universe-slicer.anycubic.com/prod"

WORKDIR="$(pwd)/work"
DIST="$(pwd)/dist"
EXTRACT_DIR="$WORKDIR/extracted"
APPDIR="$WORKDIR/AnycubicSlicer.AppDir"
rm -rf "$WORKDIR" "$DIST"
mkdir -p "$WORKDIR" "$DIST"
cd "$WORKDIR"

echo "==> Downloading official .deb"
PACKAGES="$(curl -fsSL "$PACKAGES_URL")"
DEB_FILENAME="$(echo "$PACKAGES" | awk '/^Package: anycubicslicernext$/{f=1} f && /^Filename:/{print $2; exit}')"
DEB_URL="${BASE_URL}/${DEB_FILENAME}"
DEB_FILE="$WORKDIR/$(basename "$DEB_FILENAME")"
curl -fL "$DEB_URL" -o "$DEB_FILE"

echo "==> Extracting DEB package"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
dpkg-deb -x "$DEB_FILE" "$EXTRACT_DIR"

VERSION_FILE="$EXTRACT_DIR/usr/share/AnycubicSlicerNext/resources/build-version.txt"
if [ -f "$VERSION_FILE" ]; then
  VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
else
  VERSION="unknown"
fi
echo "Detected app version: $VERSION"

echo "==> Building AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR"
cp -a "$EXTRACT_DIR/usr/bin" "$APPDIR/"
cp -a "$EXTRACT_DIR/usr/lib" "$APPDIR/"
cp -a "$EXTRACT_DIR/usr/share/AnycubicSlicerNext/resources" "$APPDIR/"

mkdir -p "$APPDIR/share/applications" "$APPDIR/share/icons/hicolor/256x256/apps"
chmod +x "$APPDIR/bin/AnycubicSlicerNext" || true

ICON_SRC="$APPDIR/resources/images/AnycubicSlicer.png"
ICON_DST="$APPDIR/share/icons/hicolor/256x256/apps/AnycubicSlicer.png"
if [ -f "$ICON_SRC" ]; then
  cp -a "$ICON_SRC" "$ICON_DST"
  cp -a "$ICON_DST" "$APPDIR/AnycubicSlicer.png"
fi

DESKTOP_SRC="$EXTRACT_DIR/usr/share/applications/AnycubicSlicer.desktop"
DESKTOP="$APPDIR/share/applications/AnycubicSlicer.desktop"
if [ -f "$DESKTOP_SRC" ]; then
  cp -a "$DESKTOP_SRC" "$DESKTOP"
  sed -i 's|Icon=.*|Icon=AnycubicSlicer|' "$DESKTOP"
  sed -i 's|Exec=.*|Exec=AnycubicSlicerNext %U|' "$DESKTOP"
  cp -a "$DESKTOP" "$APPDIR/AnycubicSlicer.desktop"
fi

echo "==> Creating AppRun launcher"
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/bash
DIR=$(readlink -f "$0" | xargs dirname)
export LD_LIBRARY_PATH="$DIR/lib:$DIR/bin:$LD_LIBRARY_PATH"

# Segfault workaround for systems with unexpected locale info (from OrcaSlicer)
export LC_ALL=C

export ANYCUBIC_RESOURCES_PATH="$DIR/resources"

# WebKit rendering fixes
export WEBKIT_DISABLE_DMABUF_RENDERER=1
export WEBKIT_FORCE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_COMPOSITING_MODE=1

exec "$DIR/bin/AnycubicSlicerNext" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "==> Downloading appimagetool"
APPIMAGETOOL="$WORKDIR/appimagetool-x86_64.AppImage"
curl -fL -o "$APPIMAGETOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x "$APPIMAGETOOL"

echo "==> Building AppImage"
export VERSION="$VERSION"
export ARCH=x86_64
# CI runners have no FUSE, and appimagetool is itself an AppImage —
# --appimage-extract-and-run avoids needing to mount it.
"$APPIMAGETOOL" --appimage-extract-and-run --no-appstream "$APPDIR" "$DIST/AnycubicSlicerNext-x86_64.AppImage"

echo "Built: $DIST/AnycubicSlicerNext-x86_64.AppImage"
