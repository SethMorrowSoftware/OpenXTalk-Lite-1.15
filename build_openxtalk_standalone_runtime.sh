#!/bin/bash

# OpenXTalk Standalone Runtime Build Script
# This script builds the Standalone-Community.app (standalone builder/runtime)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_build/mac/Release"
PYTHON_DIR="$SCRIPT_DIR/thirdparty/python2"

echo "=== OpenXTalk Standalone Runtime Build ==="
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
JAVA_HOME_PATH="/opt/homebrew/opt/openjdk@11"

# Try alternate location if not found
if [ ! -d "$JAVA_HOME_PATH" ]; then
    JAVA_HOME_PATH="/usr/local/opt/openjdk@11"
fi

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
    echo "ERROR: Homebrew OpenJDK 11 not found"
    echo "Please install it with: brew install openjdk@11"
    exit 1
fi

echo ""

# Step 1: Build kernel-standalone library
echo "Step 1: Building kernel-standalone library..."

# Unset PYTHONHOME temporarily to avoid conflicts with Xcode's Python 3
unset PYTHONHOME
JAVA_HOME="$JAVA_HOME" xcodebuild -project "build-mac/livecode/livecode.xcodeproj" \
    -scheme kernel-standalone \
    -configuration Release \
    SYMROOT="${SCRIPT_DIR}/_build/mac" \
    OBJROOT="${SCRIPT_DIR}/_cache/mac"

if [ $? -ne 0 ]; then
    echo "ERROR: kernel-standalone build failed"
    exit 1
fi

echo "kernel-standalone library built successfully"
echo ""

# Step 2: Build Standalone-Community.app
echo "Step 2: Building Standalone-Community.app..."

# The standalone app is built as part of the development target
JAVA_HOME="$JAVA_HOME" xcodebuild -project "build-mac/livecode/engine/engine.xcodeproj" \
    -target standalone \
    -configuration Release \
    SYMROOT="${SCRIPT_DIR}/_build/mac" \
    OBJROOT="${SCRIPT_DIR}/_cache/mac"

if [ $? -ne 0 ]; then
    echo "WARNING: Standalone build had some issues, checking if app was built..."
fi

# Check if Standalone-Community.app was built
if [ -d "$BUILD_DIR/Standalone-Community.app" ]; then
    echo "Standalone-Community.app built successfully"
    
    # Apply ad-hoc codesigning
    echo ""
    echo "Step 3: Applying ad-hoc codesigning..."
    codesign --force --deep --sign - "$BUILD_DIR/Standalone-Community.app"
    
    if [ $? -eq 0 ]; then
        echo "Ad-hoc codesigning completed successfully"
        
        # Verify codesignature
        echo "Verifying codesignature..."
        codesign --verify --verbose "$BUILD_DIR/Standalone-Community.app"
        
        if [ $? -eq 0 ]; then
            echo "Codesignature verification passed"
        else
            echo "WARNING: Codesignature verification failed"
        fi
    else
        echo "WARNING: Ad-hoc codesigning failed"
    fi
    
    # Set proper permissions
    echo ""
    echo "Step 4: Setting proper file permissions..."
    chmod -R u+w "$BUILD_DIR/Standalone-Community.app"
    chmod +x "$BUILD_DIR/Standalone-Community.app/Contents/MacOS/Standalone-Community"
    echo "File permissions set correctly"
    
    echo ""
    echo "=== OpenXTalk Standalone Runtime Build Complete ==="
    echo ""
    echo "Your Standalone-Community.app is ready at:"
    echo "$BUILD_DIR/Standalone-Community.app"
    echo ""
    echo "This standalone runtime includes:"
    echo "- macOS dark mode support"
    echo "- Automatic theme-aware colors"
    echo "- systemAppearanceChanged message support"
    echo ""
    echo "To use it with OpenXTalk-Lite.app, copy it to:"
    echo "OpenXTalk-Lite.app/Contents/Tools/Runtime/Mac OS X/x86-64/"
else
    echo "ERROR: Standalone-Community.app was not built"
    echo "Expected location: $BUILD_DIR/Standalone-Community.app"
    exit 1
fi
