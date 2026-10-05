# OpenXTalk Lite 1.15: Tom Perry's source, built and tested

This repository is OpenXTalk Lite 1.15 as Tom Perry left it, for Windows,
macOS and Linux, with continuous integration around it: builds, the engine
and IDE test suites, packaging and releases. Nothing in Tom Perry's code is
fixed or improved here. Bugs are recorded, not fixed. Every difference
from his source is listed, with its reason, in
**[CHANGES-FROM-TOM.md](CHANGES-FROM-TOM.md)**, and CI checks that the
list is complete.

It exists so that the original can be built, run and measured on today's
systems: as a reference for what OpenXTalk Lite 1.15 does, and as the
baseline that [OXT-Beyond](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond),
which continues the work, can be compared against.

## What is in it

Tom Perry left two working copies of his 9.7.1-OXT engine, both clones of
LiveCode Community 9.7 develop: one for Windows, with the OpenXTalk Lite
IDE 1.15, and one for macOS (Apple Silicon, holding his Intel work too).
They are imported here as he left them, on LiveCode's own history, and
merged into one tree:

```
LiveCode Community history, up to develop 4606a10ea (2021-07-26)
  Vendor thirdparty submodule into the repository
  Vendor the ide submodule into the repository
  |\
  | OpenXTalk Lite .91 IDE (Terry Little, 2023-09-14)
  | OpenXTalk Lite 0.91 ... 1.15 IDE (Tom Perry, ... 2026-05-05)
  | OpenXTalk Lite Windows engine work (Tom Perry)     <- tag tom-perry-1.15
  |  \
  |   OpenXTalk Lite macOS (Apple Silicon) engine work (Tom Perry)   <- tag tom-perry-1.15-macos
  |  /
  Merge Tom Perry's macOS engine work into his Windows engine work   <- tag tom-perry-1.15-merged
  build changes (documented in CHANGES-FROM-TOM.md, section 2)
  CI, tests and packaging (from OXT-Beyond, adapted)
```

| tag | what | identical to, in [openxtalk/OpenXTalk-Lite](https://github.com/openxtalk/OpenXTalk-Lite) |
|---|---|---|
| `tom-perry-1.15` | his Windows working copy with the IDE 1.15 | `windows/` at 6f8f4cc851 (tree `7578af09`) |
| `tom-perry-1.15-macos` | his Apple Silicon working copy | `macos-arm64/` at 4f2feee273 (tree `741d369e`) |
| `tom-perry-1.15-merged` | the two merged; the merge commit and [CHANGES-FROM-TOM.md](CHANGES-FROM-TOM.md#1-the-merge) say how each conflict was resolved | |

The IDE releases and Tom Perry's two engine commits keep their original
authors, dates and messages. LiveCode's own README is at
`git show tom-perry-1.15:README.md`.

Not here: his Linux source, which is a separate 7.x engine line (LiveCode
7.1.4 with the LiveCode 7 IDE), not the 9.x engine OpenXTalk Lite 1.15
runs on; it stays in the record repository (`linux/`). The Linux packages
here are the merged 9.x tree built for Linux.

## Every change is documented

[CHANGES-FROM-TOM.md](CHANGES-FROM-TOM.md) lists, with the reason for
each:

1. **the merge**: every path where the merged tree is not simply what
   Tom Perry's trees have (13 paths: which version each takes, or how the
   two are combined);
2. **every change after the merge**: each commit that touches a file of
   his, and what it changes in each file. They make his code build on
   today's compilers, SDKs and systems (Visual Studio 2022, current Xcode
   and macOS SDKs, current Linux, prebuilt libraries that can no longer
   be downloaded), make LiveCode's tests run on CI machines, and document
   the repository. None fixes a bug or changes a feature.

The **Pristine guard** workflow ([`tools/ci/pristine_guard.py`](tools/ci/pristine_guard.py))
enforces this on every push and pull request and before every release:
the tags must still have the trees above; every path of the merge must be
what Tom Perry's trees give or exactly what section 1 says; every file of
his changed or deleted after the merge, and every file added outside this
repository's own folders ([`.github/pristine-allowlist.txt`](.github/pristine-allowlist.txt)),
must be named in section 2.

## CI

| workflow | what it does |
|---|---|
| [Build (Windows)](.github/workflows/build-windows.yml) | x86-64 build with LiveCode's own prebuilt libraries (the ones Tom Perry built with), packaged as OpenXTalk Lite 1.15's install layout (`OpenXTalk-Lite.exe`); smoke test, standalones, browser and player, IDE compile check, engine tests, installer |
| [Build (macOS)](.github/workflows/build-macos.yml) | arm64 and x86_64 builds of Tom Perry's macOS engine work, joined into a universal `OpenXTalk-Lite.app` with his icon, signed ad hoc, as a disk image and zip; installed and tested on both architectures |
| [Build (Linux)](.github/workflows/build-linux.yml) | x86_64, arm64 and x86 builds with the IDE compile check and the engine tests; packages x86_64 with a launcher and install scripts, and tests the package as users get it |
| [Pristine guard](.github/workflows/pristine-guard.yml) | see above |
| [Release](.github/workflows/release.yml) | builds and tests all three platforms and publishes a GitHub Release only when everything, the guard included, passed; dry runs by hand |
| [Tag a release](.github/workflows/tag-release.yml) | tags `main` as the next `v1.15-r<n>` once its builds and the guard passed, and starts the release |
| [Browser and player check (release)](.github/workflows/media-check.yml) | the browser and player checks on a published release's packages |

The tools behind them (`tools/ci/`, `tools/oxt/`) and the test changes in
`tests/` come from OXT-Beyond; the commits that adapted them say what
changed. OXT-Beyond's checks of its own appearance work (its dark mode,
IDE colours, contrast and render tests) are not here.

### Test baselines

Every check compares its failures with a baseline:
`tools/ci/engine-tests-baseline*.txt` for the engine test suites and
`tools/ci/ide-compile-baseline*.txt` for the IDE compile check. A failure
not in the baseline fails the job; a baseline entry that starts passing is
reported, so it can be removed.

Here a baseline line records how Tom Perry's code behaves: a bug or a
limitation of OpenXTalk Lite 1.15 or of the LiveCode Community 9.7 code
under it, often caught by one of OXT-Beyond's regression tests for a fix
made there. Each has a comment saying which. Comparing these baselines
with OXT-Beyond's shows what OXT-Beyond fixed.

### Libraries and runtimes

- **Windows**: LiveCode's own x86-64 (MSVC v141) prebuilt libraries,
  OpenSSL 1.1.1g, curl 7.51.0, ICU 58.2, CEF 74.1.19 and the Thirdparty
  set, as `prebuilt/versions` pins them. LiveCode's server no longer
  serves them; OXT-Beyond's release
  [`prebuilts-v1`](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond/releases/tag/prebuilts-v1)
  mirrors them, and each is checked against `prebuilt/SHA256SUMS`.
- **Linux and macOS**: the same versions built from source in CI (OpenSSL
  1.1.1w instead of 1.1.1g, which cannot be linked on arm64), cached.
- **Standalone runtimes** for the platforms other than each package's own
  (Windows x86, Linux, Android): OpenXTalk Lite 1.15's own, unchanged, from
  the asset
  [`oxt-runtimes-1.15`](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond/releases/tag/runtimes-1.15).

### Not done yet

- **No 32-bit Windows build.** LiveCode's 32-bit prebuilt libraries are not
  available any more; the packages carry OpenXTalk Lite 1.15's own 32-bit
  Windows runtime. Building one would mean building OpenSSL, curl and ICU
  for x86 with these versions, for example with LiveCode's own scripts in
  `prebuilt/scripts/*.bat`.
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
- **macOS**: Xcode 16.4 and Python 2.7; `prebuilt/build-libraries.sh mac
  universal` and `prebuilt/package-libs.sh mac universal`, then
  `./config.sh --platform mac` and `xcodebuild` as in the Build step. (Tom
  Perry's own build scripts and hand-edited Xcode projects, for his Mac,
  are in the tree as he left them: `build_openxtalk.sh`, `build-mac/` and
  others.)
- **Linux**: Ubuntu 20.04 (or its container) with the packages of the
  workflow's first step; `prebuilt/build-libraries.sh linux x86_64` and
  `prebuilt/package-libs.sh linux x86_64`, then `make config-linux-x86_64`
  and the two `make` runs of the Build step.

`tools/oxt/package.py` then stages the installed layout; see
[tools/oxt/README.md](tools/oxt/README.md).

## Credits

- **Tom Perry (tperry2x)**: OpenXTalk Lite 0.91 to 1.15 and the 9.7.1-OXT
  engine work for Windows and macOS.
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
