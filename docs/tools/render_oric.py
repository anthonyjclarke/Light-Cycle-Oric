#!/usr/bin/env python3
"""Draw the figures for the Oric Tech Specs appendix (oric_specs.md) into docs/images/graphics/.

  python3 docs/tools/render_oric.py

Three figures that explain the platform rather than the game, so this file is the same in every Oric reconstruction:
the eight colours, one HIRES scanline strip showing how serial attributes take a cell each, and the AY-3-8912's sixteen
envelope shapes (register R13 = 0-15). Deterministic. Needs Pillow.
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'docs', 'images', 'graphics')

# black, red, green, yellow, blue, magenta, cyan, white: colour n is (bit 0 red, bit 1 green, bit 2 blue)
ORIC = [(0, 0, 0), (255, 0, 0), (0, 255, 0), (255, 255, 0), (0, 0, 255), (255, 0, 255), (0, 255, 255),
        (255, 255, 255)]
GRID = (90, 90, 90)


def save(img, name, scale):
    img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(os.path.join(OUT, name), optimize=True)
    print(os.path.relpath(os.path.join(OUT, name), ROOT))


def palette():
    """Colours 0-7 as swatches, with a gap between them."""
    img = Image.new('RGB', (8 * 10 + 2, 12), GRID)
    draw = ImageDraw.Draw(img)
    for n, rgb in enumerate(ORIC):
        draw.rectangle((2 + n * 10, 2, 9 + n * 10, 9), fill=rgb)
    save(img, 'oric-palette.png', 6)


# One HIRES line of cells, as bytes. An attribute (bits 6 and 5 clear) changes ink or paper from that cell on and
# shows as paper itself; a pixel byte ($40 + six pixels) draws in ink on paper; bit 7 inverts the cell's colours.
STRIP = [0x14, 0x03, 0x7F, 0x55, 0x01, 0x7F, 0x6A, 0x10, 0x06, 0x7F, 0xFF, 0x40]


def attribute_strip():
    """The STRIP bytes decoded as the ULA does, 8 lines high, with the cell edges marked underneath."""
    cells = len(STRIP)
    img = Image.new('RGB', (cells * 6, 11), GRID)
    px = img.load()
    ink, paper = 7, 0
    for c, b in enumerate(STRIP):
        if b & 0x60 == 0:
            v = b & 0x1F
            if v < 8:
                ink = v
            elif 16 <= v < 24:
                paper = v & 7
            bits = 0
        else:
            bits = b & 0x3F
        fg, bg = (7 - ink, 7 - paper) if b & 0x80 else (ink, paper)
        for y in range(8):
            for x in range(6):
                px[c * 6 + x, y] = ORIC[fg if bits & (0x20 >> x) else bg]
        for x in range(6):                              # cell ruler: alternate shades per cell
            px[c * 6 + x, 9] = (200, 200, 200) if c % 2 else (130, 130, 130)
            px[c * 6 + x, 10] = px[c * 6 + x, 9]
    save(img, 'oric-attributes.png', 8)


def envelope(shape, steps=48, period=16):
    """Volume 0-15 over time for envelope shape 0-15 (CONT, ATT, ALT, HOLD = bits 3-0), as the AY data sheet draws."""
    cont, att, alt, hold = shape & 8, shape & 4, shape & 2, shape & 1
    out = []
    for t in range(steps):
        cycle, step = divmod(t, period)
        if not cont:                                    # one ramp, then silence
            out.append((step if att else 15 - step) if cycle == 0 else 0)
            continue
        if hold and cycle > 0:                          # held at the end of the first ramp (ALT flips it)
            end = 15 if att else 0
            out.append(15 - end if alt else end)
            continue
        up = bool(att) != (alt and cycle % 2 == 1)
        out.append(step if up else 15 - step)
    return out


def envelopes():
    """The sixteen shapes in a 4 x 4 grid, R13 = 0-15 row by row."""
    w, h, pad = 56, 22, 4
    img = Image.new('RGB', (4 * (w + pad) + pad, 4 * (h + pad) + pad), (24, 24, 24))
    draw = ImageDraw.Draw(img)
    for shape in range(16):
        ox = pad + (shape % 4) * (w + pad)
        oy = pad + (shape // 4) * (h + pad)
        draw.rectangle((ox, oy, ox + w - 1, oy + h - 1), fill=(0, 0, 0))
        vol = envelope(shape)
        pts = []
        for i, v in enumerate(vol):
            x = ox + 2 + i * (w - 4) // len(vol)
            y = oy + h - 3 - v * (h - 6) // 15
            pts.append((x, y))
        draw.line(pts, fill=ORIC[6])
    save(img, 'oric-envelopes.png', 3)


def main():
    os.makedirs(OUT, exist_ok=True)
    palette()
    attribute_strip()
    envelopes()


if __name__ == '__main__':
    main()
