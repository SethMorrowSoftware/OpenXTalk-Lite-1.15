#!/usr/bin/env python3
"""Make, or check, a file that compiles to Tom Perry's macOS version on
macOS and to his Windows version everywhere else.

  python3 tools/ci/per_platform.py make WINDOWS_FILE MACOS_FILE > MERGED_FILE
  python3 tools/ci/per_platform.py split MERGED_FILE macos|windows > FILE

Tom Perry's Windows and macOS working copies (the tags tom-perry-1.15 and
tom-perry-1.15-macos) changed some files that every platform compiles,
differently or only one of them. In the merged tree each such file holds
both versions: every region where they differ becomes

  #if defined(_MACOSX) /* OXT-TOM: macOS */
  ...his macOS lines...
  #else /* OXT-TOM: Windows */
  ...his Windows lines...
  #endif /* OXT-TOM */

(with "#if !defined(_MACOSX) /* OXT-TOM: Windows */" when only the
Windows version has lines there), so that a macOS build compiles exactly
his macOS file and every other build, Linux included, exactly his
Windows file. A region is widened until the conditional directives inside
each of its two versions are balanced, so that the preprocessor never
pairs one of his #endif lines with one of these.

"split" undoes it: it keeps the macOS or the Windows lines of every
marked region and drops the marker lines, which must give his file back
byte for byte. tools/ci/pristine_guard.py checks that for every file that
section 1 of CHANGES-FROM-TOM.md marks "per-platform".

Lines keep their own line endings; the marker lines take the line ending
of the file. Only the Python 3 standard library is used.
"""

import difflib
import re
import sys

MAC_IF = '#if defined(_MACOSX) /* OXT-TOM: macOS */'
WIN_IF = '#if !defined(_MACOSX) /* OXT-TOM: Windows */'
ELSE = '#else /* OXT-TOM: Windows */'
ENDIF = '#endif /* OXT-TOM */'
MARKERS = (MAC_IF, WIN_IF, ELSE, ENDIF)

_OPEN = re.compile(rb'^\s*#\s*if(n?def)?\b')
_CLOSE = re.compile(rb'^\s*#\s*endif\b')


def _depths(lines):
    """The conditional-directive nesting depth before each line, and after
    the last one"""
    depths = [0]
    for line in lines:
        d = depths[-1]
        if _OPEN.match(line):
            d += 1
        elif _CLOSE.match(line):
            d -= 1
        depths.append(d)
    return depths


def _newline(lines):
    crlf = sum(1 for l in lines if l.endswith(b'\r\n'))
    return b'\r\n' if crlf * 2 > len(lines) else b'\n'


def make(win, mac):
    """The merged bytes of the Windows and macOS versions (bytes)."""
    a = win.splitlines(keepends=True)
    b = mac.splitlines(keepends=True)
    if a and not a[-1].endswith(b'\n') or b and not b[-1].endswith(b'\n'):
        raise ValueError('both versions must end with a line end')
    nl = _newline(a + b)
    da, db = _depths(a), _depths(b)
    if da[-1] != 0 or db[-1] != 0:
        raise ValueError('a version has unbalanced conditional directives')
    ops = difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes()
    # A region may only start or end where both versions are outside every
    # conditional directive (depth 0) and at the same line of an equal run.
    # Cut the file into pieces at those points; a piece with a difference
    # becomes one region, holding both versions whole.
    groups = []
    start = (0, 0)
    differs = False

    def flush(end):
        nonlocal start, differs
        if end == start:
            return
        groups.append(('diff' if differs else 'equal', start[0], end[0], start[1], end[1]))
        start, differs = end, False

    for tag, a0, a1, b0, b1 in ops:
        if tag != 'equal':
            differs = True
            continue
        for k in range(a1 - a0):
            pos = (a0 + k, b0 + k)
            if da[pos[0]] == 0 and db[pos[1]] == 0:
                flush(pos)
    flush((len(a), len(b)))
    # Neighbouring equal pieces back into one
    merged_groups = []
    for g in groups:
        if merged_groups and g[0] == 'equal' and merged_groups[-1][0] == 'equal':
            prev = merged_groups.pop()
            g = ('equal', prev[1], g[2], prev[3], g[4])
        merged_groups.append(g)
    groups = merged_groups
    out = []
    for kind, a0, a1, b0, b1 in groups:
        if kind == 'equal':
            out += a[a0:a1]
        elif a0 == a1:
            out += [MAC_IF.encode() + nl] + b[b0:b1] + [ENDIF.encode() + nl]
        elif b0 == b1:
            out += [WIN_IF.encode() + nl] + a[a0:a1] + [ENDIF.encode() + nl]
        else:
            out += [MAC_IF.encode() + nl] + b[b0:b1] + [ELSE.encode() + nl] + a[a0:a1] + [ENDIF.encode() + nl]
    merged = b''.join(out)
    if split(merged, 'macos') != mac or split(merged, 'windows') != win:
        raise ValueError('the merged file does not split back into the two versions')
    return merged


def split(merged, which):
    """The macOS or Windows version of a merged file (bytes)."""
    keep_mac = which == 'macos'
    out = []
    state = None   # None outside a region; 'mac' or 'win' inside
    for line in merged.splitlines(keepends=True):
        text = line.rstrip(b'\r\n').decode('utf-8', 'surrogateescape')
        if text in MARKERS:
            if text == MAC_IF and state is None:
                state = 'mac'
            elif text == WIN_IF and state is None:
                state = 'win'
            elif text == ELSE and state == 'mac':
                state = 'win'
            elif text == ENDIF and state is not None:
                state = None
            else:
                raise ValueError('unexpected marker %r' % text)
            continue
        if state is None or (state == 'mac') == keep_mac:
            out.append(line)
    if state is not None:
        raise ValueError('a region is not closed')
    return b''.join(out)


def main(argv):
    if len(argv) == 4 and argv[1] == 'make':
        with open(argv[2], 'rb') as f:
            win = f.read()
        with open(argv[3], 'rb') as f:
            mac = f.read()
        sys.stdout.buffer.write(make(win, mac))
        return 0
    if len(argv) == 4 and argv[1] == 'split' and argv[3] in ('macos', 'windows'):
        with open(argv[2], 'rb') as f:
            sys.stdout.buffer.write(split(f.read(), argv[3]))
        return 0
    sys.stderr.write(__doc__)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
