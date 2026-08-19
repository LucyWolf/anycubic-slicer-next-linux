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
all installers below always pull whatever is current.

## Install

Download the installer for your distro and double-click it (right-click →
allow launching the first time if your file manager asks). All are
self-contained: they install system dependencies, download the current
Anycubic build, and install it — no manual terminal steps needed beyond
confirming the sudo password prompt.

| Distro | Download |
|---|---|
| Debian / Ubuntu (and derivatives) | [`AnycubicSlicerNext-deb-installer.desktop`](../../releases/latest/download/AnycubicSlicerNext-deb-installer.desktop) |
| Arch / CachyOS / Manjaro | [`AnycubicSlicerNext-arch-installer.desktop`](../../releases/latest/download/AnycubicSlicerNext-arch-installer.desktop) |
| Anything else (Fedora, openSUSE, ...) | [`AnycubicSlicerNext-installer.desktop`](../../releases/latest/download/AnycubicSlicerNext-installer.desktop) |

The Debian/Ubuntu installer installs Anycubic's official `.deb` via `apt`,
no repack involved. The Arch installer installs this repo's repack (bundled
compat libs) to `/opt/AnycubicSlicerNext`. The third one auto-detects
`apt`/`pacman` and delegates to one of the above; on distros with neither
(Fedora/openSUSE) it says so honestly instead of pretending to be tested
there — see `install.sh`.

Or run the matching script directly instead of double-clicking:
```bash
# Debian/Ubuntu/Mint
curl -fsSL https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main/install-deb.sh | bash

# Arch/CachyOS/Manjaro
curl -fsSL https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main/install-arch.sh | bash

# Auto-detect
curl -fsSL https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main/install.sh | bash
```

## Updating

Re-run the same installer/double-click — it always pulls the latest
release/upstream build.

## How the Arch repack works

See `scripts/build-package.sh`. In short: extract the official `.deb` +
`libicu74`/`libselinux1` from Ubuntu's archive, copy the app's libs plus
those two into one directory, patch the one hardcoded resource path in the
binary, and wrap it in a launcher script that sets `LD_LIBRARY_PATH`.

## Flatpak (experimental, not working yet)

`flatpak/` and `scripts/build-flatpak.sh` are an in-progress test of
packaging this as a Flatpak instead of the pacman repack above — the
missing-library problem itself doesn't reproduce there (confirms the same
bundling approach carries over), but the app currently crashes (SIGSEGV,
no error output, not tied to Xvfb/no-GPU or to the runtime version — same
crash on real hardware and across `org.gnome.Platform//48` and `//50`)
shortly after startup for a reason not yet identified. Not usable, not
wired into the regular install/release flow — leave the pacman repack
above as the supported Arch/CachyOS path until this is sorted out.
