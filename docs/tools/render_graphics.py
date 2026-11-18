#!/usr/bin/env python3
"""Decode figures from the Oric tape blocks into docs/images/graphics/.

  python3 docs/tools/render_graphics.py

Reads oric/light_cycle_0501.bin and oric/game_0400.bin (from `make oric`) and draws, at the Oric's 6-pixel character
width: the publisher's PSS logo (alternate character set, rows 1-5 of the title screen, in its serial-attribute colours), the
status-line bike icon, the bonus-block animation frames and the explosion's 32 particle targets. It also replicates
the in-game screen the 1983 review photographed: the game's own RoundStart and GameLoop run on the 6502 core in
tools/cpu6502.py, and the resulting HIRES memory and status rows are drawn with the Oric's serial attributes. The Oric
ROM font is not on the tape, so letters and digits use the C64 font (from VICE) squeezed to the Oric's five pixels; the cycle icon
is the tape's own. Addresses come from
the label tables in tools/symbols.py, so they follow the disassembly's names. Deterministic. Needs Pillow.
"""
import os
import shutil
import sys

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import symbols  # noqa: E402
from cpu6502 import CPU  # noqa: E402

OUT = os.path.join(ROOT, 'docs', 'images', 'graphics')
LOADER = open(os.path.join(ROOT, 'oric', 'light_cycle_0501.bin'), 'rb').read()
GAME = open(os.path.join(ROOT, 'oric', 'game_0400.bin'), 'rb').read()

# Oric's eight colours (black, red, green, yellow, blue, magenta, cyan, white)
ORIC = [(0, 0, 0), (255, 0, 0), (0, 255, 0), (255, 255, 0), (0, 0, 255), (255, 0, 255), (0, 255, 255),
        (255, 255, 255)]
SCALE = 4


def addr(ranges, name):
    for start, _, _, label, _ in ranges:
        if label == name:
            return start
    raise KeyError(name)


def loader(a, n=1):
    return LOADER[a - 0x0501:a - 0x0501 + n]


def game(a, n=1):
    return GAME[a - 0x0400:a - 0x0400 + n]


def save(img, name):
    img = img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST)
    img.save(os.path.join(OUT, name), optimize=True)
    print(os.path.relpath(os.path.join(OUT, name), ROOT))


def title_logo():
    """Rows 1-5, columns 0-13 of TitleScreen, decoded with the serial attributes as the ULA does."""
    screen = addr(symbols.LOADER_RANGES, 'TitleScreen')
    glyphs = addr(symbols.LOADER_RANGES, 'AltGlyphs')          # alt chars 32-95
    rows, cols = range(1, 6), 14
    img = Image.new('RGB', (cols * 6, len(rows) * 8))
    for r_i, r in enumerate(rows):
        ink, paper, alt = 7, 0, False
        for c in range(cols):
            ch = loader(screen + r * 40 + c)[0]
            if ch < 0x08:
                ink = ch
            elif ch < 0x10:
                alt = bool(ch & 1)
            elif 0x10 <= ch < 0x18:
                paper = ch - 0x10
            for y in range(8):
                bits = 0
                if ch >= 32 and alt and ch < 96:
                    bits = loader(glyphs + (ch - 32) * 8 + y)[0]
                for x in range(6):
                    on = bits & (0x20 >> x)
                    img.putpixel((c * 6 + x, r_i * 8 + y), ORIC[ink] if on else ORIC[paper])
    save(img, 'pss-logo.png')


def glyph_strip(start, count, name, colour=7, gap=2):
    """Draw count 6-pixel glyphs side by side; gap=0 joins glyphs that form one picture, as the screen prints them."""
    img = Image.new('RGB', (count * 6 + (count - 1) * gap, 8))
    for i in range(count):
        for y in range(8):
            bits = game(start + i * 8 + y)[0]
            for x in range(6):
                if bits & (0x20 >> x):
                    img.putpixel((i * (6 + gap) + x, y), ORIC[colour])
    save(img, name)


def bonus_frames():
    gfx = addr(symbols.GAME_RANGES, 'BonusGfx')
    seq = list(game(addr(symbols.GAME_RANGES, 'BonusFrameOfs'), 5))
    img = Image.new('RGB', (len(seq) * 8 + (len(seq) - 1) * 2, 8), (40, 40, 40))
    for f, ofs in enumerate(seq):
        for y in range(6):
            bits = game(gfx + ofs + y)[0]
            for x in range(6):
                img.putpixel((f * 10 + 1 + x, 1 + y), ORIC[7] if bits & (0x20 >> x) else ORIC[0])
    save(img, 'bonus-frames.png')


def explosion_targets():
    dx = [b - 256 if b > 127 else b for b in game(addr(symbols.GAME_RANGES, 'ExplodeDX'), 32)]
    dy = [b - 256 if b > 127 else b for b in game(addr(symbols.GAME_RANGES, 'ExplodeDY'), 32)]
    size = 2 * (max(map(abs, dx + dy)) + 2) + 1
    mid = size // 2
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    for x, y in zip(dx, dy):
        draw.line((mid, mid, mid + x, mid + y), fill=(90, 40, 0))
    for x, y in zip(dx, dy):
        img.putpixel((mid + x, mid + y), ORIC[3])
    img.putpixel((mid, mid), ORIC[1])
    save(img, 'explosion-targets.png')


def c64_font():
    """The C64 uppercase font from VICE's data folder, squeezed to Oric-style 5-pixel glyphs in 6-pixel cells, by ASCII."""
    vice = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(shutil.which('x64sc')))), 'share', 'vice', 'C64')
    rom = open(os.path.join(vice, 'chargen-901225-01.bin'), 'rb').read()
    font = bytearray(128 * 8)
    for c in range(32, 96):
        sc = c - 64 if c >= 64 else c
        for r in range(8):
            b = (rom[sc * 8 + r] >> 1) & 0x3F           # the C64 glyph's six columns
            # merge the middle two into five, leaving the Oric's blank sixth column as the gap between letters
            font[c * 8 + r] = (b >> 1 & 0x18) | (b >> 1 | b) & 0x04 | b & 0x03
    return font


def run_oric_screen(frames=14):
    """Run the Oric game from ResetScores and RoundStart into its first frames; return memory (one-player game)."""
    label = {name: a for a, (name, _) in symbols.GAME_LABELS.items()}
    zp = {name: a for a, name in symbols.ZP.items()}
    for seed in range(256):
        mem = bytearray(0x10000)
        mem[0x0400:0x0400 + len(GAME)] = GAME
        mem[0xBA00:0xC000] = b' ' * 0x600               # the text area is spaces, as the game's own clear leaves it
        mem[0xD0:0xD4] = bytes((0x12, 0x34, seed, 0x78))
        mem[zp['zSpeed']] = 5
        mem[zp['zOnePlayer']] = 1
        cpu = CPU(mem)
        for start in ('ResetScores', 'ResetTime'):
            cpu.sp = 0xFF
            cpu.push(0xFF)
            cpu.push(0xEF)                              # RTS lands on $FFF0
            cpu.pc = label[start]
            while cpu.pc != 0xFFF0:
                cpu.step()
        cpu.sp = 0xFF
        cpu.pc = label['RoundStart']
        seen = 0
        while seen <= frames:
            if cpu.pc in (label['ReadKeysP1'], label['ReadKeysP2']):
                mem[zp['zInput']] = cpu.a = 0                    # no keys: player 1 rides straight on
                cpu.rts()
                continue
            if cpu.pc == label['StartSweep']:
                cpu.rts()
                continue
            if cpu.pc == label['GameLoop']:
                if mem[0xA000] != 0x10:                 # the round's paper (column 0): black, as photographed
                    break
                seen += 1
            cpu.step()
        else:
            return mem
    raise SystemExit('no seed gave a black paper')


def oric_screen():
    """The Oric in-game screen (240 x 224: HIRES and the three status rows), as the review photographed it."""
    mem = run_oric_screen()
    font = c64_font()
    font[123 * 8:125 * 8] = game(addr(symbols.GAME_RANGES, 'GlyphBike'), 16)   # the cycle icon (DefineGlyphs)
    img = Image.new('RGB', (240, 224))
    px = img.load()
    for y in range(224):
        text_row = 25 + (y - 200) // 8 if y >= 200 else None
        base = 0xA000 + y * 40 if text_row is None else 0xBB80 + text_row * 40
        ink, paper, double = 7, 0, False
        for col in range(40):
            b = mem[base + col]
            inverse = b & 0x80
            if b & 0x60 == 0:                           # serial attribute: shows as paper
                v = b & 0x1F
                if v < 8:
                    ink = v
                elif v < 16:
                    double = bool(v & 2)
                elif v < 24:
                    paper = v & 7
                bits = 0
            elif text_row is None:
                bits = b & 0x3F
            else:
                line = (y - 200) % 8
                if double:
                    line = ((text_row & 1) * 8 + line) >> 1
                bits = font[(b & 0x7F) * 8 + line]
            fg, bg = (7 - ink, 7 - paper) if inverse else (ink, paper)
            for i in range(6):
                px[col * 6 + i, y] = ORIC[fg if bits & (0x20 >> i) else bg]
    return img


def status_layout():
    """The Oric screen and its status rows (replicated) and the C64 panels (the demo capture), for comparison."""
    screen = oric_screen()
    save(screen.resize((240 * 3, 224 * 3), Image.NEAREST), 'oric-screen.png')
    save(screen.crop((0, 184, 240, 224)).resize((240 * 4, 40 * 4), Image.NEAREST), 'status-oric.png')
    c64 = Image.open(os.path.join(ROOT, 'docs', 'images', 'screens', 'demo-later.png')).convert('RGB')
    top = 35 + 16 * 8 - 4                               # border, then panel rows 16-22 with a margin
    left = c64.crop((32, top, 72, top + 64)).resize((160, 256), Image.NEAREST)
    right = c64.crop((312, top, 352, top + 64)).resize((160, 256), Image.NEAREST)
    fig = Image.new('RGB', (400, 256), (0, 0, 0))
    fig.paste(left, (0, 0))
    fig.paste(right, (240, 0))
    save(fig, 'status-c64.png')


def main():
    os.makedirs(OUT, exist_ok=True)
    title_logo()
    glyph_strip(addr(symbols.GAME_RANGES, 'GlyphBike'), 2, 'bike-icon.png', 6, gap=0)   # '{' '|' printed adjacent
    glyph_strip(addr(symbols.GAME_RANGES, 'GlyphArrows'), 2, 'arrow-glyphs.png')
    bonus_frames()
    explosion_targets()
    status_layout()


if __name__ == '__main__':
    main()
