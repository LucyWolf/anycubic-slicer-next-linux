#!/bin/bash
# Installs the latest repackaged AnycubicSlicerNext build to /opt on
# Arch/CachyOS/Manjaro. Self-sufficient: safe to run from anywhere, always
# fetches the current release.
set -euo pipefail

REPO="LucyWolf/anycubic-slicer-next-linux" # TODO: adjust if you rename/fork
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/AnycubicSlicerNext-linux-x86_64.tar.gz"
INSTALL_PATH="/opt/AnycubicSlicerNext"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Installing system dependencies (sudo required)"
# webkit2gtk-4.1, libxml2-legacy and gst-plugins-good hard-depend on the
# real 'zlib' package. If zlib-ng-compat (a common performance swap-in) is
# installed instead, pacman will ask to remove it as part of resolving
# this single transaction — answered via the 'yes' pipe so it happens
# atomically (remove-old + install-new in one pacman transaction), instead
# of ever running as two separate commands with a broken window in between
# where libz.so.1 would be missing and sudo/pacman themselves stop working.
yes | sudo pacman -S --needed webkit2gtk-4.1 libxml2-legacy libbsd gtk3 zlib wayland \
  libglvnd gst-plugins-base gst-plugins-good gst-libav dbus libsoup3 noto-fonts noto-fonts-cjk

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
