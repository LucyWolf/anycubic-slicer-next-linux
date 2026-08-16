#!/bin/bash
# Catch-all installer: detects the available package manager and delegates
# to the matching dedicated installer (install-deb.sh / install-arch.sh).
# For distros without a tested build (Fedora/openSUSE), says so honestly
# instead of pretending it's supported.
set -euo pipefail

RAW_BASE="https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main"

if command -v apt >/dev/null 2>&1; then
  echo "==> Detected apt (Debian/Ubuntu-based) — using the native .deb installer"
  curl -fsSL "$RAW_BASE/install-deb.sh" | bash
elif command -v pacman >/dev/null 2>&1; then
  echo "==> Detected pacman (Arch-based) — using the Arch repack installer"
  curl -fsSL "$RAW_BASE/install-arch.sh" | bash
else
  echo "No tested install path for this distro yet (only apt- and pacman-based"
  echo "systems are currently supported by this repo)."
  echo
  echo "The Arch repack bundles its own compat libs and may still work on"
  echo "Fedora/openSUSE, but this hasn't been verified and the system"
  echo "dependency list (webkit2gtk, gtk3, ...) is written for pacman, not"
  echo "dnf/zypper. Try at your own risk:"
  echo "  curl -fsSL $RAW_BASE/install-arch.sh | bash"
  exit 1
fi
