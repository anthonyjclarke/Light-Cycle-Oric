# Light Cycle – Porting to the C64

The plan for the Commodore 64 version and where it stands. Both machines run a ~1 MHz 6502, so the game logic
(movement, the computer player, lines, the explosion, bonus blocks, scoring, the random generator) ports almost
instruction for instruction. The work is the platform underneath: display, keyboard, sound, timing and the menu screens.

---

## Approach

The port is a **faithful re-host**, not a rewrite. It keeps the structure and names of `oric/game.s`, so each C64
routine can be checked against its Oric original, and replaces only the platform routines behind a small interface
([platform_layer.md](platform_layer.md)). Improvements (sprites, disk hi-scores) come after a faithful version plays
correctly. The toolchain is cc65: the disassembly is already ca65 syntax, and VICE runs and captures the builds.

---

## Status

| Phase | Scope                                                     | State                         |
|:------|:----------------------------------------------------------|:------------------------------|
| 0     | Repository, build, boot stub                              | Done 16-11-2026               |
| 1     | Platform layer and test harness                           | Done 16-11-2026, see below    |
| 2     | Game logic: movement, crash, AI, explosion, bonus blocks  | Next                          |
| 3     | Status panels and scoring                                 | –                             |
| 4     | Menus, title, hi-scores                                   | –                             |
| 5     | Polish: sprites, joystick options, NTSC, disk hi-scores   | Optional                      |
| 6     | Release: `.prg`, `.d64`, tag                              | –                             |

Phase 1 is verified by VICE captures ([graphics.md](graphics.md)): start-up, PAL detection, text mode, the bitmap
arena, panel glyphs, colour cells, plotting and crash tests in game coordinates, and the frame tick. Keyboard and
joystick reading and the SID sounds build and run, but have not yet been tried by hand: VICE's headless mode cannot
press matrix keys. That is the first check of Phase 2.

---

## Platform Mapping

| Oric feature               | C64 replacement                               |
|:---------------------------|:----------------------------------------------|
| HIRES 240×200, 6 px/byte   | Hires bitmap 320×200, 8 px/byte               |
| `HiresAddr` (÷6 loop)      | Row and column lookup tables                  |
| Paper attribute in col 0   | Bitmap colour cells, ink and paper per 8×8    |
| 3 text rows under HIRES    | Side panels drawn into the bitmap             |
| TEXT mode, serial attrs    | Text mode and colour RAM                      |
| 6×8 font, alt charset logo | 8×8 font, logo re-gridded                     |
| VIA + AY matrix scan       | CIA1 matrix scan, plus joysticks              |
| ROM IRQ keyboard (menus)   | `GetKey` / `WaitKey`, own matrix scan         |
| AY tones A and B           | SID voices 1 and 2                            |
| AY noise and envelope      | SID voice 3 noise                             |
| Volume 0–15                | SID master volume, also 0–15                  |
| Busy-wait `FrameDelay`     | Raster tick and a speed table                 |
| Character-set shuffle      | Not needed: VIC bank 1 keeps them apart       |
| Particles, hi-scores in charset RAM | Ordinary RAM                         |

---

## Decisions

**Arena geometry.** The arena keeps the Oric's 240×200 coordinates, so every x fits in a byte and every constant
carries over: start positions, the computer's look-ahead, the obstacle maths and the explosion bounds. It is drawn 40
pixels in on the 320-pixel bitmap, leaving a 40-pixel panel each side for what the Oric showed in its three text rows;
a 200-line bitmap leaves no rows below it without a raster split.

**Colour.** A hires bitmap gives two colours per 8×8 cell, so two trails in one cell would clash. The port keeps player
2's dotted trail, as the Oric did, and colours a cell when a trail first enters it. Multicolour would avoid clashes but
halve the horizontal resolution, making sideways movement twice as fast as vertical.

**Timing.** The Oric's speed came from a busy-wait plus a varying amount of drawing, so it was never constant. The C64
counts raster frames (50 Hz PAL, 60 Hz NTSC). In Phase 2 each player gets a fixed-point step accumulator; the speed
setting and boost choose the pixels per tick, and every pixel step still runs the full crash test. The table needs
measurements of the Oric original in an emulator (Oricutron) at speeds 1, 5 and 9, normal and boosted.

**Controls.** The Oric key layout, mapped by position ([player_guide.md](player_guide.md)), plus joystick port 2 for
player 1 and port 1 for player 2. Joystick 1 shares lines with the keyboard rows; `ScanPlayerKeys` masks the rows it
holds down so it is not read as keys.

**Title content.** The Oric title screen carries the publisher's address under the PSS logo. Whether the C64 title
keeps it, replaces it with a credit line or drops it is the owner's call; open.

---

## Phases 2–6

**Phase 2, game logic.** Port in dependency order, checking each against `game.s`: `Random`, `DrawLine`, `DrawBorder`
and `DrawObstacles`, `RandomStarts`, `EraseHead`, `MovePlayer` and `PlotCheckCrash`, `ComputerAI`, `AIAvoid` and
`AIBoost`, `Explosion`, `BonusBlocks`. `BonusBlocks` writes whole 6-pixel Oric bytes, so it becomes a 6×6 pixel blit
through `PlotXY` and `UnplotPixel`, with a 36-pixel `PixelSet` emptiness test. The crash exit becomes a flag returned
to `GameLoop` ([quirks.md](quirks.md)). Exit test: a full round against the computer, with crashes and explosions.

**Phase 3, panels and scoring.** Keep scores and `TIME` as 8-character ASCII buffers, reusing `AddDigit` unchanged, and
draw them into the panels with `BitmapChar`. The winner's flash becomes a colour flash. Exit test: a full 5-life match.

**Phase 4, menus.** A converter in `tools/` turns the Oric screens and strings (serial attributes, 6-pixel glyphs) into
screen codes, colour RAM and 8×8 glyphs; the 28-row title must fit 25 rows. Then `VolumeScreen`, `AskPlayers`,
`AskSpeed`, `HiscoreEntry`, `PrintHiscores`, `PlayAgain`, `FlashTitle`. Exit test: title to game to hi-score and back.

**Phase 5, polish (optional).** Hardware sprites for the cycle heads, SID pulse-width movement on the engines, NTSC
speed table, hi-scores saved to disk, exomizer packing.

**Phase 6, release.** `.prg` and `.d64`, a README with the controls, tag `v1.0`.

---

## Risks

| Risk                                | Mitigation                              |
|:------------------------------------|:----------------------------------------|
| Speed and feel differ from Oric     | Measure the Oric; tune the speed table  |
| Colour clash where trails cross     | Dotted P2 trail; first colour wins      |
| 6-pixel glyphs look wrong at 8      | Redraw the logo and glyphs by hand      |
| Title text needs 28 rows            | Reflow the instructions                 |
| AY timbre differs on the SID        | Tune by ear; semantic sound routines    |
