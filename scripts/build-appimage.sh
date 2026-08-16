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

# The .deb only bundles the app's own private libs — webkit2gtk-4.1 and the
# rest of its dependency tree are declared as system Depends, not shipped.
# Install them on this disposable CI runner (never touches an end user's
# system) and use ldd's fully resolved list to copy every shared library
# the binary actually needs into the AppImage, so it's truly self-contained.
echo "==> Installing webkit2gtk-4.1 + deps on the CI runner to bundle them"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends libwebkit2gtk-4.1-0 libxml2 >/dev/null

echo "==> Resolving full shared library dependency tree via ldd"
# Core glibc libraries must NEVER be bundled — they have to match the host's
# dynamic linker (ld.so) exactly, or symbol lookups fail at runtime
# (e.g. "undefined symbol: __nptl_change_stack_perm, version GLIBC_PRIVATE"
# when a bundled Ubuntu libc.so.6 gets loaded by a different distro's ld.so).
# These always come from the target system instead.
GLIBC_EXCLUDE_REGEX='^(ld-linux|ld-linux-x86-64|libc|libm|libpthread|libdl|librt|libresolv|libnsl|libutil|libnss_)\.so'
LDD_OUTPUT="$(LD_LIBRARY_PATH="$APPDIR/lib" ldd "$APPDIR/bin/AnycubicSlicerNext" 2>&1)" || true
echo "$LDD_OUTPUT"
echo "$LDD_OUTPUT" | awk '{print $3}' | grep '^/' | sort -u | while read -r lib; do
    if basename "$lib" | grep -qE "$GLIBC_EXCLUDE_REGEX"; then
      continue
    fi
    cp -Ln "$lib" "$APPDIR/lib/" 2>/dev/null || true
  done
true

# Also strip any glibc libs the .deb itself may have shipped in its own
# usr/lib (belt and braces — same reasoning as above).
find "$APPDIR/lib" -maxdepth 1 -type f | while read -r lib; do
  if basename "$lib" | grep -qE "$GLIBC_EXCLUDE_REGEX"; then
    rm -f "$lib"
  fi
done
true
echo "Bundled $(ls "$APPDIR/lib" | wc -l) shared libraries"

# WebKitGTK spawns separate helper process binaries (WebKitNetworkProcess,
# WebKitWebProcess, ...) at a hardcoded system path — ldd never sees these
# since they're fork+exec'd, not dynamically linked. Bundle that whole
# directory too; AppRun points WebKit at it via WEBKIT_EXEC_PATH.
WEBKIT_HELPERS_SRC="/usr/lib/x86_64-linux-gnu/webkit2gtk-4.1"
if [ -d "$WEBKIT_HELPERS_SRC" ]; then
  echo "==> Bundling WebKitGTK helper processes"
  cp -a "$WEBKIT_HELPERS_SRC" "$APPDIR/lib/webkit2gtk-4.1"
else
  echo "WARNING: $WEBKIT_HELPERS_SRC not found, WebKit will likely fail to spawn its helper processes" >&2
fi

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

# Tell WebKitGTK where to find its bundled helper process binaries
# (WebKitNetworkProcess etc.) instead of looking at the hardcoded system path.
export WEBKIT_EXEC_PATH="$DIR/lib/webkit2gtk-4.1"

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
