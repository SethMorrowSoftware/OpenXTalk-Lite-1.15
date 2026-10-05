#!/bin/bash
set -e

echo "=========================================="
echo "Building LiveCode Standalone for ARM64"
echo "Final Build with ICU Fix"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_ENGINE_DIR="$LIVECODE_ROOT/ARM libraries/ARM Engine"

cd "$LIVECODE_ROOT"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR/libkernel-standalone.a" "$BUILD_DIR/Standalone-Community"* 2>/dev/null || true

echo ""
echo "Starting ARM64 build..."
echo "Build will fail on ICU, then we'll fix and retry"
echo ""

# Build - will fail on ICU but that's expected
xcodebuild -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           2>&1 | grep -E "BUILD|PhaseScriptExecution|error|warning" | tail -30 || true

# Fix the ICU script
echo ""
echo "=========================================="
echo "Fixing ICU Python script..."
echo "=========================================="

SCRIPT_FILE="_cache/mac/Release/minimal_icu_data.build/Script-2424BE3698E0986667A18F78.sh"

if [ -f "$SCRIPT_FILE" ]; then
    echo "Found script at: $SCRIPT_FILE"
    echo "Original content:"
    head -3 "$SCRIPT_FILE"
    
    # Fix: Replace 'exec python' with 'exec python2'
    sed -i '' 's/exec python /exec python2 /g' "$SCRIPT_FILE"
    
    echo ""
    echo "Fixed content:"
    head -3 "$SCRIPT_FILE"
    echo "✓ Script fixed!"
else
    echo "✗ Script not found - build may not have reached ICU step"
    echo "Checking what was built..."
    ls -lh "$BUILD_DIR/" | grep -E "kernel|Standalone" || echo "Nothing built yet"
    exit 1
fi

# Rebuild with fixed script
echo ""
echo "=========================================="
echo "Rebuilding with fixed ICU script..."
echo "=========================================="
echo ""

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
echo "Build Complete - Status: $BUILD_STATUS"
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
else
    echo "✗ Build failed with status: $BUILD_STATUS"
    echo "Check log: $ARM_ENGINE_DIR/build-final.log"
fi
