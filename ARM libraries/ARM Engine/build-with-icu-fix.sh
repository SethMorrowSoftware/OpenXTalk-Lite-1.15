#!/bin/bash
set -e

echo "=========================================="
echo "Building Standalone with ICU Fix"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_ENGINE_DIR="$LIVECODE_ROOT/ARM libraries/ARM Engine"

cd "$LIVECODE_ROOT"

echo ""
echo "Strategy: Build twice"
echo "1. First build will fail on ICU but generate the script"
echo "2. Fix the script"
echo "3. Second build will succeed"
echo ""

# First build attempt (will fail on ICU but generate script)
echo "First build attempt (generating scripts)..."
xcodebuild -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           2>&1 | tail -20 || true

echo ""
echo "Fixing ICU script..."
SCRIPT_FILE="_cache/mac/Release/minimal_icu_data.build/Script-2424BE3698E0986667A18F78.sh"

if [ -f "$SCRIPT_FILE" ]; then
    echo "Found script, fixing..."
    sed -i '' 's/exec python /exec python2 /g' "$SCRIPT_FILE"
    echo "✓ Script fixed"
    cat "$SCRIPT_FILE"
else
    echo "✗ Script not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Second build attempt (should succeed)..."
echo "=========================================="

xcodebuild -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           2>&1 | tee "$ARM_ENGINE_DIR/build-final.log"

BUILD_STATUS=$?

echo ""
echo "=========================================="
echo "Build Status: $BUILD_STATUS"
echo "=========================================="
echo ""

# Check results
if [ -f "$BUILD_DIR/libkernel-standalone.a" ]; then
    echo "✓ libkernel-standalone.a"
    lipo -info "$BUILD_DIR/libkernel-standalone.a"
fi

if [ -f "$BUILD_DIR/Standalone-Community" ]; then
    echo "✓ Standalone-Community executable"
    file "$BUILD_DIR/Standalone-Community"
    lipo -info "$BUILD_DIR/Standalone-Community"
fi

if [ -d "$BUILD_DIR/Standalone-Community.app" ]; then
    echo "✓ Standalone-Community.app"
    if [ -f "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community" ]; then
        echo "✓ App executable"
        file "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        lipo -info "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        
        # Copy to ARM Engine folder
        echo ""
        echo "Copying to ARM Engine folder..."
        cp -R "$BUILD_DIR/Standalone-Community.app" "$ARM_ENGINE_DIR/"
        echo "✓ Copied!"
    fi
fi

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "🎉 BUILD SUCCEEDED!"
else
    echo ""
    echo "✗ Build failed with status: $BUILD_STATUS"
fi
