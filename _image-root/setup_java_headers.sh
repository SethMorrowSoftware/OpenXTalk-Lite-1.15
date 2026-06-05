#!/bin/bash

# Script to set up Java headers for LiveCode build
# Run this script with: sudo bash setup_java_headers.sh

echo "Setting up Java headers for LiveCode build..."

# Create the directory that the build system expects
mkdir -p /tmp/livecode-build

# Create symbolic link from expected path to our actual Java headers
ln -sf /Users/user/Cascade/Livecode-Community-9.6.3/java-headers /tmp/livecode-build/java-headers

# Verify the symlink was created correctly
if [ -L "/tmp/livecode-build/java-headers" ] && [ -e "/tmp/livecode-build/java-headers" ]; then
    echo "✓ Java headers symlink created successfully"
    echo "✓ Symlink points to: $(readlink /tmp/livecode-build/java-headers)"
    echo "✓ Checking for jni.h: $(ls /tmp/livecode-build/java-headers/jni.h 2>/dev/null && echo "Found" || echo "Not found")"
else
    echo "✗ Failed to create Java headers symlink"
    exit 1
fi

echo "Setup complete! You can now run the LiveCode build."
