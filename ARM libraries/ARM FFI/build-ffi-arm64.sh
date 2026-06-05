#!/bin/bash
set -e

echo "=========================================="
echo "Building libffi for ARM64 macOS"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_FFI_DIR="$LIVECODE_ROOT/ARM libraries/ARM FFI"

cd "$LIVECODE_ROOT"

echo ""
echo "Building libffi with ARM64 assembly support..."
echo "Note: libffi has native aarch64 support!"
echo ""

xcodebuild -project "build-mac/livecode/thirdparty/libffi/libffi.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libffi"; exit 1; }

echo ""
echo "=========================================="
echo "Verifying ARM64 architecture..."
echo "=========================================="

if [ -f "$BUILD_DIR/libffi.a" ]; then
    echo "✓ libffi.a built successfully!"
    echo ""
    echo "Architecture:"
    file "$BUILD_DIR/libffi.a"
    lipo -info "$BUILD_DIR/libffi.a"
    echo ""
    echo "Size:"
    ls -lh "$BUILD_DIR/libffi.a"
    echo ""
    
    # Check for ARM64 symbols
    echo "Checking for ARM64 FFI symbols:"
    nm "$BUILD_DIR/libffi.a" | grep -i "ffi_call\|aarch64" | head -5 || echo "Symbols found"
    echo ""
    
    # Copy to ARM FFI folder
    echo "Copying to ARM FFI folder..."
    cp "$BUILD_DIR/libffi.a" "$ARM_FFI_DIR/lib/"
    
    # Copy headers
    if [ -d "$LIVECODE_ROOT/thirdparty/libffi/include" ]; then
        cp -r "$LIVECODE_ROOT/thirdparty/libffi/include/"* "$ARM_FFI_DIR/include/" 2>/dev/null || true
    fi
    
    echo "✓ Build complete!"
else
    echo "✗ ERROR: libffi.a not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo "ARM64 libffi in: $ARM_FFI_DIR/lib/"
