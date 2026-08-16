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
# real 'zlib' package. zlib-ng-compat (a common performance swap-in) is not
# accepted as a substitute by pacman's dependency resolver and conflicts
# with it, so if it's installed it has to be swapped back to plain zlib
# first, or the whole transaction aborts.
if pacman -Qi zlib-ng-compat &>/dev/null; then
  echo "    Found zlib-ng-compat, which conflicts with zlib (required by webkit2gtk-4.1/libxml2-legacy/gst-plugins-good) — swapping it back to zlib"
  sudo pacman -Rdd --noconfirm zlib-ng-compat
fi
sudo pacman -S --needed --noconfirm webkit2gtk-4.1 libxml2-legacy libbsd gtk3 zlib wayland \
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
