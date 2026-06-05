#!/bin/bash
set -e

# Build Skia ARM64 NEON Optimizations
# This script compiles the ARM-specific optimization files for Skia

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Building Skia ARM64 NEON Optimizations"
echo "========================================="

SKIA_SRC="thirdparty/libskia/src"
SKIA_INCLUDE="thirdparty/libskia/include"
BUILD_DIR="ARM-libraries-arm64/skia-opts-build"
OUTPUT_LIB="ARM-libraries-arm64/libskia_opt_arm64.a"

# Create build directory
mkdir -p "$BUILD_DIR"

# Compiler flags
CFLAGS="-arch arm64 -mmacosx-version-min=11.0 -O3 -fno-exceptions -fno-rtti"
CXXFLAGS="$CFLAGS -std=c++11"
INCLUDES="-I$SKIA_INCLUDE/core -I$SKIA_INCLUDE/config -I$SKIA_INCLUDE/private -I$SKIA_INCLUDE/utils -I$SKIA_INCLUDE/gpu -I$SKIA_SRC/core -I$SKIA_SRC/opts -I$SKIA_SRC/utils -I$SKIA_SRC/gpu"

# ARM NEON source files (from libskia.gyp opts_armv7_arm64_srcs)
ARM_NEON_SOURCES=(
    "$SKIA_SRC/opts/SkBitmapProcState_arm_neon.cpp"
    "$SKIA_SRC/opts/SkBitmapProcState_matrixProcs_neon.cpp"
    "$SKIA_SRC/opts/SkBlitMask_opts_arm_neon.cpp"
    "$SKIA_SRC/opts/SkBlitRow_opts_arm_neon.cpp"
)

# ARM base source files (from libskia.gyp opts_arm_srcs)
ARM_BASE_SOURCES=(
    "$SKIA_SRC/opts/SkBlitMask_opts_arm.cpp"
    "$SKIA_SRC/opts/SkBlitRow_opts_arm.cpp"
)

# CRC32 source files
CRC32_SOURCES=(
    "$SKIA_SRC/opts/SkOpts_crc32.cpp"
)

echo ""
echo "Compiling ARM NEON optimizations..."
OBJECT_FILES=()

# Compile NEON sources
for src in "${ARM_NEON_SOURCES[@]}"; do
    if [ -f "$src" ]; then
        obj="$BUILD_DIR/$(basename ${src%.cpp}).o"
        echo "  Compiling $(basename $src)..."
        clang++ $CXXFLAGS $INCLUDES -c "$src" -o "$obj"
        OBJECT_FILES+=("$obj")
    else
        echo "  Warning: $src not found"
    fi
done

# Compile ARM base sources
for src in "${ARM_BASE_SOURCES[@]}"; do
    if [ -f "$src" ]; then
        obj="$BUILD_DIR/$(basename ${src%.cpp}).o"
        echo "  Compiling $(basename $src)..."
        clang++ $CXXFLAGS $INCLUDES -c "$src" -o "$obj"
        OBJECT_FILES+=("$obj")
    else
        echo "  Warning: $src not found"
    fi
done

# Compile CRC32 sources
for src in "${CRC32_SOURCES[@]}"; do
    if [ -f "$src" ]; then
        obj="$BUILD_DIR/$(basename ${src%.cpp}).o"
        echo "  Compiling $(basename $src)..."
        clang++ $CXXFLAGS $INCLUDES -c "$src" -o "$obj"
        OBJECT_FILES+=("$obj")
    else
        echo "  Warning: $src not found"
    fi
done

echo ""
echo "Creating static library..."
ar rcs "$OUTPUT_LIB" "${OBJECT_FILES[@]}"

echo ""
echo "Verifying library..."
lipo -info "$OUTPUT_LIB"
echo ""
echo "Library contents:"
ar -t "$OUTPUT_LIB"

echo ""
echo "Checking for NEON symbols..."
nm "$OUTPUT_LIB" | grep -E "ClampX_ClampY|PlatformRowProcs|platformProcs" | head -5

echo ""
echo "========================================="
echo "✓ Skia ARM64 NEON optimizations built!"
echo "========================================="
echo "Output: $OUTPUT_LIB"
echo "Size: $(ls -lh $OUTPUT_LIB | awk '{print $5}')"
