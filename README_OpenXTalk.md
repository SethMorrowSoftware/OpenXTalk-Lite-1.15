# OpenXTalk Lite Build System

This directory contains a comprehensive system for building OpenXTalk Lite from the LiveCode Community source code. The system applies hex patches, replaces icons, renames the application, and updates Info.plist files to create a customized OpenXTalk Lite distribution.

## Quick Start

### Option 1: Complete Build (Recommended)
```bash
make all-openxtalk
```
This will integrate the icon, build LiveCode, and apply all OpenXTalk customizations.

### Option 2: Step-by-Step Build
```bash
# 1. Integrate OpenXTalk icon into source tree (run once)
make openxtalk-integrate-icon

# 2. Build LiveCode
make compile-mac

# 3. Apply OpenXTalk patches (requires sudo)
make openxtalk-patch
```

### Option 3: Using Build Script
```bash
./build_openxtalk.sh
```

## Files and Components

### Core Scripts
- `apply_openxtalk_patches.sh` - Main patching script (requires sudo)
- `build_openxtalk.sh` - Complete build script with patching
- `integrate_openxtalk_icon.sh` - Icon replacement script

### Patch Files (in `patches/` directory)
- `patch1.hex` - Hex patch for main LiveCode-Community executable
- `patch2.hex` - Hex patch for Standalone-Community executable  
- `OpenXTalk-lite_1024.icns` - OpenXTalk application icon

### Makefile Targets
- `all-openxtalk` - Complete OpenXTalk build process
- `openxtalk-build` - Build using build script
- `openxtalk-patch` - Apply patches only (requires sudo)
- `openxtalk-integrate-icon` - Replace icons in source tree
- `clean-openxtalk` - Clean OpenXTalk build artifacts

## What the System Does

### 1. Application Renaming
- Renames `LiveCode-Community.app` to `OpenXTalk-Lite.app`
- Updates all references and paths accordingly

### 2. Info.plist Updates
- Changes `CFBundleName` to "OpenXTalk Lite"
- Changes `CFBundleDisplayName` to "OpenXTalk Lite"
- Updates both main app and standalone runtime Info.plist files

### 3. Icon Replacement
- Replaces all LiveCode icons with OpenXTalk icon
- Updates both source tree and built application
- Handles multiple icon locations and formats

### 4. Hex Patching
- Applies `patch1.hex` to main executable: `OpenXTalk-Lite.app/Contents/MacOS/LiveCode-Community`
- Applies `patch2.hex` to standalone runtime: `OpenXTalk-Lite.app/Contents/Tools/Runtime/Mac OS X/x86-64/Standalone.app/Contents/MacOS/Standalone-Community`
- Patches are applied before any codesigning stage

### 5. Permission Management
- Sets proper executable permissions
- Handles file ownership correctly

## Build Output

After successful build, you'll find:
```
_build/mac/Debug/OpenXTalk-Lite.app/
├── Contents/
│   ├── Info.plist (updated with OpenXTalk Lite branding)
│   ├── MacOS/
│   │   └── LiveCode-Community (hex patched)
│   ├── Resources/
│   │   └── *.icns (replaced with OpenXTalk icon)
│   └── Tools/
│       └── Runtime/
│           └── Mac OS X/
│               └── x86-64/
│                   └── Standalone.app/
│                       ├── Contents/
│                       │   ├── Info.plist (updated)
│                       │   └── MacOS/
│                       │       └── Standalone-Community (hex patched)
```

## Prerequisites

### Required Tools
- `xxd` - For applying hex patches (standard on macOS)
- `PlistBuddy` - For updating Info.plist files (standard on macOS)
- `sudo` access - Required for patching executables

### Required Files
Before running the build, ensure these files exist:
- `/Users/user/Desktop/patch/patch1.hex`
- `/Users/user/Desktop/patch/patch2.hex`  
- `/Users/user/Desktop/OpenXTalk-lite_1024.icns`

These files are automatically copied to the `patches/` directory during setup.

## Usage Examples

### Build OpenXTalk Lite from scratch:
```bash
cd /Users/user/Cascade/Livecode-Community-9.6.3/livecode
make all-openxtalk
```

### Apply patches to existing build:
```bash
sudo ./apply_openxtalk_patches.sh
```

### Clean and rebuild:
```bash
make clean-openxtalk
make all-openxtalk
```

### Run the built application:
```bash
open _build/mac/Debug/OpenXTalk-Lite.app
```

## Codesigning (Optional)

If you plan to distribute OpenXTalk Lite, you may need to codesign it:

```bash
# Sign with your Developer ID
codesign --force --deep --sign "Your Developer ID Application" _build/mac/Debug/OpenXTalk-Lite.app

# Or for local testing only
codesign --force --deep --sign - _build/mac/Debug/OpenXTalk-Lite.app
```

**Important:** Run codesigning AFTER applying the OpenXTalk patches, as the patches modify the executables.

## Troubleshooting

### Permission Denied Errors
- Ensure you run patching commands with `sudo`
- Check that patch files have correct permissions

### Patch Files Not Found
- Verify patch files exist in `patches/` directory
- Run the setup to copy files from Desktop if needed

### Build Failures
- Ensure LiveCode dependencies are installed (Java, ICU, etc.)
- Check that the base LiveCode build works with `make compile-mac`

### Icon Not Applied
- Run `make openxtalk-integrate-icon` to replace icons in source tree
- Rebuild after icon integration

## File Structure

```
livecode/
├── patches/                          # Patch files directory
│   ├── patch1.hex                   # Main executable patch
│   ├── patch2.hex                   # Standalone executable patch
│   └── OpenXTalk-lite_1024.icns     # OpenXTalk icon
├── apply_openxtalk_patches.sh       # Main patching script
├── build_openxtalk.sh               # Complete build script
├── integrate_openxtalk_icon.sh      # Icon integration script
├── Makefile                         # Updated with OpenXTalk targets
└── README_OpenXTalk.md              # This documentation
```

## Integration with Existing Build System

The OpenXTalk system is designed to work alongside the existing LiveCode build system:

- All original Makefile targets remain unchanged
- OpenXTalk targets are additive, not replacing existing functionality
- Can build both LiveCode and OpenXTalk from the same source tree
- Patches are applied post-build, preserving original source code

This allows you to maintain both LiveCode Community and OpenXTalk Lite builds from the same codebase.
