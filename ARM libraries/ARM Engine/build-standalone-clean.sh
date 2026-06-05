#!/bin/bash
set -e

echo "=========================================="
echo "Building LiveCode Standalone for ARM64"
echo "Clean build with Python 2 fix"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_ENGINE_DIR="$LIVECODE_ROOT/ARM libraries/ARM Engine"

cd "$LIVECODE_ROOT"

echo ""
echo "Setting up Python 2 for ICU build..."

# Add Python 2 to PATH for this build
export PATH="$LIVECODE_ROOT/thirdparty/python2/local-python/bin:$PATH"

# Verify Python 2 is available
if command -v python2 &> /dev/null; then
    echo "✓ Python 2 found: $(which python2)"
    python2 --version
elif [ -f "$LIVECODE_ROOT/thirdparty/python2/local-python/bin/python" ]; then
    echo "✓ Python 2 found in thirdparty"
    # Create symlink if needed
    if [ ! -L "/usr/local/bin/python" ]; then
        echo "Creating python symlink..."
        sudo ln -sf "$LIVECODE_ROOT/thirdparty/python2/local-python/bin/python" /usr/local/bin/python || true
    fi
else
    echo "⚠️  Python 2 not found, build may fail on ICU"
fi

echo ""
echo "Building kernel-standalone..."
echo "Started at: $(date)"
echo ""

xcodebuild -project "build-mac/livecode/engine/kernel-standalone.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           2>&1 | tee "$ARM_ENGINE_DIR/build-log-clean.txt"

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
    file "$BUILD_DIR/libkernel-standalone.a"
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
        echo "✓ App executable found"
        file "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        lipo -info "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
        ls -lh "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
    fi
    echo ""
fi

if [ $BUILD_STATUS -eq 0 ]; then
    echo "🎉 BUILD SUCCEEDED!"
    
    # Copy to ARM Engine folder
    if [ -d "$BUILD_DIR/Standalone-Community.app" ]; then
        echo ""
        echo "Copying to ARM Engine folder..."
        cp -R "$BUILD_DIR/Standalone-Community.app" "$ARM_ENGINE_DIR/"
        echo "✓ Copied to: $ARM_ENGINE_DIR/Standalone-Community.app"
    fi
else
    echo "✗ BUILD FAILED (status: $BUILD_STATUS)"
    echo "Check log: $ARM_ENGINE_DIR/build-log-clean.txt"
fi
