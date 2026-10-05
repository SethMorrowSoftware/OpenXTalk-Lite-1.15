# Installing macOS 12.1 SDK for LiveCode Build

The LiveCode 9.6.3 build system requires the **macOS 12.1 SDK** to compile successfully. If you've upgraded your macOS and Xcode, you likely have a newer SDK (like 14.4) and need to obtain the older SDK.

## Option 1: Install from Local thirdparty/sdk Directory (Quickest)

If you already have the SDK in `thirdparty/sdk/MacOSX12.1.sdk`:

1. **Symlink the SDK to Xcode** (Recommended - saves disk space)
   ```bash
   cd livecode
   
   # Create SDK directory if it doesn't exist
   sudo mkdir -p /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
   
   # Create symlink
   sudo ln -sf "$(pwd)/thirdparty/sdk/MacOSX12.1.sdk" \
       /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.1.sdk
   ```

sudo chown -R root:wheel \
       /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.1.sdk
   ```

3. **Verify installation**
   ```bash
   xcodebuild -showsdks | grep macosx12.1
   ```
   
   You should see:
   ```
   macOS 12.1                      -sdk macosx12.1
   ```


2. **Set permissions**
   ```bash
   sudo chown -R root:wheel \
       /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.1.sdk
   ```

3. **Verify**
   ```bash
   xcodebuild -showsdks | grep macosx12.1
   ```

## Option 3: Use a GitHub Repository (Community SDKs)

Some developers maintain repositories with legacy SDKs:

1. Check repositories like:
   - https://github.com/phracker/MacOSX-SDKs
   
2. Download the MacOSX12.1.sdk
   ```bash
   cd /tmp
   # Download the specific SDK (check repository for exact link)
   curl -L -O https://github.com/phracker/MacOSX-SDKs/releases/download/12.3/MacOSX12.1.sdk.tar.xz
   
   # Extract
   tar xf MacOSX12.1.sdk.tar.xz
   
   # Install
   sudo mv MacOSX12.1.sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/
   ```

## After SDK Installation

Once you have the macOS 12.1 SDK installed:

sudo chown -R root:wheel /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.1.sdk

run the patch script:

```bash
./patch_installed_SDK.sh
```

3. **Build OpenXTalk**
   ```bash
   ./build_openxtalk_no_patches.sh
   ```

## Troubleshooting

### Issue: "unable to find sdk 'macosx12.1'"

**Solution**: The SDK is not installed. Follow Option 1 above.

### Issue: Permission denied

**Solution**: Use `sudo` when copying SDKs to the Xcode directories.

