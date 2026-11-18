; Light Cycle (C64) — the computer player
;
; Oric ComputerAI ($1178), TurnVertical ($123F), TurnHorizontal ($124B),
; AIAvoid ($1268) and AIBoost ($131B), ported line for line. The one change:
; the Oric always steered toward player 1 (zP1X, zP1Y). Here the target is
; zOppX / zOppY, which GameLoop sets to the other cycle's position, so
; either player can be the computer (demo mode runs both). With P2 as the
; computer the behaviour is the Oric's exactly.

        .include "hw.inc"
        .include "zp.inc"

        .import PixelSet
        .export ComputerAI, AIBoost

AI_BOOST_RANGE  = $1E                   ; boost while 30+ pixels away on either axis

        .segment "CODE"

; Look 3 pixels ahead, 3 wide. If blocked, turn toward the opponent on the
; other axis, then let AIAvoid reverse that turn if it is blocked too.
; Result in zInput (0 = carry on).
ComputerAI:
        lda     zDir
        ldx     #$00
        stx     zInput
        cmp     #IN_RIGHT
        bne     @left
        ldx     zX
        inx
        inx
        inx
        stx     zLX0                    ; Oric scratch use of the line variable
        ldy     zY
        jsr     PixelSet
        bcs     @vert
        ldx     zLX0
        ldy     zY
        dey
        jsr     PixelSet
        bcs     @vert
        ldx     zLX0
        ldy     zY
        iny
        jsr     PixelSet
        bcs     @vert
        rts
@left:  cmp     #IN_LEFT
        bne     @down
        ldx     zX
        dex
        dex
        dex
        stx     zLX0
        ldy     zY
        jsr     PixelSet
        bcs     @vert
        ldx     zLX0
        ldy     zY
        dey
        jsr     PixelSet
        bcs     @vert
        ldx     zLX0
        ldy     zY
        iny
        jsr     PixelSet
        bcs     @vert
        rts
@vert:  jsr     TurnVertical
        sta     zInput
        jmp     AIAvoid
@down:  cmp     #IN_DOWN
        bne     @up
        ldx     zX
        ldy     zY
        iny
        iny
        iny
        sty     zLX0
        jsr     PixelSet
        bcs     @horz
        ldx     zX
        dex
        ldy     zLX0
        jsr     PixelSet
        bcs     @horz
        ldx     zX
        inx
        ldy     zLX0
        jsr     PixelSet
        bcs     @horz
        rts
@up:    cmp     #IN_UP
        beq     :+
        rts
:       ldx     zX
        ldy     zY
        dey
        dey
        dey
        sty     zLX0
        jsr     PixelSet
        bcs     @horz
        ldx     zX
        dex
        ldy     zLX0
        jsr     PixelSet
        bcs     @horz
        ldx     zX
        inx
        ldy     zLX0
        jsr     PixelSet
        bcs     @horz
        rts
@horz:  jsr     TurnHorizontal
        sta     zInput
        jmp     AIAvoid

; Up if the opponent is above (or level), else down.
TurnVertical:
        lda     zY
        cmp     zOppY
        bcc     :+
        lda     #IN_UP
        rts
:       lda     #IN_DOWN
        rts

; Left if the opponent is to the left (or level), else right.
TurnHorizontal:
        lda     zX
        cmp     zOppX
        bcc     :+
        lda     #IN_LEFT
        rts
:       lda     #IN_RIGHT
        rts

; If the chosen turn is blocked 3 pixels out, take the opposite one.
AIAvoid:
        lda     zInput
        cmp     #IN_UP
        bne     @down
        ldx     zX
        ldy     zY
        dey
        dey
        dey
        sty     zLX0
        jsr     PixelSet
        bcs     :+
        ldx     zX
        dex
        ldy     zLX0
        jsr     PixelSet
        bcs     :+
        ldx     zX
        inx
        ldy     zLX0
        jsr     PixelSet
        bcs     :+
        rts
:       lda     #IN_DOWN
        sta     zInput
        rts
@down:  cmp     #IN_DOWN
        bne     @left
        ldx     zX
        ldy     zY
        iny
        iny
        iny
        sty     zLX0
        jsr     PixelSet
        bcs     :+
        ldx     zX
        dex
        ldy     zLX0
        jsr     PixelSet
        bcs     :+
        ldx     zX
        inx
        ldy     zLX0
        jsr     PixelSet
        bcs     :+
        rts
:       lda     #IN_UP
        sta     zInput
        rts
@left:  cmp     #IN_LEFT
        bne     @right
        ldx     zX
        dex
        dex
        dex
        stx     zLX0
        ldy     zY
        jsr     PixelSet
        bcs     :+
        ldx     zLX0
        ldy     zY
        dey
        jsr     PixelSet
        bcs     :+
        ldx     zLX0
        ldy     zY
        iny
        jsr     PixelSet
        bcs     :+
        rts
:       lda     #IN_RIGHT
        sta     zInput
        rts
@right: cmp     #IN_RIGHT
        beq     :+
        rts
:       ldx     zX
        inx
        inx
        inx
        stx     zLX0
        ldy     zY
        jsr     PixelSet
        bcs     :+
        ldx     zLX0
        ldy     zY
        dey
        jsr     PixelSet
        bcs     :+
        ldx     zLX0
        ldy     zY
        iny
        jsr     PixelSet
        bcs     :+
        rts
:       lda     #IN_LEFT
        sta     zInput
        rts

; Boost while 30+ pixels from the opponent on either axis.
AIBoost:
        lda     zX
        sec
        sbc     zOppX
        bcs     :+
        eor     #$FF
        adc     #$01
:       cmp     #AI_BOOST_RANGE
        bcs     @on
        lda     zY
        sec
        sbc     zOppY
        bcs     :+
        eor     #$FF
        adc     #$01
:       cmp     #AI_BOOST_RANGE
        bcs     @on
        lda     #IN_BOOST
        and     zInput
        cmp     #IN_BOOST
        beq     :+
        rts
:       lda     zInput
        sec
        sbc     #IN_BOOST
        sta     zInput
        rts
@on:    lda     #IN_BOOST
        ora     zInput
        sta     zInput
        rts
