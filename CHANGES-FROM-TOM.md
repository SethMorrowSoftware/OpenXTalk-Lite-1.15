# Every change from Tom Perry's source

This file lists every difference between the code in this repository and
Tom Perry's OpenXTalk Lite source, and why it was made. Nothing else
differs. The **Pristine guard** (`tools/ci/pristine_guard.py`, on every
push, pull request and release) enforces it:

- the tags `tom-perry-1.15` and `tom-perry-1.15-macos` must still have the
  trees of Tom Perry's two working copies in the record repository
  [openxtalk/OpenXTalk-Lite](https://github.com/openxtalk/OpenXTalk-Lite);
- in the merge `tom-perry-1.15-merged`, every path must be what Tom
  Perry's trees have there, except the paths of [section 1](#1-the-merge),
  each of which must be exactly as the table says;
- after the merge, every file of Tom Perry's that is changed or deleted,
  and every file added outside this repository's own folders, must be
  named in [section 2](#2-the-changes-after-the-merge).

Tom Perry's source here is his two 9.7.1-OXT working copies, both clones
of LiveCode Community 9.7 develop 4606a10ea:

| tag | what | tree, identical to |
|---|---|---|
| `tom-perry-1.15` | his Windows working copy, with the OpenXTalk Lite IDE 1.15 | `windows/` at 6f8f4cc851 (tree `7578af09`) |
| `tom-perry-1.15-macos` | his Apple Silicon working copy, which holds his Intel work too | `macos-arm64/` at 4f2feee273 (tree `741d369e`) |
| `tom-perry-1.15-merged` | the merge of the two (section 1) | |

To see it all yourself:

```
git diff tom-perry-1.15 tom-perry-1.15-merged          # what the merge took from his macOS tree
git diff tom-perry-1.15-merged main -- . ':!.github' ':!tools/ci' ':!tools/oxt' ':!Installer/openxtalk-lite' ':!Installer/linux'
python3 tools/ci/pristine_guard.py                     # the checks above
```

Not in this repository: his Intel tree as such (`macos-intel/` there; the
Apple Silicon tree holds his Intel work, and differs from it only by
backups, a debug build script, the SQLite ORIGIN note and an unused
12-line `platform-window-mac.mm`), and, not yet, his Linux 1.15 source,
which is to be imported and merged like his macOS tree. (`linux/` there
is a different tree, versioned 7.4.1: LiveCode 7.1.4 with the LiveCode 7
IDE.)

## 1. The merge

`tom-perry-1.15-merged` merges his macOS tree into his Windows tree. git
takes every path that only one of them changed from that one, and every
path both changed the same way as it is. The paths below are the rest:
both trees changed them, differently (or, for `desktop-dc.h`, only the
Windows tree did, and its version is not taken).

The rule: a file that only one platform compiles takes Tom Perry's
version for that platform, as he built and ran it; a file every platform
compiles keeps both trees' changes, and where they conflict, each
platform keeps its own version behind a platform check.

| path | taken | why |
|---|---|---|
| `engine/src/dskw32.cpp` | windows | Windows only. His macOS tree held an older or other version of his Windows work, which no macOS build compiles. |
| `engine/src/w32dcs.cpp` | windows | Windows only, as above. |
| `engine/src/w32dcw32.cpp` | windows | Windows only, as above. |
| `engine/src/w32stack.cpp` | windows | Windows only, as above. |
| `engine/src/desktop.cpp` | macos | The platform layer that only macOS uses (FEATURE_PLATFORM_APPLICATION, called through platform.cpp). His macOS version has the respring check in the macOS main loop and redraws every stack when the appearance changes; his Windows tree's edit (a call to `updatesystemappearance()`) was never compiled by any build of his. |
| `engine/src/desktop-dc.cpp` | macos | macOS only, as above. His Windows tree's edits (dark initial colours, `updatesystemappearance()`) never compiled: Windows does not build this file, and on macOS it fails (a free function using the screen's members). |
| `engine/src/desktop-dc.h` | macos | Goes with `desktop-dc.cpp`: his Windows tree declared `updatesystemappearance()` here, which his macOS `desktop-dc.cpp` does not define. Only the Windows tree had changed this file. |
| `engine/src/mac-core.mm` | macos | macOS only. His Windows tree had only wrapped two functions in `#ifndef _WINDOWS`, which changes nothing on macOS. |
| `engine/src/respring.cpp` | combined | He wrote `_internal respring` twice, as two designs: on macOS the command unwinds the handler chain with MCquit and the main loop reloads the IDE with `MCdispatcher->startup()`; on Windows it only sets a flag (the unwind crashed there) and reloads the IDE step by step. Both files are kept whole, unchanged: macOS compiles his macOS one (`#if defined(_MACOSX)`), every other platform his Windows one. Only the comment at the top and the `#if`, `#else` and `#endif` lines are added. |
| `engine/src/internal_development.cpp` | combined | His Windows version, plus his macOS tree's two developer commands, `_internal build MacARM` (which the IDE's macOS ARM standalone builder calls) and `_internal dump stack`, under `#if defined(_MACOSX)`: their source, `build_macarm.cpp`, needs `<dirent.h>`, which MSVC has not, and his Windows engine never had them. |
| `engine/src/buttondraw.cpp` | combined | git kept both trees' changes: his dark-aware checkmark and cascade arrow (Windows tree) and his button labels 2 pixels higher (macOS tree). |
| `engine/engine-sources.gypi` | combined | git kept both trees' changes: respring.cpp in the development engine's sources (Windows tree; his macOS Xcode project listed it by hand) and macicon.mm (macOS tree). |
| `prebuilt/fetch-libraries.sh` | combined | git kept both trees' changes, his local prebuilt folders for each (both replaced after the merge, see section 2). |

## 2. The changes after the merge

Each commit after `tom-perry-1.15-merged` that changes one of Tom Perry's
files, in order. Commits that only add this repository's own files (CI,
tests, packaging and documentation in `.github/`, `tools/ci/`,
`tools/oxt/`, `Installer/openxtalk-lite/` and `Installer/linux/`) are not
listed: nothing in them is built into the product. Most of the build
changes are ported from [OXT-Beyond](https://github.com/SethMorrowSoftware/OpenXTalk-Beyond),
whose commit each names; each commit message here has the full detail.

None of them fixes a bug or changes a feature. Each is needed to build
his code on today's compilers, SDKs and systems, to test it, or to
document it.

### Submodules: googletest only, at the commit upstream pinned

Why: `thirdparty/` and `ide/` are vendored, so `.gitmodules` must not
list them as submodules (a recursive checkout would fail), and the C++
test framework that LiveCode's build expects was left out of Tom Perry's
tree.

- `.gitmodules`: only `libcpptest/googletest`, branch main.
- `libcpptest/googletest`: added back, at the commit LiveCode 9.7 develop
  pinned (dcc92d0ab).

### Fetch prebuilt libraries from the winoxt GitHub release

Why: LiveCode's server for its prebuilt libraries is gone, and Tom Perry
fetched them from folders on his own computers.

- `prebuilt/fetch-libraries.sh`: downloads from a mirror (PREBUILT_URL),
  checks each tarball against SHA256SUMS, takes a local folder from
  PREBUILT_LOCAL_DIR; replaces Tom Perry's local folders
  (`file:///C:\Users\user\Documents\prebuilts` on Windows, the prebuilt
  folder itself elsewhere).
- `prebuilt/SHA256SUMS` (added): the checksums of LiveCode's Windows
  prebuilt tarballs.
- `prebuilt/scripts/lib_versions.bat`, `prebuilt/scripts/lib_versions.inc`,
  `prebuilt/versions/thirdparty`: the Thirdparty prebuilt version is
  pinned to the vendored thirdparty commit, since there is no submodule
  to read it from.

### Windows build fixes: SQLite from source, Cygwin lookup, VS 2022

Why: GitHub's Windows runners have Visual Studio 2022 (with the v141
toolset Tom Perry used added at run time), not his Visual Studio 2017,
and a Cygwin of their own; and the SQLite library in LiveCode's
prebuilts (3.34.0) is older than the SQLite 3.51.1 headers Tom Perry put
into `thirdparty/libsqlite`.

- `make.cmd`: finds Visual Studio with vswhere and passes the Windows SDK
  version to msbuild.
- `configure.bat`: finds Python 2.7, never waits for a key in CI; no
  longer looks for the Speech SDK 5.1 (revSpeech uses the Windows SDK's
  sapi.h).
- `revdb/revdb.gyp`: on Windows, dbsqlite builds Tom Perry's SQLite 3.51.1
  from `thirdparty/libsqlite` instead of linking the older prebuilt one.
- `util/invoke-unix.bat`: finds Cygwin in more places and puts its tools
  first on PATH.
- `util/remove_matching.py`: runs under Python 3 as well as 2.
- `.gitattributes`: batch files with CRLF, YAML and SHA256SUMS with LF.
- `.gitignore`: build output folders of the CI scripts.

### Prevent Windows SDK min max macro collisions

Why: the Windows SDK's `min` and `max` macros break C++ code in the engine
and third-party headers with the newer SDK.

- `config/win32.gypi`: NOMINMAX and WIN32_LEAN_AND_MEAN for every Windows
  target.
- `engine/src/w32prefix.h`: the same, for files built outside gyp.

### Harden Windows definitions; no local min macro in the ODBC driver

Why: with NOMINMAX, the ODBC driver's own `min` macro is always defined,
and `#if not defined(min)` is not valid in MSVC's preprocessor.

- `config/win32.gypi`: _CRT_SECURE_NO_WARNINGS and
  _WINSOCK_DEPRECATED_NO_WARNINGS for every Windows target.
- `revdb/src/odbc_connection.cpp`: the `min` macro is removed; the one
  use compares the two lengths explicitly. The loop is otherwise
  unchanged.

### Fix Windows SDK include ordering

Why: the newer Windows SDK fails to parse `winnt.h` when the engine's
legacy macros are defined before it.

- `engine/src/prefix.h`: includes the Windows SDK before `globdefs.h`.
- `libcore/src/core.cpp`, `libfoundation/src/system-commandline.cpp`,
  `libfoundation/src/system-file-w32.cpp`: the headers that
  WIN32_LEAN_AND_MEAN no longer pulls in (`oleauto.h`, `shellapi.h`), and
  `byte_t` for the SDK's `byte`.

### Declare Windows OLE and Winsock dependencies

Why: as above, WIN32_LEAN_AND_MEAN leaves these headers out.

- `libfoundation/src/foundation-string.cpp`: includes `oleauto.h`.
- `revdb/src/dbmysql.h`: includes `winsock2.h` before `windows.h`.

### Build the engine on Linux x86_64 and arm64

Why: his Linux 1.15 source is not in this repository yet, so Linux is
built from the merged Windows and macOS tree, in which his respring
globals live in the Windows main file, so no other engine links. These
are OXT-Beyond's Linux port of the build; when his Linux source is
merged, they are to be checked against it.

- `engine/src/dskw32main.cpp`, `engine/src/dskmain.cpp`: the respring
  function pointers move to the file every desktop engine compiles.
- `engine/src/dsklnxmain.cpp`: the Linux main loop checks for a pending
  respring, as his Windows loop does.
- `engine/src/respring.cpp`: in his Windows version (section 1), the
  Windows-only `w32dc.h` and its use are included on Windows only.
- `engine/engine.gyp`: the Linux standalone and installer engines link
  with -no-pie, which Save as Standalone needs (current gcc builds
  position-independent executables by default).
- `Makefile`, `Makefile.common`, `config.py`, `config/arch.gypi`: arm64
  Linux hosts.
- `thirdparty/libcurl/include/curl/curlbuild.win.h`: aarch64 type sizes.
- `prebuilt/build-libraries.sh`, `prebuilt/fetch-libraries.sh`,
  `prebuilt/package-libs.sh`, `prebuilt/scripts/build-cef.sh`,
  `prebuilt/scripts/build-curl.sh`, `prebuilt/scripts/build-icu.sh`,
  `prebuilt/scripts/platform.inc`: the prebuilt libraries are built from
  their pinned sources, since they can no longer be downloaded (ICU 58's
  `xlocale.h` include, removed from glibc 2.26; current download
  addresses; arm64 hosts).

### Linux CI: package Thirdparty only once built; no SIGPIPE failures

Why: the packaging script took any library folder without `libz.a` for a
Windows one, so packaging OpenSSL, curl and ICU before the Thirdparty
libraries were built failed; and `| head -1` failed CI steps with SIGPIPE.

- `prebuilt/package-libs.sh`.

### OpenSSL 1.1.1w for the libraries built from source

Why: OpenSSL 1.1.1g, which Tom Perry's tree pins, cannot be linked into
a shared library on Linux arm64 (`OPENSSL_armcap_P` is not hidden) and
has no Apple Silicon target; 1.1.1w, the last 1.1.1 release, has both.
Windows keeps LiveCode's 1.1.1g prebuilts, Tom Perry's exact libraries.

- `prebuilt/versions/openssl`: 1.1.1w.
- `prebuilt/versions/openssl_win32` (added): 1.1.1g for Windows.
- `prebuilt/fetch-libraries.sh`, `prebuilt/scripts/lib_versions.inc`,
  `prebuilt/scripts/build-openssl.sh`: read the per-platform version;
  download from GitHub.

### Linux arm64: use only the arm64 libffi headers

Why: every Linux build got the Darwin x86 libffi headers first in its
include path; on arm64 they have no ARM definitions, and libscript did
not compile ("FFI_DEFAULT_ABI was not declared").

- `prebuilt/thirdparty.gyp`.

### Linux arm64: signed char, as on every other platform

Why: plain `char` is unsigned on Linux arm64 but signed on x86 and on
Apple arm64, where this code was written and tested; the freshly built
lc-compile crashed on Linux arm64.

- `config/linux-settings.gypi`: -fsigned-char.

### lc-compile: run on a thread with a 64 MB stack outside Windows

Why: lc-compile's parser recurses deeply, and the freshly built
lc-compile crashed on Linux arm64 the first time the build ran it.
Windows already links it with a 64 MB stack; Linux and macOS give the
main thread about 8 MB.

- `toolchain/lc-compile/src/main.c`, `toolchain/lc-compile/src/lc-compile-lib.gyp`.

### libscript: allocate module definitions without type-punned references

Why: `script-builder.cpp` allocated each module definition through a
reference to a different pointer type, which is undefined under strict
aliasing; gcc on arm64 read back the old nil value and lc-compile
crashed.

- `libscript/src/script-builder.cpp`: each definition is allocated into a
  pointer of its own type.
- `config/linux-settings.gypi`: no `-fstrict-aliasing`, so that gcc gives
  the same memory semantics as MSVC, with which the code was mostly
  written.

### lc-compile: correct the comment on the 64 MB compiler thread

Why: a wrong comment in the commit above.

- `toolchain/lc-compile/src/main.c`.

### Build the engine on macOS arm64 and x86_64

Why: Tom Perry built macOS with Xcode projects he edited by hand, against
the macOS 12.1 SDK and libraries on his Mac; the builds here use gyp, the
installed Xcode, and one universal app for both processors.

- `config.py`: the SDK of the installed Xcode instead of macOS 12.1, the
  machine's own architecture.
- `config/WorkspaceSettings.xcsettings`: Xcode 14 removed the legacy build
  system.
- `config/mac.gypi`: ARCHS follows the target; the oldest macOS is 11.0 on
  Apple Silicon and 10.13 on Intel (his tree: 11.0 for both); SDK 11.0
  recorded in every binary. His `build_edition` default stays.
- `thirdparty/libffi/libffi.gyp`: Apple Silicon uses the newer libffi in
  `git_master`, whose closures use a trampoline table, instead of his
  choice of the old `src/aarch64` sources: arm64 macOS does not allow
  memory that is writable and executable at once.
- `thirdparty/libcairo/libcairo.gyp`: no SSE2 code on Apple Silicon (his
  tree did the same with other conditions).
- `prebuilt/fetch-libraries.sh`, `prebuilt/package-libs.sh`,
  `prebuilt/scripts/build-icu.sh`, `prebuilt/scripts/build-openssl.sh`,
  `prebuilt/scripts/platform.inc`: the prebuilt libraries for macOS with
  the installed Xcode, per architecture (ICU 58 uses `register`, removed
  in C++17; OpenSSL's Apple Silicon target).

### macOS arm64: build libffi without CFI directives; stop on Thirdparty failures

Why: clang rejected libffi's unwind directives on Apple Silicon (undone
properly two commits below), and a failed Thirdparty build went on
unnoticed.

- `prebuilt/scripts/build-thirdparty.sh`, `thirdparty/libffi/libffi.gyp`
  (and libffi's fficonfig_arm64.h, which the later commit puts back as it
  was).

### libpng, zlib: build with current macOS SDKs

Why: current macOS SDKs define TARGET_OS_MAC, which these 2013-era
headers take for classic Mac OS: libpng then includes `<fp.h>`, which the
SDKs no longer have, and zlib defines `fdopen()` as NULL, which breaks
`<stdio.h>`.

- `thirdparty/libpng/src/pngpriv.h`, `thirdparty/libz/src/zutil.h`: Apple
  platforms take the normal `<math.h>` and `fdopen()`.

### macOS CI: report every compile error in one run

Why: the Thirdparty build stopped at its first error.

- `prebuilt/scripts/build-thirdparty.sh`.

### macOS: build the toolchain, libbrowser and deploy code with Xcode 16

Why: current clang rejects the pre-ANSI C of the parser generators, and
macOS 15's SDK adds a JavaScript type that a `switch` does not handle;
and Tom Perry's `<mach/machine.h>` in `deploy_macosx.cpp` exists only on
macOS, while the Windows and Linux IDE engines compile that file too.

- `toolchain/gentle/gentle/gentle.gyp`, `toolchain/gentle/gentle/grts.gyp`,
  `toolchain/gentle/reflex/reflex.gyp`: compiled as gnu89 on macOS.
- `libbrowser/src/libbrowser_osx_webview.mm`: a default case.
- `engine/src/deploy_macosx.cpp`: his include stays where he put it, on
  macOS only, and LiveCode's own `cpu_type_t` and `cpu_subtype_t` come
  back for the other platforms.

### macOS arm64: use the newer libffi's headers for the engine

Why: goes with the newer libffi above.

- `prebuilt/thirdparty.gyp`.

### macOS: build without strict aliasing, as on Linux and Windows

Why: as for Linux above.

- `config/mac.gypi`: -fno-strict-aliasing.

### macOS arm64: libffi has unwind information again

Why: without it, an Objective-C exception in code that LiveCode Builder
calls ended the program instead of becoming an error; the directives are
fixed instead of left out.

- `thirdparty/libffi/git_master/darwin_ios/src/aarch64/sysv_arm64.S`: the
  unwind directives after the function labels, and a label name Mach-O
  keeps local.
- `thirdparty/libffi/libffi.gyp`, and fficonfig_arm64.h: as they were
  before the commit that left the directives out.

### Linux x86: no CEF (its 32-bit builds ended with CEF 101), i386 archive names

Why: there is no 32-bit Linux build of CEF 74 to download.

- `libbrowser/libbrowser.gyp`, `libbrowser/src/libbrowser_lnx_factories.cpp`,
  `revbrowser/revbrowser.gyp`, `prebuilt/libcef.gyp`: CEF on Linux x86_64
  only.
- `prebuilt/fetch-libraries.sh`, `prebuilt/scripts/platform.inc`: the
  i386 archive names.

### macOS: compile Tom Perry's build MacARM and dump stack commands with gyp

Why: his macOS Xcode project (`build-mac/.../kernel-development.xcodeproj`)
compiled `build_macarm.cpp` and `dump_stack.cpp` into the development
engine, but he never added them to the gyp files, so a gyp build of his
`internal_development.cpp` does not link.

- `engine/kernel-development.gyp`: both files, on macOS.

### Import the CI, tests and packaging tools of OXT-Beyond

Why: the tests, and the line endings and file types that a Windows
checkout needs to package the IDE byte for byte.

- `.gitattributes`: the Linux installer files with LF; the IDE's binary
  file types (`.oxtstack`, `.ico`, `.sqlite` and others) never converted.
- `.gitignore`: the external assets that packaging downloads.
- The engine test suites, as OXT-Beyond changed them. Two kinds of
  change: the harness and the tests made to run on CI machines and on
  Windows, and OXT-Beyond's regression tests for fixes made there, which
  fail on Tom Perry's code and are recorded in the baselines
  (`tools/ci/engine-tests-baseline*.txt`). By file (OXT-Beyond commits):
  - `tests/_compilertestrunner.livecodescript`, `tests/_inputlib.livecodescript`,
    `tests/_testrunnerbehavior.livecodescript`: the test harness runs on
    Windows and leaves the PC as it was (04b1e23b7).
  - `tests/_testlib.livecodescript`: the same; TestEnsureJVM skips when
    the engine cannot load a Java runtime (0b08270eb).
  - `tests/lcb/stdlib/math.lcb`: regression tests for baseConvert limits
    (8b6a18a52, cc08c7942).
  - `tests/lcb/vm/foreign-invoke.lcb`: on Windows the tests call
    msvcrt.dll; no assumption of an Intel Mac (20913535b, 617f2983b).
  - `tests/lcb/vm/interop-objc.lcb`: no assumption of an Intel Mac
    (617f2983b).
  - `tests/lcs/core/datetime/datetime.livecodescript`: regression test for
    dates before 1970 (3b5d1de4c).
  - `tests/lcs/core/engine/engine.livecodescript`: the engine is 64-bit
    and its version 9.7.1-OXT (87cd2f1fa).
  - `tests/lcs/core/engine/widget.livecodescript`: regression test for
    exporting a widget whose kind is not loaded (860e76d31).
  - `tests/lcs/core/field/pageHeights.livecodescript`: counts pages on
    Linux only with Arial's metrics; runs on Windows (b944fa500, 04b1e23b7).
  - `tests/lcs/core/files/files.livecodescript`: short file paths on a
    folder of the test's own; TextEdit's place on current macOS
    (243bc4903, 413a5e2f0, a0887b567, 04b1e23b7).
  - `tests/lcs/core/files/folders.livecodescript`: regression tests for
    "~" paths (41699b481).
  - `tests/lcs/core/interface/interface.livecodescript`: waits for moves
    to end; names both locs when they differ (1605cd12d, 96debba8f).
  - `tests/lcs/core/interface/snapshot.livecodescript`: two passing
    checks no longer marked broken (0792183a3).
  - `tests/lcs/core/math/errors.livecodescript`: regression test for
    baseConvert above 4,294,967,295 (8b6a18a52).
  - `tests/lcs/core/multimedia/multimedia.livecodescript`: regression test
    for a player in a stack without a window (e1c4c426d).
  - `tests/lcs/core/network/network.livecodescript`: socket tests that
    clean up after themselves and check the right socket (6c92891f3,
    31f09b8d5, ed82a6850, dba7c90fc).
  - `tests/lcs/core/strings/sort.livecodescript`: regression test for
    comparing text by codepoint (db44e1c79).
  - `tests/lcs/liburl/connect.livecodescript`, `tests/lcs/liburl/forms.livecodescript`,
    `tests/lcs/liburl/headers.livecodescript`, `tests/lcs/liburl/status_codes.livecodescript`:
    the libURL tests run on Windows and talk to servers of their own, not
    to public test services (41b422260, ad30ffd3e, aa569e08d).

### README: what this repository is and how it works

Why: LiveCode's README, at the root of Tom Perry's tree, describes
LiveCode, not this repository. It is unchanged in the tags
(`git show tom-perry-1.15:README.md`).

- `README.md`.
