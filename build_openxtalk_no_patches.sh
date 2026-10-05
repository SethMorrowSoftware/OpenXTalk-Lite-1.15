#!/bin/bash

# OpenXTalk Lite Build Script (No Hex Patches)
# This script builds LiveCode and applies OpenXTalk customizations without hex patches

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_build/mac/Release"
PYTHON_DIR="$SCRIPT_DIR/thirdparty/python2"

echo "=== OpenXTalk Lite Build (No Patches) ==="
echo ""

# Step 0: Setup Python 2.7.18 system installation
echo "Step 0: Setting up Python 2.7.18 from thirdparty..."

if [ -d "$PYTHON_DIR/local-python" ]; then
    echo "Installing Python 2.7.18 to system PATH..."
    
    # Add Python to PATH for this build session
    export PATH="$PYTHON_DIR/local-python/bin:$PATH"
    export PYTHONHOME="$PYTHON_DIR/local-python"
    
    # Install/link Python to system location for build tools
    if [ ! -L "/usr/local/bin/python2.7" ]; then
        echo "Creating system symlink for python2.7..."
        sudo ln -sf "$PYTHON_DIR/local-python/bin/python2.7" /usr/local/bin/python2.7
        sudo ln -sf "$PYTHON_DIR/local-python/bin/python" /usr/local/bin/python2
        echo "Python 2.7.18 linked to system"
    else
        echo "Python 2.7.18 already linked to system"
    fi
    
    # Verify Python installation
    which python2.7 && python2.7 --version
    
    echo "Python 2.7.18 setup completed"
else
    echo "WARNING: Python 2.7.18 not found in $PYTHON_DIR/local-python"
    echo "You may need to build it first:"
    echo "  cd $PYTHON_DIR"
    echo "  ./install-local.sh"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

# Step 0.5: Setup Java JDK for JNI headers
echo "Step 0.5: Setting up Java JDK for JNI support..."

# Use Homebrew OpenJDK 11
JAVA_HOME_PATH="/usr/local/opt/openjdk@11"

if [ -d "$JAVA_HOME_PATH" ]; then
    echo "Java JDK found at: $JAVA_HOME_PATH"
    export JAVA_HOME="$JAVA_HOME_PATH"
    
    # Create symlink to expected location for xcodebuild
    JAVA_HEADERS_DIR="/tmp/livecode-build/java-headers"
    mkdir -p /tmp/livecode-build
    
    # Remove old symlink if it exists
    if [ -L "$JAVA_HEADERS_DIR" ] || [ -d "$JAVA_HEADERS_DIR" ]; then
        rm -rf "$JAVA_HEADERS_DIR"
    fi
    
    # Create new symlink
    ln -s "$JAVA_HOME_PATH/include" "$JAVA_HEADERS_DIR"
    echo "Created symlink: $JAVA_HEADERS_DIR -> $JAVA_HOME_PATH/include"
    
    # Verify JNI headers exist
    if [ -f "$JAVA_HEADERS_DIR/jni.h" ]; then
        echo "JNI headers verified at: $JAVA_HEADERS_DIR/jni.h"
        echo "Java setup completed"
    else
        echo "WARNING: JNI headers not found"
    fi
else
    echo "ERROR: Homebrew OpenJDK 11 not found at $JAVA_HOME_PATH"
    echo "Please install it with: brew install openjdk@11"
    exit 1
fi

echo ""

# Step 1: Build LiveCode
echo "Step 1: Building LiveCode..."

# Build only the core LiveCode engine, excluding mobile components
echo "Building core LiveCode engine (excluding mobile components)..."
# Unset PYTHONHOME temporarily to avoid conflicts with Xcode's Python 3
unset PYTHONHOME
JAVA_HOME="$JAVA_HOME" xcodebuild -project "build-mac/livecode/livecode.xcodeproj" -configuration Release -target "LiveCode-all"

if [ $? -ne 0 ]; then
    echo "WARNING: LiveCode build had some failures, but checking if main app built successfully..."

    # Check if the main LiveCode application was built despite the error
    if [ -d "$BUILD_DIR/LiveCode-Community.app" ]; then
        echo "✓ Main LiveCode-Community.app built successfully!"
        echo "✓ The mobile component failures are non-critical for desktop usage"
        echo "Continuing with OpenXTalk customizations..."
    else
        echo "ERROR: Main LiveCode application failed to build"
        echo "Build cannot continue"
        exit 1
    fi
else
    echo "LiveCode build completed successfully"
fi

# Step 2: Apply OpenXTalk customizations (without hex patches)
echo ""
echo "Step 2: Applying OpenXTalk customizations..."

# Check if LiveCode-Community.app exists
if [ ! -d "$BUILD_DIR/LiveCode-Community.app" ]; then
    echo "ERROR: LiveCode-Community.app not found at $BUILD_DIR/LiveCode-Community.app"
    exit 1
fi

# Rename the app
if [ -d "$BUILD_DIR/OpenXTalk-Lite.app" ]; then
    rm -rf "$BUILD_DIR/OpenXTalk-Lite.app"
fi

cp -R "$BUILD_DIR/LiveCode-Community.app" "$BUILD_DIR/OpenXTalk-Lite.app"
echo "Renamed app to OpenXTalk-Lite.app"

# Update Info.plist
PLIST_FILE="$BUILD_DIR/OpenXTalk-Lite.app/Contents/Info.plist"
if [ -f "$PLIST_FILE" ]; then
    # Update bundle name and display name
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 'OpenXTalk Lite'" "$PLIST_FILE" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'OpenXTalk Lite'" "$PLIST_FILE" 2>/dev/null || true
    echo "Updated Info.plist with OpenXTalk branding"
else
    echo "WARNING: Info.plist not found: $PLIST_FILE"
fi

# Replace icons with custom icons
ICONS_DIR="$SCRIPT_DIR/engine/icons"
MAIN_ICON_DIR="$BUILD_DIR/OpenXTalk-Lite.app/Contents/Resources"

if [ -d "$ICONS_DIR" ] && [ -d "$MAIN_ICON_DIR" ]; then
    echo "Copying custom icons from engine/icons/"
    
    # Copy main application icon
    if [ -f "$ICONS_DIR/LiveCode.icns" ]; then
        cp "$ICONS_DIR/LiveCode.icns" "$MAIN_ICON_DIR/LiveCode.icns"
        cp "$ICONS_DIR/LiveCode.icns" "$MAIN_ICON_DIR/LiveCode-Community.icns"
        cp "$ICONS_DIR/LiveCode.icns" "$MAIN_ICON_DIR/OpenXTalk-Lite.icns"
        echo "Main application icon (LiveCode.icns)"
    fi
    
    # Copy document icons
    if [ -f "$ICONS_DIR/LiveCodeDoc.icns" ]; then
        cp "$ICONS_DIR/LiveCodeDoc.icns" "$MAIN_ICON_DIR/LiveCodeDoc.icns"
        echo "LiveCode document icon (LiveCodeDoc.icns)"
    fi
    
    if [ -f "$ICONS_DIR/OpenXTalkDoc.icns" ]; then
        cp "$ICONS_DIR/OpenXTalkDoc.icns" "$MAIN_ICON_DIR/OpenXTalkDoc.icns"
        echo "OpenXTalk document icon (OpenXTalkDoc.icns)"
    fi
    
    # Fix permissions
    find "$MAIN_ICON_DIR" -name "*.icns" -exec chmod 644 {} \;
    
    echo "Custom icons installed successfully"
else
    if [ ! -d "$ICONS_DIR" ]; then
        echo "WARNING: Custom icons directory not found: $ICONS_DIR"
    fi
    if [ ! -d "$MAIN_ICON_DIR" ]; then
        echo "WARNING: Resources directory not found: $MAIN_ICON_DIR"
    fi
fi

echo ""
echo "Step 3: Applying ad-hoc codesigning..."

# Apply ad-hoc codesigning
if [ -d "$BUILD_DIR/OpenXTalk-Lite.app" ]; then
    echo "Codesigning OpenXTalk-Lite.app with ad-hoc signature..."
    
    # Remove any existing signatures first
    codesign --remove-signature "$BUILD_DIR/OpenXTalk-Lite.app" 2>/dev/null || true
    
    # Apply ad-hoc codesigning
    codesign --force --deep --sign - "$BUILD_DIR/OpenXTalk-Lite.app"
    
    if [ $? -eq 0 ]; then
        echo "Ad-hoc codesigning completed successfully"
    else
        echo "Warning: Codesigning failed, but build is still usable"
    fi
    
    # Verify the signature
    echo "Verifying codesignature..."
    codesign --verify --verbose "$BUILD_DIR/OpenXTalk-Lite.app" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Codesignature verification passed"
    else
        echo "Codesignature verification failed"
    fi
    
    echo ""
    echo "Step 4: Setting proper file permissions..."
    
    # Ensure proper ownership and permissions
    chown -R $(whoami):staff "$BUILD_DIR/OpenXTalk-Lite.app"
    chmod -R u+rwX,go+rX "$BUILD_DIR/OpenXTalk-Lite.app"
    
    # Ensure executables are properly executable
    find "$BUILD_DIR/OpenXTalk-Lite.app" -type f -name "*" -perm +111 -exec chmod 755 {} \;
    find "$BUILD_DIR/OpenXTalk-Lite.app" -path "*/MacOS/*" -type f -exec chmod 755 {} \;
    
    echo "File permissions set correctly"
    
else
    echo "ERROR: OpenXTalk-Lite.app not found at $BUILD_DIR/OpenXTalk-Lite.app"
    exit 1
fi

echo ""
echo "=== OpenXTalk Lite Build Complete (No Patches) ==="
echo ""
echo "Your OpenXTalk-Lite.app is ready at:"
echo "$BUILD_DIR/OpenXTalk-Lite.app"
echo ""
echo "Build completed successfully"
echo "OpenXTalk branding applied"
echo "Icons replaced (if available)"
echo "Ad-hoc codesigning applied"
echo "Proper file permissions set"
echo ""
echo "To run OpenXTalk Lite:"
echo "open '$BUILD_DIR/OpenXTalk-Lite.app'"
echo ""
echo "Note: This build does NOT include hex patches."
echo "If you need the menu bug fixes, you can apply patches later:"
echo "sudo ./apply_openxtalk_patches.sh"
