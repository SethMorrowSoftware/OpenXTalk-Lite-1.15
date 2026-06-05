#!/bin/bash
# Generic ARM64 library builder - NO GYP REQUIRED!
# Just uses xcodebuild with ARM64 flags on existing Xcode projects

set -e

# Usage: ./build-library-arm64.sh <library-name> [dependencies...]
# Example: ./build-library-arm64.sh libcairo libz

if [ $# -lt 1 ]; then
    echo "Usage: $0 <library-name> [dependencies...]"
    echo ""
    echo "Examples:"
    echo "  $0 libskia"
    echo "  $0 libcairo libz"
    echo "  $0 libffi"
    echo ""
    exit 1
fi

LIBRARY_NAME="$1"
shift
DEPENDENCIES="$@"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARM_BUILD_DIR="$(dirname "$SCRIPT_DIR")"
LIVECODE_ROOT="$(cd "$ARM_BUILD_DIR/../.." && pwd)"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"

echo "=========================================="
echo "Building $LIBRARY_NAME for ARM64"
echo "=========================================="
echo ""
echo "Library: $LIBRARY_NAME"
echo "Dependencies: ${DEPENDENCIES:-none}"
echo "LiveCode root: $LIVECODE_ROOT"
echo ""

cd "$LIVECODE_ROOT"

# Build dependencies first
if [ -n "$DEPENDENCIES" ]; then
    echo "Building dependencies..."
    for dep in $DEPENDENCIES; do
        echo ""
        echo "Building dependency: $dep"
        xcodebuild -project "build-mac/livecode/thirdparty/$dep/$dep.xcodeproj" \
                   -configuration Release \
                   -arch arm64 \
                   ARCHS=arm64 \
                   ONLY_ACTIVE_ARCH=NO \
                   MACOSX_DEPLOYMENT_TARGET=11.0 \
                   || { echo "ERROR: Failed to build $dep"; exit 1; }
        
        if [ -f "$BUILD_DIR/$dep.a" ]; then
            echo "✓ $dep.a built successfully"
            file "$BUILD_DIR/$dep.a"
        fi
    done
fi

# Build the main library
echo ""
echo "=========================================="
echo "Building main library: $LIBRARY_NAME"
echo "=========================================="

xcodebuild -project "build-mac/livecode/thirdparty/$LIBRARY_NAME/$LIBRARY_NAME.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build $LIBRARY_NAME"; exit 1; }

# Verify output
echo ""
echo "=========================================="
echo "Verifying build..."
echo "=========================================="

if [ -f "$BUILD_DIR/$LIBRARY_NAME.a" ]; then
    echo "✓ $LIBRARY_NAME.a built successfully!"
    echo ""
    echo "Architecture:"
    file "$BUILD_DIR/$LIBRARY_NAME.a"
    echo ""
    echo "Size:"
    ls -lh "$BUILD_DIR/$LIBRARY_NAME.a"
    echo ""
    echo "Location: $BUILD_DIR/$LIBRARY_NAME.a"
else
    echo "✗ ERROR: $LIBRARY_NAME.a not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
