#!/bin/bash
set -e

echo "=========================================="
echo "Setting up JNI Headers for ARM Build"
echo "=========================================="

JAVA_HOME_PATH="/usr/local/opt/openjdk@11"
JAVA_HEADERS_DIR="/tmp/livecode-build/java-headers"

if [ -d "$JAVA_HOME_PATH" ]; then
    echo "✓ Java JDK found at: $JAVA_HOME_PATH"
    
    # Create directory
    mkdir -p /tmp/livecode-build
    
    # Remove old symlink if it exists
    if [ -L "$JAVA_HEADERS_DIR" ] || [ -d "$JAVA_HEADERS_DIR" ]; then
        rm -rf "$JAVA_HEADERS_DIR"
    fi
    
    # Create new symlink
    ln -s "$JAVA_HOME_PATH/include" "$JAVA_HEADERS_DIR"
    echo "✓ Created symlink: $JAVA_HEADERS_DIR -> $JAVA_HOME_PATH/include"
    
    # Verify JNI headers exist
    if [ -f "$JAVA_HEADERS_DIR/jni.h" ]; then
        echo "✓ JNI headers verified at: $JAVA_HEADERS_DIR/jni.h"
        echo ""
        echo "JNI headers are architecture-independent!"
        echo "Same headers work for both ARM64 and x86_64"
        echo ""
        file "$JAVA_HEADERS_DIR/jni.h"
    else
        echo "✗ WARNING: JNI headers not found"
        exit 1
    fi
else
    echo "✗ ERROR: Homebrew OpenJDK 11 not found at $JAVA_HOME_PATH"
    echo ""
    echo "Please install it with:"
    echo "  brew install openjdk@11"
    echo ""
    exit 1
fi

echo ""
echo "JNI setup complete! Ready for ARM build."
