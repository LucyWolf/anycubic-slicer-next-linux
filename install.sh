#!/bin/bash
# Installs the latest AnycubicSlicerNext AppImage for the current user.
# No sudo, no system packages touched — everything the app needs is bundled
# inside the AppImage itself. Self-sufficient: safe to run from anywhere,
# always fetches the current release.
set -euo pipefail

REPO="LucyWolf/anycubic-slicer-next-linux" # TODO: adjust if you rename/fork
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/AnycubicSlicerNext-x86_64.AppImage"
INSTALL_DIR="$HOME/.local/bin"
APPIMAGE_PATH="$INSTALL_DIR/AnycubicSlicerNext.AppImage"

echo "==> Downloading latest AnycubicSlicerNext AppImage"
mkdir -p "$INSTALL_DIR"
curl -fL "$RELEASE_URL" -o "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

echo "==> Adding application menu entry"
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/AnycubicSlicerNext.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Anycubic Slicer Next
Comment=3D-Druck-Slicer fuer Anycubic-Drucker
Exec=$APPIMAGE_PATH %U
Icon=applications-graphics
Terminal=false
Categories=Graphics;Engineering;
EOF

cat <<EOF

Fertig. Start ueber das Anwendungsmenue ("Anycubic Slicer Next") oder direkt:
  $APPIMAGE_PATH
EOF
