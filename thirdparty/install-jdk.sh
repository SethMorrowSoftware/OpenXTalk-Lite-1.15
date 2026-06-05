#!/bin/bash

# OpenXTalk JDK Installation Script
# This script sets up JNI headers for the system JDK

set -e

echo "Setting up JNI headers for system JDK..."

# Check if system JDK is available
if ! command -v javac >/dev/null 2>&1; then
    echo "ERROR: System JDK not found"
    echo "Please install Java JDK first:"
    echo "  brew install openjdk@11"
    exit 1
fi

# Verify system JDK works
echo "Verifying system JDK..."
if ! javac -version >/dev/null 2>&1; then
    echo "ERROR: System JDK is not working properly"
    echo "Please reinstall Java JDK:"
    echo "  brew reinstall openjdk@11"
    exit 1
fi

# Create JNI headers directory and symlink to system JDK headers
echo "Creating JNI headers symlink..."
mkdir -p "/tmp/livecode-build"
ln -sf "/usr/local/opt/openjdk@11/include" "/tmp/livecode-build/java-headers"

echo "JDK setup completed successfully!"
echo ""
echo "System JDK location: /usr/local/opt/openjdk@11"
echo "JNI headers linked at: /tmp/livecode-build/java-headers"
echo ""
echo "You can verify the installation with:"
echo "  javac -version"
echo "  java -version"
