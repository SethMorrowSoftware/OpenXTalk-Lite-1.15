#!/bin/bash
set -e

echo "=========================================="
echo "Restoring Intel build environment"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARM_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
LIVECODE_ROOT="$(cd "$ARM_BUILD_DIR/../.." && pwd)"

echo "LiveCode root: $LIVECODE_ROOT"
echo "ARM build dir: $ARM_BUILD_DIR"
echo ""

# Restore original files from backups
echo "Restoring original files..."

if [ -f "$ARM_BUILD_DIR/backups/libcairo.gyp.original" ]; then
    cp "$ARM_BUILD_DIR/backups/libcairo.gyp.original" \
       "$LIVECODE_ROOT/thirdparty/libcairo/libcairo.gyp"
    echo "  ✓ Restored libcairo.gyp"
else
    echo "  ✗ No backup found for libcairo.gyp"
    exit 1
fi

echo ""
echo "=========================================="
echo "Intel build environment restored!"
echo "=========================================="
echo ""
echo "Restored files:"
echo "  - thirdparty/libcairo/libcairo.gyp"
echo ""
echo "To setup ARM build again, run: ./setup-arm-build.sh"
