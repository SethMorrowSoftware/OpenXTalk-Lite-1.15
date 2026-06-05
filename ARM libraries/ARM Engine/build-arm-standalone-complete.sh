#!/bin/bash
set -e

echo "=========================================="
echo "LiveCode ARM64 Standalone Build"
echo "Complete setup and build"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_ENGINE_DIR="$LIVECODE_ROOT/ARM libraries/ARM Engine"

cd "$LIVECODE_ROOT"

echo ""
echo "Step 1: Setup JNI Headers"
echo "=========================================="

JAVA_HOME_PATH="/usr/local/opt/openjdk@11"
JAVA_HEADERS_DIR="/tmp/livecode-build/java-headers"

if [ -d "$JAVA_HOME_PATH" ]; then
    echo "✓ Java JDK found at: $JAVA_HOME_PATH"
    export JAVA_HOME="$JAVA_HOME_PATH"
    
    mkdir -p /tmp/livecode-build
    rm -rf "$JAVA_HEADERS_DIR"
    ln -s "$JAVA_HOME_PATH/include" "$JAVA_HEADERS_DIR"
    
    if [ -f "$JAVA_HEADERS_DIR/jni.h" ]; then
        echo "✓ JNI headers ready at: $JAVA_HEADERS_DIR/jni.h"
    else
        echo "✗ WARNING: JNI headers not found"
    fi
else
    echo "✗ ERROR: OpenJDK 11 not found"
    echo "Install with: brew install openjdk@11"
    exit 1
fi

echo ""
echo "Step 2: Verify ARM64 Libraries"
echo "=========================================="

LIBS_OK=true
for lib in libskia.a libcairo.a libffi.a libpng.a libjpeg.a libgif.a libsqlite.a libxml.a libxslt.a libpcre.a libz.a libzip.a; do
    if [ -f "$BUILD_DIR/$lib" ]; then
        ARCH=$(lipo -info "$BUILD_DIR/$lib" 2>/dev/null | grep -o "arm64" || echo "")
        if [ "$ARCH" = "arm64" ]; then
            echo "✓ $lib (ARM64)"
        else
            echo "✗ $lib (not ARM64)"
            LIBS_OK=false
        fi
    else
        echo "⚠ $lib (not found - may be built during engine build)"
    fi
done

if [ "$LIBS_OK" = false ]; then
    echo ""
    echo "Some libraries are not ARM64. Build may fail."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Step 3: Clean Previous Build"
echo "=========================================="

echo "Cleaning kernel and foundation caches..."
rm -rf _cache/mac/Release/kernel*.build/
rm -rf _cache/mac/Release/libFoundation.build/
rm -rf "$BUILD_DIR/libkernel-standalone.a"
rm -rf "$BUILD_DIR/Standalone-Community"*
echo "✓ Clean complete"

echo ""
echo "Step 4: Build ARM64 Standalone Engine"
echo "=========================================="
echo "Started at: $(date)"
echo ""

JAVA_HOME="$JAVA_HOME" xcodebuild \
    -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
    -configuration Release \
    -arch arm64 \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET=11.0 \
    2>&1 | tee "$ARM_ENGINE_DIR/build-complete.log"

BUILD_STATUS=${PIPESTATUS[0]}

echo ""
echo "=========================================="
echo "Build finished at: $(date)"
echo "Build status: $BUILD_STATUS"
echo "=========================================="
echo ""

# Analyze results
echo "Step 5: Analyze Build Results"
echo "=========================================="

if [ -f "$BUILD_DIR/libkernel-standalone.a" ]; then
    echo "✓ libkernel-standalone.a"
    lipo -info "$BUILD_DIR/libkernel-standalone.a"
    ls -lh "$BUILD_DIR/libkernel-standalone.a"
else
    echo "✗ libkernel-standalone.a not found"
fi

if [ -f "$BUILD_DIR/Standalone-Community" ]; then
    echo "✓ Standalone-Community executable"
    file "$BUILD_DIR/Standalone-Community"
    lipo -info "$BUILD_DIR/Standalone-Community"
    ls -lh "$BUILD_DIR/Standalone-Community"
fi

if [ -d "$BUILD_DIR/Standalone-Community.app" ]; then
    echo "✓ Standalone-Community.app bundle"
    if [ -f "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community" ]; then
        echo "✓ App executable"
        file "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        lipo -info "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        ls -lh "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        
        echo ""
        echo "Copying to ARM Engine folder..."
        cp -R "$BUILD_DIR/Standalone-Community.app" "$ARM_ENGINE_DIR/"
        echo "✓ Success!"
    fi
fi

echo ""
if [ $BUILD_STATUS -eq 0 ]; then
    echo "🎉 BUILD SUCCEEDED! 🎉"
else
    echo "Build failed with status: $BUILD_STATUS"
    echo ""
    echo "Checking for errors in log..."
    grep -A5 "error:" "$ARM_ENGINE_DIR/build-complete.log" | tail -20
fi
