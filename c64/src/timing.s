; Light Cycle (C64) — timing: PAL/NTSC detection, raster IRQ, frame ticks
;
; The Oric paces the game with busy-wait loops (FrameDelay, Delay), so its
; speed varies with how much it draws. The C64 version counts raster ticks
; instead: one zTick per frame (50 Hz PAL, 60 Hz NTSC). Speed tables that
; turn ticks into pixels per step belong to the game logic (Phase 2) and
; are calibrated against the Oric there.

        .include "hw.inc"
        .include "zp.inc"

        .export InitTiming, WaitTick, WaitTicks

IRQ_LINE = 251                          ; bottom border, below the 200 visible lines

        .segment "CODE"

; Detect PAL/NTSC, install the IRQ/NMI vectors and start the raster IRQ.
; Expects IRQs masked and MEM_IO_ONLY; leaves IRQs masked (caller CLIs).
InitTiming:
        ; Highest raster line, low byte: PAL $37 (311), NTSC $06 or $05.
@w0:    lda     VIC_RASTER
@w1:    cmp     VIC_RASTER
        beq     @w1
        bmi     @w0
        ldx     #0
        cmp     #$20
        bcc     :+
        inx
:       stx     zIsPAL

        lda     #<IrqHandler
        sta     VEC_IRQ
        lda     #>IrqHandler
        sta     VEC_IRQ + 1
        lda     #<NmiHandler
        sta     VEC_NMI
        lda     #>NmiHandler
        sta     VEC_NMI + 1

        lda     #IRQ_LINE
        sta     VIC_RASTER
        lda     VIC_CTRL1
        and     #$7F                    ; raster compare bit 8 = 0
        sta     VIC_CTRL1
        lda     #$01
        sta     VIC_IRQ_MASK            ; raster IRQ only
        sta     VIC_IRQ_FLAG
        lda     #0
        sta     zTick
        rts

IrqHandler:
        pha
        lda     #$01
        sta     VIC_IRQ_FLAG            ; acknowledge
        inc     zTick
        pla
NmiHandler:                             ; RESTORE key: ignored
        rti

; Wait for the next frame tick. Preserves X, Y.
WaitTick:
        lda     zTick
@wait:  cmp     zTick
        beq     @wait
        rts

; Wait X frame ticks (X = 0 waits 256). Preserves Y.
WaitTicks:
        jsr     WaitTick
        dex
        bne     WaitTicks
        rts
