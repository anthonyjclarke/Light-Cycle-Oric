; Light Cycle (C64) — zero-page variables (declared in zp.inc)
;
; Platform variables first, then the game state. Game names are the Oric's
; (the zero-page map at the top of oric/game.s), so ported code reads the same.

        .exportzp zTmp0, zTmp1, zTmp2, zTmp3, zPtr, zPix, zMask
        .exportzp zTick, zIsPAL, zInput, zLastKey, zJoyIdle, zVolume, zTextPtr
        .exportzp zX, zY, zDir, zPlayer, zP1Dir, zP2Dir, zP1X, zP1Y, zP2X, zP2Y
        .exportzp zOppX, zOppY, zAI, zCrashed
        .exportzp zBonusTmr, zBonusState, zBonusCol, zBonusRow
        .exportzp zLX0, zLX1, zLY0, zLY1, zLDX, zLDY, zLErrX, zLErrY, zLSX, zLSY, zLineStep
        .exportzp zSlowP1, zSlowP2, zLastSlowP1, zLastSlowP2, zFlicker
        .exportzp zObA, zObB, zObC, zObD, zObE, zObF
        .exportzp zSpeed, zFrame, zRnd2, zRnd3, zRndEnd, zBudget, zFrameCost, zFrameBase

        .segment "ZEROPAGE"

; --- platform
zTmp0:          .res 1
zTmp1:          .res 1
zTmp2:          .res 1
zTmp3:          .res 1
zPtr:           .res 2
zPix:           .res 2
zMask:          .res 1
zTick:          .res 1
zIsPAL:         .res 1
zInput:         .res 1
zLastKey:       .res 1
zJoyIdle:       .res 1
zVolume:        .res 1
zTextPtr:       .res 2          ; string pointer for callers of BitmapChar (which uses zPtr)

; --- game (Oric names)
zX:             .res 1          ; current cycle while MovePlayer runs
zY:             .res 1
zDir:           .res 1
zPlayer:        .res 1          ; 0 = P1, 1 = P2
zP1Dir:         .res 1
zP2Dir:         .res 1
zP1X:           .res 1
zP1Y:           .res 1
zP2X:           .res 1
zP2Y:           .res 1
zOppX:          .res 1          ; C64: the computer's target (the Oric always chased P1)
zOppY:          .res 1
zAI:            .res 1          ; C64: bit 0 = P1 computer, bit 1 = P2 computer
zCrashed:       .res 1          ; C64: set by PlotCheckCrash instead of jumping out
zBonusTmr:      .res 1
zBonusState:    .res 1
zBonusCol:      .res 1          ; Oric byte column (x = col * 6)
zBonusRow:      .res 1
zLX0:           .res 1          ; Bresenham line state
zLX1:           .res 1
zLY0:           .res 1
zLY1:           .res 1
zLDX:           .res 1
zLDY:           .res 1
zLErrX:         .res 1
zLErrY:         .res 1
zLSX:           .res 1
zLSY:           .res 1
zLineStep:      .res 1
zSlowP1:        .res 1          ; 0 = boosting, 1 = normal
zSlowP2:        .res 1
zLastSlowP1:    .res 1
zLastSlowP2:    .res 1
zFlicker:       .res 1
zObA:           .res 1          ; obstacle / explosion scratch
zObB:           .res 1
zObC:           .res 1
zObD:           .res 1
zObE:           .res 1
zObF:           .res 1
zSpeed:         .res 1          ; 1 (fast) .. 9 (slow)
zFrame:         .res 1
zRnd:           .res 2          ; random generator: 4 bytes, read as zRnd2 / zRnd3
zRnd2:          .res 1
zRnd3:          .res 1
zRndEnd:                        ; Random indexes zRndEnd,x with X = $FC..$FF
zBudget:        .res 2          ; C64: Oric time still to run this tick (µs, signed)
zFrameCost:     .res 2          ; C64: Oric µs for the next frame
zFrameBase:     .res 2          ; C64: frame cost before boost (speed + computer players)
