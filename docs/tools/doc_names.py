#!/usr/bin/env python3
"""Fail if a chapter of the handbook names a label that no longer exists in the source.

  python3 docs/tools/doc_names.py

Checks every `code span` in the chapters listed in docs/handbook.json that looks like a label: a routine name
(`MovePlayer`), a variable (`zInput`) or a constant (`ARENA_X_OFFSET`). Known names come from the Oric disassembly's
symbol tables (tools/symbols.py) and every identifier in c64/src. Skipped: CHANGELOG.md. Words that only look like
labels go in docs/tools/doc_names_ignore.txt. Standard library only.
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
IGNORE = os.path.join(ROOT, 'docs', 'tools', 'doc_names_ignore.txt')
SPAN = re.compile(r'`([A-Za-z_][A-Za-z0-9_]*)`')
FILE_EXT = re.compile(r'\.(py|md|mjs|js|json|s|inc|cfg|tap|bin|prg|d64|html|css)$')


def known_names():
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import symbols
    names = set(symbols.ZP.values())
    names.update(n for n, _ in symbols.HW.values())
    names.update(n for n, _ in symbols.GAME_LABELS.values())
    names.update(n for n, _ in symbols.LOADER_LABELS.values())
    names.update(r[3] for r in symbols.GAME_RANGES + symbols.LOADER_RANGES if r[3])
    for path in glob.glob(os.path.join(ROOT, 'c64', 'src', '*.[si]*')):
        with open(path, encoding='utf-8') as f:
            names.update(re.findall(r'[A-Za-z_][A-Za-z0-9_]*', f.read()))
    return names


def looks_like_label(word):
    if FILE_EXT.search(word):
        return False
    if re.fullmatch(r'[A-Z][A-Z0-9]*(_[A-Z0-9]+)+', word):       # CONSTANT_NAME
        return True
    return bool(re.match(r'z[A-Z]', word) or re.search(r'[a-z][A-Z]', word))   # zVar, CamelCase


def main():
    with open(os.path.join(ROOT, 'docs', 'handbook.json'), encoding='utf-8') as f:
        config = json.load(f)
    chapters = [s for g in config['groups'] if not g.get('historical') for s in g['sources'] if s != 'CHANGELOG.md']
    ignore = set()
    if os.path.exists(IGNORE):
        with open(IGNORE, encoding='utf-8') as f:
            ignore = {line.strip() for line in f if line.strip() and not line.startswith('#')}
    known = known_names()
    missing = []
    for chapter in chapters:
        with open(os.path.join(ROOT, chapter), encoding='utf-8') as f:
            for number, line in enumerate(f, 1):
                for word in SPAN.findall(line):
                    if word in ignore or word in known or not looks_like_label(word):
                        continue
                    missing.append('%s:%d: `%s`' % (chapter, number, word))
    for entry in missing:
        print(entry)
    if missing:
        sys.exit('%d name(s) in the docs are not in the source: rename them, or add placeholders to %s'
                 % (len(missing), os.path.relpath(IGNORE, ROOT)))
    print('doc names ok: %d chapters' % len(chapters))


if __name__ == '__main__':
    main()
