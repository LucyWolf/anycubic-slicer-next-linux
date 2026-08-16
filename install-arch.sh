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

# webkit2gtk-4.1, libxml2-legacy and gst-plugins-good need a newer 'zlib'
# than zlib-ng-compat (CachyOS's default zlib provider) declares itself
# providing. Swapping it is done as its OWN isolated pacman transaction
# first — bundling it together with installing 3 new packages at once
# made pacman's solver give up with "unresolvable conflicts" on a system
# where 100+ packages depend on zlib-ng-compat (sudo, gcc, plasma-workspace,
# ...), since that combined transaction is too complex for it to reason
# about safely. A plain, isolated 'zlib' swap is a well-supported pacman
# operation on its own.
if pacman -Qi zlib-ng-compat &>/dev/null; then
  echo "    Swapping zlib-ng-compat -> zlib (isolated step)"
  yes | sudo pacman -S --needed zlib

  # Hard safety check: if sudo/pacman broke, STOP here immediately rather
  # than continuing into more steps that would also fail confusingly.
  if ! sudo -n true 2>/dev/null && ! sudo -v; then
    echo "ERROR: sudo is not working after the zlib swap. Stopping here —" >&2
    echo "do not close this window, get help before doing anything else." >&2
    exit 1
  fi
  if ! pacman --version >/dev/null 2>&1; then
    echo "ERROR: pacman is not working after the zlib swap. Stopping here —" >&2
    echo "do not close this window, get help before doing anything else." >&2
    exit 1
  fi
  echo "    zlib swap OK, sudo/pacman still working"
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
