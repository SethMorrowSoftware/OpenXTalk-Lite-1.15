# Files from Tom Perry's OpenXTalk Lite 1.15 release

Files of Tom Perry's own Windows release of OpenXTalk Lite 1.15 that no
source tree of his has, kept here byte for byte so that the packages of
this repository carry them as his release does. They come from
`openxtalk-lite-1.15-win-noinstaller.7z` (SHA-256
`9f3b388d953edab05c88c9025c8f9f877fe6ec1038f3572908bab11f0556edcb`),
folder `OpenXTalk Lite/`. `.gitattributes` keeps git from changing their
line endings.

## `Ext/`

His release's `Ext` folder, unchanged: the mergExt collection, which his
IDE loads at startup (`Toolset/home.livecodescript`,
`revInternal__SetupExternals` and `revEnvironmentExtPath`):

| folder | what | licence (its `LICENSE.txt`) |
|---|---|---|
| `blur-1.1.53` | the `blur` command (Trevor DeVore) | MIT |
| `mergJSON-1.0.70` | `mergJSONEncode`, `mergJSONDecode` (Monte Goulding) | GPLv3 |
| `mergMarkdown-1.0.66` | `mergMarkdownToXHTML` (Monte Goulding) | MIT |
| `mergMicrophone-1.0.66` | microphone recording, macOS only (Monte Goulding) | GPLv3 |

`tools/oxt/package.py` puts it into the Windows package. The macOS and
Linux packages do not have it: its macOS builds are i386 and x86_64 only
(the app must be universal), and its Linux builds were never tried with
this IDE.

## `win-exe-resources/`

The icon and version resources of his `OpenXTalk-Lite.exe`, which he wrote
into the engine after building it (the engine sources,
`engine/rsrc/development.rc`, still name LiveCode's): `RT_GROUP_ICON` 111
(the class icon of every engine window, his `ide/OpenXTalk-lite_1024.ico`)
and 112 (the document icon), their 18 `RT_ICON` images, and `RT_VERSION`
("OpenXTalk for Windows", "OpenXTalk 2019-2026"). One file per resource,
`<type>-<id>-<language>.bin`, as read from his exe.
`tools/oxt/win_resources.py apply` gives the packaged `OpenXTalk-Lite.exe`
exactly these (`tools/ci/package-windows.ps1` runs it after staging).
