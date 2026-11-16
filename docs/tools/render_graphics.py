#!/usr/bin/env python3
"""Decode figures from the Oric tape blocks into docs/images/graphics/.

  python3 docs/tools/render_graphics.py

Reads oric/light_cycle_0501.bin and oric/game_0400.bin (from `make oric`) and draws, at the Oric's 6-pixel character
width: the publisher's PSS logo (alternate character set, rows 1-5 of the title screen, in its serial-attribute colours), the
status-line bike icon, the bonus-block animation frames and the explosion's 32 particle targets. Addresses come from
the label tables in tools/symbols.py, so they follow the disassembly's names. Deterministic. Needs Pillow.
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import symbols  # noqa: E402

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


def glyph_strip(start, count, name, colour=7):
    img = Image.new('RGB', (count * 6 + (count - 1) * 2, 8))
    for i in range(count):
        for y in range(8):
            bits = game(start + i * 8 + y)[0]
            for x in range(6):
                if bits & (0x20 >> x):
                    img.putpixel((i * 8 + x, y), ORIC[colour])
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


def main():
    os.makedirs(OUT, exist_ok=True)
    title_logo()
    glyph_strip(addr(symbols.GAME_RANGES, 'GlyphBike'), 2, 'bike-icon.png', 6)
    glyph_strip(addr(symbols.GAME_RANGES, 'GlyphArrows'), 2, 'arrow-glyphs.png')
    bonus_frames()
    explosion_targets()


if __name__ == '__main__':
    main()
