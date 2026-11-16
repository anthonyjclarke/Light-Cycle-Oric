# Light Cycle – Commodore 64 Port Plan

Plan for a C64 version built from the Oric disassembly in [`DISASSEMBLY.md`](DISASSEMBLY.md). Both machines use a ~1 MHz 6502, so the game logic (movement, AI, lines, explosion, bonus blocks, scoring, RNG) ports almost instruction-for-instruction. The work is replacing the platform layer: display, keyboard, sound, timing and the menu screens.

---

## Approach

The port should be a **faithful re-host**, not a rewrite. The structure of `game.s` is kept, with routine names unchanged, so every C64 routine can be checked against its Oric original. Only the platform routines behind a thin interface are replaced. Improvements such as sprites, joysticks and disk hi-scores come after the faithful version plays correctly.

The toolchain is **ca65/ld65 (cc65)**. The disassembly is already ca65 syntax, cc65 and VICE (`x64sc`) are already installed, and `c1541` (part of VICE) builds `.d64` images. Kick Assembler, used in the MOSaic reconstruction repos, is the alternative. Switching later costs only a syntax pass.

---

## Platform Mapping

| Oric feature               | C64 replacement                               |
|:---------------------------|:----------------------------------------------|
| HIRES 240×200, 6 px/byte   | Hires bitmap 320×200, 8 px/byte               |
| `HiresAddr` (÷6 loop)      | Row/column lookup tables (much faster)        |
| Paper attribute in col 0   | Screen-RAM colour nibbles per 8×8 cell        |
| 3 text rows under HIRES    | Status panels drawn into the bitmap           |
| TEXT mode + serial attrs   | Text mode + colour RAM                        |
| 6×8 font, alt charset logo | 8×8 custom charset, logo re-gridded           |
| Double-height text         | Custom tall glyph pairs or plain colour       |
| VIA + AY matrix scan       | CIA1 `$DC00/$DC01` matrix scan                |
| ROM IRQ keyboard (menus)   | KERNAL `GETIN` or own scan                    |
| AY tones A/B               | SID voices 1/2 (pulse or triangle)            |
| AY noise + envelope        | SID voice 3 noise, fast attack, long decay    |
| Volume 0–15 (AY R8/R9)     | SID master volume `$D418` (also 0–15)         |
| Busy-wait `FrameDelay`     | Raster-synced 50 Hz tick + speed table        |
| Charset shuffle `$9800`    | Not needed: VIC bank layout avoids overlap    |
| Particles in charset RAM   | Ordinary RAM tables                           |
| Hi-score in charset RAM    | Ordinary RAM (optional disk save later)       |

---

## Key Decisions

### Arena geometry

The arena stays **240×200 in game coordinates**. All x positions then still fit in one byte, and every constant (start x=25/215, AI look-ahead, obstacle maths, explosion bounds) carries over unchanged. On the 320-pixel bitmap the arena sits at a 40-pixel (5-cell) offset. That leaves a 40-pixel panel on each side for name, lives and score, replacing the Oric's three text rows (the C64 has no spare lines below a 200-line bitmap without a raster split). The Oric arena actually starts at x=6 because column 0 holds the paper attribute. Keep that coordinate system and offset by 40 when plotting.

### Colour

A hires bitmap gives two colours per 8×8 cell, so two trails in one cell will clash. The faithful option is to keep P2's dotted trail (as the Oric does), colour each cell when a trail first enters it, and accept occasional clash. Multicolour bitmap avoids clash (three colours per cell) but halves horizontal resolution, which makes horizontal movement twice as fast as vertical. **Recommendation: hires, with the dotted P2 trail kept.**

### Timing

The Oric's speed comes from a busy-wait plus variable drawing work, so it was never constant. The C64 version runs a fixed 50 Hz raster tick, and each player carries an 8.8 fixed-point step accumulator: speed setting + boost select pixels-per-tick from a table. Every pixel step still runs the full crash test, so more than one step per tick is safe. Calibrate the table by timing the Oric original in Oricutron (to be installed) at speeds 1, 5 and 9, normal and boost. NTSC needs a second table (60 Hz).

### Controls

Default to the original key layout via a CIA matrix scan (P1 `2 A W E R`, P2 `] RSHIFT ; ' L`, mapped to C64 key positions). Add joystick port 2 for P1 and port 1 for P2 as a later option. Port 1 shares lines with the keyboard matrix, so scan it with the keyboard columns released.

### Title screen content

The Oric title screen includes a street address. Decide whether the C64 version should carry it, an updated credit line, or the name only.

---

## C64 Memory Map (proposed)

VIC bank 1 (`$4000–$7FFF`) keeps video memory clear of code and the KERNAL.

| Range         | Use                                    |
|:--------------|:---------------------------------------|
| `$0801–$080C` | BASIC `SYS` stub                       |
| `$080D–$3FFF` | Code, tables, text, particle state     |
| `$4400–$47E7` | Text screen (menus)                    |
| `$4800–$4FFF` | Custom charset (menus, logo)           |
| `$5C00–$5FE7` | Bitmap colour matrix                   |
| `$6000–$7F3F` | Hires bitmap                           |
| `$C000–$C0FF` | Hi-score table                         |

Code size is about 4.3 KB on the Oric. Plotting tables (200-entry row address lo/hi, 240-entry column offset and mask) add roughly 1 KB.

---

## Phases

### 0. Project setup

`git init` with `main`/`dev`, plus a directory layout (`c64/src`, `c64/build`, `tools`, `oric`, `docs`), `Makefile` targets (`prg`, `d64`, `run` → `x64sc -autostart`), an ld65 config, the BASIC stub, `.gitignore` and `CHANGELOG.md`. Exit test: a `.prg` that boots and sets the border colour.

### 1. Platform layer

| Module     | Routines                                   |
|:-----------|:-------------------------------------------|
| `video.s`  | `BitmapOn` `TextOn` `ClearBitmap`          |
| `plot.s`   | `HiresAddr` `PlotPixel` `UnplotPixel`      |
| `input.s`  | `ReadKeysP1` `ReadKeysP2` `WaitKey`        |
| `sound.s`  | `EngineTone` `ExplosionSfx` `StartSweep`   |
| `timing.s` | Raster IRQ, `WaitTick`, speed tables       |

`HiresAddr` keeps its contract (X, Y in → pointer + mask out, registers preserved), so callers port unchanged. Sound becomes semantic calls rather than raw `AyWrite` register writes, because AY and SID registers don't correspond. Exit test: a pixel-plot demo plus a key and joystick test screen.

### 2. Core game logic

Port in dependency order, comparing against `game.s` routine by routine: `Random` → `DrawLine` → `DrawBorder`/`DrawObstacles` → `RandomStarts` → `EraseHead`/`MovePlayer`/`PlotCheckCrash` → `ComputerAI`/`AIAvoid`/`AIBoost` → `Explosion` → `BonusBlocks`. `BonusBlocks` writes whole 6-pixel Oric bytes, so it becomes a 6×6 pixel blit through `PlotPixel`/`UnplotPixel`, and its "area empty" check becomes 36 `PixelSet` tests or a cell-aligned check. Replace the `JMP`-out-of-`JSR` crash exit with a flag returned to `GameLoop`, which fixes the stack leak. Exit test: a full round against the computer with crashes and explosions.

### 3. HUD and scoring

Keep scores and TIME as 8-character ASCII digit buffers in RAM (reusing `AddDigit` unchanged) and render them into the side panels with a small 8×8 digit font. Lives, names, the bike icon and the winner flash (inverse on the Oric) become a colour flash. Add explicit `SEC` in `DecideWinner`. Exit test: a full 5-life match with the correct winner.

### 4. Menus and screens

Build a converter in `tools/` that turns the Oric screens and strings (serial attribute bytes, 6-pixel glyphs) into C64 screen codes, colour RAM and 8×8 glyphs. The 28-row title screen has to fit 25 rows. Then port `VolumeScreen`, `AskPlayers`, `AskSpeed`, `HiscoreEntry`, `PrintHiscores`, `PlayAgain` and `FlashTitle` (colour-RAM cycling). Exit test: the whole loop from title to game to hi-score to play again.

### 5. Polish (optional, after a faithful build)

Ideas: hardware sprites for the cycle heads (removes the erase/redraw, while collisions still use the bitmap), joystick support, a SID engine sound with pulse-width sweep, NTSC timing, hi-scores saved to disk, and exomizer packing.

### 6. Release

`.prg` + `.d64` via `c1541`, a README with controls, and tag `v1.0`.

---

## Verification

Each phase ends with a VICE run: `x64sc -autostart build/lightcycle.prg`. For behaviour comparison, run the original `CYCLE.TAP` in Oricutron next to it. Keep `tools/build_disasm.py` in the build so the Oric reference source stays verified.

---

## Risks

| Risk                                | Mitigation                              |
|:------------------------------------|:----------------------------------------|
| Speed/feel differs from original    | Measure Oric timings, tune table        |
| Colour clash where trails cross     | Dotted P2 trail; per-cell first-colour  |
| 6-px Oric glyphs look wrong at 8 px | Redraw logo/glyphs by hand where needed |
| Title text won't fit 25 rows        | Reflow instructions; drop blank rows    |
| AY timbre not reproducible on SID   | Tune by ear; semantic sound API         |
