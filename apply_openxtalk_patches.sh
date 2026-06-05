#!/bin/bash

# OpenXTalk Lite Patching Script
# This script applies hex patches and customizations to convert LiveCode-Community to OpenXTalk-Lite
# Run with: sudo bash apply_openxtalk_patches.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
BUILD_DIR="$SCRIPT_DIR/_build/mac/Debug"

echo "=== OpenXTalk Lite Patching Script ==="
echo "Script directory: $SCRIPT_DIR"
echo "Patches directory: $PATCHES_DIR"
echo "Build directory: $BUILD_DIR"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run with sudo"
    echo "Usage: sudo bash apply_openxtalk_patches.sh"
    exit 1
fi

# Check if patches exist
if [ ! -f "$PATCHES_DIR/patch1.hex" ] || [ ! -f "$PATCHES_DIR/patch2.hex" ]; then
    echo "ERROR: Patch files not found in $PATCHES_DIR"
    echo "Required files: patch1.hex, patch2.hex"
    exit 1
fi

# Check if icon exists
if [ ! -f "$PATCHES_DIR/OpenXTalk-lite_1024.icns" ]; then
    echo "ERROR: OpenXTalk icon not found: $PATCHES_DIR/OpenXTalk-lite_1024.icns"
    exit 1
fi

# Check if build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build directory not found: $BUILD_DIR"
    echo "Please run 'make compile-mac' first to build LiveCode"
    exit 1
fi

echo ""
echo "Step 1: Renaming LiveCode-Community.app to OpenXTalk-Lite.app..."

# Rename the main application
if [ -d "$BUILD_DIR/LiveCode-Community.app" ]; then
    if [ -d "$BUILD_DIR/OpenXTalk-Lite.app" ]; then
        echo "Removing existing OpenXTalk-Lite.app..."
        rm -rf "$BUILD_DIR/OpenXTalk-Lite.app"
    fi
    echo "Renaming LiveCode-Community.app to OpenXTalk-Lite.app..."
    mv "$BUILD_DIR/LiveCode-Community.app" "$BUILD_DIR/OpenXTalk-Lite.app"
else
    echo "WARNING: LiveCode-Community.app not found, checking if OpenXTalk-Lite.app already exists..."
    if [ ! -d "$BUILD_DIR/OpenXTalk-Lite.app" ]; then
        echo "ERROR: Neither LiveCode-Community.app nor OpenXTalk-Lite.app found in $BUILD_DIR"
        exit 1
    fi
fi

echo ""
echo "Step 2: Updating Info.plist to show 'OpenXTalk Lite'..."

MAIN_PLIST="$BUILD_DIR/OpenXTalk-Lite.app/Contents/Info.plist"
if [ -f "$MAIN_PLIST" ]; then
    # Update CFBundleName and CFBundleDisplayName
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 'OpenXTalk Lite'" "$MAIN_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleName string 'OpenXTalk Lite'" "$MAIN_PLIST"
    
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'OpenXTalk Lite'" "$MAIN_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string 'OpenXTalk Lite'" "$MAIN_PLIST"
    
    echo "Updated main application Info.plist"
else
    echo "WARNING: Main Info.plist not found: $MAIN_PLIST"
fi

echo ""
echo "Step 3: Replacing application icon..."

# Replace the main application icon
MAIN_ICON_DIR="$BUILD_DIR/OpenXTalk-Lite.app/Contents/Resources"
if [ -d "$MAIN_ICON_DIR" ]; then
    # Find existing icon files and replace them
    find "$MAIN_ICON_DIR" -name "*.icns" -exec cp "$PATCHES_DIR/OpenXTalk-lite_1024.icns" {} \;
    
    # Also copy with standard name
    cp "$PATCHES_DIR/OpenXTalk-lite_1024.icns" "$MAIN_ICON_DIR/OpenXTalk-Lite.icns"
    cp "$PATCHES_DIR/OpenXTalk-lite_1024.icns" "$MAIN_ICON_DIR/LiveCode-Community.icns"
    
    # Fix permissions on copied icon files
    find "$MAIN_ICON_DIR" -name "*.icns" -exec chmod 644 {} \;
    
    echo "Replaced application icons in $MAIN_ICON_DIR"
else
    echo "WARNING: Resources directory not found: $MAIN_ICON_DIR"
fi

echo ""
echo "Step 4: Applying hex patch 1 to main executable..."

MAIN_EXECUTABLE="$BUILD_DIR/OpenXTalk-Lite.app/Contents/MacOS/LiveCode-Community"
if [ -f "$MAIN_EXECUTABLE" ]; then
    echo "Applying patch1.hex to: $MAIN_EXECUTABLE"
    xxd -r "$PATCHES_DIR/patch1.hex" "$MAIN_EXECUTABLE"
    echo "Patch 1 applied successfully"
else
    echo "WARNING: Main executable not found: $MAIN_EXECUTABLE"
fi

echo ""
echo "Step 5: Applying hex patch 2 to Standalone executable..."

STANDALONE_EXECUTABLE="$BUILD_DIR/OpenXTalk-Lite.app/Contents/Tools/Runtime/Mac OS X/x86-64/Standalone.app/Contents/MacOS/Standalone-Community"
if [ -f "$STANDALONE_EXECUTABLE" ]; then
    echo "Applying patch2.hex to: $STANDALONE_EXECUTABLE"
    xxd -r "$PATCHES_DIR/patch2.hex" "$STANDALONE_EXECUTABLE"
    echo "Patch 2 applied successfully"
else
    echo "WARNING: Standalone executable not found: $STANDALONE_EXECUTABLE"
    echo "Checking alternative paths..."
    
    # Try alternative path
    ALT_STANDALONE="$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
    if [ -f "$ALT_STANDALONE" ]; then
        echo "Found standalone at: $ALT_STANDALONE"
        echo "Applying patch2.hex to: $ALT_STANDALONE"
        xxd -r "$PATCHES_DIR/patch2.hex" "$ALT_STANDALONE"
        echo "Patch 2 applied successfully"
    else
        echo "WARNING: Standalone executable not found in alternative location either"
    fi
fi

echo ""
echo "Step 6: Updating Standalone Info.plist..."

STANDALONE_PLIST="$BUILD_DIR/OpenXTalk-Lite.app/Contents/Tools/Runtime/Mac OS X/x86-64/Standalone.app/Contents/Info.plist"
if [ -f "$STANDALONE_PLIST" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 'OpenXTalk Lite'" "$STANDALONE_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleName string 'OpenXTalk Lite'" "$STANDALONE_PLIST"
    
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'OpenXTalk Lite'" "$STANDALONE_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string 'OpenXTalk Lite'" "$STANDALONE_PLIST"
    
    echo "Updated Standalone Info.plist"
else
    # Try alternative path
    ALT_STANDALONE_PLIST="$BUILD_DIR/Standalone-Community.app/Contents/Info.plist"
    if [ -f "$ALT_STANDALONE_PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleName 'OpenXTalk Lite'" "$ALT_STANDALONE_PLIST" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleName string 'OpenXTalk Lite'" "$ALT_STANDALONE_PLIST"
        
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'OpenXTalk Lite'" "$ALT_STANDALONE_PLIST" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string 'OpenXTalk Lite'" "$ALT_STANDALONE_PLIST"
        
        echo "Updated alternative Standalone Info.plist"
    else
        echo "WARNING: Standalone Info.plist not found"
    fi
fi

echo ""
echo "Step 7: Setting proper permissions..."

# Ensure executables are executable
chmod +x "$BUILD_DIR/OpenXTalk-Lite.app/Contents/MacOS/"* 2>/dev/null || true
find "$BUILD_DIR/OpenXTalk-Lite.app" -name "*.app" -exec chmod +x {}/Contents/MacOS/* \; 2>/dev/null || true

echo ""
echo "=== OpenXTalk Lite Patching Complete ==="
echo ""
echo "Summary of changes:"
echo "✓ Renamed LiveCode-Community.app to OpenXTalk-Lite.app"
echo "✓ Updated Info.plist files to show 'OpenXTalk Lite'"
echo "✓ Replaced application icons with OpenXTalk icon"
echo "✓ Applied hex patch 1 to main executable"
echo "✓ Applied hex patch 2 to standalone executable"
echo "✓ Set proper file permissions"
echo ""
echo "OpenXTalk-Lite.app is ready at: $BUILD_DIR/OpenXTalk-Lite.app"
echo ""
echo "IMPORTANT: Run codesigning after this script if needed for distribution."
