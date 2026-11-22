#!/usr/bin/env python3
"""Assemble the Oric source and write a loadable tape image.

    python3 tools/build_tap.py build/CYCLE.TAP

Assembles oric/loader.s and oric/game.s with cl65 and wraps them in the two tape blocks of the original, in order:
'LIGHT CYCLE' (BASIC stub and loader, $0501-$0E80, runs on load) then 'GAME' ($0400-$1800, loaded by the first).
The header bytes are the original tape's, so the result is byte-identical to CYCLE.TAP when the source is unchanged
(`make verify` checks it). Each block is three $16 sync bytes, $24, nine header bytes, the name, $00, then the data.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (source, load address, tape name, the nine header bytes after $24 exactly as on CYCLE.TAP)
BLOCKS = [
    ('oric/loader.s', 0x0501, b'LIGHT CYCLE', bytes([0x00, 0xEC, 0x00, 0x04, 0x0E, 0x80, 0x05, 0x01, 0xFF])),
    ('oric/game.s', 0x0400, b'GAME', bytes([0x34, 0xEC, 0x80, 0x04, 0x18, 0x00, 0x04, 0x00, 0xFF])),
]


def assemble(src, start, td):
    out = os.path.join(td, os.path.basename(src) + '.bin')
    subprocess.run(['cl65', '-t', 'none', '--start-addr', f'0x{start:04X}', '-o', out, os.path.join(ROOT, src)],
                   check=True)
    obj = os.path.splitext(os.path.join(ROOT, src))[0] + '.o'
    if os.path.exists(obj):
        os.remove(obj)  # cl65 drops its object file next to the source
    return open(out, 'rb').read()


def main():
    dst = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'build', 'CYCLE.TAP')
    tape = bytearray()
    with tempfile.TemporaryDirectory() as td:
        for src, start, name, header in BLOCKS:
            data = assemble(src, start, td)
            end = header[4] << 8 | header[5]
            if len(data) != end - start + 1:
                sys.exit(f'{src}: {len(data)} bytes, but the header says ${start:04X}-${end:04X}')
            tape += b'\x16' * 3 + b'\x24' + header + name + b'\x00' + data
    os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
    open(dst, 'wb').write(tape)
    print(f'{os.path.relpath(dst, ROOT)}: {len(tape)} bytes')


if __name__ == '__main__':
    main()
