; Light Cycle (C64) — bonus blocks
;
; Oric BonusBlocks ($10DB) and DrawBonusFrame ($1159). Every 255 frames
; pick a random spot; if its 6x6 area is empty, animate a block there, one
; frame of BonusGfx per 25 frames in BonusFrameOfs order. The last frame
; stays as a new obstacle.
;
; The Oric works on whole HIRES bytes: a 6-pixel column (x = col * 6) and
; "empty" means the byte is $40. Here the same 6x6 area is tested and drawn
; pixel by pixel. The timers count Oric frames, which GameLoop runs at the
; Oric's measured rate, so blocks appear as often as on the Oric.

        .include "hw.inc"
        .include "zp.inc"

        .import Random, PixelSet, PlotXY, UnplotPixel
        .import BonusGfx, BonusFrameOfs
        .export BonusBlocks, ResetBonus

BONUS_INTERVAL  = $FF                   ; frames between attempts
BONUS_FRAME     = $19                   ; frames per animation step

        .segment "CODE"

BonusBlocks:
        lda     zBonusState
        bne     @animate
        inc     zBonusTmr
        lda     zBonusTmr
        cmp     #BONUS_INTERVAL
        beq     @try
        rts
@try:   lda     #$00
        sta     zBonusTmr
        inc     zBonusState
        jsr     Random
        lda     zRnd2
        and     #$1F
        clc
        adc     #$03
        sta     zBonusCol               ; byte column 3-34: x 18-204
@row:   jsr     Random
        lda     zRnd3
        cmp     #$A0
        bcs     @row
        adc     #$12
        sta     zBonusRow               ; y 18-177
        ; the 6x6 area must be empty
        jsr     BlockLeft
        lda     #6
        sta     zTmp2
        ldy     zBonusRow
@ty:    ldx     zTmp1
        lda     #6
        sta     zTmp3
@tx:    jsr     PixelSet
        bcs     ResetBonus
        inx
        dec     zTmp3
        bne     @tx
        iny
        dec     zTmp2
        bne     @ty
        rts
@animate:
        inc     zBonusTmr
        lda     zBonusTmr
        cmp     #BONUS_FRAME
        bne     @wait
        lda     #$00
        sta     zBonusTmr
        ldy     zBonusState
        dey
        ldx     BonusFrameOfs,y
        jsr     DrawBonusFrame
        inc     zBonusState
        lda     zBonusState
        cmp     #$06
        beq     ResetBonus
@wait:  rts

; Back to waiting (Oric: zeroes $44-$49).
ResetBonus:
        lda     #$00
        sta     zBonusState
        sta     zBonusTmr
        rts

; zTmp1 = the block's left x (col * 6).
BlockLeft:
        lda     zBonusCol
        asl     a
        adc     zBonusCol               ; col * 3 (C clear: col < 128)
        asl     a                       ; col * 6
        sta     zTmp1
        rts

; Draw the 6x6 frame at BonusGfx + X: bits 5-0 of each byte, left to right;
; a clear bit clears the pixel, as writing the Oric byte did.
DrawBonusFrame:
        stx     zTmp0
        jsr     BlockLeft
        lda     #0
        sta     zTmp2                   ; row 0-5
@row:   lda     zTmp0
        clc
        adc     zTmp2
        tax
        lda     BonusGfx,x
        sta     zTmp3
        lda     zBonusRow
        clc
        adc     zTmp2
        tay
        ldx     zTmp1
@bit:   asl     zTmp3                   ; bit 7, 6 out first: skip them
        asl     zTmp3
        lda     #6
        sta     zObD                    ; free during play (DrawObstacles only)
@px:    asl     zTmp3
        bcc     @clear
        jsr     PlotXY
        jmp     :+
@clear: jsr     UnplotPixel
:       inx
        dec     zObD
        bne     @px
        inc     zTmp2
        lda     zTmp2
        cmp     #6
        bne     @row
        rts
