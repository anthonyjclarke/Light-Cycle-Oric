; Light Cycle (C64) — entry point
;
; Phase 0: boot, set colours, print a banner. Later phases replace the
; banner with the Oric game flow (Start -> VolumeScreen -> MainMenu ...).

        .include "hw.inc"

        .export Start

        .segment "CODE"

Start:
        sei
        lda     #COL_BLUE
        sta     VIC_BORDER
        lda     #COL_BLACK
        sta     VIC_BG0
        jsr     ClearScreen
        ldx     #BannerLen - 1
@copy:  lda     Banner,x
        sta     SCREEN_ROM + 40*12 + (40 - BannerLen) / 2,x
        lda     #COL_CYAN
        sta     COLOUR_RAM + 40*12 + (40 - BannerLen) / 2,x
        dex
        bpl     @copy
        cli
@idle:  jmp     @idle

; Fill the default text screen ($0400) with spaces.
ClearScreen:
        lda     #$20
        ldx     #0
@loop:  sta     SCREEN_ROM,x
        sta     SCREEN_ROM + $100,x
        sta     SCREEN_ROM + $200,x
        sta     SCREEN_ROM + $2E8,x
        inx
        bne     @loop
        rts

        .segment "RODATA"

; Screen codes: letters A-Z are $01-$1A, digits and space match ASCII.
.repeat 26, i
.charmap $41 + i, $01 + i
.endrepeat
Banner: .byte   "LIGHT CYCLE C64 - PHASE 0"
BannerLen = * - Banner
