#!/usr/bin/env python3
"""Build the annotated, reassemblable disassembly of Light Cycle (Oric).

Run from the project root after tools/tap_extract.py:
    python3 tools/build_disasm.py
Writes oric/game.s and oric/loader.s, reassembles both with cl65 and checks
they are byte-identical to the extracted blocks.
"""
import os, re, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(__file__))
import symbols as S

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIC = os.path.join(ROOT, "oric")


def info(binfile, start, size, ranges, labels):
    out = [f'GLOBAL {{ INPUTNAME "{binfile}"; STARTADDR ${start:04X}; '
           f'INPUTSIZE {size}; CPU "6502"; COMMENTS 4; }};']
    for a, (name, _) in S.HW.items():
        out.append(f'LABEL {{ NAME "{name}"; ADDR ${a:04X}; }};')
    for a, name in S.ZP.items():
        out.append(f'LABEL {{ NAME "{name}"; ADDR ${a:02X}; }};')
    for a, b, typ, name, _ in ranges:
        out.append(f'RANGE {{ START ${a:04X}; END ${b:04X}; TYPE {typ}; }};')
        if name:
            out.append(f'LABEL {{ NAME "{name}"; ADDR ${a:04X}; }};')
    for a, (name, _) in labels.items():
        out.append(f'LABEL {{ NAME "{name}"; ADDR ${a:04X}; }};')
    return "\n".join(out) + "\n"


def block(text):
    lines = ["", "; " + "-" * 74]
    lines += [("; " + l).rstrip() for l in text.splitlines()]
    lines.append("; " + "-" * 74)
    return lines


def postprocess(raw, title, ranges, labels, inline):
    blocks = {name: c for _, _, _, name, c in ranges if name and c}
    blocks.update({n: c for n, c in labels.values() if c})
    hwdoc = {n: d for n, d in S.HW.values()}
    used, out = set(), []
    out += [f"; {title}", "; Annotated disassembly — reassembles byte-identical with:",
            ";   cl65 -t none --start-addr <load address> -o out.bin <this file>", ""]
    for line in raw.splitlines():
        if line.startswith(("; da65", "; Created", "; Input file", "; Page")):
            continue
        m = re.match(r"^(\w+)\s*:=\s*\$([0-9A-F]+)", line)
        if m:
            d = hwdoc.get(m.group(1))
            out.append(f"{line:<28}; {d}" if d else line)
            continue
        if line.strip() == ".setcpu \"6502\"":
            out.append(line)
            if "Game" in title:
                out.append(S.ZP_DOC.rstrip())
            continue
        if line.startswith("; " + "-" * 76):
            continue  # drop da65's own separators; our block comments mark routines
        m = re.match(r"^(\w+):", line)
        if m and m.group(1) in blocks:
            out += block(blocks[m.group(1)])
        m = re.search(r";\s([0-9A-F]{4})\s(?:[0-9A-F]{2}\s)+.*$", line)
        if m:
            a = int(m.group(1), 16)
            code = line[:m.start()].rstrip()
            c = inline.get(a, "")
            used.add(a) if c else None
            line = f"{code:<40}; {a:04X}" + (f"  {c}" if c else "")
        out.append(line.rstrip())
    missing = sorted(set(inline) - used)
    if missing:
        print("  WARNING inline comments not placed:", " ".join(f"{a:04X}" for a in missing))
    return "\n".join(out) + "\n"


def build(binname, start, ranges, labels, inline, outname, title):
    binpath = os.path.join(ORIC, binname)
    size = os.path.getsize(binpath)
    with tempfile.TemporaryDirectory() as td:
        inf = os.path.join(td, "x.info")
        open(inf, "w").write(info(binpath, start, size, ranges, labels))
        raw = subprocess.run(["da65", "-i", inf], capture_output=True, text=True, check=True).stdout
        src = postprocess(raw, title, ranges, labels, inline)
        dst = os.path.join(ORIC, outname)
        open(dst, "w").write(src)
        rebuilt = os.path.join(td, "re.bin")
        subprocess.run(["cl65", "-t", "none", "--start-addr", f"0x{start:04X}", "-o", rebuilt, dst],
                       check=True, cwd=td)
        ok = open(rebuilt, "rb").read() == open(binpath, "rb").read()
        obj = os.path.splitext(dst)[0] + ".o"
        if os.path.exists(obj):
            os.remove(obj)  # cl65 drops its object file next to the source
    print(f"{outname}: {src.count(chr(10))} lines, reassembly {'IDENTICAL' if ok else 'DIFFERS'}")
    return ok


ok = build("game_0400.bin", 0x0400, S.GAME_RANGES, S.GAME_LABELS, S.GAME_INLINE,
           "game.s", "Light Cycle (Oric) — Game block 'GAME' $0400-$1800")
ok &= build("light_cycle_0501.bin", 0x0501, S.LOADER_RANGES, S.LOADER_LABELS, S.LOADER_INLINE,
            "loader.s", "Light Cycle (Oric) — Loader block 'LIGHT CYCLE' $0501-$0E80")
sys.exit(0 if ok else 1)
