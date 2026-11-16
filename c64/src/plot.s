; Light Cycle (C64) — pixel addressing in game coordinates
;
; Game coordinates are the Oric's: x 0-239, y 0-199. The C64 bitmap is 320
; wide, so the arena is drawn ARENA_X_OFFSET (40) pixels in. The routines
; keep the Oric contracts so the game logic ports unchanged:
;
;   Oric (oric/game.s)          C64
;   HiresAddr  X,Y -> ptr,mask  HiresAddr  X,Y -> zPix, zMask; A,X,Y kept
;   PlotPixel  set at zPix      PlotPixel  set at zPix/zMask; X,Y kept
;   UnplotPixel X,Y             UnplotPixel X,Y; X,Y kept
;   PixelSet   X,Y -> C         PixelSet   X,Y -> C=1 if lit; X,Y kept
;
; The Oric divides x by 6 in a loop (up to 40 passes); here every lookup is
; a table read.

        .include "hw.inc"
        .include "zp.inc"

        .export HiresAddr, PlotPixel, PlotXY, UnplotPixel, PixelSet

        .segment "CODE"

; In: X = x (0-239), Y = y (0-199). Out: zPix, zMask. Preserves A, X, Y.
HiresAddr:
        pha
        lda     RowLo,y
        clc
        adc     ColLo,x
        sta     zPix
        lda     RowHi,y
        adc     ColHi,x
        sta     zPix + 1
        lda     PixMask,x
        sta     zMask
        pla
        rts

; Set the pixel addressed by zPix/zMask. Preserves X, Y.
PlotPixel:
        tya
        pha
        ldy     #0
        lda     zMask
        ora     (zPix),y
        sta     (zPix),y
        pla
        tay
        rts

; Set pixel (X, Y). Preserves X, Y.
PlotXY:
        jsr     HiresAddr
        jmp     PlotPixel

; Clear pixel (X, Y). Preserves X, Y.
UnplotPixel:
        jsr     HiresAddr
        tya
        pha
        ldy     #0
        lda     zMask
        eor     #$FF
        and     (zPix),y
        sta     (zPix),y
        pla
        tay
        rts

; C = 1 if pixel (X, Y) is lit. Preserves X, Y.
PixelSet:
        jsr     HiresAddr
        tya
        pha
        ldy     #0
        lda     (zPix),y
        and     zMask
        cmp     #1                      ; C = (A >= 1) = lit
        pla
        tay
        rts

        .segment "RODATA"

; Bitmap address of the start of each pixel row (row 0-199).
RowLo:
        .repeat ARENA_HEIGHT, row
        .byte   <(BITMAP + (row / 8) * 320 + (row .mod 8))
        .endrepeat
RowHi:
        .repeat ARENA_HEIGHT, row
        .byte   >(BITMAP + (row / 8) * 320 + (row .mod 8))
        .endrepeat

; Byte offset of each game x within a row, including the arena offset.
ColLo:
        .repeat ARENA_WIDTH, col
        .byte   <(((col + ARENA_X_OFFSET) / 8) * 8)
        .endrepeat
ColHi:
        .repeat ARENA_WIDTH, col
        .byte   >(((col + ARENA_X_OFFSET) / 8) * 8)
        .endrepeat

; Bit within the byte (bit 7 = leftmost pixel).
PixMask:
        .repeat ARENA_WIDTH, col
        .byte   $80 >> ((col + ARENA_X_OFFSET) .mod 8)
        .endrepeat
