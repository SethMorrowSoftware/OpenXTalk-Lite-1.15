#!/bin/bash
set -e

echo "=========================================="
echo "Building libcairo for ARM64 macOS"
echo "=========================================="

# Configuration
LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_CAIRO_DIR="$LIVECODE_ROOT/ARM libraries/ARM Cairo"
LOG_DIR="$ARM_CAIRO_DIR/build-logs"

# Create log file
LOG_FILE="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Build started at: $(date)"
echo "Log file: $LOG_FILE"
echo ""

cd "$LIVECODE_ROOT"

# Step 1: Build dependencies
echo "=========================================="
echo "STEP 1: Building libcairo dependencies..."
echo "=========================================="
echo ""
echo "Building libz for ARM64..."
xcodebuild -project "build-mac/livecode/thirdparty/libz/libz.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libz"; exit 1; }

# Verify architecture
if [ -f "$BUILD_DIR/libz.a" ]; then
    echo "Verifying libz architecture:"
    file "$BUILD_DIR/libz.a"
fi

echo ""
echo "=========================================="
echo "STEP 2: Building libcairo..."
echo "=========================================="
echo ""
echo "Building libcairo with ARM NEON optimizations..."
xcodebuild -project "build-mac/livecode/thirdparty/libcairo/libcairo.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libcairo"; exit 1; }

echo ""
echo "=========================================="
echo "STEP 3: Verifying ARM64 architecture..."
echo "=========================================="

if [ -f "$BUILD_DIR/libcairo.a" ]; then
    echo "libcairo.a:"
    file "$BUILD_DIR/libcairo.a"
    echo ""
    
    # Check size
    echo "Library size:"
    ls -lh "$BUILD_DIR/libcairo.a"
    echo ""
    
    # Check for ARM symbols
    echo "Checking for ARM NEON symbols:"
    nm "$BUILD_DIR/libcairo.a" | grep -i "pixman_arm\|neon" | head -10 || echo "No ARM symbols found in nm output"
    echo ""
fi

echo ""
echo "=========================================="
echo "STEP 4: Copying to ARM Cairo folder..."
echo "=========================================="

# Copy libraries
echo "Copying libraries..."
cp "$BUILD_DIR/libcairo.a" "$ARM_CAIRO_DIR/lib/" || { echo "ERROR: Failed to copy libcairo.a"; exit 1; }

# Copy dependency
if [ -f "$BUILD_DIR/libz.a" ]; then
    cp "$BUILD_DIR/libz.a" "$ARM_CAIRO_DIR/lib/"
fi

# Copy headers
echo "Copying headers..."
mkdir -p "$ARM_CAIRO_DIR/include/cairo"
cp "$LIVECODE_ROOT/thirdparty/libcairo/src/cairo.h" "$ARM_CAIRO_DIR/include/cairo/" || { echo "ERROR: Failed to copy cairo.h"; exit 1; }
cp "$LIVECODE_ROOT/thirdparty/libcairo/src/cairo-features.h" "$ARM_CAIRO_DIR/include/cairo/" 2>/dev/null || true
cp "$LIVECODE_ROOT/thirdparty/libcairo/cairo-version.h" "$ARM_CAIRO_DIR/include/cairo/" 2>/dev/null || true

# Copy pixman headers (part of cairo)
for header in "$LIVECODE_ROOT/thirdparty/libcairo/src/pixman"*.h; do
    if [ -f "$header" ]; then
        cp "$header" "$ARM_CAIRO_DIR/include/cairo/"
    fi
done

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo "Build finished at: $(date)"
echo ""
echo "ARM64 libraries in: $ARM_CAIRO_DIR/lib/"
ls -lh "$ARM_CAIRO_DIR/lib/"
echo ""
echo "Headers in: $ARM_CAIRO_DIR/include/cairo/"
echo ""
echo "Full log saved to: $LOG_FILE"
