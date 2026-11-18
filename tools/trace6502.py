#!/usr/bin/env python3
"""Recursive-descent code tracer for a 6502 binary; emits a da65 info file.

Usage: trace6502.py bin loadaddr entry[,entry...] > out.info
Reports code ranges, data ranges, JSR/JMP targets, absolute data refs.
"""
import sys

# mode: imp acc imm zp zpx zpy abs abx aby ind izx izy rel
OPS = {}
def op(code, mn, mode): OPS[code] = (mn, mode)
tbl = """
00 BRK imp|01 ORA izx|05 ORA zp|06 ASL zp|08 PHP imp|09 ORA imm|0A ASL acc|0D ORA abs|0E ASL abs
10 BPL rel|11 ORA izy|15 ORA zpx|16 ASL zpx|18 CLC imp|19 ORA aby|1D ORA abx|1E ASL abx
20 JSR abs|21 AND izx|24 BIT zp|25 AND zp|26 ROL zp|28 PLP imp|29 AND imm|2A ROL acc|2C BIT abs|2D AND abs|2E ROL abs
30 BMI rel|31 AND izy|35 AND zpx|36 ROL zpx|38 SEC imp|39 AND aby|3D AND abx|3E ROL abx
40 RTI imp|41 EOR izx|45 EOR zp|46 LSR zp|48 PHA imp|49 EOR imm|4A LSR acc|4C JMP abs|4D EOR abs|4E LSR abs
50 BVC rel|51 EOR izy|55 EOR zpx|56 LSR zpx|58 CLI imp|59 EOR aby|5D EOR abx|5E LSR abx
60 RTS imp|61 ADC izx|65 ADC zp|66 ROR zp|68 PLA imp|69 ADC imm|6A ROR acc|6C JMP ind|6D ADC abs|6E ROR abs
70 BVS rel|71 ADC izy|75 ADC zpx|76 ROR zpx|78 SEI imp|79 ADC aby|7D ADC abx|7E ROR abx
81 STA izx|84 STY zp|85 STA zp|86 STX zp|88 DEY imp|8A TXA imp|8C STY abs|8D STA abs|8E STX abs
90 BCC rel|91 STA izy|94 STY zpx|95 STA zpx|96 STX zpy|98 TYA imp|99 STA aby|9A TXS imp|9D STA abx
A0 LDY imm|A1 LDA izx|A2 LDX imm|A4 LDY zp|A5 LDA zp|A6 LDX zp|A8 TAY imp|A9 LDA imm|AA TAX imp|AC LDY abs|AD LDA abs|AE LDX abs
B0 BCS rel|B1 LDA izy|B4 LDY zpx|B5 LDA zpx|B6 LDX zpy|B8 CLV imp|B9 LDA aby|BA TSX imp|BC LDY abx|BD LDA abx|BE LDX aby
C0 CPY imm|C1 CMP izx|C4 CPY zp|C5 CMP zp|C6 DEC zp|C8 INY imp|C9 CMP imm|CA DEX imp|CC CPY abs|CD CMP abs|CE DEC abs
D0 BNE rel|D1 CMP izy|D5 CMP zpx|D6 DEC zpx|D8 CLD imp|D9 CMP aby|DD CMP abx|DE DEC abx
E0 CPX imm|E1 SBC izx|E4 CPX zp|E5 SBC zp|E6 INC zp|E8 INX imp|E9 SBC imm|EA NOP imp|EC CPX abs|ED SBC abs|EE INC abs
F0 BEQ rel|F1 SBC izy|F5 SBC zpx|F6 INC zpx|F8 SED imp|F9 SBC aby|FD SBC abx|FE INC abx
"""
for chunk in tbl.replace("\n", "|").split("|"):
    if chunk.strip():
        c, m, md = chunk.split(); op(int(c, 16), m, md)
LEN = dict(imp=1, acc=1, imm=2, zp=2, zpx=2, zpy=2, abs=3, abx=3, aby=3, ind=3, izx=2, izy=2, rel=2)

def main():
    data = open(sys.argv[1], "rb").read()
    base = int(sys.argv[2], 16)
    end = base + len(data)
    todo = [int(e, 16) for e in sys.argv[3].split(",")]
    code, calls, jumps, refs, bad = set(), set(), set(), {}, []
    while todo:
        pc = todo.pop()
        while base <= pc < end and pc not in code:
            o = data[pc - base]
            if o not in OPS:
                bad.append(pc); break
            mn, md = OPS[o]; n = LEN[md]
            for k in range(n): code.add(pc + k)
            arg = data[pc - base + 1] | (data[pc - base + 2] << 8 if n == 3 else 0) if n > 1 else None
            nxt = pc + n
            if md == "rel":
                t = nxt + (arg - 256 if arg > 127 else arg); todo.append(t); jumps.add(t)
            elif mn == "JSR":
                calls.add(arg); todo.append(arg)
            elif mn == "JMP" and md == "abs":
                jumps.add(arg); todo.append(arg); break
            elif mn in ("RTS", "RTI", "BRK") or (mn == "JMP"):
                if mn == "JMP": refs.setdefault(arg, set()).add("JMP()")
                break
            elif md in ("abs", "abx", "aby") and base <= arg < end:
                refs.setdefault(arg, set()).add(mn)
            pc = nxt

    # ranges
    def ranges(s):
        s = sorted(s); out = []
        for a in s:
            if out and a == out[-1][1] + 1: out[-1][1] = a
            else: out.append([a, a])
        return out
    cr = ranges(code)
    print(f'GLOBAL {{ STARTADDR ${base:04X}; INPUTSIZE {len(data)}; CPU "6502"; COMMENTS 4; }};')
    prev = base
    for a, b in cr:
        if a > prev: print(f'RANGE {{ START ${prev:04X}; END ${a-1:04X}; TYPE ByteTable; }};')
        print(f'RANGE {{ START ${a:04X}; END ${b:04X}; TYPE Code; }};')
        prev = b + 1
    if prev < end: print(f'RANGE {{ START ${prev:04X}; END ${end-1:04X}; TYPE ByteTable; }};')
    sys.stderr.write(f"code bytes {len(code)} / {len(data)}; subs {len(calls)}; bad {[hex(b) for b in bad]}\n")
    sys.stderr.write("subs: " + " ".join(f"{c:04X}" for c in sorted(calls)) + "\n")
    sys.stderr.write("data refs in-range: " + " ".join(f"{a:04X}:{'/'.join(sorted(v))}" for a, v in sorted(refs.items())) + "\n")


if __name__ == "__main__":
    main()
