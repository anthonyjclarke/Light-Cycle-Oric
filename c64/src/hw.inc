; Light Cycle (C64) — hardware registers, memory layout and constants

; CPU port
CPU_PORT        = $01
MEM_IO_ONLY     = $35           ; RAM everywhere except I/O at $D000 (no BASIC/KERNAL)
MEM_CHARROM     = $33           ; character ROM at $D000 (for copying the font)

; Hardware vectors (RAM under the KERNAL while MEM_IO_ONLY)
VEC_NMI         = $FFFA
VEC_RESET       = $FFFC
VEC_IRQ         = $FFFE

; VIC-II
VIC_CTRL1       = $D011
VIC_RASTER      = $D012
VIC_CTRL2       = $D016
VIC_MEMSETUP    = $D018
VIC_IRQ_FLAG    = $D019
VIC_IRQ_MASK    = $D01A
VIC_BORDER      = $D020
VIC_BG0         = $D021

; CIA
CIA1_PRA        = $DC00         ; keyboard column select (write) / joystick 2 (read)
CIA1_PRB        = $DC01         ; keyboard row read / joystick 1
CIA1_DDRA       = $DC02
CIA1_DDRB       = $DC03
CIA1_ICR        = $DC0D
CIA2_PRA        = $DD00         ; bits 0-1: VIC bank, inverted
CIA2_DDRA       = $DD02
CIA2_ICR        = $DD0D

; SID
SID             = $D400
SID_V1          = SID + 0       ; voice n at SID + 7*(n-1): freq lo/hi, pw lo/hi, ctrl, AD, SR
SID_V2          = SID + 7
SID_V3          = SID + 14
SID_VOLUME      = $D418

; Memory layout: VIC bank 1 ($4000-$7FFF), see docs/porting.md
VIC_BANK_BITS   = %10           ; $DD00 value selecting bank 1
TEXT_SCREEN     = $4400         ; menus: 40x25 screen codes
CHARSET         = $4800         ; menus and bitmap glyphs (copy of ROM font for now)
BITMAP_COLOURS  = $5C00         ; bitmap mode: ink (hi nibble) / paper (lo nibble) per cell
BITMAP          = $6000         ; 320x200 hires bitmap
COLOUR_RAM      = $D800

; $D018 values: screen at bank+nibble*$400, charset/bitmap at bank+bits*$400
MEMSETUP_TEXT   = ((TEXT_SCREEN - $4000) / $400) << 4 | ((CHARSET - $4000) / $400)
MEMSETUP_BITMAP = ((BITMAP_COLOURS - $4000) / $400) << 4 | $08

; Arena: the Oric's 240x200 HIRES area, centred with 5 cells of panel either side
ARENA_X_OFFSET  = 40            ; screen x = game x + 40
ARENA_WIDTH     = 240
ARENA_HEIGHT    = 200
ARENA_COL0      = ARENA_X_OFFSET / 8        ; first arena cell column (5)
ARENA_COLS      = ARENA_WIDTH / 8           ; 30

; String terminator for PrintText (screen code 0 is '@')
STR_END         = $FF

; Colours
COL_BLACK       = 0
COL_WHITE       = 1
COL_RED         = 2
COL_CYAN        = 3
COL_PURPLE      = 4
COL_GREEN       = 5
COL_BLUE        = 6
COL_YELLOW      = 7
COL_ORANGE      = 8
COL_BROWN       = 9
COL_LIGHTRED    = 10
COL_DARKGREY    = 11
COL_GREY        = 12
COL_LIGHTGREEN  = 13
COL_LIGHTBLUE   = 14
COL_LIGHTGREY   = 15

; zInput bits, as on the Oric (zInput / KeyBitP1 in oric/game.s)
IN_RIGHT        = $01
IN_LEFT         = $02
IN_DOWN         = $04
IN_UP           = $08
IN_BOOST        = $10

; Key codes returned by GetKey / WaitKey (Oric ROM codes where the game used them)
KEY_LEFT        = $08
KEY_RIGHT       = $09
KEY_DOWN        = $0A
KEY_UP          = $0B
KEY_RETURN      = $0D
KEY_STOP        = $03
KEY_DEL         = $7F
