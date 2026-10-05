#!/bin/bash

# OpenXTalk Lite Build Script
# This script builds LiveCode and automatically applies OpenXTalk customizations
# Run with: bash build_openxtalk.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_build/mac/Debug"

echo "=== OpenXTalk Lite Build Script ==="
echo "Building LiveCode with OpenXTalk customizations..."
echo ""

# Step 1: Build LiveCode
echo "Step 1: Building LiveCode engine..."
make compile-mac

# Check if build was successful
if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: Build failed - no build directory found"
    exit 1
fi

echo ""
echo "Step 2: Applying OpenXTalk customizations..."
echo "This step requires sudo privileges for patching executables."
echo ""

# Check if we can run the patch script
if [ ! -f "$SCRIPT_DIR/apply_openxtalk_patches.sh" ]; then
    echo "ERROR: OpenXTalk patch script not found: $SCRIPT_DIR/apply_openxtalk_patches.sh"
    exit 1
fi

# Apply the patches with sudo
echo "Running OpenXTalk patching script (requires sudo)..."
sudo bash "$SCRIPT_DIR/apply_openxtalk_patches.sh"

echo ""
echo "Step 3: Applying ad-hoc codesigning to prevent Gatekeeper warnings..."

# Check if the app exists
if [ -d "$BUILD_DIR/OpenXTalk-Lite.app" ]; then
    echo "Codesigning OpenXTalk-Lite.app with ad-hoc signature..."
    
    # Remove any existing signatures first
    codesign --remove-signature "$BUILD_DIR/OpenXTalk-Lite.app" 2>/dev/null || true
    
    # Apply ad-hoc codesigning to prevent "damaged application" warnings
    codesign --force --deep --sign - "$BUILD_DIR/OpenXTalk-Lite.app"
    
    if [ $? -eq 0 ]; then
        echo "✓ Ad-hoc codesigning completed successfully"
    else
        echo "⚠ Warning: Codesigning failed, but build is still usable"
        echo "  You may see Gatekeeper warnings when running the app"
    fi
    
    # Verify the signature
    echo "Verifying codesignature..."
    codesign --verify --verbose "$BUILD_DIR/OpenXTalk-Lite.app" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✓ Codesignature verification passed"
    else
        echo "⚠ Codesignature verification failed"
    fi
    
    echo ""
    echo "Step 4: Correcting file permissions..."
    echo "Setting proper permissions for OpenXTalk-Lite.app..."
    
    # Fix ownership and permissions to allow normal user access
    sudo chown -R $(whoami):staff "$BUILD_DIR/OpenXTalk-Lite.app"
    chmod -R u+rwX,go+rX "$BUILD_DIR/OpenXTalk-Lite.app"
    
    # Ensure executables are properly executable
    find "$BUILD_DIR/OpenXTalk-Lite.app" -type f -name "*" -perm +111 -exec chmod 755 {} \;
    find "$BUILD_DIR/OpenXTalk-Lite.app" -path "*/MacOS/*" -type f -exec chmod 755 {} \;
    
    echo "✓ File permissions corrected"
    
else
    echo "ERROR: OpenXTalk-Lite.app not found at $BUILD_DIR/OpenXTalk-Lite.app"
    exit 1
fi

echo ""
echo "=== OpenXTalk Lite Build Complete ==="
echo ""
echo "Your OpenXTalk-Lite.app is ready at:"
echo "$BUILD_DIR/OpenXTalk-Lite.app"
echo ""
echo "✓ Build completed successfully"
echo "✓ OpenXTalk patches applied"
echo "✓ Ad-hoc codesigning applied (prevents Gatekeeper warnings)"
echo ""
echo "To run OpenXTalk Lite:"
echo "open '$BUILD_DIR/OpenXTalk-Lite.app'"
echo ""
echo "Note: This build uses ad-hoc codesigning for local use."
echo "For distribution, replace with a proper Developer ID signature:"
echo "codesign --force --deep --sign 'Your Developer ID Application' '$BUILD_DIR/OpenXTalk-Lite.app'"
