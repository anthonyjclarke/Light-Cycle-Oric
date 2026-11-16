; Light Cycle (C64) — entry point
;
; Phase 1: a platform test harness. It exercises every platform routine
; the game logic will call: start-up, text and bitmap modes, the plot
; routines in game coordinates, colour cells, panel glyphs, keyboard and
; joystick input, frame ticks and the SID effects. Two test cycles run
; from the Oric start positions; steer them with the game's keys or
; joysticks. Phase 2 replaces this file with the ported game flow.

        .include "hw.inc"
        .include "zp.inc"
        .include "screencodes.inc"

        .import InitPlatform
        .import BitmapOn, TextOn, ClearBitmap, ClearText
        .import SetArenaColour, SetPanelColour, SetCellColour, BitmapChar, PrintText
        .import PlotXY, PixelSet
        .import WaitTick, WaitTicks
        .import ReadKeysP1, ReadKeysP2, GetKey
        .import SetVolume, EnginesOn, EnginesOff, EngineTone, ExplosionSfx, StartSweep

        .import __BSS_RUN__, __BSS_SIZE__
        .export Start

TEST_VOLUME     = 10
PANEL_INK_ON    = COL_WHITE << 4 | COL_BLACK
PANEL_INK_OFF   = COL_DARKGREY << 4 | COL_BLACK
ARENA_INK       = COL_WHITE

        .segment "CODE"

Start:
        jsr     InitPlatform
        jsr     ClearBss
        jsr     TitleScreen
        lda     #TEST_VOLUME
        jsr     SetVolume
        lda     #1
        sta     SweepWanted
@round: jsr     NewRound
@frame: jsr     WaitTick
        jsr     ReadKeysP1              ; clobbers X
        ldx     #0
        jsr     UpdatePlayer
        jsr     ReadKeysP2
        ldx     #1
        jsr     UpdatePlayer
        lda     Crashed
        beq     @frame
        jsr     ExplosionSfx
        lda     #COL_RED
        sta     VIC_BORDER
        ldx     #50
        jsr     WaitTicks
        lda     #COL_BLACK
        sta     VIC_BORDER
        jmp     @round

; Zero the BSS segment (the loader leaves whatever was in RAM).
ClearBss:
        lda     #<__BSS_RUN__
        sta     zPtr
        lda     #>__BSS_RUN__
        sta     zPtr + 1
        ldx     #<__BSS_SIZE__
        ldy     #0
        tya
@loop:  cpx     #0
        bne     @byte
        dec     BssPages
        bmi     @done
@byte:  sta     (zPtr),y
        iny
        bne     :+
        inc     zPtr + 1
:       dex
        jmp     @loop
@done:  rts

; ---------------------------------------------------------------------------
; Text mode check: banner, machine type, controls. Any key (or 3 s) goes on.
TitleScreen:
        lda     #$20
        ldx     #COL_GREY
        jsr     ClearText
        jsr     TextOn
        ldx     #0
@line:  lda     TitleLines,x
        bmi     @wait
        sta     zTmp2                   ; row
        lda     TitleLines + 1,x
        sta     zTmp3                   ; colour
        lda     TitleLines + 2,x
        sta     zPtr
        lda     TitleLines + 3,x
        sta     zPtr + 1
        txa
        pha
        ldx     #2                      ; column
        ldy     zTmp2
        lda     zTmp3
        jsr     PrintText
        pla
        clc
        adc     #4
        tax
        bne     @line
@wait:  lda     zIsPAL
        bne     :+
        lda     #<TextNTSC
        ldx     #>TextNTSC
        bne     :++
:       lda     #<TextPAL
        ldx     #>TextPAL
:       sta     zPtr
        stx     zPtr + 1
        ldx     #22
        ldy     #4
        lda     #COL_YELLOW
        jsr     PrintText
        lda     #150
        sta     TitleTimer              ; not zTmp0: GetKey uses the scratch bytes
@tick:  jsr     WaitTick
        jsr     GetKey
        bne     @done
        dec     TitleTimer
        bne     @tick
@done:  rts

; ---------------------------------------------------------------------------
; Clear the bitmap, draw the Oric's arena frame and the panels, start the
; cycles from the Oric's start positions (RandomStarts uses x 25 and 215).
NewRound:
        jsr     ClearBitmap
        ldx     PaperIndex
        inx
        cpx     #4
        bcc     :+
        ldx     #0
:       stx     PaperIndex
        lda     PaperColours,x
        ora     #ARENA_INK << 4
        jsr     SetArenaColour
        lda     #PANEL_INK_OFF
        jsr     SetPanelColour
        jsr     DrawFrame
        jsr     DrawPanels
        jsr     BitmapOn
        lda     #0
        sta     Crashed
        ldx     #1
@init:  lda     StartX,x
        sta     PosX,x
        lda     StartY,x
        sta     PosY,x
        lda     StartDir,x
        sta     Dir,x
        dex
        bpl     @init
        lda     SweepWanted
        beq     :+
        lda     #0
        sta     SweepWanted
        jmp     StartSweep              ; first round only: 2.6 s rising engines
:       jmp     EnginesOn

; The Oric arena: solid top and bottom rows from x 6 to 239, side walls at
; x 6 and x 239 (DrawBorder; column 0 held the paper attribute).
DrawFrame:
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

; Panel glyphs: "P1"/"P2" and one letter per input bit (U D L R B).
DrawPanels:
        ldx     #1
        ldy     #1
        lda     #'P'
        jsr     BitmapChar
        ldx     #2
        lda     #'1'
        jsr     BitmapChar
        ldx     #37
        lda     #'P'
        jsr     BitmapChar
        ldx     #38
        lda     #'2'
        jsr     BitmapChar
        ldy     #4
@bit:   lda     InputLetters - 4,y
        ldx     #2
        jsr     BitmapChar
        lda     InputLetters - 4,y
        ldx     #37
        jsr     BitmapChar
        iny
        cpy     #9
        bne     @bit
        lda     #PANEL_INK_ON
        ldx     #1
        ldy     #1
        jsr     SetCellColour
        ldx     #2
        jsr     SetCellColour
        ldx     #37
        jsr     SetCellColour
        ldx     #38
        jmp     SetCellColour

; ---------------------------------------------------------------------------
; X = player, zInput = this frame's input. Lights the panel letters, picks
; a new direction (lowest input bit wins; the game itself follows the
; Oric's MovePlayer rules),
; retunes the engine and moves 1 pixel (2 when boosting), crash-testing
; each pixel with PixelSet.
UpdatePlayer:
        stx     Player
        jsr     ShowInput
        ldx     Player
        lda     zInput
        and     #$0F
        beq     @keep
        ldy     #3
@pick:  lsr     a                       ; lowest set bit wins: right, left, down, up
        bcs     @found
        dey
        bpl     @pick
@found: lda     DirBit,y
        sta     Dir,x
@keep:  lda     zInput
        and     #IN_BOOST
        beq     :+
        lda     #0                      ; zSlowPn = 0 while boosting
        beq     :++
:       lda     #1
:       pha
        jsr     EngineTone
        pla
        eor     #1
        clc
        adc     #1                      ; steps: 1 normal, 2 boost
        sta     Steps
@step:  ldx     Player
        ldy     Dir,x
        lda     PosX,x
        clc
        adc     DeltaX,y
        sta     PosX,x
        lda     PosY,x
        clc
        adc     DeltaY,y
        sta     PosY,x
        tay
        lda     PosX,x
        tax
        jsr     PixelSet
        bcs     @crash
        jsr     PlotXY
        dec     Steps
        bne     @step
        rts
@crash: inc     Crashed
        rts

; Colour the five panel letters for player Player from zInput.
ShowInput:
        ldx     Player
        lda     PanelColumn,x
        tax
        lda     zInput
        sta     zTmp1
        ldy     #4                      ; rows 4..8 = R L D U B, bits $01..$10
@row:   lda     #PANEL_INK_OFF
        lsr     zTmp1
        bcc     :+
        lda     #PANEL_INK_ON
:       jsr     SetCellColour
        iny
        cpy     #9
        bne     @row
        rts

        .segment "RODATA"

StartX:         .byte   25, 215
StartY:         .byte   60, 140
StartDir:       .byte   IN_RIGHT, IN_LEFT
PanelColumn:    .byte   2, 37
; Oric PaperColours: red, blue, magenta, black
PaperColours:   .byte   COL_RED, COL_BLUE, COL_PURPLE, COL_BLACK
; Indexed by Y from UpdatePlayer's bit search (3 = bit 0 ... 0 = bit 3)
DirBit:         .byte   IN_UP, IN_DOWN, IN_LEFT, IN_RIGHT
; Indexed by direction bit value
DeltaX:         .byte   0, 1, <-1, 0, 0, 0, 0, 0, 0
DeltaY:         .byte   0, 0, 0, 0, 1, 0, 0, 0, <-1
InputLetters:   .byte   "RLDUB"         ; rows 4-8: bits $01 $02 $04 $08 $10

TitleLines:
        .byte   2, COL_CYAN
        .word   Text1
        .byte   4, COL_GREY
        .word   Text2
        .byte   7, COL_WHITE
        .word   Text3
        .byte   9, COL_GREY
        .word   Text4
        .byte   10, COL_GREY
        .word   Text5
        .byte   12, COL_GREY
        .word   Text6
        .byte   14, COL_GREY
        .word   Text7
        .byte   $FF
Text1:  .byte   "LIGHT CYCLE C64 - PLATFORM TEST", STR_END
Text2:  .byte   "MACHINE:", STR_END
Text3:  .byte   "         UP DOWN LEFT RIGHT BOOST", STR_END
Text4:  .byte   "PLAYER 1  2   A    W    E     R", STR_END
Text5:  .byte   "PLAYER 2  @  RSH   :    ;     L", STR_END
Text6:  .byte   "OR JOYSTICKS: PORT 2 = P1, PORT 1 = P2", STR_END
Text7:  .byte   "PRESS A KEY", STR_END
TextPAL:        .byte   "PAL 50HZ", STR_END
TextNTSC:       .byte   "NTSC 60HZ", STR_END

        .segment "DATA"

BssPages:       .byte   >__BSS_SIZE__   ; ClearBss page counter

        .segment "BSS"

Player:         .res 1
TitleTimer:     .res 1
Steps:          .res 1
Crashed:        .res 1
SweepWanted:    .res 1
PaperIndex:     .res 1
PosX:           .res 2
PosY:           .res 2
Dir:            .res 2
