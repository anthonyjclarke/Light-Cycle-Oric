; Light Cycle (C64) — arena: random numbers, lines, frame, obstacles, starts
;
; Ported from oric/game.s instruction for instruction where the logic is
; the Oric's, so the same random seed draws the same arena. Carry is used
; as the Oric code leaves it (several ADC/SBC follow Random without CLC/SEC).

        .include "hw.inc"
        .include "zp.inc"

        .import PlotXY, SetArenaColour
        .export Random, SeedRandom, DrawLine, LineStep, DrawBorder, DrawObstacles
        .export SetPaperColour, RandomStarts, ArenaPaper

ARENA_INK       = COL_WHITE

        .segment "CODE"

; Oric Random ($0DDB): each of the four bytes becomes the previous byte's
; old value plus itself plus carry. Callers read zRnd2 / zRnd3.
Random:
        ldy     #$29
        ldx     #$FC
@loop:  tya
        ldy     zRndEnd,x               ; X = $FC..$FF wraps to the 4 bytes below zRndEnd
        adc     zRndEnd,x
        sta     zRndEnd,x
        inx
        bne     @loop
        rts

; C64: A, X, Y = seed bytes (the Oric used whatever the ROM left at $D0-$D3).
SeedRandom:
        sta     zRndEnd - 4
        stx     zRndEnd - 3
        sty     zRnd2
        eor     #$5A
        sta     zRnd3
        rts

; Oric DrawLine ($0A89): Bresenham from (zLX0, zLY0) to (zLX1, zLY1),
; plotting every point. With zLineStep set it returns after one step and
; LineStep continues from the saved state (the explosion uses this).
DrawLine:
        ldx     #$01
        sec
        lda     zLX1
        sbc     zLX0
        bcs     :+
        eor     #$FF
        adc     #$01
        ldx     #$FF
:       sta     zLDX
        sta     zLErrY
        stx     zLSX
        ldx     #$01
        sec
        lda     zLY1
        sbc     zLY0
        bcs     :+
        eor     #$FF
        adc     #$01
        ldx     #$FF
:       sta     zLDY
        sta     zLErrX
        stx     zLSY
LinePlot:
        ldx     zLX0                    ; Oric PlotLinePoint
        ldy     zLY0
        jsr     PlotXY
LineStep:
        lda     zLErrY
        cmp     zLErrX
        bcc     @stepY
        clc
        lda     zLErrX
        adc     zLDY
        sta     zLErrX
        clc
        lda     zLX0
        adc     zLSX
        sta     zLX0
        lda     zLErrX
        cmp     zLErrY
        bcc     @clearX
@stepY: clc
        lda     zLErrY
        adc     zLDX
        sta     zLErrY
        clc
        lda     zLY0
        adc     zLSY
        sta     zLY0
        lda     zLErrX
        cmp     zLErrY
        bcc     @clearX
        sbc     zLErrY
        sta     zLErrX
        lda     #$00
        sta     zLErrY
        beq     @next
@clearX:
        sec
        lda     zLErrY
        sbc     zLErrX
        sta     zLErrY
        lda     #$00
        sta     zLErrX
@next:  lda     zLineStep
        beq     @more
        rts
@more:  lda     zLX0
        cmp     zLX1
        bne     LinePlot
        lda     zLY0
        cmp     zLY1
        bne     LinePlot
        rts

; Oric DrawBorder ($0DEA): solid rows 0 and 199 from x 6 to 239, side walls
; at x 6 and 239 (column 0 of each Oric line held the paper attribute).
DrawBorder:
        ldx     #6
@hz:    ldy     #0
        jsr     PlotXY
        ldy     #ARENA_HEIGHT - 1
        jsr     PlotXY
        inx
        cpx     #ARENA_WIDTH
        bne     @hz
        ldy     #1
@vt:    ldx     #6
        jsr     PlotXY
        ldx     #ARENA_WIDTH - 1
        jsr     PlotXY
        iny
        cpy     #ARENA_HEIGHT - 1
        bne     @vt
        rts

; Oric SetPaperColour ($0E1C): a random paper for the round.
SetPaperColour:
        jsr     Random
        lda     zRnd3
        and     #$03
        tay
        lda     PaperColours,y
        sta     ArenaPaper              ; hud.s: the panels share it, as the Oric's status rows did
        ora     #ARENA_INK << 4
        jmp     SetArenaColour

; Oric DrawObstacles ($0B0B): a V-shaped wedge at the middle of each wall,
; pointing inward, with random depth and width.
DrawObstacles:
        lda     #$00
        sta     zLineStep
        jsr     Random
        lda     zRnd2
        and     #$0F
        adc     #$5A
        sta     zObA
        lda     #$F0
        sbc     zObA
        sta     zObC
        jsr     Random
        lda     zRnd2
        and     #$07
        adc     #$07
        sta     zObF
        ; top wedge
        lda     #$78
        sta     zLX1
        lda     zObF
        sta     zLY1
        lda     zObA
        sta     zLX0
        lda     #$00
        sta     zLY0
        jsr     DrawLine
        lda     #$00
        sta     zLY0
        lda     zObC
        sta     zLX0
        jsr     DrawLine
        ; bottom wedge
        lda     #$78
        sta     zLX1
        lda     #$C7
        sbc     zObF
        sta     zLY1
        lda     zObA
        sta     zLX0
        lda     #$C7
        sta     zLY0
        jsr     DrawLine
        lda     zObC
        sta     zLX0
        lda     #$C7
        sta     zLY0
        jsr     DrawLine
        jsr     Random
        lda     zRnd2
        and     #$0F
        adc     #$50
        sta     zObB
        lda     #$C7
        sbc     zObB
        sta     zObD
        jsr     Random
        lda     zRnd2
        and     #$07
        adc     #$13
        sta     zObE
        ; left wedge
        lda     #$64
        sta     zLY1
        lda     zObE
        sta     zLX1
        lda     zObB
        sta     zLY0
        lda     #$06
        sta     zLX0
        jsr     DrawLine
        lda     #$06
        sta     zLX0
        lda     zObD
        sta     zLY0
        jsr     DrawLine
        ; right wedge
        lda     #$64
        sta     zLY1
        lda     #$F6
        sbc     zObE
        sta     zLX1
        lda     zObB
        sta     zLY0
        lda     #$EF
        sta     zLX0
        jsr     DrawLine
        lda     #$EF
        sta     zLX0
        lda     zObD
        sta     zLY0
        jmp     DrawLine

; Oric RandomStarts ($0E48): P1 at x 25 heading right, P2 at x 215 heading
; left, each at a random height 3-194.
RandomStarts:
@p1:    jsr     Random
        lda     zRnd3
        cmp     #$C0
        bcs     @p1
        adc     #$03
        sta     zP1Y
@p2:    jsr     Random
        lda     zRnd2
        cmp     #$C0
        bcs     @p2
        adc     #$03
        sta     zP2Y
        lda     #$19
        sta     zP1X
        lda     #$D7
        sta     zP2X
        ldx     #IN_RIGHT
        stx     zP1Dir
        inx
        stx     zP2Dir                  ; IN_LEFT
        rts

        .segment "RODATA"

; Oric PaperColours ($0619): red, blue, magenta, black
PaperColours:   .byte   COL_RED, COL_BLUE, COL_PURPLE, COL_BLACK

        .segment "BSS"

ArenaPaper:     .res 1             ; the round's paper colour
