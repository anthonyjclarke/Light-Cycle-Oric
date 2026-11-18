"""Minimal cycle-counting 6502 core (documented opcodes, binary mode only).

Used by tools/oric_timing.py to time the Oric game's own code. Memory is a flat 64K bytearray: no I/O side effects.
Cycle counts follow the NMOS 6502 data sheet, including page-crossing and taken-branch penalties.
"""
from trace6502 import OPS, LEN  # noqa: F401  (shared opcode table)

RMW = {'ASL', 'LSR', 'ROL', 'ROR', 'INC', 'DEC'}
STORE = {'STA', 'STX', 'STY'}


class CPU:
    def __init__(self, mem):
        self.m = mem
        self.a = self.x = self.y = 0
        self.sp = 0xFF
        self.pc = 0
        self.c = self.z = self.i = self.d = self.v = self.n = 0
        self.cycles = 0

    # --- helpers -------------------------------------------------------------------------------------------------
    def rd16(self, a):
        return self.m[a & 0xFFFF] | self.m[(a + 1) & 0xFFFF] << 8

    def push(self, v):
        self.m[0x100 + self.sp] = v & 0xFF
        self.sp = (self.sp - 1) & 0xFF

    def pull(self):
        self.sp = (self.sp + 1) & 0xFF
        return self.m[0x100 + self.sp]

    def nz(self, v):
        v &= 0xFF
        self.n, self.z = v >> 7, int(v == 0)
        return v

    def flags(self):
        return self.n << 7 | self.v << 6 | 0x30 | self.d << 3 | self.i << 2 | self.z << 1 | self.c

    def set_flags(self, p):
        self.n, self.v, self.d, self.i, self.z, self.c = p >> 7 & 1, p >> 6 & 1, p >> 3 & 1, p >> 2 & 1, p >> 1 & 1, p & 1

    def rts(self):
        lo = self.pull()
        self.pc = ((self.pull() << 8 | lo) + 1) & 0xFFFF
        self.cycles += 6

    # --- one instruction -----------------------------------------------------------------------------------------
    def step(self):
        m, pc = self.m, self.pc
        op = m[pc]
        if op not in OPS:
            raise RuntimeError('bad opcode $%02X at $%04X' % (op, pc))
        mn, md = OPS[op]
        n = LEN[md]
        b1 = m[(pc + 1) & 0xFFFF]
        w = b1 | m[(pc + 2) & 0xFFFF] << 8
        self.pc = (pc + n) & 0xFFFF
        ea, extra = None, 0
        if md == 'zp':
            ea, cyc = b1, 3
        elif md == 'zpx':
            ea, cyc = (b1 + self.x) & 0xFF, 4
        elif md == 'zpy':
            ea, cyc = (b1 + self.y) & 0xFF, 4
        elif md == 'abs':
            ea, cyc = w, 4
        elif md in ('abx', 'aby'):
            ea = (w + (self.x if md == 'abx' else self.y)) & 0xFFFF
            cyc = 4
            if (ea ^ w) & 0xFF00:
                extra = 1
        elif md == 'izx':
            p = (b1 + self.x) & 0xFF
            ea, cyc = m[p] | m[(p + 1) & 0xFF] << 8, 6
        elif md == 'izy':
            base = m[b1] | m[(b1 + 1) & 0xFF] << 8
            ea, cyc = (base + self.y) & 0xFFFF, 5
            if (ea ^ base) & 0xFF00:
                extra = 1
        elif md == 'ind':
            ea, cyc = m[w] | m[(w & 0xFF00) | ((w + 1) & 0xFF)] << 8, 5
        else:
            cyc = 2
        # store / RMW timing
        if mn in STORE and md in ('abx', 'aby', 'izy'):
            cyc, extra = cyc + 1, 0
        if mn in RMW and md != 'acc':
            cyc = {'zp': 5, 'zpx': 6, 'abs': 6, 'abx': 7}[md]
            extra = 0
        val = lambda: b1 if md == 'imm' else m[ea]  # noqa: E731

        if mn == 'LDA': self.a = self.nz(val())
        elif mn == 'LDX': self.x = self.nz(val())
        elif mn == 'LDY': self.y = self.nz(val())
        elif mn == 'STA': m[ea] = self.a
        elif mn == 'STX': m[ea] = self.x
        elif mn == 'STY': m[ea] = self.y
        elif mn in ('ADC', 'SBC'):
            v = val() if mn == 'ADC' else val() ^ 0xFF
            r = self.a + v + self.c
            self.v = int((~(self.a ^ v) & (self.a ^ r) & 0x80) != 0)
            self.c = int(r > 0xFF)
            self.a = self.nz(r)
        elif mn == 'AND': self.a = self.nz(self.a & val())
        elif mn == 'ORA': self.a = self.nz(self.a | val())
        elif mn == 'EOR': self.a = self.nz(self.a ^ val())
        elif mn in ('CMP', 'CPX', 'CPY'):
            r = {'CMP': self.a, 'CPX': self.x, 'CPY': self.y}[mn] - val()
            self.c = int(r >= 0)
            self.nz(r)
        elif mn == 'BIT':
            v = val()
            self.z, self.n, self.v = int((self.a & v) == 0), v >> 7, v >> 6 & 1
        elif mn in RMW:
            v = self.a if md == 'acc' else m[ea]
            if mn == 'ASL': self.c, v = v >> 7, v << 1
            elif mn == 'LSR': self.c, v = v & 1, v >> 1
            elif mn == 'ROL': v, self.c = v << 1 | self.c, v >> 7
            elif mn == 'ROR': v, self.c = v >> 1 | self.c << 7, v & 1
            elif mn == 'INC': v += 1
            else: v -= 1
            v = self.nz(v)
            if md == 'acc': self.a = v
            else: m[ea] = v
        elif mn == 'INX': self.x = self.nz(self.x + 1)
        elif mn == 'INY': self.y = self.nz(self.y + 1)
        elif mn == 'DEX': self.x = self.nz(self.x - 1)
        elif mn == 'DEY': self.y = self.nz(self.y - 1)
        elif mn == 'TAX': self.x = self.nz(self.a)
        elif mn == 'TAY': self.y = self.nz(self.a)
        elif mn == 'TXA': self.a = self.nz(self.x)
        elif mn == 'TYA': self.a = self.nz(self.y)
        elif mn == 'TSX': self.x = self.nz(self.sp)
        elif mn == 'TXS': self.sp = self.x
        elif mn == 'PHA': self.push(self.a); cyc = 3
        elif mn == 'PHP': self.push(self.flags()); cyc = 3
        elif mn == 'PLA': self.a = self.nz(self.pull()); cyc = 4
        elif mn == 'PLP': self.set_flags(self.pull()); cyc = 4
        elif mn == 'CLC': self.c = 0
        elif mn == 'SEC': self.c = 1
        elif mn == 'CLI': self.i = 0
        elif mn == 'SEI': self.i = 1
        elif mn == 'CLD': self.d = 0
        elif mn == 'SED': self.d = 1
        elif mn == 'CLV': self.v = 0
        elif mn == 'NOP': pass
        elif mn == 'JMP': self.pc = ea; cyc = 3 if md == 'abs' else 5
        elif mn == 'JSR':
            ret = (pc + 2) & 0xFFFF
            self.push(ret >> 8); self.push(ret)
            self.pc, cyc = w, 6
        elif mn == 'RTS':
            self.rts(); return
        elif mn == 'RTI':
            self.set_flags(self.pull()); lo = self.pull(); self.pc = self.pull() << 8 | lo; cyc = 6
        elif md == 'rel':
            cond = {'BPL': not self.n, 'BMI': self.n, 'BVC': not self.v, 'BVS': self.v,
                    'BCC': not self.c, 'BCS': self.c, 'BNE': not self.z, 'BEQ': self.z}[mn]
            if cond:
                t = (self.pc + (b1 - 256 if b1 > 127 else b1)) & 0xFFFF
                extra = 1 + int((t ^ self.pc) & 0xFF00 != 0)
                self.pc = t
        elif mn == 'BRK':
            raise RuntimeError('BRK at $%04X' % pc)
        else:
            raise RuntimeError('unimplemented %s' % mn)
        self.cycles += cyc + extra
