; Light Cycle (C64) — zero-page variables (defined in zp.s)

; --- platform
        .importzp zTmp0, zTmp1, zTmp2, zTmp3   ; scratch: any routine may clobber
        .importzp zPtr                          ; 2-byte scratch pointer
        .importzp zPix                          ; HiresAddr result: bitmap byte address
        .importzp zMask                         ; HiresAddr result: bit mask
        .importzp zTick                         ; incremented by the raster IRQ
        .importzp zIsPAL                        ; 1 = PAL (50 Hz), 0 = NTSC (60 Hz)
        .importzp zInput                        ; ReadKeysP1/P2 result (IN_* bits)
        .importzp zLastKey                      ; GetKey edge detection
        .importzp zJoyIdle                      ; $DC01 with no column selected
        .importzp zVolume                       ; 0-15
        .importzp zTextPtr                      ; string pointer (BitmapChar clobbers zPtr)

; --- game (Oric names; see zp.s)
        .importzp zX, zY, zDir, zPlayer, zP1Dir, zP2Dir, zP1X, zP1Y, zP2X, zP2Y
        .importzp zOppX, zOppY, zAI, zCrashed
        .importzp zBonusTmr, zBonusState, zBonusCol, zBonusRow
        .importzp zLX0, zLX1, zLY0, zLY1, zLDX, zLDY, zLErrX, zLErrY, zLSX, zLSY, zLineStep
        .importzp zSlowP1, zSlowP2, zLastSlowP1, zLastSlowP2, zFlicker
        .importzp zObA, zObB, zObC, zObD, zObE, zObF
        .importzp zSpeed, zFrame, zRnd2, zRnd3, zRndEnd, zBudget, zFrameCost, zFrameBase
