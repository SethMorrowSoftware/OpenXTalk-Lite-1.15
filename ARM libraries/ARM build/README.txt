ARM BUILD SYSTEM
================

This folder contains ARM-specific build configurations and scripts
that are kept SEPARATE from the Intel x86_64 build system.

STRUCTURE:
----------

ARM build/
  ├── gyp-modified/        Modified .gyp files for ARM64 builds
  │   └── libcairo.gyp     Cairo with x86 SSE code excluded
  │
  ├── config/              ARM-specific configuration files
  │   ├── arch.gypi        Architecture detection (adds ARM64)
  │   └── mac.gypi         Mac config with ARM64 architecture
  │
  ├── scripts/             Build scripts for ARM libraries
  │   ├── setup-arm-build.sh      Copies modified files to source tree
  │   ├── restore-intel-build.sh  Restores original Intel files
  │   └── build-library.sh        Generic library build script
  │
  └── README.txt           This file

WORKFLOW:
---------

1. Run setup-arm-build.sh to copy ARM-modified gyp files
2. Build ARM libraries
3. Run restore-intel-build.sh to restore Intel build files

This ensures:
- Intel build remains untouched
- ARM modifications are version controlled
- Easy switching between ARM and Intel builds
- Clear separation of concerns

MODIFIED FILES:
---------------

libcairo.gyp:
  - Excludes x86 SSE2/SSSE3/MMX code when building for ARM64
  - Includes ARM NEON assembly files

config/arch.gypi:
  - Adds ARM64 architecture detection

config/mac.gypi:
  - Sets ARCHS to arm64
  - Updates deployment target to macOS 11.0
