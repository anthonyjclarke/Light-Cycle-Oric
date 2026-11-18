; Light Cycle (C64) — the crash explosion
;
; Oric Explosion ($0C06) with PartLoadEnds / PartLoadState / PartSaveState,
; ported line for line. 32 particles start at the crash point (zX, zY),
; each after a random delay of 5-20 ticks, and travel one Bresenham step
; per tick toward a target offset by ExplodeDX/DY, as a single moving dot:
; each step unplots the old pixel (so the explosion nibbles at trails and
; walls it crosses, as on the Oric) and plots the new one. A particle stops
; at its target or at the arena's edge. 35 ticks in all.
;
; The Oric kept particle state at $9D00 (spare character-set RAM); here it
; is ordinary BSS. Its tick took about 42 ms (measured by
; tools/oric_timing.py); two C64 frames is 40 ms PAL.

        .include "hw.inc"
        .include "zp.inc"

        .import Random, DrawLine, LineStep, PlotXY, UnplotPixel, WaitTicks
        .import ExplodeDX, ExplodeDY
        .export Explosion

PARTICLES       = 32
EXPLOSION_TICKS = $23
TICK_FRAMES     = 2

        .segment "CODE"

Explosion:
        lda     #$01
        sta     zLineStep
        lda     #EXPLOSION_TICKS
        sta     zObC
        lda     #PARTICLES - 1
        sta     zObA
        sta     zObB
@init:  jsr     Random
        lda     zRnd2
        and     #$0F
        adc     #$05
        ldx     zObB
        sta     PartLife,x              ; start delay 5-20 ticks
        lda     zX
        sta     PartX,x
        lda     ExplodeDX,x
        clc
        adc     zX
        sta     PartTX,x
        lda     zY
        sta     PartY,x
        lda     ExplodeDY,x
        clc
        adc     zY
        sta     PartTY,x
        dec     zObB
        bpl     @init

@tick:  lda     zObA
        sta     zObB
@part:  ldx     zObB
        ldy     PartLife,x
        cpy     #$01
        beq     @move
        cpy     #$00
        beq     @next
        dec     PartLife,x
        lda     PartLife,x
        cmp     #$01
        bne     @next
        jsr     PartLoadEnds            ; delay over: start the line
        jsr     DrawLine
        jsr     PartSaveState
        lda     zLX0
        sta     PartX,x
        lda     zLY0
        sta     PartY,x
@next:  dec     zObB
        bpl     @part
        ldx     #TICK_FRAMES
        jsr     WaitTicks
        dec     zObC
        beq     @done
        jmp     @tick
@done:  rts

@move:  jsr     PartLoadEnds
        jsr     PartLoadState
        ldx     zLX0
        ldy     zLY0
        jsr     UnplotPixel
        jsr     LineStep
        jsr     PartSaveState
        ldx     zLX0
        ldy     zLY0
        jsr     PlotXY
        ldx     zObB
        lda     zLX0
        sta     PartX,x
        lda     zLY0
        sta     PartY,x
        ldx     zLX0
        cpx     #$08
        bcc     @kill
        cpx     #$EE
        bcs     @kill
        ldy     zLY0
        cpy     #$02
        bcc     @kill
        cpy     #$C6
        bcs     @kill
        lda     zLX0
        cmp     zLX1
        bne     @next
        lda     zLY0
        cmp     zLY1
        bne     @next
@kill:  ldx     zLX0
        ldy     zLY0
        jsr     UnplotPixel
        lda     #$00
        ldx     zObB
        sta     PartLife,x
        jmp     @next

; Particle zObB's position and target into the line variables. Leaves X.
PartLoadEnds:
        ldx     zObB
        lda     PartX,x
        sta     zLX0
        lda     PartY,x
        sta     zLY0
        lda     PartTX,x
        sta     zLX1
        lda     PartTY,x
        sta     zLY1
        rts

PartLoadState:
        ldx     zObB
        lda     PartDX,x
        sta     zLDX
        lda     PartDY,x
        sta     zLDY
        lda     PartSX,x
        sta     zLSX
        lda     PartSY,x
        sta     zLSY
        lda     PartErrX,x
        sta     zLErrX
        lda     PartErrY,x
        sta     zLErrY
        rts

; Save the line state for particle zObB. Leaves X = zObB.
PartSaveState:
        ldx     zObB
        lda     zLDX
        sta     PartDX,x
        lda     zLDY
        sta     PartDY,x
        lda     zLErrX
        sta     PartErrX,x
        lda     zLErrY
        sta     PartErrY,x
        lda     zLSX
        sta     PartSX,x
        lda     zLSY
        sta     PartSY,x
        rts

        .segment "BSS"

PartLife:       .res PARTICLES
PartX:          .res PARTICLES
PartTX:         .res PARTICLES
PartY:          .res PARTICLES
PartTY:         .res PARTICLES
PartDX:         .res PARTICLES
PartDY:         .res PARTICLES
PartSX:         .res PARTICLES
PartSY:         .res PARTICLES
PartErrX:       .res PARTICLES
PartErrY:       .res PARTICLES
