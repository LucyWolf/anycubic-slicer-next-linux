#!/bin/bash
# Prints upstream version info for the current AnycubicSlicerNext build, as
# GITHUB_OUTPUT-style key=value lines (one per line):
#   version=1.3.96
#   build_id=20260319_224609
#   tag=v1.3.96-20260319_224609
#
# Anycubic sometimes ships a new build without bumping the "Version" field
# (see comment in the AUR PKGBUILD this was derived from), so build_id (from
# the .deb Filename's embedded timestamp) is what guarantees the tag is
# unique per build, while version keeps it human-readable / traceable to
# the upstream release it came from.
set -euo pipefail

PACKAGES_URL="https://cdn-universe-slicer.anycubic.com/prod/dists/noble/main/binary-amd64/Packages"
PACKAGES="$(curl -fsSL "$PACKAGES_URL")"

VERSION="$(echo "$PACKAGES" | awk '/^Package: anycubicslicernext$/{f=1} f && /^Version:/{print $2; exit}')"
FILENAME="$(echo "$PACKAGES" | awk '/^Package: anycubicslicernext$/{f=1} f && /^Filename:/{print $2; exit}')"

# Filename looks like: dists/noble/main/binary-amd64/develop_AnycubicSlicerNext-1.3.96_20260319_224609-Ubuntu_24_04_3_LTS.deb
BASENAME="$(basename "$FILENAME")"
BUILD_ID="$(echo "$BASENAME" | grep -oE '[0-9]+_[0-9]+' | head -1)"

if [ -z "$VERSION" ] || [ -z "$BUILD_ID" ]; then
  echo "Could not parse version/build id from upstream Packages file (version='$VERSION' filename='$BASENAME')" >&2
  exit 1
fi

echo "version=${VERSION}"
echo "build_id=${BUILD_ID}"
echo "tag=v${VERSION}-${BUILD_ID}"
