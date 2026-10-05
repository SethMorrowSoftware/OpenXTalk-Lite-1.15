#!/usr/bin/env python3
"""Write each image of a Windows .ico file as a PNG file.

  python ico_to_png.py <file.ico> <out-folder> <prefix>

writes <out-folder>/<prefix>-<size>.png for every square image in the icon:
a PNG image is copied byte for byte (named after the size in its own
header, as the icon's directory says 256 for anything larger), a 32-bit
BMP image is converted (its alpha channel, or the AND mask when every
alpha value is 0). When an icon holds two images of one size, the PNG one
wins.

Used to make png/ from Tom Perry's ide/OpenXTalk-lite_1024.ico:

  python Installer/openxtalk-lite/branding/ico_to_png.py \\
      ide/OpenXTalk-lite_1024.ico Installer/openxtalk-lite/branding/png openxtalk-lite

Only the Python 3 standard library is used.
"""

import os
import struct
import sys
import zlib

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def png_chunk(kind, data):
    return (struct.pack('>I', len(data)) + kind + data
            + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff))


def write_png(width, height, rows):
    """rows: height lists of RGBA bytes, top row first."""
    raw = b''.join(b'\x00' + bytes(row) for row in rows)
    return (PNG_SIGNATURE
            + png_chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
            + png_chunk(b'IDAT', zlib.compress(raw, 9))
            + png_chunk(b'IEND', b''))


def bmp_to_png(data, width, height):
    header_size, bmp_width, bmp_height, _, bit_count = struct.unpack('<IiiHH', data[:16])
    if bit_count != 32:
        raise ValueError('%dx%d image has %d bits per pixel; only 32 is supported' % (width, height, bit_count))
    if bmp_width != width or abs(bmp_height) != 2 * height:
        raise ValueError('%dx%d image has a %dx%d bitmap' % (width, height, bmp_width, bmp_height))
    stride = width * 4
    pixels = data[header_size:header_size + stride * height]
    mask_stride = ((width + 31) // 32) * 4
    mask = data[header_size + stride * height:]
    use_mask = all(pixels[i] == 0 for i in range(3, len(pixels), 4))
    rows = []
    for y in range(height):
        src = height - 1 - y                     # the bitmap is stored bottom-up
        row = bytearray()
        for x in range(width):
            b, g, r, a = pixels[src * stride + 4 * x:src * stride + 4 * x + 4]
            if use_mask:
                bit = mask[src * mask_stride + x // 8] >> (7 - x % 8) & 1
                a = 0 if bit else 255
            row += bytes((r, g, b, a))
        rows.append(row)
    return write_png(width, height, rows)


def images(path):
    with open(path, 'rb') as f:
        data = f.read()
    reserved, kind, count = struct.unpack('<HHH', data[:6])
    if reserved != 0 or kind != 1:
        raise ValueError('%s is not an .ico file' % path)
    found = {}
    for i in range(count):
        w, h, _, _, _, _, size, offset = struct.unpack('<BBBBHHII', data[6 + 16 * i:22 + 16 * i])
        w, h = w or 256, h or 256
        body = data[offset:offset + size]
        if body[:8] == PNG_SIGNATURE:
            # The directory says 256 (0) for anything larger; the PNG's own
            # header has the real size
            w, h = struct.unpack('>II', body[16:24])
        if w != h:
            continue
        if body[:8] == PNG_SIGNATURE:
            found[w] = body
        elif w not in found:
            found[w] = bmp_to_png(body, w, h)
    return found


def main(argv):
    if len(argv) != 4:
        sys.stderr.write(__doc__)
        return 2
    ico, out, prefix = argv[1:]
    os.makedirs(out, exist_ok=True)
    for size, png in sorted(images(ico).items()):
        name = os.path.join(out, '%s-%d.png' % (prefix, size))
        with open(name, 'wb') as f:
            f.write(png)
        print('%s (%d bytes)' % (name, len(png)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
