; Light Cycle (C64) — rounds and the game loop
;
; Oric RoundStart ($1755), GameLoop ($177A), EngineSound ($0974) and the
; crash path (Crash, $0ED9), re-hosted on a fixed 50/60 Hz tick.
;
; Timing. The Oric ran GameLoop flat out, padded by FrameDelay, so its frame
; rate depended on the speed setting and on how much each frame did.
; tools/oric_timing.py timed the Oric code itself on a cycle-counting 6502:
; a frame costs FRAME_BASE(speed) microseconds with two humans, plus
; AI_COST per computer player and BOOST_COST per boosting cycle. Each C64
; tick adds the tick's length to zBudget and runs Oric frames until the
; budget is spent, so movement, bonus blocks and every frame counter run
; at the Oric's rate, including its quirks: a one-player game is slower
; than a two-player one, and boost is ~1.5x, not 2x, because a boosting
; frame takes longer.
;
; Players. zAI picks who the computer drives: bit 0 = P1, bit 1 = P2. The
; Oric's one-player game is zAI = 2; demo mode is zAI = 3.

        .include "hw.inc"
        .include "zp.inc"

        .import ClearBitmap, BitmapOn, SetPanelColour
        .import DrawHud, TickTime, AwardOpponent
        .import DrawBorder, SetPaperColour, DrawObstacles, RandomStarts, ArenaPaper
        .import MovePlayer, BonusBlocks, Explosion
        .import WaitTick, WaitTicks
        .import EnginesOn, EngineTone, ExplosionSfx, StartSweep
        .export SetupFrameCost, RoundStart, RunTick, Crash

; Measured on the Oric (docs/porting.md): two-player frame at speed 1 and
; the cost of each further speed step, one computer player, one boost.
FRAME_SPEED1    = 7213
FRAME_PER_SPEED = 1287
AI_COST         = 3958
BOOST_COST      = 3550
; One C64 frame in microseconds: 19656 cycles at 985248 Hz (PAL),
; 17095 at 1022727 Hz (NTSC).
TICK_PAL        = 19950
TICK_NTSC       = 16716
MAX_FRAMES      = 6                     ; per tick: guards against a runaway budget


        .segment "CODE"

; zFrameBase = frame cost for zSpeed and the number of computer players.
SetupFrameCost:
        ldx     zSpeed
        lda     FrameCostLo - 1,x
        sta     zFrameBase
        lda     FrameCostHi - 1,x
        sta     zFrameBase + 1
        lda     zAI
        ldx     #2
@ai:    lsr     a
        bcc     :+
        pha
        lda     zFrameBase
        clc
        adc     #<AI_COST
        sta     zFrameBase
        lda     zFrameBase + 1
        adc     #>AI_COST
        sta     zFrameBase + 1
        pla
:       dex
        bne     @ai
        rts

; Oric RoundStart: a fresh arena and the engines' rising sweep.
RoundStart:
        jsr     RandomStarts
        jsr     ClearBitmap
        jsr     DrawBorder
        jsr     SetPaperColour
        lda     ArenaPaper              ; panels on the round's paper, as the
        ora     #COL_WHITE << 4         ; Oric's status rows were
        jsr     SetPanelColour
        jsr     DrawHud
        jsr     BitmapOn
        jsr     DrawObstacles
        lda     #$00
        sta     zCrashed
        sta     zBudget
        sta     zBudget + 1
        lda     zVolume
        beq     :+
        jsr     StartSweep              ; ~2.6 s; leaves the engines on
        jmp     :++
:       jsr     EnginesOn
:       lda     #$01                    ; engines are at normal pitch
        sta     zLastSlowP1
        sta     zLastSlowP2
        rts

; One C64 tick: wait for the frame, then run Oric frames for the tick's
; worth of Oric time. Returns with zCrashed set if a cycle crashed.
RunTick:
        jsr     WaitTick
        ldx     zIsPAL
        lda     zBudget
        clc
        adc     TickLo,x
        sta     zBudget
        lda     zBudget + 1
        adc     TickHi,x
        sta     zBudget + 1
        lda     #MAX_FRAMES
        sta     zTmp2
@frame: lda     zBudget + 1
        bmi     @done                   ; budget <= 0: this tick is spent
        ora     zBudget
        beq     @done
        jsr     OricFrame
        lda     zCrashed
        bne     @done
        ; budget -= base + BOOST_COST per boosting cycle
        lda     zFrameBase
        sta     zFrameCost
        lda     zFrameBase + 1
        sta     zFrameCost + 1
        ldx     #1
@boost: lda     zSlowP1,x
        bne     :+
        lda     zFrameCost
        clc
        adc     #<BOOST_COST
        sta     zFrameCost
        lda     zFrameCost + 1
        adc     #>BOOST_COST
        sta     zFrameCost + 1
:       dex
        bpl     @boost
        lda     zBudget
        sec
        sbc     zFrameCost
        sta     zBudget
        lda     zBudget + 1
        sbc     zFrameCost + 1
        sta     zBudget + 1
        dec     zTmp2
        bne     @frame
        lda     #$00                    ; too far behind: drop the backlog
        sta     zBudget
        sta     zBudget + 1
@done:  rts

; Oric GameLoop, one frame (without its FrameDelay).
OricFrame:
        lda     #$00
        sta     zPlayer
        lda     zP1X
        sta     zX
        lda     zP1Y
        sta     zY
        lda     zP1Dir
        sta     zDir
        lda     zP2X                    ; C64: P1's target is P2 (demo mode)
        sta     zOppX
        lda     zP2Y
        sta     zOppY
        jsr     MovePlayer
        lda     zCrashed
        bne     @crash
        lda     zY
        sta     zP1Y
        lda     zX
        sta     zP1X
        lda     zDir
        sta     zP1Dir
        lda     #$01
        sta     zPlayer
        lda     zP2X
        sta     zX
        lda     zP2Y
        sta     zY
        lda     zP2Dir
        sta     zDir
        lda     zP1X                    ; P2's target is P1, as on the Oric
        sta     zOppX
        lda     zP1Y
        sta     zOppY
        jsr     MovePlayer
        lda     zCrashed
        bne     @crash
        lda     zY
        sta     zP2Y
        lda     zX
        sta     zP2X
        lda     zDir
        sta     zP2Dir
        inc     zFrame
        jsr     BonusBlocks
        jsr     TickTime
        jmp     EngineSound
@crash: rts

; Oric EngineSound: retune an engine when its boost state changes.
EngineSound:
        lda     zSlowP1
        cmp     zLastSlowP1
        beq     :+
        sta     zLastSlowP1
        ldx     #0
        jsr     EngineTone
:       lda     zSlowP2
        cmp     zLastSlowP2
        beq     :+
        sta     zLastSlowP2
        ldx     #1
        jsr     EngineTone
:       rts

; Oric Crash: the explosion at the crashed cycle's position (zX, zY), the
; opponent scores TIME + 200, the crashed player loses a life, then the
; short pause (10 x FrameDelay on the Oric: 0.01-0.12 s by speed; zSpeed
; frames here). Returns Z = 1 if that was the crashed player's last life.
Crash:
        jsr     ExplosionSfx
        jsr     Explosion
        jsr     AwardOpponent
        php
        ldx     zSpeed
        jsr     WaitTicks
        plp
        rts

        .segment "RODATA"

FrameCostLo:
        .repeat 9, s
        .byte   <(FRAME_SPEED1 + s * FRAME_PER_SPEED)
        .endrepeat
FrameCostHi:
        .repeat 9, s
        .byte   >(FRAME_SPEED1 + s * FRAME_PER_SPEED)
        .endrepeat
TickLo:         .byte   <TICK_NTSC, <TICK_PAL       ; indexed by zIsPAL
TickHi:         .byte   >TICK_NTSC, >TICK_PAL
