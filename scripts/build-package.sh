#!/bin/bash
# Repackages Anycubic's official .deb (built for Ubuntu 24.04) into a
# relocatable tarball for non-Ubuntu distros (Arch/CachyOS etc.), bundling
# the older libicu74 and libselinux1 the binary was linked against instead
# of relying on the system's (newer, incompatible) versions.
#
# Same process as the anycubicslicernext-bin AUR package's PKGBUILD, just
# producing a tarball + installer instead of a pacman package, so it also
# works on non-Arch distros.
set -euo pipefail

PACKAGES_URL="https://cdn-universe-slicer.anycubic.com/prod/dists/noble/main/binary-amd64/Packages"
BASE_URL="https://cdn-universe-slicer.anycubic.com/prod"
ICU_URL="https://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu74_74.2-1ubuntu3.1_amd64.deb"
SELINUX_URL="https://archive.ubuntu.com/ubuntu/pool/main/libs/libselinux/libselinux1_3.5-2ubuntu2.1_amd64.deb"

WORK="$(pwd)/work"
DIST="$(pwd)/dist"
rm -rf "$WORK" "$DIST"
mkdir -p "$WORK" "$DIST"
cd "$WORK"

PACKAGES="$(curl -fsSL "$PACKAGES_URL")"
DEB_FILENAME="$(echo "$PACKAGES" | awk '/^Package: anycubicslicernext$/{f=1} f && /^Filename:/{print $2; exit}')"
DEB_URL="${BASE_URL}/${DEB_FILENAME}"

echo "Downloading: $DEB_URL"
curl -fLO "$DEB_URL"
DEB_FILE="$(basename "$DEB_FILENAME")"

curl -fLO "$ICU_URL"
curl -fLO "$SELINUX_URL"

mkdir -p extracted/app extracted/icu extracted/selinux

(cd extracted/app && ar x "../../$DEB_FILE" && tar -xf data.tar.gz)

extract_zst() {
  local dir="$1" deb="$2"
  (cd "$dir" && ar x "../../$deb")
  if command -v zstd >/dev/null 2>&1; then
    (cd "$dir" && zstd -d -c data.tar.zst | tar -xf -)
  else
    (cd "$dir" && tar --zstd -xf data.tar.zst)
  fi
}

extract_zst extracted/icu "$(basename "$ICU_URL")"
extract_zst extracted/selinux "$(basename "$SELINUX_URL")"

PKG="$WORK/AnycubicSlicerNext"
# Overridable so build-flatpak.sh can produce an /app-rooted layout instead
# of the /opt one install-arch.sh/install-deb.sh use.
INSTALL_PATH="${INSTALL_PATH:-/opt/AnycubicSlicerNext}"
mkdir -p "$PKG"/bin "$PKG"/lib "$PKG"/share/resources "$PKG"/share/applications

cp extracted/app/usr/bin/AnycubicSlicerNext "$PKG"/bin/
cp -r extracted/app/usr/share/AnycubicSlicerNext/resources/. "$PKG"/share/resources/
rm -rf "$PKG"/share/resources/fonts

find extracted/app/usr/lib -type f -exec cp -t "$PKG"/lib {} +
cp extracted/icu/usr/lib/x86_64-linux-gnu/libicui18n.so.74 "$PKG"/lib/
cp extracted/icu/usr/lib/x86_64-linux-gnu/libicuuc.so.74 "$PKG"/lib/
cp extracted/selinux/usr/lib/x86_64-linux-gnu/libselinux.so.1 "$PKG"/lib/

# The binary has this path baked in as a plain string; patch it to where
# install.sh actually puts the app (/opt, matching the AUR package so this
# is a proven-working substitution).
sed -i "s@/usr/share/AnycubicSlicerNext/resources@${INSTALL_PATH}/share/resources@" "$PKG"/bin/AnycubicSlicerNext

cp extracted/app/usr/share/applications/AnycubicSlicer.desktop "$PKG"/share/applications/
sed -i "s@/usr/share/AnycubicSlicerNext/resources@${INSTALL_PATH}/share/resources@" "$PKG"/share/applications/AnycubicSlicer.desktop
sed -i "s@Exec=.*@Exec=${INSTALL_PATH}/AnycubicSlicerNext.sh@" "$PKG"/share/applications/AnycubicSlicer.desktop

cat > "$PKG"/AnycubicSlicerNext.sh << WRAPPER
#!/bin/bash
export LD_LIBRARY_PATH=${INSTALL_PATH}/lib:\$LD_LIBRARY_PATH
exec ${INSTALL_PATH}/bin/AnycubicSlicerNext "\$@"
WRAPPER
chmod +x "$PKG"/AnycubicSlicerNext.sh

cd "$WORK"
tar -czf "$DIST/AnycubicSlicerNext-linux-x86_64.tar.gz" AnycubicSlicerNext

echo "Built: $DIST/AnycubicSlicerNext-linux-x86_64.tar.gz"
