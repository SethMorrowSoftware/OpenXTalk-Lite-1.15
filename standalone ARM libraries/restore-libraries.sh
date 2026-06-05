#!/bin/bash
# Restore ARM64 libraries from this archive to the build system

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVECODE_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Restoring ARM64 Libraries"
echo "========================================="
echo ""
echo "From: $SCRIPT_DIR"
echo "To:   $LIVECODE_ROOT"
echo ""

# Make sure we're in the right place
if [ ! -f "$LIVECODE_ROOT/build-arm64-standalone.sh" ]; then
    echo "Error: Cannot find LiveCode root directory!"
    echo "Expected to find build-arm64-standalone.sh in parent directory"
    exit 1
fi

# Create target directories if they don't exist
mkdir -p "$LIVECODE_ROOT/ARM-libraries-arm64"
mkdir -p "$LIVECODE_ROOT/prebuilt/lib/mac"

# Make libraries writable
echo "Making target directories writable..."
chmod -R 755 "$LIVECODE_ROOT/ARM-libraries-arm64" 2>/dev/null || true
chmod -R 755 "$LIVECODE_ROOT/prebuilt/lib/mac" 2>/dev/null || true

# Copy static libraries
echo ""
echo "Copying static libraries..."
cp -v "$SCRIPT_DIR"/*.a "$LIVECODE_ROOT/ARM-libraries-arm64/"
cp -v "$SCRIPT_DIR"/*.a "$LIVECODE_ROOT/prebuilt/lib/mac/"

echo ""
echo "✓ Static libraries restored"
echo ""
echo "Libraries are now available in:"
echo "  - ARM-libraries-arm64/"
echo "  - prebuilt/lib/mac/"
echo ""
echo "Externals and Support files are in:"
echo "  - standalone ARM libraries/Externals/"
echo "  - standalone ARM libraries/Support/"
echo "  - standalone ARM libraries/Database Drivers/"
echo ""
echo "These can be copied to your built .app bundles as needed."
echo ""
echo "========================================="
echo "✓ Restore Complete!"
echo "========================================="
