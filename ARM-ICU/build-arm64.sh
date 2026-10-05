#!/bin/bash
set -e

echo "=========================================="
echo "Building ICU 58.2 for ARM64 macOS"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVECODE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ICU_SOURCE="$SCRIPT_DIR/icu/source"
BUILD_DIR="$SCRIPT_DIR/build-arm64"
INSTALL_DIR="$SCRIPT_DIR/install-arm64"

echo ""
echo "ICU Source: $ICU_SOURCE"
echo "Build Dir: $BUILD_DIR"
echo "Install Dir: $INSTALL_DIR"
echo ""

# Clean previous build
rm -rf "$BUILD_DIR" "$INSTALL_DIR"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

echo "Configuring ICU for ARM64..."
echo ""

# Configure ICU for ARM64
CFLAGS="-arch arm64 -mmacosx-version-min=11.0" \
CXXFLAGS="-arch arm64 -mmacosx-version-min=11.0" \
LDFLAGS="-arch arm64 -mmacosx-version-min=11.0" \
"$ICU_SOURCE/configure" \
    --prefix="$INSTALL_DIR" \
    --enable-static \
    --disable-shared \
    --disable-samples \
    --disable-tests \
    --with-data-packaging=static

echo ""
echo "Building ICU (this will take a few minutes)..."
echo ""

make -j$(sysctl -n hw.ncpu)

echo ""
echo "Installing ICU..."
echo ""

make install

echo ""
echo "=========================================="
echo "Verifying ARM64 libraries..."
echo "=========================================="

for lib in libicuuc.a libicui18n.a libicudata.a libicuio.a; do
    if [ -f "$INSTALL_DIR/lib/$lib" ]; then
        echo ""
        echo "✓ $lib"
        file "$INSTALL_DIR/lib/$lib"
        lipo -info "$INSTALL_DIR/lib/$lib"
        ls -lh "$INSTALL_DIR/lib/$lib"
    else
        echo "✗ $lib not found"
    fi
done

echo ""
echo "=========================================="
echo "Copying to prebuilt location..."
echo "=========================================="

# Create mac-arm64 subdirectory for ARM libraries
mkdir -p "$LIVECODE_ROOT/prebuilt/lib/mac-arm64"

cp "$INSTALL_DIR/lib/libicu"*.a "$LIVECODE_ROOT/prebuilt/lib/mac-arm64/"

echo "✓ Copied ARM64 ICU libraries to: prebuilt/lib/mac-arm64/"
ls -lh "$LIVECODE_ROOT/prebuilt/lib/mac-arm64/"

echo ""
echo "🎉 ICU ARM64 BUILD COMPLETE! 🎉"
echo ""
echo "Next: Update Xcode project to use mac-arm64 libraries for ARM builds"
