# Anycubic Slicer Next – Linux repack

Anycubic only ships an official `.deb` built for Ubuntu 24.04. On other
distros (Arch, CachyOS, Manjaro, ...) it installs but login and the printer
camera feed are broken, most likely because those distros ship newer,
incompatible `libicu`/`libselinux` than the app expects.

This repo automatically repackages Anycubic's official `.deb` with the
matching older Ubuntu libraries bundled alongside it — same fix the
[`anycubicslicernext-bin`](https://aur.archlinux.org/packages/anycubicslicernext-bin)
AUR package uses, just distributed as a plain tarball so it also works on
non-Arch distros.

A GitHub Actions workflow checks Anycubic's package feed daily
(`.github/workflows/build-release.yml`) and publishes a new
[Release](../../releases) automatically whenever they ship a new build.

## Install

First install the system libraries the app needs (not bundled — only the
two libs Arch's newer versions break are bundled):

**Arch / CachyOS / Manjaro:**
```bash
sudo pacman -S webkit2gtk-4.1 libxml2-legacy libbsd gtk3 zlib wayland libglvnd \
  gst-plugins-base gst-plugins-good gst-libav dbus libsoup3 noto-fonts noto-fonts-cjk
```

**Debian / Ubuntu (if you still want the repack instead of the native .deb):**
```bash
sudo apt install libwebkit2gtk-4.1-0 libgtk-3-bin libglu1-mesa zlib1g \
  libwayland-bin libdbus-1-3 libsoup-2.4-1 gstreamer1.0-libav
```

Then either:

- **Double-click** `AnycubicSlicerNext-installer.desktop` (right-click →
  allow launching the first time if your file manager asks), or
- **Run manually:**
  ```bash
  curl -fsSL https://raw.githubusercontent.com/lucy-wolf/anycubic-slicer-next-linux/main/install.sh | bash
  ```

Installs to `/opt/AnycubicSlicerNext`, launcher symlinked to
`/usr/local/bin/AnycubicSlicerNext`, `.desktop` entry added to your
application menu.

## Updating

Re-run the same install command/double-click — it always pulls the latest
release. To automate that too, re-run it via cron/systemd timer if you want.

## How the repack works

See `scripts/build-package.sh`. In short: extract the official `.deb` +
`libicu74`/`libselinux1` from Ubuntu's archive, copy the app's libs plus
those two into one directory, patch the one hardcoded resource path in the
binary, and wrap it in a launcher script that sets `LD_LIBRARY_PATH`.
