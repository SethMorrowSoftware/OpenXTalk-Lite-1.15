# OpenXTalk Lite icons

Tom Perry's OpenXTalk Lite icon, used where the packages need an icon file
of their own. No artwork was drawn for this repository.

| file | from |
|---|---|
| `OpenXTalk-Lite.icns` | `patches/OpenXTalk-lite_1024.icns` in Tom Perry's macOS source trees (`macos-arm64/` and `macos-intel/` in [openxtalk/OpenXTalk-Lite](https://github.com/openxtalk/OpenXTalk-Lite)), unchanged: the app icon his `integrate_openxtalk_icon.sh` installed. `tools/oxt/package.py` copies it into the macOS app. |
| `png/openxtalk-lite-<size>.png` | the images of `ide/OpenXTalk-lite_1024.ico` (the icon the OpenXTalk Lite 1.15 IDE ships), written by `ico_to_png.py`: 16 to 256 converted from the icon's 32-bit bitmaps, 512 its PNG image byte for byte. The Linux package installs them (`LINUX_ICON_SIZES` in `package.py`). |

The Windows installer and its shortcuts use `ide/OpenXTalk-lite_1024.ico`
itself.

To make `png/` again:

```
python Installer/openxtalk-lite/branding/ico_to_png.py ide/OpenXTalk-lite_1024.ico Installer/openxtalk-lite/branding/png openxtalk-lite
```
