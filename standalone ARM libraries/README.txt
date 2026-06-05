========================================
LiveCode ARM64 (Apple Silicon) Libraries
========================================

Date Created: November 9, 2025
Architecture: ARM64 (Apple Silicon native)
macOS Version: 11.0+

This directory contains ALL the ARM64 libraries and externals needed
to build LiveCode for Apple Silicon Macs.

IMPORTANT: Keep this directory safe! These libraries took significant
effort to build and configure for ARM64. If the _build folder gets
wiped, you can restore from here.

CONTENTS:
=========

1. STATIC LIBRARIES (.a files)
-------------------------------
All third-party libraries compiled natively for ARM64:

Core Libraries:
- libffi.a (59 KB) - Foreign Function Interface with ARM64 assembly
- libicu*.a (34 MB total) - ICU 58.2 internationalization
- libskia*.a (84 MB + 42 KB opts) - Skia graphics with NEON
- libcairo.a (8.2 MB) - Cairo 2D graphics
- libssl.a, libcrypto.a (4.6 MB) - OpenSSL 1.1.1w
- libcustomssl.a, libcustomcrypto.a - OpenSSL (custom names)
- libz.a (102 KB) - zlib compression
- libpng.a, libjpeg.a, libgif.a - Image formats
- libxml.a, libxslt.a - XML processing
- libpcre.a - Regular expressions
- libsqlite.a - SQLite database
- libpixman_x86_stub.a - Stub for Cairo x86 compatibility

2. EXTERNALS (Bundles)
-----------------------
LiveCode external bundles for standalones:

Externals/:
- revbrowser.bundle (156 KB) - Web browser integration
- revdb.bundle (110 KB) - Database connectivity
- revxml.bundle (1.8 MB) - XML parsing
- revspeech.bundle (65 KB) - Text-to-speech
- revzip.bundle - ZIP compression

Database Drivers/:
- dbsqlite.bundle - SQLite driver (most commonly used)
- dbmysql.bundle - MySQL driver (requires MySQL client lib)

3. SUPPORT FILES
----------------
Runtime support libraries:

Support/:
- revsecurity.dylib (2.4 MB) - SSL/TLS security
- revpdfprinter.bundle (1.3 MB) - PDF generation

USAGE:
======

To Restore Libraries After Clean Build:
----------------------------------------
1. Copy all .a files to: prebuilt/lib/mac/
2. Copy all .a files to: ARM-libraries-arm64/
3. Run the build scripts as normal

To Deploy Externals with Standalone:
-------------------------------------
Copy to your Standalone.app:
- Externals/ → Standalone.app/Contents/Externals/
- Database Drivers/ → Standalone.app/Contents/Externals/Database Drivers/
- Support/ → Standalone.app/Contents/Support/

BUILD INFORMATION:
==================

All libraries were built with:
- Compiler: clang (Xcode 15.3)
- Architecture: arm64
- Deployment Target: macOS 11.0
- Optimization: -O3
- SDK: macOS 12.1

Library Sources:
- libffi 3.4.4 (built from source)
- ICU 58.2 (built from source)
- OpenSSL 1.1.1w (built from source)
- zlib 1.3.1 (built from source)
- Skia (built with NEON optimizations)
- Cairo (built with ARM support)

VERIFICATION:
=============

All libraries verified as ARM64:
$ lipo -info *.a
Non-fat file: ... is architecture: arm64

All externals verified as ARM64:
$ lipo -info Externals/*.bundle/Contents/MacOS/*
Non-fat file: ... is architecture: arm64

BACKUP RECOMMENDATION:
======================

This directory should be:
1. Backed up regularly
2. Version controlled (if possible)
3. Kept outside the _build directory
4. Archived for future use

If you need to rebuild from scratch, refer to:
- build-arm64-standalone.sh
- build-arm64-development.sh
- build-arm64-externals.sh
- build-openssl-arm64.sh
- build-zlib-arm64.sh
- build-skia-arm64-opts.sh

NOTES:
======

- MySQL and PostgreSQL drivers require their respective client
  libraries to be built for ARM64 (not included)
- All core functionality is present and working
- These libraries are compatible with macOS 11.0 and later
- No Rosetta translation needed - pure ARM64 code

For questions or issues, refer to the build logs and scripts
in the main livecode directory.

========================================
Built with ❤️ for Apple Silicon
========================================
