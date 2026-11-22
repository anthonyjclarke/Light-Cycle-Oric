# Light Cycle – Platform Layer

The C64 routines the game logic calls instead of touching hardware (`c64/src/`). Where a routine does an Oric routine's
job it keeps that name and register contract, so ported code calls it unchanged. Everything here is read from the
source; the plotting, video and timing routines are also exercised by the game in VICE.

---

## Start-Up and Timing

`InitPlatform` (`platform.s`) takes the machine over once at start: interrupts off, BASIC and the KERNAL banked out
(`$01 = $35`), CIA interrupts disabled, then `InitVideo`, `InitTiming`, `InitInput` and `InitSound`, and interrupts on.
Nothing calls the ROMs afterwards. `ClearBss` (`main.s`) zeroes the variables.

| Routine      | Module     | Contract                                                        |
|:-------------|:-----------|:----------------------------------------------------------------|
| `InitTiming` | `timing.s` | Sets `zIsPAL`, IRQ/NMI vectors, raster IRQ on line 251          |
| `WaitTick`   | `timing.s` | Waits for the next frame; keeps X, Y                            |
| `WaitTicks`  | `timing.s` | Waits X frames (0 = 256); keeps Y                               |

The interrupt handler only acknowledges the VIC and increments `zTick`. RESTORE's NMI is ignored. PAL is told from NTSC
by the highest raster line (312 lines against 263).

---

## Video

| Routine          | Replaces (Oric)           | Contract                                              |
|:-----------------|:--------------------------|:------------------------------------------------------|
| `InitVideo`      | –                         | VIC bank 1, ROM font copied to `$4800`, black border  |
| `BitmapOn`       | `$1E` to `$BFDF`          | Hires bitmap mode                                     |
| `TextOn`         | `$1A` to `$BFDF`          | Text mode, black background                           |
| `ClearBitmap`    | `ClearHires`              | Zeroes `$6000–$7FFF`                                  |
| `ClearText`      | `ClearTextScreen`         | A = screen code, X = colour                           |
| `SetArenaColour` | `SetPaperColour`          | A = ink×16 + paper for arena cells                    |
| `SetPanelColour` | –                         | A = ink×16 + paper for both panels                    |
| `SetCellColour`  | –                         | A = colour, X = column, Y = row; keeps X, Y           |
| `BitmapChar`     | HIRES-mode text rows      | A = screen code into cell X, Y; keeps X, Y            |
| `BitmapCharTall` | Double-height attribute   | As `BitmapChar`, double height into Y and Y + 1       |
| `PrintText`      | Menu text copies          | `zPtr` = string, X, Y = position, A = colour          |

`CharsetToHires` and `CharsetToText` have no equivalent: on the C64 the text screen (`$4400`), font (`$4800`), bitmap
colours (`$5C00`) and bitmap (`$6000`) never overlap.

---

## Plotting

Coordinates are the Oric's (x 0–239, y 0–199); the arena is drawn `ARENA_X_OFFSET` (40) pixels in. Every lookup is a
table generated at assembly time, against the Oric's divide-by-6 loop.

| Routine       | Contract                                                  |
|:--------------|:----------------------------------------------------------|
| `HiresAddr`   | X = x, Y = y → `zPix`, `zMask`; keeps A, X, Y             |
| `PlotPixel`   | Sets the pixel at `zPix`/`zMask`; keeps X, Y              |
| `PlotXY`      | Sets pixel X, Y; keeps X, Y                               |
| `UnplotPixel` | Clears pixel X, Y; keeps X, Y                             |
| `PixelSet`    | C = 1 if pixel X, Y is lit; keeps X, Y                    |

`PixelSet` is the Oric's `PixelSet`, and with `PlotXY` it covers `PlotCheckCrash`'s test-then-plot.

---

## Input

| Routine      | Replaces (Oric) | Contract                                                     |
|:-------------|:----------------|:-------------------------------------------------------------|
| `ReadKeysP1` | `ReadKeysP1`    | Keys `2 A W E R` + joystick 2 → `zInput` and A; X clobbered  |
| `ReadKeysP2` | `ReadKeysP2`    | Keys `@ RSHIFT : ; L` + joystick 1 → `zInput` and A          |
| `GetKey`     | –               | New key code or 0; codes as the Oric's (`KEY_*` in `hw.inc`) |
| `WaitKey`    | `WaitKey`       | Blocks for a new key; code in A                              |
| `ReadFire`   | –               | C = 1 while fire is held on either joystick                  |

`zInput` keeps the Oric bits: `IN_UP` `$08`, `IN_DOWN` `$04`, `IN_LEFT` `$02`, `IN_RIGHT` `$01`, `IN_BOOST` `$10`. The
key tables (`KeyTableP1`, `KeyTableP2`) have the Oric layout: column, row mask and input bit per key. `GetKey` scans all
64 keys, returns a code only on a new press, and maps SHIFT with the cursor keys to `KEY_UP` and `KEY_LEFT`, as the
Oric's separate cursor keys gave. Pressing keys while moving joystick 2 can show ghost keys; joystick 1 is masked.

---

## Sound

[sound.md](sound.md) shows how each Oric effect maps to the SID.

| Routine        | Replaces (Oric)        | Contract                                          |
|:---------------|:-----------------------|:--------------------------------------------------|
| `InitSound`    | –                      | Silences the SID; voices set up; volume 0         |
| `SetVolume`    | R8/R9 writes           | A = 0–15 → `zVolume` and the SID master volume    |
| `EnginesOn`    | `SoundInit`            | Both engines gated on at normal pitch             |
| `EnginesOff`   | –                      | Both engines gated off                            |
| `EngineTone`   | `EngineSound`          | X = player, A = 0 boosting / 1 normal; keeps Y    |
| `StartSweep`   | `StartSweep`           | Blocking ~2.6 s rise; leaves engines on           |
| `ExplosionSfx` | `Explosion`'s AY table | Engines off, noise burst with long decay          |

---

## Zero Page

Declared in `zp.s`, imported through `zp.inc`; with the KERNAL banked out all of `$02–$FF` is free.

| Name                | Use                                          |
|:--------------------|:---------------------------------------------|
| `zTmp0`–`zTmp3`     | Scratch; any routine may change them         |
| `zPtr`              | Two-byte scratch pointer                     |
| `zPix`, `zMask`     | `HiresAddr` result                           |
| `zTick`             | Frame counter                                |
| `zIsPAL`            | 1 = PAL, 0 = NTSC                            |
| `zInput`            | Player input bits                            |
| `zLastKey`          | `GetKey`'s edge detection                    |
| `zJoyIdle`          | Port B with no column selected (joystick 1)  |
| `zVolume`           | 0–15                                         |
