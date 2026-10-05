# Python 2.7.18 Backup Package

This directory contains a complete backup of Python 2.7.18 source code for the OpenXTalk build system.

## Purpose

Python 2.7 reached end-of-life on January 1, 2020, and official downloads may no longer be available. This backup ensures that the OpenXTalk build system can continue to function even if Python 2.7 becomes unavailable online.

## Contents

- `src/Python-2.7.18/` - Complete Python 2.7.18 source code
- `install-local.sh` - Script to build and install Python 2.7.18 locally

## Usage

If you need to install Python 2.7.18 locally (for example, if Homebrew installation fails):

```bash
cd thirdparty/python2
./install-local.sh
```

This will build Python 2.7.18 from source and install it to a local directory that can be used by the build system.

## Compatibility

This backup was created for macOS and should work with the OpenXTalk build system requirements. The build system specifically requires Python 2.7 for the configuration scripts (`config.py`).

## Maintenance

This backup should be kept up-to-date if the build system requirements change. The current version (2.7.18) was the last stable release of Python 2.7.
