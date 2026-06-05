#!/bin/bash
set -e

# ARM64 LiveCode Standalone Build Script
# This script builds the LiveCode standalone engine for ARM64 macOS
# using pre-built ARM64 libraries to avoid build system conflicts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "ARM64 LiveCode Standalone Build"
echo "========================================="

# 1. Setup JNI headers
echo "Setting up JNI headers..."
mkdir -p /tmp/livecode-build
if [ ! -L /tmp/livecode-build/java-headers ]; then
    ln -sf /usr/local/opt/openjdk@11/include /tmp/livecode-build/java-headers
fi
echo "✓ JNI headers ready"

# 2. Copy ARM64 libraries to build directory
echo ""
echo "Copying ARM64 libraries..."
mkdir -p _build/mac/Release

# Make existing libraries writable first
chmod -R 644 _build/mac/Release/*.a 2>/dev/null || true

# Copy all ARM64 libraries
cp ARM-libraries-arm64/*.a _build/mac/Release/
echo "✓ Copied $(ls ARM-libraries-arm64/*.a | wc -l | tr -d ' ') ARM64 libraries"

# 3. Verify ARM64 architecture
echo ""
echo "Verifying ARM64 libraries..."
for lib in _build/mac/Release/libffi.a _build/mac/Release/libicuuc.a _build/mac/Release/libskia.a; do
    if [ -f "$lib" ]; then
        arch=$(lipo -info "$lib" | grep -o "arm64" || echo "WRONG")
        if [ "$arch" = "arm64" ]; then
            echo "✓ $(basename $lib): ARM64"
        else
            echo "✗ $(basename $lib): NOT ARM64!"
            exit 1
        fi
    fi
done

# 4. Make libraries read-only to prevent overwriting
echo ""
echo "Protecting ARM64 libraries..."
chmod 444 _build/mac/Release/libffi*.a
chmod 444 _build/mac/Release/libicu*.a
echo "✓ Libraries protected (read-only)"

# 5. Build externals if they don't exist
echo ""
echo "Checking for externals..."
EXTERNALS_NEEDED=false
for ext in revbrowser revdb revxml revspeech; do
    if [ ! -d "_build/mac/Release/${ext}.bundle" ]; then
        EXTERNALS_NEEDED=true
        break
    fi
done

if [ "$EXTERNALS_NEEDED" = true ]; then
    echo "Building externals..."
    ./build-arm64-externals.sh || echo "⚠️  Some externals may have failed"
else
    echo "✓ Externals already built"
fi

# 6. Clean previous build artifacts
echo ""
echo "Cleaning previous build..."
rm -rf _cache/mac/Release/*.build/

# 7. Build standalone target with library monitoring
echo ""
echo "========================================="
echo "Building standalone target..."
echo "========================================="

# Start build in background and monitor for libffi rebuilds
xcodebuild \
    -project "build-mac/livecode/engine/engine.xcodeproj" \
    -target "standalone" \
    -configuration Release \
    -arch arm64 \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET=11.0 \
    2>&1 | tee build-arm64.log &

BUILD_PID=$!

# Monitor and replace libffi if it gets overwritten
echo "Monitoring libffi (PID: $BUILD_PID)..."
while kill -0 $BUILD_PID 2>/dev/null; do
    sleep 2
    # Check if libffi was rebuilt with wrong architecture
    if [ -f "_build/mac/Release/libffi.a" ]; then
        if ar -t _build/mac/Release/libffi.a 2>/dev/null | grep -q "darwin.o"; then
            echo "⚠ Detected x86 libffi rebuild - replacing with ARM64 version..."
            chmod 644 _build/mac/Release/libffi*.a 2>/dev/null || true
            cp ARM-libraries-arm64/libffi.a _build/mac/Release/libffi.a
            cp ARM-libraries-arm64/libffi.a _build/mac/Release/libffi-host.a 2>/dev/null || true
            chmod 444 _build/mac/Release/libffi*.a
            echo "✓ ARM64 libffi restored"
        fi
    fi
done

# Wait for build to complete
wait $BUILD_PID
BUILD_RESULT=$?

if [ $BUILD_RESULT -ne 0 ]; then
    echo "Build process exited with code $BUILD_RESULT"
fi

# 8. Check build result
echo ""
echo "========================================="
if grep -q "BUILD SUCCEEDED" build-arm64.log; then
    echo "✓ BUILD SUCCEEDED!"
    echo "========================================="
    
    # 9. Create deployment folder structure
    echo ""
    echo "Creating deployment folder structure..."
    DEPLOY_DIR="_build/mac/Release/arm64"
    rm -rf "$DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR"/{Externals/"Database Drivers",Support}
    
    # Copy Standalone.app
    echo "Copying Standalone.app..."
    cp -R _build/mac/Release/Standalone-Community.app "$DEPLOY_DIR/Standalone.app"
    
    # Copy externals
    echo "Copying externals..."
    cp -R _build/mac/Release/revbrowser.bundle "$DEPLOY_DIR/Externals/" 2>/dev/null || true
    cp -R _build/mac/Release/revdb.bundle "$DEPLOY_DIR/Externals/" 2>/dev/null || true
    cp -R _build/mac/Release/revxml.bundle "$DEPLOY_DIR/Externals/" 2>/dev/null || true
    cp -R _build/mac/Release/revzip.bundle "$DEPLOY_DIR/Externals/" 2>/dev/null || true
    cp -R _build/mac/Release/revspeech.bundle "$DEPLOY_DIR/Externals/" 2>/dev/null || true
    
    # Copy database drivers
    echo "Copying database drivers..."
    cp -R _build/mac/Release/dbsqlite.bundle "$DEPLOY_DIR/Externals/Database Drivers/" 2>/dev/null || true
    cp -R _build/mac/Release/dbpostgresql.bundle "$DEPLOY_DIR/Externals/Database Drivers/" 2>/dev/null || true
    cp -R _build/mac/Release/dbodbc.bundle "$DEPLOY_DIR/Externals/Database Drivers/" 2>/dev/null || true
    
    # Copy support files
    echo "Copying support files..."
    cp -R _build/mac/Release/revpdfprinter.bundle "$DEPLOY_DIR/Support/" 2>/dev/null || true
    cp _build/mac/Release/revsecurity.dylib "$DEPLOY_DIR/Support/" 2>/dev/null || true
    
    # Create Externals.txt
    echo "Database,revdb.bundle" > "$DEPLOY_DIR/Externals/Externals.txt"
    
    echo ""
    echo "========================================="
    echo "✓ Deployment package created!"
    echo "========================================="
    echo ""
    echo "Location: $DEPLOY_DIR"
    echo ""
    echo "Contents:"
    ls -la "$DEPLOY_DIR"
    echo ""
    echo "Externals:"
    ls -la "$DEPLOY_DIR/Externals"
    echo ""
    echo "Support:"
    ls -la "$DEPLOY_DIR/Support"
    
    exit 0
else
    echo "✗ BUILD FAILED"
    echo "========================================="
    echo ""
    echo "Last 50 lines of build log:"
    tail -50 build-arm64.log
    exit 1
fi
