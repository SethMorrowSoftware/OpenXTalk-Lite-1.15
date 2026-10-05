#!/bin/bash

# Patch macOS 12.1 SDK to work with Xcode 15.3+
# This script modifies the SDK version to bypass Xcode's minimum SDK check

set -e

SDK_PATH="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.1.sdk"
PLIST_FILE="$SDK_PATH/SDKSettings.plist"

echo "=== Patching macOS 12.1 SDK for Xcode 15.3+ ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: This script must be run as root"
    echo "Please run: sudo ./patch_installed_SDK.sh"
    exit 1
fi

# Check if SDK exists
if [ ! -d "$SDK_PATH" ]; then
    echo "ERROR: macOS 12.1 SDK not found at: $SDK_PATH"
    echo "Please install the SDK first."
    exit 1
fi

# Check if SDKSettings.plist exists
if [ ! -f "$PLIST_FILE" ]; then
    echo "ERROR: SDKSettings.plist not found at: $PLIST_FILE"
    exit 1
fi

# Backup the original file
BACKUP_FILE="$PLIST_FILE.backup"
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Creating backup: $BACKUP_FILE"
    cp "$PLIST_FILE" "$BACKUP_FILE"
    echo "✓ Backup created"
else
    echo "✓ Backup already exists: $BACKUP_FILE"
fi

# Show current version
echo ""
echo "Current SDK version:"
plutil -extract Version xml1 -o - "$PLIST_FILE" 2>/dev/null | grep -A1 "<key>Version</key>" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' || echo "Unable to read version"

# Patch the version from 12.1 to 13.0
echo ""
echo "Patching SDK version from 12.1 to 13.0..."
plutil -replace Version -string "13.0" "$PLIST_FILE"

if [ $? -eq 0 ]; then
    echo "✓ SDK version patched successfully"
else
    echo "ERROR: Failed to patch SDK version"
    exit 1
fi

# Verify the change
echo ""
echo "New SDK version:"
plutil -extract Version xml1 -o - "$PLIST_FILE" 2>/dev/null | grep -A1 "<key>Version</key>" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/' || echo "Unable to read version"

# Test if Xcode now recognizes the SDK
echo ""
echo "Testing if Xcode recognizes the SDK..."
if xcodebuild -showsdks 2>&1 | grep -q "macosx12.1"; then
    echo "✓ SUCCESS: Xcode now recognizes macOS 12.1 SDK"
    echo ""
    echo "You can now run your build script:"
    echo "  ./build_openxtalk_no_patches.sh"
else
    echo "⚠ WARNING: Xcode may not recognize the SDK yet"
    echo "Try restarting Xcode or running: xcode-select --reset"
fi

echo ""
echo "=== Patch Complete ==="
echo ""
echo "Note: To restore the original SDK version, run:"
echo "  sudo cp $BACKUP_FILE $PLIST_FILE"
