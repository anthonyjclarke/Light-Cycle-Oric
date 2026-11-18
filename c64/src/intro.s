; Light Cycle (C64) — the intro picture
;
; A multicolour bitmap after the original PSS cassette inlay, drawn by
; tools/make_intro.py and stored run-length packed in intro.rle: bitmap,
; then screen colours, then colour RAM, each ending with $FE $00. Not in the
; Oric game, whose title screen was the instructions.

        .include "hw.inc"
        .include "zp.inc"

        .export IntroScreen

        .segment "CODE"

; Unpack the picture into VIC bank 1 and show it in multicolour bitmap mode.
IntroScreen:
        lda     #$0B                    ; blank the display while unpacking
        sta     VIC_CTRL1
        lda     #<IntroData
        sta     zPtr
        lda     #>IntroData
        sta     zPtr + 1
        lda     #<BITMAP
        ldx     #>BITMAP
        jsr     Unpack
        lda     #<BITMAP_COLOURS
        ldx     #>BITMAP_COLOURS
        jsr     Unpack
        lda     #<COLOUR_RAM
        ldx     #>COLOUR_RAM
        jsr     Unpack
        lda     #COL_BLACK
        sta     VIC_BORDER
        lda     #COL_BLUE               ; the picture's shared background
        sta     VIC_BG0
        lda     #MEMSETUP_BITMAP
        sta     VIC_MEMSETUP
        lda     #$D8                    ; multicolour, 40 columns
        sta     VIC_CTRL2
        lda     #$3B
        sta     VIC_CTRL1
        rts

; Unpack from zPtr (left after the end marker) to A/X: $FE n v writes n
; copies of v, $FE $00 ends, any other byte is copied.
Unpack:
        sta     zPix
        stx     zPix + 1
        ldy     #0
@next:  jsr     GetByte
        cmp     #$FE
        beq     @run
        sta     (zPix),y
        jsr     NextDest
        jmp     @next
@run:   jsr     GetByte
        beq     @end
        tax
        jsr     GetByte
@copy:  sta     (zPix),y
        jsr     NextDest
        dex
        bne     @copy
        jmp     @next
@end:   rts

; Next packed byte in A (flags from LDA); keeps X, Y = 0.
GetByte:
        lda     (zPtr),y
        inc     zPtr
        bne     :+
        inc     zPtr + 1
:       cmp     #0
        rts

NextDest:
        inc     zPix
        bne     :+
        inc     zPix + 1
:       rts

        .segment "RODATA"

IntroData:
        .incbin "intro.rle"
