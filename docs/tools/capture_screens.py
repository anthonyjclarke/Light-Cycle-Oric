#!/usr/bin/env python3
"""Capture VICE screenshots of the C64 build at fixed points in time.

  python3 docs/tools/capture_screens.py [--out DIR] [--only NAME]

Each capture boots c64/build/lightcycle.prg in a fresh, headless x64sc (warp, no sound, default settings) and saves
the screen after a fixed number of CPU cycles. Fixed cycle counts, with VICE's random autostart delay turned off,
make the captures repeatable: nothing in the harness depends on input or on the wall clock. Default output:
docs/images/screens/. Standard library only.
"""
import argparse
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
PRG = os.path.join(ROOT, 'c64', 'build', 'lightcycle.prg')

# name: (cycles, what it shows). Boot and autostart take ~2.5 M cycles; then the attract cycle runs untouched:
# the intro picture for 8 s, the instructions for 10 s, then demo mode (fixed random seed, so repeatable).
CAPTURES = {
    'intro': (4_000_000, 'The intro picture after the cassette inlay'),
    'instructions': (12_000_000, 'The instructions screen (placeholder until Phase 4)'),
    'demo-early': (24_000_000, 'Demo mode: the first round, a few seconds in'),
    'demo-later': (40_000_000, 'Demo mode: trails, bonus blocks, a dotted P2 trail'),
}


def capture(name, cycles, out):
    target = os.path.join(out, name + '.png')
    if os.path.exists(target):
        os.remove(target)
    subprocess.run(['x64sc', '-default', '-console', '-warp', '-sounddev', 'dummy', '+autostart-delay-random',
                    '-limitcycles', str(cycles), '-exitscreenshot', target,
                    '-autostartprgmode', '1', '-autostart', PRG],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    if not os.path.exists(target):
        sys.exit('capture failed: ' + name)
    print('%-14s %s' % (name, os.path.relpath(target, ROOT)))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', default=os.path.join(ROOT, 'docs', 'images', 'screens'))
    parser.add_argument('--only', choices=sorted(CAPTURES))
    args = parser.parse_args()
    if not os.path.exists(PRG):
        sys.exit('%s not found: run make first' % os.path.relpath(PRG, ROOT))
    os.makedirs(args.out, exist_ok=True)
    for name, (cycles, _) in CAPTURES.items():
        if args.only in (None, name):
            capture(name, cycles, args.out)


if __name__ == '__main__':
    main()
