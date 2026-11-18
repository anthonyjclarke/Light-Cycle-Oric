#!/usr/bin/env python3
"""Time the Oric game's own code: how long a GameLoop frame, the explosion and the crash pause take.

  python3 tools/oric_timing.py

Runs oric/game_0400.bin (from `make oric`) on the cycle-counting 6502 core in tools/cpu6502.py, starting at RoundStart
with the state MainMenu leaves, and records the cycles between successive GameLoop entries until the first crash. The
Oric runs at 1 MHz and its ULA steals no CPU cycles, so cycles are microseconds. During play the game masks interrupts,
so no IRQ time is missing. Keys are supplied by replacing ReadKeysP1/ReadKeysP2 with a fixed input; StartSweep is
skipped (it only runs before the first frame). Several random seeds are averaged.

The C64 port's speed table (c64/src/game.s) is derived from the frames-per-second column.
"""
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(__file__))
from cpu6502 import CPU  # noqa: E402
import symbols  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LABEL = {name: a for a, (name, _) in symbols.GAME_LABELS.items()}
ZP = {name: a for a, name in symbols.ZP.items()}
GAME = open(os.path.join(ROOT, 'oric', 'game_0400.bin'), 'rb').read()
SEEDS = [(0x12, 0x34, 0x56, 0x78), (0x9A, 0xBC, 0xDE, 0xF0), (0x31, 0x41, 0x59, 0x26), (0x27, 0x18, 0x28, 0x18),
         (0x55, 0xAA, 0x0F, 0xF0), (0x01, 0x23, 0x45, 0x67)]


def run_round(speed, p1_input, one_player, seed, max_frames=4000):
    mem = bytearray(0x10000)
    mem[0x0400:0x0400 + len(GAME)] = GAME
    mem[0xD0:0xD4] = bytes(seed)
    mem[ZP['zSpeed']] = speed
    mem[ZP['zVolume']] = 8
    mem[ZP['zOnePlayer']] = int(one_player)
    cpu = CPU(mem)
    cpu.pc = LABEL['RoundStart']
    hooks = {LABEL['ReadKeysP1']: p1_input, LABEL['ReadKeysP2']: 0}
    frames, last, explosion, pause_start, moved = [], None, None, None, 0
    x0 = None
    while True:
        pc = cpu.pc
        if pc in hooks:
            mem[ZP['zInput']] = cpu.a = hooks[pc]
            cpu.rts()
            continue
        if pc == LABEL['StartSweep']:
            cpu.rts()
            continue
        if pc == LABEL['GameLoop']:
            if x0 is None:
                x0 = mem[ZP['zP1X']]
            if last is not None:
                frames.append(cpu.cycles - last)
            last = cpu.cycles
            moved = mem[ZP['zP1X']] - x0
            if len(frames) >= max_frames:
                break
        if pc == LABEL['Explosion']:
            explosion = cpu.cycles
        if pc == LABEL['Crash'] + 6 and explosion is not None and isinstance(explosion, int):   # after JSR Explosion
            explosion = ('done', cpu.cycles - explosion)
        if pc == 0x0F06:                                                                           # crash pause
            pause_start = cpu.cycles
        if pc == 0x0F11 and pause_start is not None:
            return frames, moved, explosion[1] if isinstance(explosion, tuple) else None, cpu.cycles - pause_start
        cpu.step()
    return frames, moved, None, None


def main():
    print('| Speed | Players | Boost | Frame (µs) | Frames/s | P1 px/s | Explosion (s) | Pause (s) |')
    print('|:------|:--------|:------|:-----------|:---------|:--------|:--------------|:----------|')
    for speed in (1, 3, 5, 7, 9):
        for one_player in (True, False):
            for boost in (False, True):
                fr, px, ex, pa = [], [], [], []
                for seed in SEEDS:
                    frames, moved, explosion, pause = run_round(speed, 0x11 if boost else 0x01, one_player, seed)
                    if len(frames) > 20:
                        fr.append(statistics.mean(frames))
                        px.append(moved / (sum(frames) / 1e6))
                    if explosion:
                        ex.append(explosion / 1e6)
                        pa.append(pause / 1e6)
                f = statistics.mean(fr)
                print('| %-5d | %-7d | %-5s | %10.0f | %8.1f | %7.1f | %13.2f | %9.2f |' % (
                    speed, 1 if one_player else 2, 'yes' if boost else 'no', f, 1e6 / f, statistics.mean(px),
                    statistics.mean(ex) if ex else 0, statistics.mean(pa) if pa else 0))


if __name__ == '__main__':
    main()
