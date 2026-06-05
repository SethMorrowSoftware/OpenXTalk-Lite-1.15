#!/bin/bash
# Remove x86-specific files from Cairo Xcode project for ARM builds

set -e

PROJECT_FILE="$1"

if [ -z "$PROJECT_FILE" ]; then
    echo "Usage: $0 <path-to-project.pbxproj>"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo "ERROR: Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "Removing x86-specific files from Cairo Xcode project..."
echo "Project: $PROJECT_FILE"

# Backup original
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

# Remove lines containing x86-specific files
# pixman-sse2.c, pixman-ssse3.c, pixman-x86.c, pixman-mmx.c

sed -i '' '/pixman-sse2\.c/d' "$PROJECT_FILE"
sed -i '' '/pixman-ssse3\.c/d' "$PROJECT_FILE"
sed -i '' '/pixman-x86\.c/d' "$PROJECT_FILE"
sed -i '' '/pixman-mmx\.c/d' "$PROJECT_FILE"

echo "✓ Removed x86-specific file references"
echo "✓ Backup saved to: $PROJECT_FILE.backup"
echo ""
echo "Modified project ready for ARM64 builds!"
