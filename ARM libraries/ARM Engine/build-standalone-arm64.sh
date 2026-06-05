#!/bin/bash
set -e

echo "=========================================="
echo "Building LiveCode Standalone Engine for ARM64"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_ENGINE_DIR="$LIVECODE_ROOT/ARM libraries/ARM Engine"

cd "$LIVECODE_ROOT"

echo ""
echo "This will attempt to build the standalone engine kernel"
echo "using all the ARM64 libraries we've built."
echo ""
echo "Build started at: $(date)"
echo ""

# Try building the standalone kernel
echo "=========================================="
echo "Building kernel-standalone..."
echo "=========================================="

xcodebuild -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           2>&1 | tee "$ARM_ENGINE_DIR/build-log.txt"

BUILD_STATUS=$?

echo ""
echo "=========================================="
echo "Build finished at: $(date)"
echo "=========================================="

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✓ BUILD SUCCEEDED!"
    echo ""
    
    # Check what was built
    echo "Checking build output..."
    if [ -f "$BUILD_DIR/Standalone" ]; then
        echo "✓ Standalone engine found!"
        file "$BUILD_DIR/Standalone"
        lipo -info "$BUILD_DIR/Standalone"
        ls -lh "$BUILD_DIR/Standalone"
        
        # Copy to ARM Engine folder
        cp "$BUILD_DIR/Standalone" "$ARM_ENGINE_DIR/"
        echo ""
        echo "✓ Copied to: $ARM_ENGINE_DIR/Standalone"
    fi
    
    if [ -f "$BUILD_DIR/Standalone-Community" ]; then
        echo "✓ Standalone-Community engine found!"
        file "$BUILD_DIR/Standalone-Community"
        lipo -info "$BUILD_DIR/Standalone-Community"
        ls -lh "$BUILD_DIR/Standalone-Community"
        
        cp "$BUILD_DIR/Standalone-Community" "$ARM_ENGINE_DIR/"
        echo ""
        echo "✓ Copied to: $ARM_ENGINE_DIR/Standalone-Community"
    fi
    
    echo ""
    echo "🎉 SUCCESS! ARM64 standalone engine built!"
else
    echo "✗ BUILD FAILED"
    echo ""
    echo "Check the log file for details:"
    echo "$ARM_ENGINE_DIR/build-log.txt"
    echo ""
    echo "Common issues:"
    echo "- Missing dependencies"
    echo "- Toolchain not built"
    echo "- Source code incompatibilities"
    exit 1
fi
