# OpenXTalk Lite 1.15: Tom Perry's source, built and tested

This repository is OpenXTalk Lite 1.15 exactly as Tom Perry left it, with
continuous integration around it: builds for Windows, macOS and Linux, the
engine and IDE test suites, packaging, and releases. Nothing in Tom Perry's
code is fixed or improved here. Bugs are recorded, not fixed.

It exists so that the original can be built, run and measured on today's
systems: as a reference for what OpenXTalk Lite 1.15 does, and as the
baseline that [OXT-Beyond](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond),
which continues the work, can be compared against.

## What is in it

```
LiveCode Community history, up to develop 4606a10ea (2021-07-26)
  Vendor thirdparty submodule into the repository
  Vendor the ide submodule into the repository
  OpenXTalk Lite .91 IDE (Terry Little, 2023-09-14)
  OpenXTalk Lite 0.91 ... 1.15 IDE (Tom Perry, 2023-09-25 ... 2026-05-05)
  OpenXTalk Lite Windows engine work by Tom Perry (2026-06-01)   <- tag tom-perry-1.15
  build changes (26 commits)
  CI, tests and packaging (from OXT-Beyond, then adapted)
```

The tag **`tom-perry-1.15`** is the pristine code: the OpenXTalk Lite IDE
1.15 and Tom Perry's 9.7.1-OXT engine work, on LiveCode Community 9.7
develop. Its tree is identical, hash for hash, to `windows/` in the record
repository [openxtalk/OpenXTalk-Lite](https://github.com/openxtalk/OpenXTalk-Lite)
at 6f8f4cc851 (tree `7578af0924f537495f952e06ea4588b3e075e906`). The IDE
releases and Tom Perry's engine commit keep their original authors, dates
and messages. LiveCode's own README is at `git show tom-perry-1.15:README.md`.

To see everything Tom Perry changed in LiveCode, and everything this
repository changed in Tom Perry's tree:

```
git diff 4606a10ea tom-perry-1.15 -- . ':!thirdparty' ':!ide'   # Tom Perry's engine work (and vendoring)
git diff tom-perry-1.15 main -- $(sed -n '/^\[build\]/,$p' .github/pristine-allowlist.txt | grep -v '^\[')
```

## The pristine guarantee

Everything after the tag must stay inside the paths that
[`.github/pristine-allowlist.txt`](.github/pristine-allowlist.txt) allows:

- **this repository's own files**: `.github/`, `tools/ci/`, `tools/oxt/`,
  `tests/`, `Installer/openxtalk-lite/`, `Installer/linux/`, this README,
  `.gitattributes` and `.gitignore`. Nothing in them is built into the
  product;
- **the build changes**, file by file: only what current compilers, SDKs
  and systems need to build Tom Perry's code.

The **Pristine guard** workflow ([`tools/ci/pristine_guard.py`](tools/ci/pristine_guard.py))
checks this on every push and pull request and before every release. It
also checks that the tag still has the tree above, so the reference cannot
move. Its job summary lists every build change with its line counts.

### The build changes

Tom Perry built his 9.x engine for Windows only, with Visual Studio 2017
and LiveCode's prebuilt libraries from a local folder. The commits after
the tag make the same code build on GitHub's runners today. Each says what
fails without it; most are ported from OXT-Beyond and name the commit
there.

| platform | what changes | from |
|---|---|---|
| all | `.gitmodules` lists only googletest, which is restored | |
| Windows | Visual Studio 2022 with the v141 toolset (`make.cmd`, `configure.bat`); Windows SDK include order, `NOMINMAX` and `WIN32_LEAN_AND_MEAN` for every target, the OLE and Winsock headers that then have to be named; SQLite built from Tom Perry's own `thirdparty/libsqlite` (3.51.1) instead of the older prebuilt library; Cygwin lookup; prebuilt libraries fetched from a mirror | OXT-Beyond PRs #1 to #3 |
| Linux | Tom Perry's respring globals moved to where every engine links them; non-PIE standalone engines; arm64 and i386 hosts; a 64 MB stack for lc-compile; no type-punned module definitions; the prebuilt library scripts for current systems; no CEF on 32-bit Linux | OXT-Beyond PR #6 and later |
| macOS | **Tom Perry's own portability fixes from his macOS source trees** (authored by him); Xcode 16 and arm64 build settings; `MCStacklist::redrawall()`, which his dark-mode handler calls and nobody defined; libffi, libpng and zlib for current SDKs | Tom Perry; OXT-Beyond PR #7 and later |
| all | OpenSSL 1.1.1w instead of 1.1.1g for the libraries built from source: 1.1.1g cannot be linked into a shared object on arm64 and has no Apple Silicon target | OXT-Beyond |

Left out on purpose: OXT-Beyond's bug fixes (Linux headless font crash,
clipboard, players, dates and many more), its dark mode, branding and
updater, its newer libraries (OpenSSL 3, curl 8, ICU 78, zlib, libpng,
giflib, libjpeg, PCRE), its cleanup of LiveCode's build files, and the
"Report bugs to" URLs of the compiler tools.

## CI

| workflow | what it does |
|---|---|
| [Build (Windows)](.github/workflows/build-windows.yml) | x86-64 build with LiveCode's own prebuilt libraries (the ones Tom Perry built with), packages it as OpenXTalk Lite 1.15's install layout (`OpenXTalk-Lite.exe`), and runs the smoke test, standalone, browser and player, IDE compile, engine test and installer checks |
| [Build (Linux)](.github/workflows/build-linux.yml) | x86_64, arm64 and x86 builds with the IDE compile check and the engine tests; packages x86_64 with a launcher and install scripts, and tests the package as users get it |
| [Build (macOS)](.github/workflows/build-macos.yml) | arm64 and x86_64 builds, joined into a universal `OpenXTalk-Lite.app`, signed ad hoc, as a disk image and zip; installed and tested on both architectures |
| [Pristine guard](.github/workflows/pristine-guard.yml) | see above |
| [Release](.github/workflows/release.yml) | builds and tests all three platforms and publishes a GitHub Release only when everything, the guard included, passed; dry runs by hand |
| [Tag a release](.github/workflows/tag-release.yml) | tags `main` as the next `v1.15-r<n>` once its builds and the guard passed, and starts the release |
| [Browser and player check (release)](.github/workflows/media-check.yml) | the browser and player checks on a published release's packages |

The tools behind them (`tools/ci/`, `tools/oxt/`) and the test changes in
`tests/` come from OXT-Beyond; the commits that adapted them say what
changed. OXT-Beyond's checks of its own appearance work (dark mode, IDE
colours, contrast, render tests) are not here.

### Test baselines

Every check compares its failures with a baseline:
`tools/ci/engine-tests-baseline*.txt` for the engine test suites and
`tools/ci/ide-compile-baseline*.txt` for the IDE compile check. A failure
not in the baseline fails the job. A baseline entry that starts passing is
reported, so it can be removed.

Here a baseline line is a record of how Tom Perry's code behaves: a bug or
a limitation of OpenXTalk Lite 1.15 or the LiveCode Community 9.7 code
under it, or one of OXT-Beyond's regression tests for a fix made there.
Each line gets a comment saying which. Comparing these baselines with
OXT-Beyond's shows what OXT-Beyond fixed.

### Libraries and runtimes

- **Windows**: LiveCode's own x86-64 (MSVC v141) prebuilt libraries,
  OpenSSL 1.1.1g, curl 7.51.0, ICU 58.2, CEF 74.1.19 and the Thirdparty
  set, as `prebuilt/versions` pins them. LiveCode's server no longer
  serves them; OXT-Beyond's release
  [`prebuilts-v1`](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond/releases/tag/prebuilts-v1)
  mirrors them, and each is checked against `prebuilt/SHA256SUMS`.
- **Linux and macOS**: the same versions built from source in CI (OpenSSL
  1.1.1w, see above), cached.
- **Standalone runtimes** for the platforms other than each package's own
  (Windows x86, Linux, Android): OpenXTalk Lite 1.15's own, unchanged, from
  the asset
  [`oxt-runtimes-1.15`](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond/releases/tag/runtimes-1.15)
  (`tools/oxt/external-assets.json`).

### Not done yet

- **No 32-bit Windows build.** LiveCode's 32-bit prebuilt libraries are not
  available any more. The packages carry OpenXTalk Lite 1.15's own 32-bit
  Windows runtime instead. Building one would mean building OpenSSL, curl
  and ICU for x86 with Tom Perry's versions, for example with LiveCode's own
  scripts in `prebuilt/scripts/*.bat`.
- **Tom Perry's macOS engine work is not in this tree.** His macOS working
  copies (`macos-intel/` and `macos-arm64/` in openxtalk/OpenXTalk-Lite)
  hold his macOS dark mode, AppKit theme drawing and `macSetIcon`, and other
  versions of the Windows files this tree has. Only the portability fixes
  from them are here. The macOS packages are his Windows tree built for
  macOS.
- The prebuilt libraries and the runtimes are downloaded from OXT-Beyond's
  releases; mirroring them as releases of this repository would remove that
  dependency.

## Releases

A release is tagged `v1.15-r<n>`: OpenXTalk Lite 1.15, the nth release
built from this repository. `ide/.version` stays Tom Perry's `1.15`, so the
files are named `OpenXTalk-Lite-1.15-…`. Run **Actions > Tag a release** on
`main` once its builds have passed; it makes the next tag and starts the
release. Releases are never replaced: a new build of the same code gets
the next number.

## Building it yourself

The workflows are the exact recipe; each step names the scripts it runs.
In short:

- **Windows** (x86-64): Visual Studio 2022 with the MSVC v141 toolset and
  the Windows 10 SDK 10.0.17763.0, Python 2.7 in `C:\Python27`, and Cygwin
  with flex and bison. Fetch the prebuilt libraries with
  `prebuilt/fetch-libraries.sh win32 x86_64` (in Cygwin, with
  `PREBUILT_URL` set to the `prebuilts-v1` release above), then
  `tools/ci/build-windows.ps1 -Stage configure` and `-Stage build`.
- **Linux**: Ubuntu 20.04 (or its container) with the packages of the
  workflow's first step; `prebuilt/build-libraries.sh linux x86_64` and
  `prebuilt/package-libs.sh linux x86_64`, then
  `make config-linux-x86_64` and the two `make` runs of the Build step.
- **macOS**: Xcode 16.4 and Python 2.7; `prebuilt/build-libraries.sh mac
  universal`, then `./config.sh --platform mac` and `xcodebuild` as in the
  Build step.

`tools/oxt/package.py` then stages the installed layout; see
[tools/oxt/README.md](tools/oxt/README.md). OXT-Beyond's
[BUILDING.md](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond/blob/main/BUILDING.md)
describes the same toolchains in detail.

## Credits

- **Tom Perry (tperry2x)**: OpenXTalk Lite 0.91 to 1.15 and the 9.7.1-OXT
  engine work.
- **Terry Little (TerryL)**: started OpenXTalk Lite with the .91 package,
  and contributed to later versions.
- The OpenXTalk community, credited in the IDE history: Paul McClernan,
  Richmond, Axwald, Neville, Ferrus Logic, overclockedmind, micmac and
  others.
- **LiveCode Ltd** and the LiveCode Community contributors wrote the
  LiveCode Community Edition that all of this is built on.
- The CI, tests and packaging come from **OXT-Beyond** and its
  contributors.

## Licence

LiveCode Community Edition is licensed under the GNU General Public License
version 3, with LiveCode Ltd's additional permission for OpenSSL and ATL at
the top of [`LICENSE`](LICENSE). Tom Perry's and the other contributors'
changes are distributed under the same terms. Third-party components keep
their own licences (see `thirdparty/` and the IDE's
`Open Source Licenses.txt`). The build tools GENTLE and REFLEX, which
lc-compile's build makes for itself, may not be redistributed, so no
artifact or package of this repository contains them.
