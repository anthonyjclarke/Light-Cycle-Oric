; Light Cycle (C64) — hardware registers and constants

; VIC-II
VIC_BORDER      = $D020
VIC_BG0         = $D021
VIC_CTRL1       = $D011
VIC_RASTER      = $D012
VIC_MEMSETUP    = $D018

; CIA
CIA1_PRA        = $DC00         ; keyboard column select / joystick 2
CIA1_PRB        = $DC01         ; keyboard row read / joystick 1
CIA2_PRA        = $DD00         ; bits 0-1: VIC bank (inverted)

; SID
SID_VOLUME      = $D418

; Memory
SCREEN_ROM      = $0400         ; power-on text screen (Phase 0 only)
COLOUR_RAM      = $D800

; Colours
COL_BLACK       = 0
COL_WHITE       = 1
COL_RED         = 2
COL_CYAN        = 3
COL_PURPLE      = 4
COL_GREEN       = 5
COL_BLUE        = 6
COL_YELLOW      = 7
