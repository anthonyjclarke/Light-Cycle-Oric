; Light Cycle (C64) — zero-page variables (declared in zp.inc)

        .exportzp zTmp0, zTmp1, zTmp2, zTmp3, zPtr, zPix, zMask
        .exportzp zTick, zIsPAL, zInput, zLastKey, zJoyIdle, zVolume

        .segment "ZEROPAGE"

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
