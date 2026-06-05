#!/bin/bash
set -e

# Build zlib for ARM64 macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Building zlib for ARM64 macOS"
echo "========================================="

ZLIB_VERSION="1.3.1"
ZLIB_DIR="/tmp/zlib-${ZLIB_VERSION}"
INSTALL_DIR="$SCRIPT_DIR/ARM-libraries-arm64/zlib"

# Download zlib if not already present
if [ ! -f "/tmp/zlib-${ZLIB_VERSION}.tar.gz" ]; then
    echo ""
    echo "Downloading zlib ${ZLIB_VERSION}..."
    cd /tmp
    curl -L "https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz" -o "zlib-${ZLIB_VERSION}.tar.gz"
else
    echo ""
    echo "zlib tarball already downloaded"
fi

# Extract
echo ""
echo "Extracting zlib..."
cd /tmp
rm -rf "$ZLIB_DIR"
tar -xzf "zlib-${ZLIB_VERSION}.tar.gz"

# Configure for ARM64
echo ""
echo "Configuring zlib for ARM64..."
cd "$ZLIB_DIR"

export CFLAGS="-arch arm64 -mmacosx-version-min=11.0 -O3"
./configure --prefix="$INSTALL_DIR" --static

# Build
echo ""
echo "Building zlib..."
make -j$(sysctl -n hw.ncpu)

# Install
echo ""
echo "Installing zlib..."
make install

# Verify
echo ""
echo "========================================="
echo "Verifying ARM64 library..."
echo "========================================="

lipo -info "$INSTALL_DIR/lib/libz.a"
ls -lh "$INSTALL_DIR/lib/libz.a"

# Copy to prebuilt and ARM libraries
echo ""
echo "Copying to prebuilt location..."
cp "$INSTALL_DIR/lib/libz.a" "$SCRIPT_DIR/prebuilt/lib/mac/"
cp "$INSTALL_DIR/lib/libz.a" "$SCRIPT_DIR/ARM-libraries-arm64/"

echo ""
echo "========================================="
echo "✓ zlib ARM64 build complete!"
echo "========================================="
echo "Library: $(ls -lh $SCRIPT_DIR/ARM-libraries-arm64/libz.a | awk '{print $5}')"
