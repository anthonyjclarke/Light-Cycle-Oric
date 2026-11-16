#!/usr/bin/env python3
"""Split an Oric .TAP into its blocks and detokenise any BASIC block.

Usage: tap_extract.py CYCLE.TAP outdir
"""
import sys, os

TOK = ("END EDIT STORE RECALL TRON TROFF POP PLOT PULL LORES DOKE REPEAT UNTIL FOR "
       "LLIST LPRINT NEXT DATA INPUT DIM CLS READ LET GOTO RUN IF RESTORE GOSUB RETURN "
       "REM HIMEM GRAB RELEASE TEXT HIRES SHOOT EXPLODE ZAP PING SOUND MUSIC PLAY CURSET "
       "CURMOV DRAW CIRCLE PATTERN FILL CHAR PAPER INK STOP ON WAIT CLOAD CSAVE DEF POKE "
       "PRINT CONT LIST CLEAR GET CALL ! NEW TAB( TO FN SPC( @ AUTO ELSE THEN NOT STEP "
       "+ - * / ^ AND OR > = < SGN INT ABS USR FRE POS HEX$ & SQR RND LN EXP COS SIN TAN "
       "ATN PEEK DEEK LOG LEN STR$ VAL ASC CHR$ PI TRUE FALSE KEY$ SCRN POINT LEFT$ RIGHT$ MID$").split()

def blocks(d):
    i = 0
    while (j := d.find(b"\x16\x16\x16", i)) >= 0:
        k = j
        while d[k] == 0x16:
            k += 1
        h = d[k + 1:k + 10]
        n = d.index(0, k + 10)
        name = d[k + 10:n].decode("ascii", "replace")
        start, end = h[6] << 8 | h[7], h[4] << 8 | h[5]
        data = d[n + 1:n + 1 + end - start + 1]
        yield dict(name=name, type=h[2], auto=h[3], start=start, end=end, data=data)
        i = n + 1 + len(data)

def detok(data, base):
    out, p = [], 0
    while True:
        link = data[p] | data[p + 1] << 8
        if link == 0:
            return "\n".join(out), base + p + 2
        line = data[p + 2] | data[p + 3] << 8
        q, s, quote = p + 4, "", False
        while data[q]:
            c = data[q]
            if c == 0x22:
                quote = not quote
            s += TOK[c - 0x80] if c >= 0x80 and not quote and c - 0x80 < len(TOK) else chr(c)
            q += 1
        out.append(f"{line} {s}")
        p = link - base

d = open(sys.argv[1], "rb").read()
os.makedirs(sys.argv[2], exist_ok=True)
for b in blocks(d):
    tag = b["name"].replace(" ", "_").lower()
    fn = os.path.join(sys.argv[2], f"{tag}_{b['start']:04x}.bin")
    open(fn, "wb").write(b["data"])
    print(f"{b['name']!r} type=${b['type']:02x} auto=${b['auto']:02x} ${b['start']:04X}-${b['end']:04X} -> {fn}")
    if b["type"] == 0:
        txt, endp = detok(b["data"], b["start"])
        open(os.path.join(sys.argv[2], f"{tag}.bas"), "w").write(txt + "\n")
        print(txt)
        print(f"BASIC ends at ${endp:04X}; remaining {b['end'] - endp + 1} bytes are data/code")
