# Anycubic Slicer Next – Linux AppImage

Anycubic only ships an official `.deb` built for Ubuntu 24.04, which causes
various problems on non-Ubuntu distros (Arch/CachyOS: broken login/camera
due to system library mismatches).

This repo builds a self-contained **AppImage** from Anycubic's official
`.deb` instead — everything the app needs is bundled inside, so it never
touches your system's package manager or libraries. No `sudo`, no `apt`,
no `pacman`.

A GitHub Actions workflow checks Anycubic's package feed daily
(`.github/workflows/build-release.yml`) and publishes a new
[Release](../../releases) automatically whenever they ship a new build.

Build approach adapted from
[thecalamityjoe87/anycubic-slicer-next-packages](https://github.com/thecalamityjoe87/anycubic-slicer-next-packages),
wired into this repo's own version-check/auto-release pipeline.

## Install

Download [`AnycubicSlicerNext-installer.desktop`](../../releases/latest/download/AnycubicSlicerNext-installer.desktop)
and double-click it (right-click → allow launching the first time if your
file manager asks). It downloads the current AppImage to `~/.local/bin/`
and adds an entry to your application menu — no system packages touched.

Or run it directly instead of double-clicking:
```bash
curl -fsSL https://raw.githubusercontent.com/LucyWolf/anycubic-slicer-next-linux/main/install.sh | bash
```

## Updating

Re-run the same installer/double-click — it always pulls the latest release.

## Known issue

As of writing, the community Flatpak build of this same app (same upstream
source) gets killed (`SIGKILL`, exit 137) a moment after launch on at least
one tested Wayland/Intel-iGPU system, for a reason not yet identified —
ruled out so far: OOM killer, `systemd-oomd`, GPU/software rendering,
X11 vs Wayland backend, portal issues, and no coredump is generated (so
it's a genuine external kill, not an app crash). If the AppImage build
here hits the same issue, that would point to something upstream in the
app itself rather than Flatpak's sandboxing.
