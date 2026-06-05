#!/bin/bash
set -e

# Build OpenSSL 1.1.1 for ARM64 macOS
# This script downloads, configures, and builds OpenSSL for Apple Silicon

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Building OpenSSL 1.1.1 for ARM64 macOS"
echo "========================================="

OPENSSL_VERSION="1.1.1w"
OPENSSL_DIR="/tmp/openssl-${OPENSSL_VERSION}"
INSTALL_DIR="$SCRIPT_DIR/ARM-libraries-arm64/openssl"

# Download OpenSSL if not already present
if [ ! -f "/tmp/openssl-${OPENSSL_VERSION}.tar.gz" ]; then
    echo ""
    echo "Downloading OpenSSL ${OPENSSL_VERSION}..."
    cd /tmp
    curl -L "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -o "openssl-${OPENSSL_VERSION}.tar.gz"
else
    echo ""
    echo "OpenSSL tarball already downloaded"
fi

# Extract
echo ""
echo "Extracting OpenSSL..."
cd /tmp
rm -rf "$OPENSSL_DIR"
tar -xzf "openssl-${OPENSSL_VERSION}.tar.gz"

# Configure for ARM64
echo ""
echo "Configuring OpenSSL for ARM64..."
cd "$OPENSSL_DIR"

./Configure darwin64-arm64-cc \
    --prefix="$INSTALL_DIR" \
    --openssldir="$INSTALL_DIR/ssl" \
    no-shared \
    no-tests \
    -mmacosx-version-min=11.0

# Build
echo ""
echo "Building OpenSSL..."
make -j$(sysctl -n hw.ncpu)

# Install
echo ""
echo "Installing OpenSSL..."
make install_sw

# Verify
echo ""
echo "========================================="
echo "Verifying ARM64 libraries..."
echo "========================================="

for lib in "$INSTALL_DIR/lib/libssl.a" "$INSTALL_DIR/lib/libcrypto.a"; do
    if [ -f "$lib" ]; then
        echo ""
        echo "$(basename $lib):"
        lipo -info "$lib"
        ls -lh "$lib"
    else
        echo "ERROR: $lib not found!"
        exit 1
    fi
done

# Copy to prebuilt location
echo ""
echo "Copying to prebuilt location..."
mkdir -p "$SCRIPT_DIR/prebuilt/lib/mac"
cp "$INSTALL_DIR/lib/libssl.a" "$SCRIPT_DIR/prebuilt/lib/mac/"
cp "$INSTALL_DIR/lib/libcrypto.a" "$SCRIPT_DIR/prebuilt/lib/mac/"

# Copy to ARM libraries directory
cp "$INSTALL_DIR/lib/libssl.a" "$SCRIPT_DIR/ARM-libraries-arm64/"
cp "$INSTALL_DIR/lib/libcrypto.a" "$SCRIPT_DIR/ARM-libraries-arm64/"

echo ""
echo "========================================="
echo "✓ OpenSSL ARM64 build complete!"
echo "========================================="
echo "Libraries installed to:"
echo "  - $INSTALL_DIR/lib/"
echo "  - prebuilt/lib/mac/"
echo "  - ARM-libraries-arm64/"
echo ""
echo "Library sizes:"
ls -lh "$SCRIPT_DIR/ARM-libraries-arm64/libssl.a" "$SCRIPT_DIR/ARM-libraries-arm64/libcrypto.a"
