# Anycubic Slicer Next – Linux installers

Anycubic only ships an official `.deb` built for Ubuntu 24.04.

- On **Debian/Ubuntu/Mint** it just works — this repo simply automates
  fetching and installing the current official `.deb`.
- On **Arch/CachyOS/Manjaro** login and the printer camera feed are broken,
  most likely because those distros ship newer, incompatible
  `libicu`/`libselinux` than the app expects. This repo repackages the
  official `.deb` with the matching older Ubuntu libraries bundled
  alongside it — same fix the
  [`anycubicslicernext-bin`](https://aur.archlinux.org/packages/anycubicslicernext-bin)
  AUR package uses, just distributed as a plain tarball.

A GitHub Actions workflow checks Anycubic's package feed daily
(`.github/workflows/build-release.yml`) and publishes a new
[Release](../../releases) automatically whenever they ship a new build —
both installers below always pull whatever is current.

## Install

Download the installer for your distro and double-click it (right-click →
allow launching the first time if your file manager asks). Both are
self-contained: they install system dependencies, download the current
Anycubic build, and install it — no manual terminal steps needed beyond
confirming the sudo password prompt.

| Distro | Download |
|---|---|
| Debian / Ubuntu / Mint | [`AnycubicSlicerNext-deb-installer.desktop`](../../releases/latest/download/AnycubicSlicerNext-deb-installer.desktop) |
| Arch / CachyOS / Manjaro | [`AnycubicSlicerNext-arch-installer.desktop`](../../releases/latest/download/AnycubicSlicerNext-arch-installer.desktop) |

The Debian/Ubuntu installer installs Anycubic's official `.deb` via `apt`,
no repack involved. The Arch installer installs this repo's repack (bundled
compat libs) to `/opt/AnycubicSlicerNext`.

Or run the matching script directly instead of double-clicking:
```bash
# Arch/CachyOS/Manjaro
curl -fsSL https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main/install-arch.sh | bash

# Debian/Ubuntu/Mint
curl -fsSL https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main/install-deb.sh | bash
```

## Updating

Re-run the same installer/double-click — it always pulls the latest
release/upstream build.

## How the Arch repack works

See `scripts/build-package.sh`. In short: extract the official `.deb` +
`libicu74`/`libselinux1` from Ubuntu's archive, copy the app's libs plus
those two into one directory, patch the one hardcoded resource path in the
binary, and wrap it in a launcher script that sets `LD_LIBRARY_PATH`.
