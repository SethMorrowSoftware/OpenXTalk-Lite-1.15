#!/bin/bash
set -e

echo "=========================================="
echo "Building LiveCode Standalone for ARM64"
echo "Using Python 3 wrapper (no Python 2 needed!)"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_ENGINE_DIR="$LIVECODE_ROOT/ARM libraries/ARM Engine"

cd "$LIVECODE_ROOT"

# Add util directory to PATH so 'python' wrapper is found first
export PATH="$LIVECODE_ROOT/util:$PATH"

echo ""
echo "Python setup:"
echo "  which python: $(which python)"
echo "  python version: $(python --version 2>&1)"
echo ""

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR/libkernel-standalone.a" "$BUILD_DIR/Standalone-Community"* 2>/dev/null || true
rm -rf _cache/mac/Release/minimal_icu_data.build/ 2>/dev/null || true

echo ""
echo "Starting ARM64 build..."
echo "Build started at: $(date)"
echo ""

xcodebuild -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           2>&1 | tee "$ARM_ENGINE_DIR/build-py3.log"

BUILD_STATUS=$?

echo ""
echo "=========================================="
echo "Build finished at: $(date)"
echo "Build status: $BUILD_STATUS"
echo "=========================================="
echo ""

# Check what was built
echo "Checking build output..."
echo ""

if [ -f "$BUILD_DIR/libkernel-standalone.a" ]; then
    echo "✓ libkernel-standalone.a"
    lipo -info "$BUILD_DIR/libkernel-standalone.a"
    ls -lh "$BUILD_DIR/libkernel-standalone.a"
    echo ""
fi

if [ -f "$BUILD_DIR/Standalone-Community" ]; then
    echo "✓ Standalone-Community executable"
    file "$BUILD_DIR/Standalone-Community"
    lipo -info "$BUILD_DIR/Standalone-Community"
    ls -lh "$BUILD_DIR/Standalone-Community"
    echo ""
fi

if [ -d "$BUILD_DIR/Standalone-Community.app" ]; then
    echo "✓ Standalone-Community.app bundle"
    if [ -f "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community" ]; then
        echo "✓ App executable found!"
        file "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        lipo -info "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        ls -lh "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        
        echo ""
        echo "Copying to ARM Engine folder..."
        cp -R "$BUILD_DIR/Standalone-Community.app" "$ARM_ENGINE_DIR/"
        echo "✓ Copied to: $ARM_ENGINE_DIR/Standalone-Community.app"
    fi
    echo ""
fi

if [ $BUILD_STATUS -eq 0 ]; then
    echo "🎉 BUILD SUCCEEDED! 🎉"
    echo ""
    echo "ARM64 LiveCode Standalone Engine is ready!"
    echo "No Python 2 required - built with Python 3!"
else
    echo "✗ Build failed with status: $BUILD_STATUS"
    echo "Check log: $ARM_ENGINE_DIR/build-py3.log"
    exit $BUILD_STATUS
fi
