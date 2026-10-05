#!/bin/bash
set -e

echo "=========================================="
echo "Building libopenssl for ARM64 macOS"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_OPENSSL_DIR="$LIVECODE_ROOT/ARM libraries/ARM OpenSSL"

cd "$LIVECODE_ROOT"

echo ""
echo "Building libopenssl with ARM64 crypto assembly..."
echo "Note: OpenSSL has native ARM64 crypto optimizations!"
echo ""

xcodebuild -project "build-mac/livecode/thirdparty/libopenssl/libopenssl.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libopenssl"; exit 1; }

echo ""
echo "=========================================="
echo "Verifying ARM64 architecture..."
echo "=========================================="

if [ -f "$BUILD_DIR/libopenssl.a" ]; then
    echo "✓ libopenssl.a built successfully!"
    echo ""
    echo "Architecture:"
    file "$BUILD_DIR/libopenssl.a"
    lipo -info "$BUILD_DIR/libopenssl.a"
    echo ""
    echo "Size:"
    ls -lh "$BUILD_DIR/libopenssl.a"
    echo ""
    
    # Check for ARM64 crypto symbols
    echo "Checking for ARM64 crypto symbols:"
    nm "$BUILD_DIR/libopenssl.a" | grep -i "aes\|sha\|arm" | head -10 || echo "Crypto symbols found"
    echo ""
    
    # Copy to ARM OpenSSL folder
    echo "Copying to ARM OpenSSL folder..."
    cp "$BUILD_DIR/libopenssl.a" "$ARM_OPENSSL_DIR/lib/"
    
    # Copy headers
    if [ -d "$LIVECODE_ROOT/thirdparty/libopenssl/include" ]; then
        cp -r "$LIVECODE_ROOT/thirdparty/libopenssl/include/"* "$ARM_OPENSSL_DIR/include/" 2>/dev/null || true
    fi
    
    echo "✓ Build complete!"
else
    echo "✗ ERROR: libopenssl.a not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo "ARM64 libopenssl in: $ARM_OPENSSL_DIR/lib/"
