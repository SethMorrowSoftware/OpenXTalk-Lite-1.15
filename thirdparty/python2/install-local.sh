#!/bin/bash

# Python 2.7.18 Local Installation Script
# This script builds Python 2.7.18 from source for local use

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src/Python-2.7.18"
INSTALL_DIR="$SCRIPT_DIR/local-python"

echo "=== Python 2.7.18 Local Installation ==="
echo ""

# Check if source exists
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Python 2.7.18 source not found at $SRC_DIR"
    echo "Please ensure the Python 2.7.18 source is available in src/Python-2.7.18/"
    exit 1
fi

# Check if already installed
if [ -d "$INSTALL_DIR" ]; then
    echo "Python 2.7.18 already appears to be installed at $INSTALL_DIR"
    echo "Remove $INSTALL_DIR if you want to reinstall"
    exit 0
fi

echo "Building Python 2.7.18 from source..."
echo "Source: $SRC_DIR"
echo "Install directory: $INSTALL_DIR"
echo ""

# Configure Python 2.7.18
cd "$SRC_DIR"
echo "Step 1: Configuring Python 2.7.18..."
./configure --prefix="$INSTALL_DIR" --enable-shared

if [ $? -ne 0 ]; then
    echo "ERROR: Configuration failed"
    exit 1
fi

# Build Python 2.7.18
echo "Step 2: Building Python 2.7.18..."
make

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed"
    exit 1
fi

# Install Python 2.7.18
echo "Step 3: Installing Python 2.7.18..."
make install

if [ $? -ne 0 ]; then
    echo "ERROR: Installation failed"
    exit 1
fi

echo ""
echo "✓ Python 2.7.18 successfully installed to $INSTALL_DIR"
echo ""
echo "To use this Python installation:"
echo "export PATH=\"$INSTALL_DIR/bin:\$PATH\""
echo "export PYTHONHOME=\"$INSTALL_DIR\""
echo ""
echo "The OpenXTalk build script should automatically detect and use this installation."
