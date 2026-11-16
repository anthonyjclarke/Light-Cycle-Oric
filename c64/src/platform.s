; Light Cycle (C64) — platform start-up
;
; Takes the machine over: BASIC and KERNAL banked out (all RAM except I/O),
; CIA interrupts off, own IRQ/NMI handlers, VIC bank 1. Nothing after this
; calls the ROMs. Oric equivalent: the first lines of Start plus
; ViaGameSetup, which likewise stop the ROM's interrupt during play.

        .include "hw.inc"
        .include "zp.inc"

        .import InitVideo, InitTiming, InitInput, InitSound
        .export InitPlatform

        .segment "CODE"

; Call once, first thing. Returns with IRQs enabled.
InitPlatform:
        sei
        cld
        lda     #MEM_IO_ONLY
        sta     CPU_PORT
        lda     #$7F
        sta     CIA1_ICR                ; no CIA interrupts
        sta     CIA2_ICR
        lda     CIA1_ICR                ; clear anything pending
        lda     CIA2_ICR
        lda     #0
        sta     VIC_IRQ_MASK
        jsr     InitVideo
        jsr     InitTiming
        jsr     InitInput
        jsr     InitSound
        cli
        rts
