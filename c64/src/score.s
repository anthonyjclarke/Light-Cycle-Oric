; Light Cycle (C64) — scores, lives, TIME and the winner
;
; Oric AddDigitUnits / AddDigit ($0954), TickTime ($1724), AwardP1 ($0F14),
; AwardP2 ($0F3F), ResetTime ($0FEE), ResetScores ($0E96) and DecideWinner
; ($0F6A). The Oric kept every number as ASCII digits in its status rows on
; screen and did decimal arithmetic on them there; the C64 keeps the same
; 8-character fields in RAM (ScoreP1, ScoreP2, TimeDigits) and redraws the
; panels from them (hud.s). Lives are single ASCII digits, as on the Oric.

        .include "hw.inc"
        .include "zp.inc"

        .import ShowTime, ShowScore, ShowLives
        .export ResetScores, TickTime, AwardOpponent, DecideWinner
        .export ScoreP1, ScoreP2, TimeDigits, LivesP1, LivesP2

DIGITS          = 8

        .segment "CODE"

; Oric ResetScores: scores "     000", lives "5", TIME "    0".
ResetScores:
        ldx     #DIGITS - 1
@clear: lda     #' '
        sta     ScoreP1,x
        sta     ScoreP2,x
        sta     TimeDigits,x
        dex
        bpl     @clear
        lda     #'0'
        ldx     #2
@zero:  sta     ScoreP1 + 5,x
        sta     ScoreP2 + 5,x
        dex
        bpl     @zero
        sta     TimeDigits + 7
        lda     #'5'
        sta     LivesP1
        sta     LivesP2
        rts

; Oric AddDigitUnits: add A to the units digit of the number at (zPtr).
AddDigitUnits:
        ldy     #DIGITS - 1
        ; fall through

; Oric AddDigit: add A to digit Y of the 8-character ASCII number at
; (zPtr), treating a space as 0 and rippling the carry left. (As on the
; Oric, a carry out of digit 0 would write before the field: unreachable.)
AddDigit:
        sta     zTmp0
        lda     (zPtr),y
        cmp     #' '
        bne     :+
        lda     #'0'
:       clc
        adc     zTmp0
        cmp     #'9' + 1
        bmi     @store
        sec
        sbc     #10
        sta     (zPtr),y
        lda     #1
        dey
        bpl     AddDigit
@store: sta     (zPtr),y
        rts

; Oric TickTime: TIME + 1 every 4 frames at speeds 4-9, every 8 at 1-3.
; Called once per Oric frame, after zFrame has moved on.
TickTime:
        lda     zSpeed
        cmp     #4
        bcc     @slow
        lda     zFrame
        and     #$03
        cmp     #$03
        beq     @add
        rts
@slow:  lda     zFrame
        and     #$07
        cmp     #$07
        beq     @add
        rts
@add:   lda     #<TimeDigits
        sta     zPtr
        lda     #>TimeDigits
        sta     zPtr + 1
        lda     #1
        jsr     AddDigitUnits
        jmp     ShowTime

; Oric AwardP1 / AwardP2 and the lives update in Crash: player zPlayer has
; crashed, so the other player scores TIME + 200, TIME restarts and the
; crashed player loses a life. Returns Z = 1 if that was the last life.
AwardOpponent:
        lda     zPlayer
        bne     @p2crashed
        lda     #<ScoreP2
        ldx     #>ScoreP2
        jsr     AddTimeTo
        ldx     #1
        jsr     ShowScore
        dec     LivesP1
        ldx     #0
        jsr     ShowLives
        lda     LivesP1
        cmp     #'0'
        rts
@p2crashed:
        lda     #<ScoreP1
        ldx     #>ScoreP1
        jsr     AddTimeTo
        ldx     #0
        jsr     ShowScore
        dec     LivesP2
        ldx     #1
        jsr     ShowLives
        lda     LivesP2
        cmp     #'0'
        rts

; Add each TIME digit (units first, until a space) and then 200 to the
; score at A/X, then reset TIME (the body of AwardP1 / AwardP2).
AddTimeTo:
        sta     zPtr
        stx     zPtr + 1
        ldx     #DIGITS - 1
@digit: lda     TimeDigits,x
        cmp     #' '
        beq     @bonus
        sec
        sbc     #'0'
        stx     zTmp1
        ldy     zTmp1
        jsr     AddDigit
        ldx     zTmp1
        dex
        bpl     @digit
@bonus: lda     #2                      ; + 200
        ldy     #5
        jsr     AddDigit
        ; fall through

; Oric ResetTime: TIME back to "    0".
ResetTime:
        ldx     #DIGITS - 2
        lda     #' '
@space: sta     TimeDigits,x
        dex
        bpl     @space
        lda     #'0'
        sta     TimeDigits + DIGITS - 1
        jmp     ShowTime

; Oric DecideWinner: compare the scores' last seven digits. Returns A = 0
; if P1 wins (also on a tie, as on the Oric), 1 if P2 wins. The Oric
; relied on a carry left set by an earlier CMP (quirk 2); SEC here.
DecideWinner:
        sec
        ldy     #DIGITS - 1
@cmp:   lda     ScoreP1,y
        sbc     ScoreP2,y
        dey
        bne     @cmp
        lda     #0
        bcs     :+
        lda     #1
:       rts

        .segment "BSS"

ScoreP1:        .res DIGITS
ScoreP2:        .res DIGITS
TimeDigits:     .res DIGITS
LivesP1:        .res 1
LivesP2:        .res 1
