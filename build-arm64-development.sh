#!/bin/bash
set -e

# Build LiveCode-Community.app (IDE) for ARM64 macOS
# This is the full LiveCode IDE, not just the standalone engine

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Building LiveCode-Community.app (IDE)"
echo "for ARM64 macOS"
echo "========================================="

# Setup Java JDK for JNI headers (persistent location inside project tree)
echo ""
echo "Setting up Java JDK for JNI support..."

# Use Homebrew OpenJDK 11
JAVA_HOME_PATH="/usr/local/opt/openjdk@11"
JAVA_HEADERS_DIR="$SCRIPT_DIR/prebuilt/include/java-headers"

if [ -d "$JAVA_HOME_PATH" ]; then
    echo "Java JDK found at: $JAVA_HOME_PATH"
    export JAVA_HOME="$JAVA_HOME_PATH"
    
    # Create symlink inside project tree (persistent across reboots)
    if [ -L "$JAVA_HEADERS_DIR" ] || [ -d "$JAVA_HEADERS_DIR" ]; then
        rm -rf "$JAVA_HEADERS_DIR"
    fi
    
    ln -s "$JAVA_HOME_PATH/include" "$JAVA_HEADERS_DIR"
    echo "Created symlink: $JAVA_HEADERS_DIR -> $JAVA_HOME_PATH/include"
    
    if [ -f "$JAVA_HEADERS_DIR/jni.h" ]; then
        echo "JNI headers verified at: $JAVA_HEADERS_DIR/jni.h"
    else
        echo "WARNING: JNI headers not found"
    fi
else
    echo "ERROR: Homebrew OpenJDK 11 not found at $JAVA_HOME_PATH"
    echo "Please install it with: brew install openjdk@11"
    exit 1
fi

echo ""

# Build libmysql.a from source for ARM64
echo ""
echo "========================================="
echo "Building libmysql.a from source (ARM64)..."
echo "========================================="

MYSQL_BUILD_DIR="_build/libmysql-arm64"
MYSQL_SRC_DIR="thirdparty/libmysql"
mkdir -p "$MYSQL_BUILD_DIR"

MYSQL_ERRORS=0
for f in "$MYSQL_SRC_DIR"/src/*.c; do
    xcrun clang -arch arm64 -c -O2 -w \
        -D_MACOSX -DHAVE_OPENSSL -DOPENSSL_API_COMPAT=0x10000100L \
        -I "$MYSQL_SRC_DIR/include" -I "$MYSQL_SRC_DIR/src" -I prebuilt/include \
        -isysroot thirdparty/sdk/MacOSX12.1.sdk \
        -mmacosx-version-min=10.9 \
        "$f" -o "$MYSQL_BUILD_DIR/$(basename "$f" .c).o" 2>&1
    if [ $? -ne 0 ]; then
        MYSQL_ERRORS=$((MYSQL_ERRORS + 1))
    fi
done

if [ $MYSQL_ERRORS -eq 0 ]; then
    xcrun ar rcs "$MYSQL_BUILD_DIR/libmysql.a" "$MYSQL_BUILD_DIR"/*.o
    chmod 644 ARM-libraries-arm64/libmysql.a 2>/dev/null || true
    cp "$MYSQL_BUILD_DIR/libmysql.a" ARM-libraries-arm64/libmysql.a
    echo "libmysql.a built from source (arm64)"
else
    echo "libmysql.a build had $MYSQL_ERRORS errors"
fi

# Make libraries writable first
echo ""
echo "Making libraries writable..."
chmod 644 ARM-libraries-arm64/*.a 2>/dev/null || true
chmod 644 prebuilt/lib/mac/*.a 2>/dev/null || true

# Copy all ARM64 libraries to prebuilt
echo "Copying ARM64 libraries to prebuilt..."
cp ARM-libraries-arm64/*.a prebuilt/lib/mac/

# Protect libraries as read-only
echo "Protecting ARM64 libraries..."
chmod 444 ARM-libraries-arm64/*.a
chmod 444 prebuilt/lib/mac/*.a

# Clean build artifacts
echo ""
echo "Cleaning previous build..."
rm -rf _build/mac/Release/LiveCode-Community.app
rm -rf _build/mac/Release/*.a
rm -rf _cache/mac

# Monitor and replace libffi if it gets rebuilt with x86 sources
echo ""
echo "Starting build with libffi monitoring..."
xcodebuild -project "build-mac/livecode/engine/engine.xcodeproj" \
    -target "development" \
    -configuration Release \
    -arch arm64 \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO \
    > build-development-arm64.log 2>&1 &

BUILD_PID=$!

# Monitor for libffi rebuild
while kill -0 $BUILD_PID 2>/dev/null; do
    sleep 2
    
    # Check if libffi was rebuilt with x86 sources
    if [ -f "_build/mac/Release/libffi.a" ]; then
        if ar -t _build/mac/Release/libffi.a 2>/dev/null | grep -q "darwin.o"; then
            echo "Detected x86 libffi rebuild - replacing with ARM64 version..."
            chmod 644 _build/mac/Release/libffi*.a 2>/dev/null || true
            cp ARM-libraries-arm64/libffi.a _build/mac/Release/libffi.a
            chmod 444 _build/mac/Release/libffi*.a
        fi
    fi
done

# Wait for build to complete
wait $BUILD_PID
BUILD_EXIT=$?

echo ""
echo "========================================="

if [ $BUILD_EXIT -eq 0 ]; then
    echo "✓ BUILD SUCCEEDED!"
    echo "========================================="
    echo ""
    echo "LiveCode IDE location:"
    find _build/mac/Release -name "LiveCode-Community.app" -type d
    
    if [ -f "_build/mac/Release/LiveCode-Community.app/Contents/MacOS/LiveCode-Community" ]; then
        echo ""
        echo "Verifying ARM64 architecture..."
        lipo -info _build/mac/Release/LiveCode-Community.app/Contents/MacOS/LiveCode-Community
        ls -lh _build/mac/Release/LiveCode-Community.app/Contents/MacOS/LiveCode-Community
    fi
    
    # Build externals (revxml, revdb, etc.) for ARM64
    echo ""
    echo "========================================="
    echo "Building ARM64 externals (revxml, etc.)..."
    echo "========================================="
    
    # Build revxml
    xcodebuild -project "build-mac/livecode/revxml/revxml.xcodeproj" \
        -target "external-revxml" \
        -configuration Release \
        -arch arm64 \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        >> build-development-arm64.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "revxml.bundle"
    else
        echo "revxml failed (check log)"
    fi
    
    # Build revdb (database connectivity)
    xcodebuild -project "build-mac/livecode/revdb/revdb.xcodeproj" \
        -target "external-revdb" \
        -configuration Release \
        -arch arm64 \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        >> build-development-arm64.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "revdb.bundle"
    else
        echo "revdb failed (check log)"
    fi
    
    # Build dbsqlite (SQLite database driver)
    xcodebuild -project "build-mac/livecode/revdb/revdb.xcodeproj" \
        -target "dbsqlite" \
        -configuration Release \
        -arch arm64 \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        >> build-development-arm64.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "dbsqlite.bundle"
    else
        echo "dbsqlite failed (check log)"
    fi
    
    # Build dbmysql (MySQL database driver — requires arm64 libmysql.a)
    xcodebuild -project "build-mac/livecode/revdb/revdb.xcodeproj" \
        -target "dbmysql" \
        -configuration Release \
        -arch arm64 \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        >> build-development-arm64.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "dbmysql.bundle"
    else
        echo "dbmysql skipped (needs arm64 libmysql.a prebuilt)"
    fi
    
    echo ""
    echo "Built externals:"
    ls -1 _build/mac/Release/*.bundle _build/mac/Release/*.dylib 2>/dev/null | grep -v "\.app" | while read f; do echo "  $(basename "$f")"; done || echo "  (none)"
    
    # Build ARM64 toolchain (lc-compile-ffi-java, lc-run)
    # Note: The libffi Xcode project has been modified to copy the prebuilt ARM64
    # libffi.a instead of compiling from source (which was missing arm64 assembly).
    echo ""
    echo "========================================="
    echo "Building ARM64 toolchain..."
    echo "========================================="
    
    # Build lc-compile-ffi-java
    xcodebuild -project "build-mac/livecode/toolchain/lc-compile-ffi-java/lc-compile-ffi-java.xcodeproj" \
        -target "lc-compile-ffi-java" \
        -configuration Release \
        -arch arm64 \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        >> build-development-arm64.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  lc-compile-ffi-java"
    else
        echo "  lc-compile-ffi-java failed (check log)"
    fi
    
    # Build lc-run
    xcodebuild -project "build-mac/livecode/toolchain/lc-compile/lc-run.xcodeproj" \
        -target "lc-run" \
        -configuration Release \
        -arch arm64 \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        >> build-development-arm64.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  lc-run"
    else
        echo "  lc-run failed (check log)"
    fi
    
    # Verify toolchain architectures
    echo ""
    echo "Toolchain binaries:"
    for tool in lc-compile lc-compile-ffi-java lc-run; do
        if [ -f "_build/mac/Release/$tool" ]; then
            ARCH=$(lipo -info "_build/mac/Release/$tool" 2>/dev/null | awk -F': ' '{print $NF}')
            echo "  $tool: $ARCH"
        else
            echo "  $tool: NOT FOUND"
        fi
    done
    
    # Apply OpenXTalk customizations
    echo ""
    echo "========================================="
    echo "Applying OpenXTalk customizations..."
    echo "========================================="
    
    BUILD_DIR="_build/mac/Release"
    
    # Check if LiveCode-Community.app exists
    if [ ! -d "$BUILD_DIR/LiveCode-Community.app" ]; then
        echo "ERROR: LiveCode-Community.app not found at $BUILD_DIR/LiveCode-Community.app"
        exit 1
    fi
    
    # Rename the app
    if [ -d "$BUILD_DIR/OpenXTalk-Lite-ARM.app" ]; then
        rm -rf "$BUILD_DIR/OpenXTalk-Lite-ARM.app"
    fi
    
    echo "Copying to OpenXTalk-Lite-ARM.app..."
    cp -R "$BUILD_DIR/LiveCode-Community.app" "$BUILD_DIR/OpenXTalk-Lite-ARM.app"
    echo "Renamed app to OpenXTalk-Lite-ARM.app"
    
    # Update Info.plist
    PLIST_FILE="$BUILD_DIR/OpenXTalk-Lite-ARM.app/Contents/Info.plist"
    if [ -f "$PLIST_FILE" ]; then
        echo "Updating Info.plist with OpenXTalk branding..."
        # Update bundle name and display name
        /usr/libexec/PlistBuddy -c "Set :CFBundleName 'OpenXTalk Lite'" "$PLIST_FILE" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'OpenXTalk Lite'" "$PLIST_FILE" 2>/dev/null || true
        echo "Updated Info.plist"
    else
        echo "WARNING: Info.plist not found: $PLIST_FILE"
    fi
    
    # Replace icons with custom icons
    ICONS_DIR="$SCRIPT_DIR/engine/icons"
    MAIN_ICON_DIR="$BUILD_DIR/OpenXTalk-Lite-ARM.app/Contents/Resources"
    
    if [ -d "$ICONS_DIR" ] && [ -d "$MAIN_ICON_DIR" ]; then
        echo "Copying custom icons from engine/icons/..."
        
        # Copy main application icon
        if [ -f "$ICONS_DIR/LiveCode.icns" ]; then
            cp "$ICONS_DIR/LiveCode.icns" "$MAIN_ICON_DIR/LiveCode.icns"
            cp "$ICONS_DIR/LiveCode.icns" "$MAIN_ICON_DIR/LiveCode-Community.icns"
            cp "$ICONS_DIR/LiveCode.icns" "$MAIN_ICON_DIR/OpenXTalk-Lite.icns"
            echo "Main application icon (LiveCode.icns)"
        fi
        
        # Copy document icons
        if [ -f "$ICONS_DIR/LiveCodeDoc.icns" ]; then
            cp "$ICONS_DIR/LiveCodeDoc.icns" "$MAIN_ICON_DIR/LiveCodeDoc.icns"
            echo "LiveCode document icon (LiveCodeDoc.icns)"
        fi
        
        if [ -f "$ICONS_DIR/OpenXTalkDoc.icns" ]; then
            cp "$ICONS_DIR/OpenXTalkDoc.icns" "$MAIN_ICON_DIR/OpenXTalkDoc.icns"
            echo "OpenXTalk document icon (OpenXTalkDoc.icns)"
        fi
        
        # Fix permissions
        find "$MAIN_ICON_DIR" -name "*.icns" -exec chmod 644 {} \;
        
        echo "Custom icons installed"
    else
        if [ ! -d "$ICONS_DIR" ]; then
            echo "WARNING: Custom icons directory not found: $ICONS_DIR"
        fi
        if [ ! -d "$MAIN_ICON_DIR" ]; then
            echo "WARNING: Resources directory not found: $MAIN_ICON_DIR"
        fi
    fi
    
    # Apply ad-hoc codesigning
    echo ""
    echo "Applying ad-hoc codesigning..."
    
    if [ -d "$BUILD_DIR/OpenXTalk-Lite-ARM.app" ]; then
        # Remove any existing signatures first
        codesign --remove-signature "$BUILD_DIR/OpenXTalk-Lite-ARM.app" 2>/dev/null || true
        
        # Apply ad-hoc codesigning
        codesign --force --deep --sign - "$BUILD_DIR/OpenXTalk-Lite-ARM.app"
        
        if [ $? -eq 0 ]; then
            echo "Ad-hoc codesigning completed"
        else
            echo "Codesigning failed, but build is still usable"
        fi
        
        # Verify the signature
        codesign --verify --verbose "$BUILD_DIR/OpenXTalk-Lite-ARM.app" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Codesignature verification passed"
        else
            echo "Codesignature verification failed"
        fi
    fi
    
    # Set proper file permissions
    echo ""
    echo "Setting proper file permissions..."
    
    # Ensure proper ownership and permissions
    chown -R $(whoami):staff "$BUILD_DIR/OpenXTalk-Lite-ARM.app"
    chmod -R u+rwX,go+rX "$BUILD_DIR/OpenXTalk-Lite-ARM.app"
    
    # Ensure executables are properly executable
    find "$BUILD_DIR/OpenXTalk-Lite-ARM.app" -type f -name "*" -perm +111 -exec chmod 755 {} \;
    find "$BUILD_DIR/OpenXTalk-Lite-ARM.app" -path "*/MacOS/*" -type f -exec chmod 755 {} \;
    
    echo "File permissions set"
    
    echo ""
    echo "========================================="
    echo "OpenXTalk Lite Build Complete!"
    echo "========================================="
    echo ""
    echo "Your OpenXTalk-Lite-ARM.app is ready at:"
    echo "$BUILD_DIR/OpenXTalk-Lite-ARM.app"
    echo ""
    echo "To run OpenXTalk Lite:"
    echo "open '$BUILD_DIR/OpenXTalk-Lite-ARM.app'"
    echo ""
    
else
    echo "BUILD FAILED"
    echo "========================================="
    echo ""
    echo "Last 50 lines of build log:"
    tail -50 build-development-arm64.log
fi

exit $BUILD_EXIT
