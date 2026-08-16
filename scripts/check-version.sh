#!/bin/bash
# Prints a stable release tag for the current upstream AnycubicSlicerNext build.
#
# Anycubic sometimes ships a new build without bumping the "Version" field
# (see comment in the AUR PKGBUILD this was derived from), so the version
# alone is not a reliable uniqueness key. The .deb Filename embeds a build
# timestamp (e.g. develop_AnycubicSlicerNext-1.3.96_20260319_224609-...),
# so the tag is derived from that instead.
set -euo pipefail

PACKAGES_URL="https://cdn-universe-slicer.anycubic.com/prod/dists/noble/main/binary-amd64/Packages"
PACKAGES="$(curl -fsSL "$PACKAGES_URL")"

FILENAME="$(echo "$PACKAGES" | awk '/^Package: anycubicslicernext$/{f=1} f && /^Filename:/{print $2; exit}')"

# Filename looks like: dists/noble/main/binary-amd64/develop_AnycubicSlicerNext-1.3.96_20260319_224609-Ubuntu_24_04_3_LTS.deb
BASENAME="$(basename "$FILENAME")"
BUILD_ID="$(echo "$BASENAME" | grep -oE '[0-9]+_[0-9]+' | head -1)"

if [ -z "$BUILD_ID" ]; then
  echo "Could not extract build id from filename: $BASENAME" >&2
  exit 1
fi

echo "v${BUILD_ID}"
