# Light Cycle – Porting to the C64

The plan for the Commodore 64 version and where it stands. Both machines run a ~1 MHz 6502, so the game logic (movement,
the computer player, lines, the explosion, bonus blocks, scoring, the random generator) ports almost instruction for
instruction. The work is the platform underneath: display, keyboard, sound, timing and the menu screens.

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
| 2     | Game logic, demo mode, intro picture                      | Done 16-11-2026, see below    |
| 3     | Status panels, scoring, lives, winner                     | Done 16-11-2026, see below    |
| 4     | Menus, title, hi-scores                                   | Next                          |
| 5     | Polish: sprites, joystick options, NTSC, disk hi-scores   | Optional                      |
| 6     | Release: `.prg`, `.d64`, tag                              | –                             |

Phases 1–3 are verified by VICE captures ([graphics.md](graphics.md)) and by stopping VICE inside a crash: the intro
picture, the instructions, demo mode drawing the Oric's arena, both computer players, the dotted trail, bonus blocks,
crashes, the explosion and new rounds. Not yet tried by hand: the keyboard and joysticks in a real game, and the SID
sounds. VICE's headless mode cannot press matrix keys, and its captures have no sound.

### Phase 2: The Game Logic

`arena.s`, `player.s`, `ai.s`, `explosion.s` and `bonus.s` are the Oric routines ported line for line under their Oric
names (`Random`, `DrawLine`, `DrawObstacles`, `RandomStarts`, `MovePlayer`, `EraseHead`, `PlotCheckCrash`, `ComputerAI`,
`AIBoost`, `Explosion`, `BonusBlocks` and the rest). Carry is kept where the Oric relies on it, so the same seed draws
the same arena. The Oric's data tables are exported from the tape by `tools/export_tables.py` into
`c64/src/oric_tables.inc`, not typed in by hand. The differences are:

| Oric                                              | C64                                                     |
|:--------------------------------------------------|:--------------------------------------------------------|
| `PlotCheckCrash` jumps out to the crash code      | Sets `zCrashed`, returns from `MovePlayer` (quirk 1)    |
| The computer always chases P1 (`zP1X`, `zP1Y`)    | It chases `zOppX`, `zOppY`: the other cycle             |
| Only P2 can be the computer                       | `zAI` bit 0 = P1, bit 1 = P2: demo mode is both         |
| `BonusBlocks` tests and writes whole HIRES bytes  | Tests and draws the same 6×6 area pixel by pixel        |
| `DrawBonusFrame` borrows `zSlowP1` as a counter   | Uses its own scratch byte (quirk 7)                     |
| Explosion state in spare charset RAM at `$9D00`   | BSS tables                                              |
| `GameLoop` padded by `FrameDelay`                 | `RunTick` runs Oric frames against a time budget        |

**Timing.** `tools/oric_timing.py` runs the Oric's own `RoundStart` and `GameLoop` on a cycle-counting 6502 core
(`tools/cpu6502.py`) until the first crash, for each speed, one or two players, with and without boost, over six seeds.
The Oric runs at 1 MHz and its ULA takes no CPU time, so cycles are microseconds.

| Speed | Two players (µs/frame) | One player (µs/frame) | One player, P1 boosting | Explosion |
|:------|:-----------------------|:----------------------|:------------------------|:----------|
| 1     | 7213                   | 11171                 | 14819                   | 1.48 s    |
| 5     | 12370                  | 16328                 | 19976                   | 1.48 s    |
| 9     | 17506                  | 21464                 | 25112                   | 1.48 s    |

So a frame costs 7213 µs + 1287 µs per speed step, plus ~3958 µs per computer player and ~3550 µs per boosting cycle.
`RunTick` adds each C64 frame's length (19950 µs PAL, 16716 µs NTSC) to a budget and runs Oric frames while it lasts,
charging each frame that cost. Every frame counter then runs at the Oric's rate: movement, bonus blocks, the computer's
decisions. Two Oric effects carry over by design: a one-player game is slower than a two-player one, and boost is about
1.5 times normal speed rather than twice, because a boosting frame takes longer. At speed 5 a cycle travels about 31
pixels per second against the computer.

**Demo mode.** Left alone, the attract cycle runs the computer against itself (`zAI` = 3), silently, with scores and
lives, for four crashes, until a player runs out of lives, or until a key or fire. With the volume at 0 the Oric
skipped the round-start sweep, and so does the demo.

**Intro picture.** `tools/make_intro.py` draws a multicolour bitmap after the original PSS cassette inlay: the PSS logo
(decoded from the tape), chrome LIGHT CYCLE lettering with a glint, a perspective grid, the light cycle with its
yellow-green trail and flare, and a strapline that reads ARCADE ACTION FOR COMMODORE 64 where the inlay said ORIC 1. It
is packed to about 5 KB (`intro.rle`) and unpacked into VIC bank 1 by `IntroScreen`.

### Phase 3: Scores, Lives and the Winner

`score.s` ports `AddDigit`, `TickTime`, the awards, `ResetTime`, `ResetScores` and `DecideWinner`. The Oric kept its
numbers as ASCII digits in the status rows on screen and added to them there; the C64 keeps the same 8-character fields
in RAM (`ScoreP1`, `ScoreP2`, `TimeDigits`) and lives as ASCII digits (`LivesP1`, `LivesP2`), and `hud.s` redraws a
field when it changes. A crash runs the explosion, then `AwardOpponent` (the Oric's `AwardP1` / `AwardP2` and the lives
update), then the pause; on a last life `PlayGame` calls `DecideWinner` and `FlashWinner`. Verified in VICE by setting
both players to one life and letting the computers play: the right winner flashed, with its score.

| Oric                                           | C64                                                      |
|:-----------------------------------------------|:---------------------------------------------------------|
| Three text rows under the HIRES screen         | Each side's half stacked in a 5-cell panel, at its foot  |
| `TIME`: white box, double height on green      | The same boxes in both panels (`BitmapCharTall`)         |
| `PLAYER 1` yellow, `COMPUTER` cyan             | `P1` yellow, `P2` or `CPU` cyan                          |
| Status rows on the arena's paper colour        | Panels on the arena's paper colour (`ArenaPaper`)        |
| 8-digit scores                                 | The last five digits shown; all eight kept               |
| Cycle icon in characters 123–124               | The same glyphs in two spare font characters             |
| Winner's name toggled in inverse 25 times      | The same: 25 toggles, ending reversed                    |
| `DecideWinner` relies on a stray carry         | `SEC` first (quirk 2)                                    |

The layout change, with figures of both and the reasons, is in [graphics.md](graphics.md) (The Status Layout).

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

**Arena geometry.** The arena keeps the Oric's 240×200 coordinates, so every x fits in a byte and every constant carries
over: start positions, the computer's look-ahead, the obstacle maths and the explosion bounds. It is drawn 40 pixels in
on the 320-pixel bitmap, leaving a 40-pixel panel each side for what the Oric showed in its three text rows; a 200-line
bitmap leaves no rows below it without a raster split.

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

**Title content.** The Oric title screen carries the publisher's address under the PSS logo. Whether the C64 title keeps
it, replaces it with a credit line or drops it is the owner's call; open.

---

## Phases 2–6

**Phase 2, game logic.** Port in dependency order, checking each against `game.s`: `Random`, `DrawLine`, `DrawBorder`
and `DrawObstacles`, `RandomStarts`, `EraseHead`, `MovePlayer` and `PlotCheckCrash`, `ComputerAI`, `AIAvoid` and
`AIBoost`, `Explosion`, `BonusBlocks`. `BonusBlocks` writes whole 6-pixel Oric bytes, so it becomes a 6×6 pixel blit
through `PlotXY` and `UnplotPixel`, with a 36-pixel `PixelSet` emptiness test. The crash exit becomes a flag returned to
`GameLoop` ([quirks.md](quirks.md)). Exit test: a full round against the computer, with crashes and explosions.

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
