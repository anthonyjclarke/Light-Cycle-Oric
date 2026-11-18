; Light Cycle (C64) — the status panels, in the Oric's style
;
; The Oric showed names, lives, TIME and scores in the three text rows
; under its HIRES screen (DrawStatusLine, $0BC4):
;
;   PLAYER 1  {|  [ TIME ]  {|  COMPUTER      row 0
;                 [big   ]                    row 1  TIME digits, double
;   00000000   5  [digits]   5  00000000      row 2  height, black on green
;
; The C64 arena fills the screen's 200 lines, so each player's half of
; that layout is stacked in the 5-cell panel on their side, at the foot
; of the panel as on the Oric:
;
;   row 16  TIME, black on white          row 20  name + cycle icon
;   row 17  TIME digits, double height,   row 21  lives, under the icon
;   row 18  black on green                row 22  score (last 5 digits)
;
; Colours follow the Oric's attributes: player 1 yellow, player 2 cyan,
; values white, and the panels take the round's paper colour, as the
; status rows did. Names are shortened to fit five cells: P1, P2, CPU.
; The cycle icon is the Oric's GlyphBike, defined into two spare font
; characters by DefineHudGlyphs.

        .include "hw.inc"
        .include "zp.inc"
        .include "screencodes.inc"

        .import BitmapChar, BitmapCharTall, SetCellColour, WaitTicks
        .import ScoreP1, ScoreP2, TimeDigits, LivesP1, LivesP2
        .import GlyphBike, ArenaPaper
        .export DefineHudGlyphs, DrawHud, ShowTime, ShowScore, ShowLives, FlashWinner

GLYPH_BIKE      = $1E                   ; screen codes replaced by the cycle icon (↑ ←)
RIGHT_PANEL     = 35                    ; right panel's first column; the left is 0
ROW_TIME_LABEL  = 16
ROW_TIME        = 17                    ; and 18: double height
ROW_NAME        = 20
ROW_LIVES       = 21
ROW_SCORE       = 22
TIME_LABEL_INK  = COL_BLACK << 4 | COL_WHITE        ; Oric $00, $17
TIME_DIGIT_INK  = COL_BLACK << 4 | COL_LIGHTGREEN   ; Oric $00, $12
FLASHES         = 25                    ; Oric DecideWinner: 25 toggles, ends reversed
FLASH_FRAMES    = 5                     ; Oric FlashDelay ~0.1 s
DIGITS_SHOWN    = 5                     ; last five of each 8-digit field

        .segment "CODE"

; Copy the Oric's two cycle-icon glyphs into the font: the left half
; right-aligned in its cell and the right half left-aligned, so the two
; 6-pixel halves meet as they did on the Oric.
DefineHudGlyphs:
        ldx     #7
@copy:  lda     GlyphBike,x
        sta     CHARSET + GLYPH_BIKE * 8,x
        lda     GlyphBike + 8,x
        asl     a                       ; bits 5-0 -> 7-2
        asl     a
        sta     CHARSET + (GLYPH_BIKE + 1) * 8,x
        dex
        bpl     @copy
        rts

; Both panels: colours, names, icons, TIME label and every value (after
; ClearBitmap and SetPanelColour).
DrawHud:
        ldx     #0
@side:  stx     HudSide
        lda     PanelLeft,x
        sta     HudCol
        ; colours
        lda     #TIME_LABEL_INK
        ldy     #ROW_TIME_LABEL
        jsr     PaintRow
        lda     #TIME_DIGIT_INK
        ldy     #ROW_TIME
        jsr     PaintRow
        ldy     #ROW_TIME + 1
        jsr     PaintRow
        ldx     HudSide
        lda     PanelInk,x
        ora     ArenaPaper
        ldy     #ROW_NAME
        jsr     PaintRow
        lda     #COL_WHITE << 4
        ora     ArenaPaper
        ldy     #ROW_LIVES
        jsr     PaintRow
        ldy     #ROW_SCORE
        jsr     PaintRow
        ; TIME label
        ldx     HudSide
        lda     TimeLabelX,x
        sta     HudX
        lda     #<TextTime
        ldx     #>TextTime
        ldy     #ROW_TIME_LABEL
        jsr     HudText
        ; name and cycle icon
        lda     #0
        sta     HudRev
        jsr     DrawName
        ldx     HudSide
        lda     BikeX,x
        tax
        lda     #GLYPH_BIKE
        ldy     #ROW_NAME
        jsr     DigitAt
        inx
        lda     #GLYPH_BIKE + 1
        jsr     DigitAt
        ldx     HudSide
        jsr     ShowScore
        ldx     HudSide
        jsr     ShowLives
        ldx     HudSide
        inx
        cpx     #2
        bne     @side
        jmp     ShowTime

; TIME's last five digits, double height, in both panels.
ShowTime:
        ldx     #0
@side:  lda     PanelLeft,x
        sta     HudCol
        txa
        pha
        ldx     #DIGITS_SHOWN - 1
@digit: lda     TimeDigits + 8 - DIGITS_SHOWN,x
        stx     HudSaveX
        pha
        txa
        clc
        adc     HudCol
        tax
        pla
        ldy     #ROW_TIME
        jsr     BitmapCharTall
        ldx     HudSaveX
        dex
        bpl     @digit
        pla
        tax
        inx
        cpx     #2
        bne     @side
        rts

; X = player: their score's last five digits.
ShowScore:
        lda     PanelLeft,x
        sta     HudCol
        cpx     #0
        bne     @p2
        ldx     #DIGITS_SHOWN - 1
@d1:    lda     ScoreP1 + 8 - DIGITS_SHOWN,x
        ldy     #ROW_SCORE
        jsr     DigitAt
        dex
        bpl     @d1
        rts
@p2:    ldx     #DIGITS_SHOWN - 1
@d2:    lda     ScoreP2 + 8 - DIGITS_SHOWN,x
        ldy     #ROW_SCORE
        jsr     DigitAt
        dex
        bpl     @d2
        rts

; X = player: their lives digit, under the cycle icon.
ShowLives:
        lda     PanelLeft,x
        sta     HudCol
        lda     LivesP1,x
        pha
        lda     LivesX,x
        tax
        pla
        ldy     #ROW_LIVES
        jmp     DigitAt

; A = winner (0/1): toggle their name between normal and reverse 25
; times, as the Oric did; it stays reversed.
FlashWinner:
        tax
        stx     HudSide
        lda     PanelLeft,x
        sta     HudCol
        lda     #0
        sta     HudRev
        lda     #FLASHES
        sta     FlashLeft
@flash: lda     HudRev
        eor     #$80
        sta     HudRev
        jsr     DrawName
        ldx     #FLASH_FRAMES
        jsr     WaitTicks
        dec     FlashLeft
        bne     @flash
        rts

; --- helpers -----------------------------------------------------------------

; Name of player HudSide (P1, P2 or CPU), each glyph ORed with HudRev.
DrawName:
        ldx     HudSide
        lda     zAI
        and     AiBit,x
        beq     :+
        inx                             ; computer: the CPU string
        inx
:       lda     NameLo,x
        sta     zTextPtr
        lda     NameHi,x
        sta     zTextPtr + 1
        lda     NameX,x
        sta     HudX
        ldy     #0
@next:  sty     HudRow
        lda     (zTextPtr),y
        cmp     #STR_END
        beq     @done
        ora     HudRev
        ldy     #ROW_NAME
        jsr     HudChar
        ldy     HudRow
        iny
        bne     @next
@done:  rts

; Glyph A at panel column HudCol + X, row Y. Keeps X, Y. (BitmapChar
; uses zTmp0-2, so the HUD keeps its own state in BSS.)
DigitAt:
        stx     HudSaveX
        pha
        txa
        clc
        adc     HudCol
        tax
        pla
        jsr     BitmapChar
        ldx     HudSaveX
        rts

; Glyph A at the next column (HudChar keeps a cursor in HudX); row Y.
HudChar:
        ldx     HudX
        jsr     DigitAt
        inc     HudX
        rts

; STR_END-terminated string at A/X into panel row Y, from column HudX.
HudText:
        sta     zTextPtr
        stx     zTextPtr + 1
        sty     HudRow
        ldy     #0
@next:  sty     HudSaveY
        lda     (zTextPtr),y
        cmp     #STR_END
        beq     @done
        ldy     HudRow
        jsr     HudChar
        ldy     HudSaveY
        iny
        bne     @next
@done:  ldy     HudRow
        rts

; Colour all five cells of panel row Y with A. Keeps A, Y.
PaintRow:
        sta     HudInk
        ldx     HudCol
        lda     #5
        sta     HudCount
@cell:  lda     HudInk
        jsr     SetCellColour
        inx
        dec     HudCount
        bne     @cell
        lda     HudInk
        rts

        .segment "RODATA"

PanelLeft:      .byte   0, RIGHT_PANEL
PanelInk:       .byte   COL_YELLOW << 4, COL_CYAN << 4     ; Oric $03, $06
AiBit:          .byte   %01, %10
NameX:          .byte   0, 3, 0, 2      ; P1, P2, CPU left, CPU right
BikeX:          .byte   3, 0            ; left: name then icon; right: icon then name
LivesX:         .byte   3, 1            ; Oric: under the icon's first / second cell
TimeLabelX:     .byte   1, 0            ; TIME against the arena side of the box
NameLo:         .byte   <TextP1, <TextP2, <TextCpu, <TextCpu
NameHi:         .byte   >TextP1, >TextP2, >TextCpu, >TextCpu
TextP1:         .byte   "P1", STR_END
TextP2:         .byte   "P2", STR_END
TextCpu:        .byte   "CPU", STR_END
TextTime:       .byte   "TIME", STR_END

        .segment "BSS"

HudCol:         .res 1
HudSide:        .res 1
HudRow:         .res 1
HudRev:         .res 1
HudSaveX:       .res 1
HudSaveY:       .res 1
HudX:           .res 1
HudInk:         .res 1
HudCount:       .res 1
FlashLeft:      .res 1
