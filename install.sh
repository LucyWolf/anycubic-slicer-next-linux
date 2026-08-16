#!/bin/bash
# Installs the latest repackaged AnycubicSlicerNext build to /opt.
# Self-sufficient: safe to run from anywhere, always fetches the current release.
set -euo pipefail

REPO="lucy-wolf/anycubic-slicer-next-linux" # TODO: adjust if you rename/fork
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/AnycubicSlicerNext-linux-x86_64.tar.gz"
INSTALL_PATH="/opt/AnycubicSlicerNext"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Downloading latest build"
curl -fL "$RELEASE_URL" -o "$TMP/AnycubicSlicerNext.tar.gz"

echo "==> Extracting"
tar -xzf "$TMP/AnycubicSlicerNext.tar.gz" -C "$TMP"

echo "==> Installing to $INSTALL_PATH (sudo required)"
sudo rm -rf "$INSTALL_PATH"
sudo mkdir -p "$(dirname "$INSTALL_PATH")"
sudo cp -r "$TMP/AnycubicSlicerNext" "$INSTALL_PATH"

echo "==> Registering launcher"
sudo ln -sf "$INSTALL_PATH/AnycubicSlicerNext.sh" /usr/local/bin/AnycubicSlicerNext
mkdir -p "$HOME/.local/share/applications"
cp "$INSTALL_PATH/share/applications/AnycubicSlicer.desktop" "$HOME/.local/share/applications/"

cat <<'EOF'

Done. Start it via:
  AnycubicSlicerNext
or from your application menu.

Note: this only bundles the app + the libicu74/libselinux1 compat libs it
needs. System libraries (webkit2gtk, gtk3, etc.) are still required — see
README.md for the pacman/apt/dnf install line for your distro.
EOF
