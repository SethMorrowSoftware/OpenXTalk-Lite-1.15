#!/bin/bash
set -e

echo "=========================================="
echo "Building libskia for ARM64 macOS"
echo "=========================================="

# Configuration
LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_SKIA_DIR="$LIVECODE_ROOT/ARM libraries/ARM Skia"
LOG_DIR="$ARM_SKIA_DIR/build-logs"

# Create log file
LOG_FILE="$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Build started at: $(date)"
echo "Log file: $LOG_FILE"
echo ""

cd "$LIVECODE_ROOT"

# Step 1: Build dependencies
echo "=========================================="
echo "STEP 1: Building libskia dependencies..."
echo "=========================================="
for lib in libgif libexpat libjpeg libpng libz; do
    echo ""
    echo "Building $lib for ARM64..."
    xcodebuild -project "build-mac/livecode/thirdparty/$lib/$lib.xcodeproj" \
               -configuration Release \
               -arch arm64 \
               ARCHS=arm64 \
               ONLY_ACTIVE_ARCH=NO \
               MACOSX_DEPLOYMENT_TARGET=11.0 \
               || { echo "ERROR: Failed to build $lib"; exit 1; }
    
    # Verify architecture
    if [ -f "$BUILD_DIR/lib$lib.a" ]; then
        echo "Verifying $lib architecture:"
        file "$BUILD_DIR/lib$lib.a"
    fi
done

echo ""
echo "=========================================="
echo "STEP 2: Building libskia optimization targets..."
echo "=========================================="

# Build libskia_opt_none (fallback, no SIMD)
echo ""
echo "Building libskia_opt_none..."
xcodebuild -project "build-mac/livecode/thirdparty/libskia/libskia.xcodeproj" \
           -configuration Release \
           -target libskia_opt_none \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libskia_opt_none"; exit 1; }

# Build libskia_opt_arm (ARM NEON optimizations)
echo ""
echo "Building libskia_opt_arm (ARM NEON)..."
xcodebuild -project "build-mac/livecode/thirdparty/libskia/libskia.xcodeproj" \
           -configuration Release \
           -target libskia_opt_arm \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libskia_opt_arm"; exit 1; }

echo ""
echo "=========================================="
echo "STEP 3: Building main libskia..."
echo "=========================================="
xcodebuild -project "build-mac/livecode/thirdparty/libskia/libskia.xcodeproj" \
           -configuration Release \
           -target libskia \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "ERROR: Failed to build libskia"; exit 1; }

echo ""
echo "=========================================="
echo "STEP 4: Verifying ARM64 architecture..."
echo "=========================================="

if [ -f "$BUILD_DIR/libskia.a" ]; then
    echo "libskia.a:"
    file "$BUILD_DIR/libskia.a"
    echo ""
fi

if [ -f "$BUILD_DIR/libskia_opt_arm.a" ]; then
    echo "libskia_opt_arm.a:"
    file "$BUILD_DIR/libskia_opt_arm.a"
    echo ""
fi

if [ -f "$BUILD_DIR/libskia_opt_none.a" ]; then
    echo "libskia_opt_none.a:"
    file "$BUILD_DIR/libskia_opt_none.a"
    echo ""
fi

# Check for ARM NEON symbols
if [ -f "$BUILD_DIR/libskia_opt_arm.a" ]; then
    echo "Checking for ARM NEON optimizations:"
    nm "$BUILD_DIR/libskia_opt_arm.a" | grep -i "neon\|arm" | head -10 || echo "No NEON symbols found in nm output"
    echo ""
fi

echo ""
echo "=========================================="
echo "STEP 5: Copying to ARM Skia folder..."
echo "=========================================="

# Copy libraries
echo "Copying libraries..."
cp "$BUILD_DIR"/libskia*.a "$ARM_SKIA_DIR/lib/" || { echo "ERROR: Failed to copy libraries"; exit 1; }

# Copy headers
echo "Copying headers..."
cp -r "$LIVECODE_ROOT/thirdparty/libskia/include/"* "$ARM_SKIA_DIR/include/" || { echo "ERROR: Failed to copy headers"; exit 1; }

# Copy dependency libraries
echo "Copying dependency libraries..."
for lib in libgif libexpat libjpeg libpng libz; do
    if [ -f "$BUILD_DIR/lib$lib.a" ]; then
        cp "$BUILD_DIR/lib$lib.a" "$ARM_SKIA_DIR/lib/"
    fi
done

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo "Build finished at: $(date)"
echo ""
echo "ARM64 libraries in: $ARM_SKIA_DIR/lib/"
ls -lh "$ARM_SKIA_DIR/lib/"
echo ""
echo "Headers in: $ARM_SKIA_DIR/include/"
echo ""
echo "Full log saved to: $LOG_FILE"
