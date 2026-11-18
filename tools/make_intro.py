#!/usr/bin/env python3
"""Draw the C64 intro picture, after the original PSS cassette inlay, as a multicolour bitmap.

  python3 tools/make_intro.py

The scene is drawn procedurally at the C64's multicolour resolution (160x200, double-wide pixels) in C64 colour
numbers: the PSS logo (decoded from the Oric tape, so it is the game's own) over PERSONAL SOFTWARE SERVICES on black;
a blue panel holding chrome LIGHT CYCLE lettering with a star glint, a perspective grid, a light cycle seen from the
front three-quarter with its yellow-green light trail and a white flare; and a cyan strip with the strapline. Each
4x8 cell then keeps the shared background (blue) plus its three most used colours, as multicolour mode allows.

Writes c64/src/intro.rle (bitmap, screen and colour RAM, each run-length packed; see Unpack in c64/src/intro.s) and
docs/images/graphics/intro-design.png (a preview at double width). Needs Pillow; the LIGHT CYCLE lettering uses
VICE's copy of the C64 character ROM.
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 160, 200
BG = 6                                  # shared background: blue
CHARGEN = '/opt/homebrew/share/vice/C64/chargen-901225-01.bin'
PREVIEW = os.path.join(ROOT, 'docs', 'images', 'graphics', 'intro-design.png')
OUT = os.path.join(ROOT, 'c64', 'src', 'intro.rle')

# Pepto's measured C64 palette, for the preview and for nearest-colour fallback.
PALETTE = [(0, 0, 0), (255, 255, 255), (104, 55, 43), (112, 164, 178), (111, 61, 134), (88, 141, 67), (53, 40, 121),
           (184, 199, 111), (111, 79, 37), (67, 57, 0), (154, 103, 89), (68, 68, 68), (108, 108, 108),
           (154, 210, 132), (108, 94, 181), (149, 149, 149)]
BLACK, WHITE, RED, CYAN, PURPLE, GREEN, BLUE, YELLOW, ORANGE, BROWN, LRED, DGREY, GREY, LGREEN, LBLUE, LGREY = range(16)

# 3x5 font for the small lettering (only the characters used); M is 5 wide.
SMALL = {
    'A': '010101111101101', 'C': '011100100100011', 'D': '110101101101110', 'E': '111100110100111',
    'F': '111100110100100', 'I': '111010010010111', 'L': '100100100100111', 'M': '1000111011101011000110001',
    'N': '110101101101101', 'O': '010101101101010', 'P': '110101110100100', 'R': '110101110101101',
    'S': '011100010001110', 'T': '111010010010010', 'V': '101101101101010', 'W': '101101111111101',
    'U': '101101101101111', 'H': '101101111101101', 'G': '011100101101011', 'Y': '101101010010010',
    '6': '011100111101111', '4': '101101111001001', ' ': '000000000000000', '.': '000000000000010',
}


def small_text(img, text, cx, y, colour):
    widths = [len(SMALL[ch]) // 5 for ch in text]       # 3 wide, or 5 for M
    x = cx - (sum(widths) + len(text) - 1) // 2
    for ch, w in zip(text, widths):
        bits = SMALL[ch]
        for r in range(5):
            for c in range(w):
                if bits[r * w + c] == '1':
                    img.putpixel((x + c, y + r), colour)
        x += w + 1


def pss_logo():
    """The tape's PSS logo (rows 1-5 of the title screen, alternate character set) as a 72x40 bitmap."""
    sys.path.insert(0, os.path.join(ROOT, 'tools'))
    import symbols
    loader = open(os.path.join(ROOT, 'oric', 'light_cycle_0501.bin'), 'rb').read()
    at = lambda a: loader[a - 0x0501]  # noqa: E731
    start = {name: a for a, _, _, name, _ in symbols.LOADER_RANGES if name}
    screen, glyphs = start['TitleScreen'], start['AltGlyphs']
    rows = []
    for r in range(1, 6):
        for y in range(8):
            line = []
            for c in range(1, 13):
                ch = at(screen + r * 40 + c)
                bits = at(glyphs + (ch - 32) * 8 + y) if 32 <= ch < 96 else 0
                line += [bool(bits & (0x20 >> x)) for x in range(6)]
            rows.append(line)
    return rows


def chrome_word(img, word, top):
    """Letters from the C64 font, each font pixel 3 wide and 3 tall: white upper half, a dark seam, then
    light grey lines with gaps, as the inlay's striped chrome; a black drop shadow."""
    font = open(CHARGEN, 'rb').read()
    sx, sy = 3, 3
    width = len(word) * 8 * sx
    x0 = (W - width) // 2
    for pass_ in ('shadow', 'face'):
        for i, ch in enumerate(word):
            code = ord(ch) - 64                       # screen code for A-Z
            for fy in range(8):
                bits = font[code * 8 + fy]
                for fx in range(8):
                    if not bits & (0x80 >> fx):
                        continue
                    for dy in range(sy):
                        y = top + fy * sy + dy
                        for dx in range(sx):
                            x = x0 + (i * 8 + fx) * sx + dx
                            if pass_ == 'shadow':
                                img.putpixel((x + 1, y + 2), BLACK)
                                continue
                            band = (y - top) / (8 * sy)
                            if band < 0.45:
                                colour = WHITE
                            elif band < 0.55:
                                colour = GREY
                            else:
                                colour = LGREY if (y - top) % 2 == 0 else BLUE
                            img.putpixel((x, y), colour)


def star(draw, cx, cy, arm, colour, core=WHITE):
    draw.line((cx - arm, cy, cx + arm, cy), fill=colour)
    draw.line((cx, cy - arm // 2, cx, cy + arm // 2), fill=colour)
    draw.line((cx - arm // 3, cy - arm // 4, cx + arm // 3, cy + arm // 4), fill=colour)
    draw.line((cx - arm // 3, cy + arm // 4, cx + arm // 3, cy - arm // 4), fill=colour)
    draw.point((cx, cy), fill=core)


def scene():
    img = Image.new('P', (W, H), BLACK)
    draw = ImageDraw.Draw(img)

    # Top band: PSS logo (light blue, blue shadow) and the company name.
    logo = pss_logo()
    lw, lh = 54, 26
    lx = (W - lw) // 2
    for y in range(lh):
        for x in range(lw):
            if logo[y * len(logo) // lh][x * 72 // lw]:
                img.putpixel((lx + x + 1, 3 + y + 1), BLUE)
    for y in range(lh):
        for x in range(lw):
            if logo[y * len(logo) // lh][x * 72 // lw]:
                img.putpixel((lx + x, 3 + y), LBLUE)
    small_text(img, 'PERSONAL SOFTWARE SERVICES', W // 2, 32, WHITE)

    # Blue panel with a light-blue frame.
    top, bottom = 40, 183
    draw.rectangle((4, top, W - 5, bottom), fill=BLUE)
    draw.rectangle((4, top, W - 5, bottom), outline=LBLUE)

    # Perspective grid on the floor, vanishing point above the panel's centre.
    horizon, vx, vy = 118, W // 2, 70
    for k in range(1, 12):
        y = horizon + int(k * k * 0.55)
        if y < bottom:
            draw.line((5, y, W - 6, y), fill=LBLUE)
    for k in range(-14, 15):
        x_bottom = vx + k * 16
        x_h = vx + (x_bottom - vx) * (horizon - vy) // (bottom - vy)
        draw.line((x_h, horizon, x_bottom, bottom - 1), fill=LBLUE)
    # Title: chrome LIGHT / CYCLE and a glint.
    chrome_word(img, 'LIGHT', 46)
    chrome_word(img, 'CYCLE', 74)
    star(draw, 128, 46, 18, WHITE)

    # The light trail: a yellow-green beam from the left edge into the cycle, a white flare at its source.
    cy = 140
    draw.polygon([(5, cy - 9), (78, cy - 13), (78, cy + 9), (5, cy + 5)], fill=LGREEN)
    draw.polygon([(5, cy - 6), (78, cy - 9), (78, cy + 3), (5, cy + 2)], fill=YELLOW)
    draw.line((5, cy - 3, 78, cy - 4), fill=WHITE)
    for a, b, c in ((24, 112, 6), (36, 124, 4), (10, 128, 3)):
        draw.line((24, 136, a + 30, b), fill=WHITE)
        draw.line((24, 136, a - 20, b + 40), fill=c and LBLUE)
    star(draw, 24, 136, 24, WHITE)
    draw.ellipse((17, 131, 31, 141), fill=WHITE)

    # The cycle: a rounded pod, brown with a green sheen and dark underside, a white canopy, a dark nose ring.
    draw.ellipse((70, 112, 146, 168), fill=BROWN)
    draw.ellipse((84, 114, 144, 158), fill=GREEN)
    draw.ellipse((96, 118, 140, 150), fill=BROWN)
    draw.chord((70, 112, 146, 168), 30, 150, fill=DGREY)
    draw.polygon([(92, 118), (118, 112), (124, 120), (98, 126)], fill=WHITE)
    draw.ellipse((70, 122, 86, 160), fill=LGREY)                      # the cut face the beam enters
    draw.ellipse((72, 128, 82, 156), fill=WHITE)

    # Keep the grid and flare rays inside the panel.
    draw.rectangle((0, top, 3, bottom), fill=BLACK)
    draw.rectangle((W - 4, top, W - 1, bottom), fill=BLACK)
    draw.rectangle((4, top, W - 5, bottom), outline=LBLUE)

    # Bottom strip with the strapline.
    draw.rectangle((4, 186, W - 5, 197), fill=CYAN)
    small_text(img, 'ARCADE ACTION FOR COMMODORE 64', W // 2, 189, BLACK)
    return img


def nearest(colour, allowed):
    r, g, b = PALETTE[colour]
    return min(allowed, key=lambda c: (PALETTE[c][0] - r) ** 2 + (PALETTE[c][1] - g) ** 2 + (PALETTE[c][2] - b) ** 2)


def encode(img):
    px = img.load()
    bitmap, screen, colram = bytearray(8000), bytearray(1000), bytearray(1000)
    final = Image.new('P', (W, H))
    for cy in range(25):
        for cx in range(40):
            counts = {}
            for y in range(8):
                for x in range(4):
                    c = px[cx * 4 + x, cy * 8 + y]
                    if c != BG:
                        counts[c] = counts.get(c, 0) + 1
            chosen = sorted(counts, key=lambda c: -counts[c])[:3]
            chosen += [BLACK] * (3 - len(chosen))
            slots = {BG: 0, chosen[0]: 1, chosen[1]: 2, chosen[2]: 3}
            screen[cy * 40 + cx] = chosen[0] << 4 | chosen[1]
            colram[cy * 40 + cx] = chosen[2]
            for y in range(8):
                byte = 0
                for x in range(4):
                    c = px[cx * 4 + x, cy * 8 + y]
                    if c not in slots:
                        c = nearest(c, [BG] + chosen)
                    byte = byte << 2 | slots[c]
                    final.putpixel((cx * 4 + x, cy * 8 + y), c)
                bitmap[cy * 320 + cx * 8 + y] = byte
    return bitmap, screen, colram, final


def rle(data):
    """$FE n v = n copies of v (n 1-255); $FE 0 = end; any other byte is itself."""
    out, i = bytearray(), 0
    while i < len(data):
        v, n = data[i], 1
        while i + n < len(data) and data[i + n] == v and n < 255:
            n += 1
        if n >= 4 or v == 0xFE:
            out += bytes((0xFE, n, v))
        else:
            out += bytes([v]) * n
        i += n
    return out + b'\xfe\x00'


def main():
    bitmap, screen, colram, final = encode(scene())
    packed = rle(bitmap) + rle(screen) + rle(colram)
    open(OUT, 'wb').write(packed)
    final.putpalette([v for rgb in PALETTE for v in rgb])
    final.convert('RGB').resize((W * 2 * 2, H * 2), Image.NEAREST).save(PREVIEW, optimize=True)
    print('%s: %d bytes (from %d)' % (os.path.relpath(OUT, ROOT), len(packed), 10000))
    print(os.path.relpath(PREVIEW, ROOT))


if __name__ == '__main__':
    main()
