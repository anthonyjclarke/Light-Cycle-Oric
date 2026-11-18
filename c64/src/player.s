; Light Cycle (C64) — moving a cycle
;
; Oric MovePlayer ($1356), EraseHead ($1476) and PlotCheckCrash ($0EC9),
; ported line for line. Two differences, both from the Oric's platform:
;
; - Input: zAI chooses keys or the computer per player (the Oric only let
;   the computer drive P2), so demo mode can run computer against computer.
; - Crash: the Oric's PlotCheckCrash jumped straight to the crash code out
;   of two subroutine levels (quirk 1). Here it sets zCrashed and returns
;   from MovePlayer directly, leaving the stack balanced.

        .include "hw.inc"
        .include "zp.inc"

        .import HiresAddr, PlotPixel, UnplotPixel, PixelSet
        .import ReadKeysP1, ReadKeysP2, ComputerAI, AIBoost
        .export MovePlayer

        .segment "CODE"

; Move the current cycle (zX, zY, zDir, zPlayer) one Oric frame's worth.
MovePlayer:
        lda     zPlayer
        bne     @p2
        lda     zAI
        lsr     a                       ; C = P1 is the computer
        bcs     @computer
        jsr     ReadKeysP1
        jmp     @input
@p2:    lda     zAI
        and     #$02
        bne     @computer
        jsr     ReadKeysP2
        jmp     @input
@computer:
        jsr     ComputerAI
        jsr     AIBoost
@input: lda     zInput
        pha
        and     #IN_BOOST
        ldx     zPlayer
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        eor     #$01
        sta     zSlowP1,x               ; 0 while boosting
        lda     zFrame
        and     zSlowP1,x               ; normal speed: move on even frames only
        beq     @move
        pla
        rts
@move:  pla
        and     #$0F
        beq     @keep
        jsr     EraseHead
        lda     zInput
        and     #$0F
        cmp     #IN_UP                  ; a new direction only if exactly one is held
        beq     @turn
        cmp     #IN_DOWN
        beq     @turn
        cmp     #IN_LEFT
        beq     @turn
        cmp     #IN_RIGHT
        beq     @turn
        jmp     @step
@turn:  sta     zDir
        jmp     @step
@keep:  jsr     EraseHead
@step:  lda     zPlayer
        beq     :+
        inc     zFlicker
:       lda     zDir
        cmp     #IN_UP
        bne     :+
        dec     zY
:       cmp     #IN_DOWN
        bne     :+
        inc     zY
:       cmp     #IN_LEFT
        bne     :+
        dec     zX
:       cmp     #IN_RIGHT
        bne     :+
        inc     zX

        ; Draw the 3-pixel head ahead of the new position, crash-testing each
        ; pixel, then test the pixel straight ahead.
:       lda     zDir
        cmp     #IN_UP
        bne     @down
        ldx     zX
        ldy     zY
        dey
        dey
        jsr     PlotCheckCrash          ; (x, y-2)
        jsr     PlotPixel
        dex
        iny
        jsr     PlotCheckCrash          ; (x-1, y-1)
        jsr     PlotPixel
        inx
        inx
        jsr     PlotCheckCrash          ; (x+1, y-1)
        jsr     PlotPixel
        dex
        jsr     PlotCheckCrash          ; (x, y-1)
        lda     zDir
@down:  cmp     #IN_DOWN
        bne     @left
        ldx     zX
        ldy     zY
        dex
        iny
        jsr     PlotCheckCrash          ; (x-1, y+1)
        jsr     PlotPixel
        inx
        iny
        jsr     PlotCheckCrash          ; (x, y+2)
        jsr     PlotPixel
        inx
        dey
        jsr     PlotCheckCrash          ; (x+1, y+1)
        jsr     PlotPixel
        dex
        jsr     PlotCheckCrash          ; (x, y+1)
        lda     zDir
@left:  cmp     #IN_LEFT
        bne     @right
        ldx     zX
        ldy     zY
        dey
        dex
        jsr     PlotCheckCrash          ; (x-1, y-1)
        jsr     PlotPixel
        dex
        iny
        jsr     PlotCheckCrash          ; (x-2, y)
        jsr     PlotPixel
        inx
        iny
        jsr     PlotCheckCrash          ; (x-1, y+1)
        jsr     PlotPixel
        dey
        jsr     PlotCheckCrash          ; (x-1, y)
        lda     zDir
@right: cmp     #IN_RIGHT
        bne     @trail
        ldx     zX
        ldy     zY
        inx
        dey
        jsr     PlotCheckCrash          ; (x+1, y-1)
        jsr     PlotPixel
        inx
        iny
        jsr     PlotCheckCrash          ; (x+2, y)
        jsr     PlotPixel
        dex
        iny
        jsr     PlotCheckCrash          ; (x+1, y+1)
        jsr     PlotPixel
        dey
        jsr     PlotCheckCrash          ; (x+1, y)

        ; The trail pixel; P2's is plotted on alternate steps only (dotted).
@trail: lda     zPlayer
        beq     :+
        lda     zFlicker
        and     #$01
        bne     @done
:       ldx     zX
        ldy     zY
        jsr     HiresAddr
        jsr     PlotPixel
@done:  rts

; Oric PlotCheckCrash ($0EC9): if pixel (X, Y) is lit the current cycle has
; crashed. Otherwise returns with zPix/zMask addressing it; keeps X, Y.
; On a crash: sets zCrashed and returns from MovePlayer (its only caller).
PlotCheckCrash:
        jsr     PixelSet
        bcs     @crash
        rts
@crash: inc     zCrashed
        pla                             ; drop the return into MovePlayer
        pla
        rts                             ; ...and return to MovePlayer's caller

; Oric EraseHead ($1476): clear the three head pixels for zDir at (zX, zY).
EraseHead:
        lda     zDir
        cmp     #IN_UP
        bne     @down
        ldx     zX
        ldy     zY
        dey
        dey
        jsr     UnplotPixel
        dex
        iny
        jsr     UnplotPixel
        inx
        inx
        jsr     UnplotPixel
        lda     zDir
@down:  cmp     #IN_DOWN
        bne     @left
        ldx     zX
        ldy     zY
        dex
        iny
        jsr     UnplotPixel
        inx
        iny
        jsr     UnplotPixel
        inx
        dey
        jsr     UnplotPixel
        lda     zDir
@left:  cmp     #IN_LEFT
        bne     @right
        ldx     zX
        ldy     zY
        dey
        dex
        jsr     UnplotPixel
        dex
        iny
        jsr     UnplotPixel
        inx
        iny
        jsr     UnplotPixel
        lda     zDir
@right: cmp     #IN_RIGHT
        bne     @done
        ldx     zX
        ldy     zY
        inx
        dey
        jsr     UnplotPixel
        inx
        iny
        jsr     UnplotPixel
        dex
        iny
        jsr     UnplotPixel
@done:  rts
