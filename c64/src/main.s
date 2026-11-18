; Light Cycle (C64) — entry point and attract loop
;
; The attract cycle: the intro picture, then the instructions (a text
; placeholder until the Phase 4 menus), then demo mode, the computer
; against itself, and round again. A key or fire on any of them starts a
; game: one player against the computer, or two players, five lives each.
; The hi-score table and the play-again screen arrive in Phase 4; until
; then a finished game, or RUN/STOP, returns to the attract cycle.

        .include "hw.inc"
        .include "zp.inc"
        .include "screencodes.inc"

        .import __BSS_RUN__, __BSS_SIZE__
        .import InitPlatform
        .import TextOn, ClearText, PrintText
        .import WaitTick, GetKey, ReadFire
        .import SetVolume, EnginesOff
        .import SeedRandom, SetupFrameCost, RoundStart, RunTick, Crash
        .import IntroScreen
        .import DefineHudGlyphs, ResetScores, DecideWinner, FlashWinner, Delay
        .export Start

DEFAULT_VOLUME  = 10
DEFAULT_SPEED   = 5
INTRO_SECONDS   = 8                     ; idle time on the picture
TITLE_SECONDS   = 10                    ; idle time on the instructions before the demo
DEMO_ROUNDS     = 4

AI_NONE         = %00                   ; two players
AI_P2           = %10                   ; one player against the computer (the Oric's)
AI_BOTH         = %11                   ; demo

        .segment "CODE"

Start:
        jsr     InitPlatform
        jsr     ClearBss
        jsr     DefineHudGlyphs
        lda     #$12                    ; fixed seed; mixed with the tick count when a key starts a game
        ldx     #$34
        ldy     #$56
        jsr     SeedRandom
        lda     #DEFAULT_VOLUME
        jsr     SetVolume
        lda     #DEFAULT_SPEED
        sta     zSpeed

Attract:
        jsr     IntroScreen
        lda     #INTRO_SECONDS
        jsr     WaitChoice
        cmp     #AI_BOTH
        bne     @play
        jsr     TitleScreen
        lda     #TITLE_SECONDS
        jsr     WaitChoice
        cmp     #AI_BOTH
        bne     @play
        jsr     Demo
        jmp     Attract
@play:  sta     zAI
        jsr     PlayGame
        jmp     Attract

; ---------------------------------------------------------------------------
; A match: rounds until a player has no lives left (or RUN/STOP), then the
; Oric's winner flash. zAI chooses the players.
PlayGame:
        jsr     ResetScores
        jsr     SetupFrameCost
@round: jsr     RoundStart
@tick:  jsr     RunTick
        lda     zCrashed
        bne     @crash
        jsr     GetKey
        cmp     #KEY_STOP
        bne     @tick
        jmp     EnginesOff
@crash: jsr     Crash
        bne     @round
        jsr     EnginesOff
        jsr     DecideWinner
        jsr     FlashWinner
        jsr     Delay                   ; Oric GameOver: two Delays
        jmp     Delay

; Computer against computer, silent (with volume 0 the Oric also skipped
; the start sweep), for DEMO_ROUNDS crashes or until a key or fire.
Demo:
        lda     #AI_BOTH
        sta     zAI
        lda     zVolume
        pha
        lda     #0
        jsr     SetVolume
        lda     #DEMO_ROUNDS
        sta     DemoLeft
        jsr     ResetScores
        jsr     SetupFrameCost
@round: jsr     RoundStart
@tick:  jsr     RunTick
        lda     zCrashed
        bne     @crash
        jsr     GetKey
        bne     @quit
        jsr     ReadFire
        bcs     @quit
        jmp     @tick
@crash: jsr     Crash
        beq     @quit
        dec     DemoLeft
        bne     @round
@quit:  jsr     EnginesOff
        pla
        jmp     SetVolume

; ---------------------------------------------------------------------------
; Placeholder instructions screen.
TitleScreen:
        lda     #$20
        ldx     #COL_GREY
        jsr     ClearText
        jsr     TextOn
        ldx     #0
@line:  lda     TitleLines,x
        bmi     @lines
        sta     zTmp2                   ; row
        lda     TitleLines + 1,x
        sta     zTmp3                   ; colour
        lda     TitleLines + 2,x
        sta     zPtr
        lda     TitleLines + 3,x
        sta     zPtr + 1
        txa
        pha
        ldx     #3                      ; column
        ldy     zTmp2
        lda     zTmp3
        jsr     PrintText
        pla
        clc
        adc     #4
        tax
        bne     @line
@lines: rts

; Wait up to A seconds for a choice: returns A = zAI for the game chosen
; (1, SPACE or fire: one player; 2: two players), or AI_BOTH on timeout.
WaitChoice:
        sta     TitleSecs
@sec:   lda     #50
        sta     TitleTicks
@tick:  jsr     WaitTick
        jsr     ReadFire
        bcs     @one
        jsr     GetKey
        cmp     #'1'
        beq     @one
        cmp     #' '
        beq     @one
        cmp     #'2'
        beq     @two
        dec     TitleTicks
        bne     @tick
        dec     TitleSecs
        bne     @sec
        lda     #AI_BOTH
        rts
@one:   jsr     MixSeed
        lda     #AI_P2
        rts
@two:   jsr     MixSeed
        lda     #AI_NONE
        rts

; A human started the game: let the moment vary the arena.
MixSeed:
        lda     zTick
        eor     zRnd3
        sta     zRnd3
        rts

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

        .segment "RODATA"

TitleLines:
        .byte   3, COL_CYAN
        .word   Text1
        .byte   7, COL_WHITE
        .word   Text2
        .byte   9, COL_WHITE
        .word   Text3
        .byte   13, COL_GREY
        .word   Text4
        .byte   14, COL_GREY
        .word   Text5
        .byte   15, COL_GREY
        .word   Text6
        .byte   18, COL_GREY
        .word   Text7
        .byte   21, COL_DARKGREY
        .word   Text8
        .byte   $FF
Text1:  .byte   "L I G H T   C Y C L E", STR_END
Text2:  .byte   "1 OR SPACE  ONE PLAYER V COMPUTER", STR_END
Text3:  .byte   "2           TWO PLAYERS", STR_END
Text4:  .byte   "         UP DOWN LEFT RIGHT BOOST", STR_END
Text5:  .byte   "PLAYER 1  2   A    W    E     R", STR_END
Text6:  .byte   "PLAYER 2  @  RSH   :    ;     L", STR_END
Text7:  .byte   "JOYSTICKS: PORT 2 = P1, PORT 1 = P2", STR_END
Text8:  .byte   "RUN/STOP ENDS A GAME", STR_END

        .segment "DATA"

BssPages:       .byte   >__BSS_SIZE__   ; ClearBss page counter

        .segment "BSS"

TitleSecs:      .res 1
TitleTicks:     .res 1
DemoLeft:       .res 1
