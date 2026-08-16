#!/bin/bash
# Installs the current official AnycubicSlicerNext .deb directly from
# Anycubic on Debian/Ubuntu/Mint. No repack needed here — the libicu/
# libselinux mismatch that breaks login/camera on Arch doesn't apply on
# Ubuntu-based distros, so this just fetches and installs the real package.
# Self-sufficient: safe to run from anywhere, always fetches the current build.
set -euo pipefail

PACKAGES_URL="https://cdn-universe-slicer.anycubic.com/prod/dists/noble/main/binary-amd64/Packages"
BASE_URL="https://cdn-universe-slicer.anycubic.com/prod"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Checking current upstream version"
PACKAGES="$(curl -fsSL "$PACKAGES_URL")"
FILENAME="$(echo "$PACKAGES" | awk '/^Package: anycubicslicernext$/{f=1} f && /^Filename:/{print $2; exit}')"

if [ -z "$FILENAME" ]; then
  echo "Could not find the anycubicslicernext package in Anycubic's repo index." >&2
  exit 1
fi

DEB_URL="${BASE_URL}/${FILENAME}"
DEB_FILE="$TMP/$(basename "$FILENAME")"

echo "==> Downloading $DEB_URL"
curl -fL "$DEB_URL" -o "$DEB_FILE"

echo "==> Installing (sudo required, apt resolves dependencies automatically)"
sudo apt install -y "$DEB_FILE"

cat <<'EOF'

Done. Start "Anycubic Slicer Next" from your application menu, or run:
  AnycubicSlicerNext
EOF
