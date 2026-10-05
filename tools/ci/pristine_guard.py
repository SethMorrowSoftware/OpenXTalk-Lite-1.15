#!/usr/bin/env python3
"""Check that every difference from Tom Perry's source is documented.

  python3 tools/ci/pristine_guard.py [--head REF] [--changes FILE]
      [--allowlist FILE] [--summary]

Tom Perry's source is two tags (CHANGES-FROM-TOM.md says what they are):
tom-perry-1.15, his Windows working copy with the OpenXTalk Lite IDE
1.15, and tom-perry-1.15-macos, his Apple Silicon working copy, each the
tree of a folder of openxtalk/OpenXTalk-Lite (EXPECTED_TREES). The tag
tom-perry-1.15-merged merges them. This script checks:

  1. The references: each tag still has its expected tree, and the merge's
     parents are the two of them, so that nothing can move the reference.
  2. The merge: for every path, the merged tree must have what Tom Perry's
     trees give (the version of the one tree that changed the path from
     the trees' common base, or the version both have), unless section 1
     of CHANGES-FROM-TOM.md has a row for the path, "| `path` | windows |",
     "macos" or "combined": then the merged tree must have his Windows
     version, his macOS version, or something that is neither. A path
     both trees changed differently must have a row.
  3. After the merge: every path that differs between tom-perry-1.15-merged
     and --head (default HEAD), without rename detection, must be either
     named (in backquotes) in section 2 of CHANGES-FROM-TOM.md, or an added
     path matched by a pattern of .github/pristine-allowlist.txt (this
     repository's own folders). A file of Tom Perry's that is changed or
     deleted must always be named.

It warns about rows and names in CHANGES-FROM-TOM.md that match nothing,
and lists the documented changes with their line counts. --summary
appends the report to the GitHub Actions job summary.

The allowlist has one path pattern per line ("*" within a path segment,
"**" across segments; "#" starts a comment).

Exit status: 0 everything is documented, 1 a check failed, 2 usage or git
errors. Only the Python 3 standard library is used. The checks need the
trees of the tags and of --head, not the files' contents.
"""

import argparse
import os
import re
import subprocess
import sys

WINDOWS_TAG = 'tom-perry-1.15'
MACOS_TAG = 'tom-perry-1.15-macos'
MERGED_TAG = 'tom-perry-1.15-merged'
EXPECTED_TREES = {
    # windows/ of openxtalk/OpenXTalk-Lite at 6f8f4cc851
    WINDOWS_TAG: '7578af0924f537495f952e06ea4588b3e075e906',
    # macos-arm64/ of openxtalk/OpenXTalk-Lite at 4f2feee273
    MACOS_TAG: '741d369ee3ed1acbc98cd9375874943cfac32d1a',
}
DEFAULT_CHANGES = 'CHANGES-FROM-TOM.md'
DEFAULT_ALLOWLIST = '.github/pristine-allowlist.txt'


class GuardError(Exception):
    pass


def git(*args):
    try:
        out = subprocess.run(('git',) + args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        raise GuardError('git %s: %s' % (' '.join(args), e.stderr.decode('utf-8', 'replace').strip()))
    return out.stdout.decode('utf-8', 'surrogateescape')


def tree_entries(ref):
    """{path: (mode, object id)} of every file, link and submodule of ref"""
    entries = {}
    for record in git('ls-tree', '-r', '-z', '--full-tree', ref).split('\0'):
        if not record:
            continue
        meta, path = record.split('\t', 1)
        mode, _, oid = meta.split(' ')
        entries[path] = (mode, oid)
    return entries


def glob_to_regex(pattern):
    out = []
    i = 0
    while i < len(pattern):
        if pattern.startswith('**/', i):
            out.append('(?:.*/)?')
            i += 3
        elif pattern.startswith('**', i):
            out.append('.*')
            i += 2
        elif pattern[i] == '*':
            out.append('[^/]*')
            i += 1
        elif pattern[i] == '?':
            out.append('[^/]')
            i += 1
        else:
            out.append(re.escape(pattern[i]))
            i += 1
    return re.compile('^' + ''.join(out) + '$')


def read_allowlist(path):
    patterns = []
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.split('#', 1)[0].strip()
            if line:
                patterns.append((line, glob_to_regex(line)))
    return patterns


def read_changes(path):
    """(section 1 rows {path: (taken, line)}, section 2 names {name: line})"""
    with open(path, encoding='utf-8') as f:
        lines = f.read().split('\n')
    section = 0
    rows, names = {}, {}
    for number, line in enumerate(lines, 1):
        m = re.match(r'^## (\d+)\.', line)
        if m:
            section = int(m.group(1))
            continue
        if section == 1:
            m = re.match(r'^\|\s*`([^`]+)`\s*\|\s*(windows|macos|combined)\s*\|', line)
            if m:
                if m.group(1) in rows:
                    raise GuardError('%s:%d: a second row for %s' % (path, number, m.group(1)))
                rows[m.group(1)] = (m.group(2), number)
        elif section == 2:
            for name in re.findall(r'`([^`\s]+)`', line):
                names.setdefault(name, number)
    if not rows:
        raise GuardError('%s: no rows in section 1 ("## 1.")' % path)
    return rows, names


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--head', default='HEAD', help='the commit to check (default %(default)s)')
    ap.add_argument('--changes', default=DEFAULT_CHANGES, help='default %(default)s')
    ap.add_argument('--allowlist', default=DEFAULT_ALLOWLIST, help='default %(default)s')
    ap.add_argument('--summary', action='store_true', help='append the report to the job summary')
    args = ap.parse_args(argv)
    gha = os.environ.get('GITHUB_ACTIONS') == 'true'
    problems = []

    def error(message):
        problems.append(message)
        print('::error title=Pristine guard::%s' % message if gha else 'error: %s' % message)

    def warning(message):
        print('::warning title=Pristine guard::%s' % message if gha else 'warning: %s' % message)

    try:
        rows, names = read_changes(args.changes)
        patterns = read_allowlist(args.allowlist)
        windows = git('rev-parse', '%s^{commit}' % WINDOWS_TAG).strip()
        macos = git('rev-parse', '%s^{commit}' % MACOS_TAG).strip()
        merged = git('rev-parse', '%s^{commit}' % MERGED_TAG).strip()
        head = git('rev-parse', '%s^{commit}' % args.head).strip()
        parents = git('rev-list', '--parents', '-n', '1', merged).split()[1:]
        base = git('rev-parse', '%s^' % macos).strip()
        trees = {tag: git('rev-parse', '%s^{tree}' % tag).strip() for tag in EXPECTED_TREES}
    except (GuardError, OSError) as e:
        error(str(e))
        return 2

    # 1. The references
    for tag, expected in EXPECTED_TREES.items():
        if trees[tag] != expected:
            error('%s has the tree %s, not %s: the reference has moved' % (tag, trees[tag], expected))
    if parents != [windows, macos]:
        error('%s must merge %s and %s (in that order), but its parents are %s'
              % (MERGED_TAG, WINDOWS_TAG, MACOS_TAG, ', '.join(p[:12] for p in parents) or 'none'))
    if problems:
        return 1

    # 2. The merge
    t_base, t_win, t_mac, t_merged = (tree_entries(r) for r in (base, windows, macos, merged))
    resolutions = []
    for path in sorted(set(t_base) | set(t_win) | set(t_mac) | set(t_merged)):
        b, w, m, r = (t.get(path) for t in (t_base, t_win, t_mac, t_merged))
        if w == m:
            natural = w
        elif w == b:
            natural = m
        elif m == b:
            natural = w
        else:
            natural = 'contested'
        row = rows.get(path)
        if row is None:
            if natural == 'contested':
                error('%s: both of Tom Perry\'s trees change %s differently, and section 1 of %s has no row '
                      'saying what the merge takes' % (MERGED_TAG, path, args.changes))
            elif r != natural:
                error('%s: %s differs from what Tom Perry\'s trees give, and section 1 of %s has no row for it'
                      % (MERGED_TAG, path, args.changes))
            continue
        taken, line = row
        ok = {'windows': r == w, 'macos': r == m, 'combined': r != w and r != m}[taken]
        if not ok:
            error('%s:%d: %s is "%s", but the merged tree has %s'
                  % (args.changes, line, path, taken,
                     'his Windows version' if r == w else 'his macOS version' if r == m else 'neither of his versions'))
        elif natural != 'contested' and r == natural:
            warning('%s:%d: %s needs no row: it is what Tom Perry\'s trees give' % (args.changes, line, path))
        resolutions.append((path, taken))
    for path, (taken, line) in rows.items():
        if path not in t_base and path not in t_win and path not in t_mac and path not in t_merged:
            warning('%s:%d: %s is in none of the trees' % (args.changes, line, path))

    # 3. After the merge
    changes = []
    out = git('diff', '--no-renames', '--name-status', '-z', merged, head).split('\0')
    for i in range(0, len(out) - 1, 2):
        changes.append((out[i], out[i + 1]))
    documented, harness = [], []
    for status, path in changes:
        if path in names:
            documented.append((status, path))
        elif status == 'A' and any(rx.match(path) for _, rx in patterns):
            harness.append((status, path))
        elif status == 'A':
            error('%s is added outside this repository\'s own folders (%s) and not named in section 2 of %s'
                  % (path, args.allowlist, args.changes))
        else:
            error('%s %s: a file of Tom Perry\'s is %s but not named in section 2 of %s'
                  % (status, path, 'deleted' if status == 'D' else 'changed', args.changes))
    changed = {p for _, p in changes}
    for name, line in sorted(names.items(), key=lambda kv: kv[1]):
        looks_like_path = '/' in name or re.match(r'^\.?[\w-]+\.\w+$', name)
        if looks_like_path and name not in changed and name in t_merged:
            warning('%s:%d: %s is named in section 2 but does not differ from %s'
                    % (args.changes, line, name, MERGED_TAG))

    stats = {}
    paths = [p for s, p in documented if s != 'D']
    if paths:
        for record in git('diff', '--no-renames', '--numstat', '-z', merged, head, '--', *paths).split('\0'):
            if record:
                added, removed, path = record.split('\t', 2)
                stats[path] = (added, removed)

    lines = ['### Pristine guard', '',
             '`%s` (Windows, tree `%s`) and `%s` (macOS, tree `%s`), merged as `%s`, against `%s`.'
             % (WINDOWS_TAG, trees[WINDOWS_TAG][:12], MACOS_TAG, trees[MACOS_TAG][:12], MERGED_TAG, head[:12]),
             '',
             '- The merge: %d paths resolved as section 1 of %s says (%s).'
             % (len(resolutions), args.changes,
                ', '.join('%d %s' % (sum(1 for _, t in resolutions if t == k), k)
                          for k in ('windows', 'macos', 'combined'))),
             '- After the merge: %d paths differ, %d of them files of this repository\'s own, %d of Tom Perry\'s '
             'changed or added and named in section 2, %d not documented.'
             % (len(changes), len(harness), len(documented), len(problems)), '']
    if problems:
        lines += ['**Problems:**', ''] + ['- %s' % p for p in problems] + ['']
    if documented:
        lines += ['<details><summary>Documented changes to Tom Perry\'s files</summary>', '',
                  '| path | status | lines added | lines removed |', '| --- | --- | ---: | ---: |']
        for status, path in documented:
            added, removed = stats.get(path, ('', ''))
            lines.append('| `%s` | %s | %s | %s |' % (path, status, added, removed))
        lines += ['', '</details>', '']
    report = '\n'.join(lines)
    print(report)
    if args.summary and os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8', newline='\n') as f:
            f.write(report + '\n')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
