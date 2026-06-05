#!/bin/bash

# Script to install Java JDK for LiveCode build
# Run this script with: bash install_java.sh

echo "Installing Java JDK for LiveCode build..."

# Try to install via Homebrew first
if command -v brew >/dev/null 2>&1; then
    echo "Attempting to install Eclipse Temurin JDK via Homebrew..."
    brew install --cask temurin
    
    if [ $? -eq 0 ]; then
        echo "Java installed successfully via Homebrew"
        # Find the Java installation
        JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null)
        if [ -n "$JAVA_HOME" ]; then
            echo "JAVA_HOME found at: $JAVA_HOME"
            echo "JNI headers should be at: $JAVA_HOME/include"
            ls -la "$JAVA_HOME/include/" 2>/dev/null || echo "JNI headers not found in expected location"
        fi
        exit 0
    fi
fi

# Alternative: Try to use system Java if available
echo "Checking for system Java..."
if /usr/libexec/java_home >/dev/null 2>&1; then
    JAVA_HOME=$(/usr/libexec/java_home)
    echo "System Java found at: $JAVA_HOME"
    
    # Check if JNI headers are available
    if [ -f "$JAVA_HOME/include/jni.h" ]; then
        echo "JNI headers found at: $JAVA_HOME/include/jni.h"
        exit 0
    else
        echo "JNI headers not found. You may need to install the full JDK."
    fi
fi

# Manual installation instructions
echo ""
echo "If automatic installation failed, please manually install Java JDK:"
echo "1. Download Oracle JDK or OpenJDK from:"
echo "   - https://www.oracle.com/java/technologies/downloads/"
echo "   - https://adoptium.net/"
echo "2. Install the .dmg file"
echo "3. Verify installation with: java -version"
echo "4. Check JAVA_HOME with: /usr/libexec/java_home"
echo ""
echo "After installation, the JNI headers should be available at:"
echo "\$JAVA_HOME/include/jni.h"
