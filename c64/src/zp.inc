; Light Cycle (C64) — zero-page variables (defined in zp.s)
; The platform layer owns these; game state (Phase 2) adds its own.

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
