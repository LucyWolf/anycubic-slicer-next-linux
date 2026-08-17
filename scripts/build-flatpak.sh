#!/bin/bash
# Builds the Flatpak bundle. Assumes flatpak + flatpak-builder are installed
# and the flathub remote is already added (the CI workflow does this before
# calling this script; see .github/workflows/build-flatpak.yml).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Building /app-rooted package layout (reusing build-package.sh)"
INSTALL_PATH=/app ./scripts/build-package.sh

# Pinned rather than auto-picking the newest branch on Flathub: the first
# real-hardware test crashed (SIGSEGV, zero output) against auto-picked //50,
# which turned out to be a very fresh runtime the test machine didn't even
# have yet. //48 is a version already installed and in daily use there
# (other Flatpak apps depend on it), so it's a much better first thing to
# rule in/out before chasing anything more exotic.
GNOME_RUNTIME_VERSION="${GNOME_RUNTIME_VERSION:-48}"
echo "    Using org.gnome.Platform//${GNOME_RUNTIME_VERSION}"

echo "==> Installing runtime + SDK (large download, first run only)"
flatpak install -y --user --noninteractive flathub \
  "org.gnome.Platform//${GNOME_RUNTIME_VERSION}" "org.gnome.Sdk//${GNOME_RUNTIME_VERSION}"

echo "==> Generating manifest with resolved runtime version"
GNOME_RUNTIME_VERSION="$GNOME_RUNTIME_VERSION" envsubst '${GNOME_RUNTIME_VERSION}' \
  < flatpak/io.github.lucywolf.AnycubicSlicerNext.yml \
  > flatpak/io.github.lucywolf.AnycubicSlicerNext.generated.yml

echo "==> Running flatpak-builder"
rm -rf flatpak-builddir flatpak-repo
flatpak-builder --force-clean --user --repo=flatpak-repo flatpak-builddir \
  flatpak/io.github.lucywolf.AnycubicSlicerNext.generated.yml

echo "==> Bundling into a single .flatpak file"
mkdir -p dist
flatpak build-bundle flatpak-repo \
  dist/AnycubicSlicerNext.flatpak io.github.lucywolf.AnycubicSlicerNext

echo "Built: dist/AnycubicSlicerNext.flatpak"
