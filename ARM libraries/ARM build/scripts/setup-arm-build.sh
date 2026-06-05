#!/bin/bash
set -e

echo "=========================================="
echo "Setting up ARM build environment"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARM_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
LIVECODE_ROOT="$(cd "$ARM_BUILD_DIR/../.." && pwd)"

echo "LiveCode root: $LIVECODE_ROOT"
echo "ARM build dir: $ARM_BUILD_DIR"
echo ""

# Backup original files
echo "Creating backups of original files..."
mkdir -p "$ARM_BUILD_DIR/backups"

if [ ! -f "$ARM_BUILD_DIR/backups/libcairo.gyp.original" ]; then
    cp "$LIVECODE_ROOT/thirdparty/libcairo/libcairo.gyp" \
       "$ARM_BUILD_DIR/backups/libcairo.gyp.original"
    echo "  ✓ Backed up libcairo.gyp"
else
    echo "  - libcairo.gyp already backed up"
fi

# Copy ARM-modified gyp files
echo ""
echo "Installing ARM-modified gyp files..."

cp "$ARM_BUILD_DIR/gyp-modified/libcairo.gyp" \
   "$LIVECODE_ROOT/thirdparty/libcairo/libcairo.gyp"
echo "  ✓ Installed ARM libcairo.gyp"

echo ""
echo "=========================================="
echo "ARM build environment ready!"
echo "=========================================="
echo ""
echo "Modified files:"
echo "  - thirdparty/libcairo/libcairo.gyp"
echo ""
echo "Python configuration:"
echo "  - ARM builds use: Python 3 (system python3)"
echo "  - Intel builds use: Python 2.7.18 (thirdparty/python2)"
echo ""
echo "Next steps:"
echo "  1. Configure build: ./config-arm-build.sh"
echo "  2. Build libraries: cd '../ARM Cairo' && ./build-cairo-arm64.sh"
echo ""
echo "To restore Intel build, run: ./restore-intel-build.sh"
