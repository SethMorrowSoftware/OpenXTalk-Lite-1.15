#!/bin/bash
# Build simple libraries (no x86 code) for ARM64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVECODE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_LIB_DIR="$SCRIPT_DIR/lib"

echo "=========================================="
echo "Building Simple Libraries for ARM64"
echo "=========================================="
echo ""

# List of simple libraries (no SIMD, no assembly)
LIBRARIES=(
    "libpng:libz"
    "libjpeg:"
    "libgif:"
    "libexpat:"
    "libsqlite:"
    "libpcre:"
    "libxml:"
    "libxslt:libxml"
)

cd "$LIVECODE_ROOT"

for lib_entry in "${LIBRARIES[@]}"; do
    IFS=':' read -r lib deps <<< "$lib_entry"
    
    echo ""
    echo "=========================================="
    echo "Building: $lib"
    if [ -n "$deps" ]; then
        echo "Dependencies: $deps"
    fi
    echo "=========================================="
    
    # Build dependencies first
    if [ -n "$deps" ]; then
        for dep in $(echo $deps | tr ',' ' '); do
            if [ ! -f "$BUILD_DIR/$dep.a" ]; then
                echo "Building dependency: $dep"
                xcodebuild -project "build-mac/livecode/thirdparty/$dep/$dep.xcodeproj" \
                           -configuration Release \
                           -arch arm64 \
                           ARCHS=arm64 \
                           ONLY_ACTIVE_ARCH=NO \
                           MACOSX_DEPLOYMENT_TARGET=11.0 \
                           || { echo "ERROR: Failed to build $dep"; exit 1; }
            fi
        done
    fi
    
    # Build main library
    echo "Building $lib..."
    xcodebuild -project "build-mac/livecode/thirdparty/$lib/$lib.xcodeproj" \
               -configuration Release \
               -arch arm64 \
               ARCHS=arm64 \
               ONLY_ACTIVE_ARCH=NO \
               MACOSX_DEPLOYMENT_TARGET=11.0 \
               || { echo "ERROR: Failed to build $lib"; continue; }
    
    # Verify and copy
    if [ -f "$BUILD_DIR/$lib.a" ]; then
        echo "✓ $lib.a built successfully"
        file "$BUILD_DIR/$lib.a"
        cp "$BUILD_DIR/$lib.a" "$ARM_LIB_DIR/"
    else
        echo "✗ ERROR: $lib.a not found"
    fi
done

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo ""
echo "Built libraries in: $ARM_LIB_DIR"
ls -lh "$ARM_LIB_DIR"
