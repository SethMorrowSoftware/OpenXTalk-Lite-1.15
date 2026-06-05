#!/bin/bash

# OpenXTalk Icon Integration Script
# This script replaces LiveCode icons with OpenXTalk icons in the source tree
# Run with: bash integrate_openxtalk_icon.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
OPENXTALK_ICON="$PATCHES_DIR/OpenXTalk-lite_1024.icns"

echo "=== OpenXTalk Icon Integration ==="

# Check if OpenXTalk icon exists
if [ ! -f "$OPENXTALK_ICON" ]; then
    echo "ERROR: OpenXTalk icon not found: $OPENXTALK_ICON"
    exit 1
fi

echo "Integrating OpenXTalk icon into build sources..."

# Find and replace LiveCode icons in the source tree
find "$SCRIPT_DIR" -name "*.icns" -not -path "*/patches/*" -not -path "*/_build/*" -not -path "*/_cache/*" | while read icon_file; do
    echo "Replacing icon: $icon_file"
    cp "$OPENXTALK_ICON" "$icon_file"
done

# Specific icon locations for LiveCode
ICON_LOCATIONS=(
    "ide/Resources/LiveCode-Community.icns"
    "engine/rsrc/LiveCode-Community.icns"
    "installer/Resources/LiveCode-Community.icns"
)

for location in "${ICON_LOCATIONS[@]}"; do
    if [ -f "$SCRIPT_DIR/$location" ]; then
        echo "Replacing icon at: $location"
        cp "$OPENXTALK_ICON" "$SCRIPT_DIR/$location"
    fi
done

echo "OpenXTalk icon integration complete!"
echo "All LiveCode icons have been replaced with OpenXTalk icon."
