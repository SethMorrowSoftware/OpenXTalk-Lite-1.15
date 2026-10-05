#!/bin/bash
set -e

echo "=========================================="
echo "Building Utility Libraries for ARM64"
echo "=========================================="

LIVECODE_ROOT="/Users/admin/Cascade/Livecode-Community-9.6.3/livecode"
BUILD_DIR="$LIVECODE_ROOT/_build/mac/Release"
ARM_UTIL_DIR="$LIVECODE_ROOT/ARM libraries/ARM Utilities"

cd "$LIVECODE_ROOT"

# Build libzip (ZIP archives)
echo ""
echo "Building libzip..."
xcodebuild -project "build-mac/livecode/thirdparty/libzip/libzip.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "WARNING: Failed to build libzip, continuing..."; }

if [ -f "$BUILD_DIR/libzip.a" ]; then
    echo "✓ libzip.a built successfully"
    file "$BUILD_DIR/libzip.a"
    lipo -info "$BUILD_DIR/libzip.a"
    cp "$BUILD_DIR/libzip.a" "$ARM_UTIL_DIR/lib/"
fi

# Build libiodbc (ODBC database connectivity)
echo ""
echo "Building libiodbc..."
xcodebuild -project "build-mac/livecode/thirdparty/libiodbc/libiodbc.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "WARNING: Failed to build libiodbc, continuing..."; }

if [ -f "$BUILD_DIR/libiodbc.a" ]; then
    echo "✓ libiodbc.a built successfully"
    file "$BUILD_DIR/libiodbc.a"
    lipo -info "$BUILD_DIR/libiodbc.a"
    cp "$BUILD_DIR/libiodbc.a" "$ARM_UTIL_DIR/lib/"
fi

# Build libpq (PostgreSQL driver)
echo ""
echo "Building libpq..."
xcodebuild -project "build-mac/livecode/thirdparty/libpq/libpq.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "WARNING: Failed to build libpq, continuing..."; }

if [ -f "$BUILD_DIR/libpq.a" ]; then
    echo "✓ libpq.a built successfully"
    file "$BUILD_DIR/libpq.a"
    lipo -info "$BUILD_DIR/libpq.a"
    cp "$BUILD_DIR/libpq.a" "$ARM_UTIL_DIR/lib/"
fi

# Build libmysql (MySQL driver)
echo ""
echo "Building libmysql..."
xcodebuild -project "build-mac/livecode/thirdparty/libmysql/libmysql.xcodeproj" \
           -configuration Release \
           -arch arm64 \
           ARCHS=arm64 \
           ONLY_ACTIVE_ARCH=NO \
           MACOSX_DEPLOYMENT_TARGET=11.0 \
           || { echo "WARNING: Failed to build libmysql, continuing..."; }

if [ -f "$BUILD_DIR/libmysql.a" ]; then
    echo "✓ libmysql.a built successfully"
    file "$BUILD_DIR/libmysql.a"
    lipo -info "$BUILD_DIR/libmysql.a"
    cp "$BUILD_DIR/libmysql.a" "$ARM_UTIL_DIR/lib/"
fi

echo ""
echo "=========================================="
echo "BUILD COMPLETE!"
echo "=========================================="
echo "Utility libraries in: $ARM_UTIL_DIR/lib/"
ls -lh "$ARM_UTIL_DIR/lib/" 2>/dev/null || echo "No libraries built"
