#!/bin/bash
set -e

echo "=========================================="
echo "Building Font Libraries for ARM64"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_FONT_DIR="$LIVECODE_ROOT/ARM libraries/ARM Font Libraries"

cd "$LIVECODE_ROOT"

# Build libfreetype (font rendering)
echo ""
echo "Building libfreetype..."
xcodebuild -project "build-mac/livecode/thirdparty/libfreetype/libfreetype.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libfreetype"; exit 1; }

if [ -f "$BUILD_DIR/libfreetype.a" ]; then
    echo "✓ libfreetype.a built successfully"
    file "$BUILD_DIR/libfreetype.a"
    lipo -info "$BUILD_DIR/libfreetype.a"
    cp "$BUILD_DIR/libfreetype.a" "$ARM_FONT_DIR/lib/"
fi

# Build libharfbuzz (text shaping) - depends on libfreetype
echo ""
echo "Building libharfbuzz..."
xcodebuild -project "build-mac/livecode/thirdparty/libharfbuzz/libharfbuzz.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libharfbuzz"; exit 1; }

if [ -f "$BUILD_DIR/libharfbuzz.a" ]; then
    echo "✓ libharfbuzz.a built successfully"
    file "$BUILD_DIR/libharfbuzz.a"
    lipo -info "$BUILD_DIR/libharfbuzz.a"
    cp "$BUILD_DIR/libharfbuzz.a" "$ARM_FONT_DIR/lib/"
fi

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo "Font libraries in: $ARM_FONT_DIR/lib/"
ls -lh "$ARM_FONT_DIR/lib/"
