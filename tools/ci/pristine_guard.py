#!/usr/bin/env python3
"""Check that the code is still Tom Perry's OpenXTalk Lite 1.15.

  python3 tools/ci/pristine_guard.py [--base REF] [--head REF]
      [--allowlist FILE] [--summary]

The tag tom-perry-1.15 is OpenXTalk Lite 1.15 as Tom Perry left it: its
tree is exactly windows/ of openxtalk/OpenXTalk-Lite at 6f8f4cc851
(EXPECTED_TREE). Everything after it must stay inside the paths that
.github/pristine-allowlist.txt allows: the repository's own files (CI,
tests, packaging, documentation) and, one by one, the files that the
build changes touch. This script

  1. checks that --base (default tom-perry-1.15) still has EXPECTED_TREE,
     so the reference cannot move;
  2. lists every path that differs between --base and --head (default
     HEAD), without rename detection (a renamed file counts as a deleted
     and an added path), and fails on each one no allowlist pattern
     matches;
  3. reports each build-change path (the "build" section of the
     allowlist) with its line counts, and warns about allowlist entries
     of that section that match nothing (a file the build no longer
     changes should leave the list).

The allowlist has one pattern per line; text after "#" is a comment; a
line "[harness]" or "[build]" starts a section (patterns before any
section header count as harness). A pattern is a path relative to the
repository root; "*" matches within one path segment, "**" any number of
segments, and a pattern ending in "/**" a whole folder.

--summary appends the report to the GitHub Actions job summary.

Exit status: 0 the code is pristine apart from the allowed paths, 1 a
check failed, 2 usage or git errors.

Only the Python 3 standard library is used.
"""

import argparse
import os
import re
import subprocess
import sys

BASE_TAG = 'tom-perry-1.15'
# windows/ of openxtalk/OpenXTalk-Lite at 6f8f4cc851 ("OpenXTalk Lite
# Windows engine work by Tom Perry"): LiveCode Community 9.7 develop
# 4606a10ea with the OpenXTalk Lite 1.15 IDE and Tom Perry's engine work
EXPECTED_TREE = '7578af0924f537495f952e06ea4588b3e075e906'
DEFAULT_ALLOWLIST = '.github/pristine-allowlist.txt'


class GuardError(Exception):
    pass


def git(*args):
    try:
        out = subprocess.run(('git',) + args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        raise GuardError('git %s: %s' % (' '.join(args), e.stderr.decode('utf-8', 'replace').strip()))
    return out.stdout.decode('utf-8', 'surrogateescape')


def glob_to_regex(pattern):
    """A path pattern as a regular expression: "**" any number of path
    segments (also none), "*" anything within one segment, "?" one
    character other than "/"."""
    out = []
    i = 0
    while i < len(pattern):
        c = pattern[i]
        if pattern.startswith('**/', i):
            out.append('(?:.*/)?')
            i += 3
        elif pattern.startswith('**', i):
            out.append('.*')
            i += 2
        elif c == '*':
            out.append('[^/]*')
            i += 1
        elif c == '?':
            out.append('[^/]')
            i += 1
        else:
            out.append(re.escape(c))
            i += 1
    return re.compile('^' + ''.join(out) + '$')


def read_allowlist(path):
    """[(section, pattern, regex, line number)]"""
    entries = []
    section = 'harness'
    with open(path, encoding='utf-8') as f:
        for number, line in enumerate(f, 1):
            line = line.split('#', 1)[0].strip()
            if not line:
                continue
            m = re.match(r'^\[(harness|build)\]$', line)
            if m:
                section = m.group(1)
                continue
            if line.startswith('/') or '\\' in line:
                raise GuardError('%s:%d: %r: write paths relative to the repository root, with "/"'
                                 % (path, number, line))
            entries.append((section, line, glob_to_regex(line), number))
    return entries


def changed_paths(base, head):
    """[(status, path)] of what differs between base and head, without
    rename detection"""
    out = git('diff', '--no-renames', '--name-status', '-z', base, head)
    fields = out.split('\0')
    changes = []
    i = 0
    while i + 1 < len(fields):
        status, path = fields[i], fields[i + 1]
        changes.append((status, path))
        i += 2
    return changes


def numstat(base, head, paths):
    if not paths:
        return {}
    out = git('diff', '--no-renames', '--numstat', '-z', base, head, '--', *paths)
    stats = {}
    for record in out.split('\0'):
        if not record:
            continue
        added, removed, path = record.split('\t', 2)
        stats[path] = (added, removed)
    return stats


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--base', default=BASE_TAG, help='the pristine reference (default %(default)s)')
    ap.add_argument('--head', default='HEAD', help='the commit to check (default %(default)s)')
    ap.add_argument('--allowlist', default=DEFAULT_ALLOWLIST, help='default %(default)s')
    ap.add_argument('--summary', action='store_true', help='append the report to the job summary')
    args = ap.parse_args(argv)
    gha = os.environ.get('GITHUB_ACTIONS') == 'true'

    def error(message):
        print('::error title=Pristine guard::%s' % message if gha else 'error: %s' % message)

    def warning(message):
        print('::warning title=Pristine guard::%s' % message if gha else 'warning: %s' % message)

    try:
        tree = git('rev-parse', '%s^{tree}' % args.base).strip()
        head = git('rev-parse', '%s^{commit}' % args.head).strip()
        entries = read_allowlist(args.allowlist)
        changes = changed_paths(args.base, args.head)
    except (GuardError, OSError) as e:
        error(str(e))
        return 2

    failed = False
    if tree != EXPECTED_TREE:
        error('%s has the tree %s, not %s (windows/ of openxtalk/OpenXTalk-Lite at 6f8f4cc851): '
              'the reference has moved' % (args.base, tree, EXPECTED_TREE))
        failed = True

    harness, build, outside = [], [], []
    used = set()
    for status, path in changes:
        match = next((e for e in entries if e[2].match(path)), None)
        if match is None:
            outside.append((status, path))
            continue
        used.add(match[3])
        (build if match[0] == 'build' else harness).append((status, path))

    for status, path in outside:
        error('%s %s: not allowed to differ from %s (add it to %s, in a commit that says why, '
              'only if the build needs it)' % (status, path, args.base, args.allowlist))
    if outside:
        failed = True
    stale = [e for e in entries if e[0] == 'build' and e[3] not in used]
    for section, pattern, _, number in stale:
        warning('%s:%d: %s matches no changed path; remove it if the build no longer changes it'
                % (args.allowlist, number, pattern))

    stats = numstat(args.base, args.head, [p for _, p in build])
    lines = ['### Pristine guard', '',
             '`%s` (tree `%s`) against `%s`: %d paths differ, %d of them repository files (CI, tests, '
             'packaging, documentation), %d build changes, %d not allowed.'
             % (args.base, tree[:12], head[:12], len(changes), len(harness), len(build), len(outside)), '']
    if outside:
        lines += ['**Not allowed:**', ''] + ['- `%s` %s' % (p, s) for s, p in outside] + ['']
    if build:
        lines += ['<details><summary>Build changes to Tom Perry\'s files</summary>', '',
                  '| path | status | lines added | lines removed |', '| --- | --- | ---: | ---: |']
        for status, path in build:
            added, removed = stats.get(path, ('', ''))
            lines.append('| `%s` | %s | %s | %s |' % (path, status, added, removed))
        lines += ['', '</details>', '']
    report = '\n'.join(lines)
    print(report)
    if args.summary and os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8', newline='\n') as f:
            f.write(report + '\n')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
