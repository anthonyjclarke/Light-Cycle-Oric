# Light Cycle (Oric) – Disassembly Notes

Companion to the annotated sources [`oric/game.s`](../oric/game.s) and [`oric/loader.s`](../oric/loader.s). Both reassemble **byte-identical** to the blocks on `CYCLE.TAP` (checked by `tools/build_disasm.py`).

```bash
python3 tools/tap_extract.py CYCLE.TAP oric
```

```bash
python3 tools/build_disasm.py
```

---

## Tape Layout

`CYCLE.TAP` holds two standard Oric tape blocks (sync `$16…$16 $24`, 9-byte header, name, data; end address inclusive).

| Block         | Type  | Load          | Size  | Contents                       |
|:--------------|:------|:--------------|:------|:-------------------------------|
| `LIGHT CYCLE` | BASIC | `$0501–$0E80` | 2432  | BASIC stub, glyphs, title code |
| `GAME`        | M/C   | `$0400–$1800` | 5121  | The game; autoruns at `$0400`  |

The BASIC stub is six lines: two `REM` banners, `REM 16K OR 48K`, `TEXT:INK7:PAPER0`, `CALL #900`, `CLOAD""`. The routine at `$0900` copies 64 glyphs into the TEXT alternate character set (`$B900`, the logo), two chevron glyphs into the standard set (`$B7E0`), and a pre-built 40×28 title/instructions screen to `$BB80`. `CLOAD""` then pulls in `GAME`, which overwrites the BASIC area and autoruns. The loader block also carries unused glyph data at `$0800–$08A7` and assembler residue at `$0975–$09FF`.

---

## Hardware Use

The game makes **no ROM calls**. It drives the hardware directly and borrows only a few ROM workspace bytes.

| Area          | How the game uses it                         |
|:--------------|:---------------------------------------------|
| Display       | HIRES 240×200 at `$A000` + 3 text rows       |
| Mode switch   | Writes `$1E`/`$1A` to `$BFDF` (HIRES/TEXT)   |
| Keyboard      | Direct matrix scan: VIA PB0–2 + AY port A    |
| Menus' keys   | ROM IRQ handler, reads `ROM_KEY` (`$02DF`)   |
| Sound         | AY-3-8912 via VIA port A + PCR (CA2/CB2)     |
| Timing        | Busy-wait loops; IRQs masked during play     |
| Randomness    | Additive generator over `$D0–$D3`            |

During a round `RoundStart` executes `SEI` and `ViaGameSetup` turns off the timer IRQ, so keys are read by `ReadKeysP1`/`ReadKeysP2` straight from the matrix. A crash calls `ViaRestoreRom`, which re-creates the ROM's 100 Hz timer setup, so menus and name entry can use the ROM keyboard again.

The "16K OR 48K" claim works because every address the game uses above `$4000` is assumed to mirror into the bottom 16K on a 16K machine: HIRES `$A000` → `$2000`, HIRES charset `$9800` → `$1800` (directly after the code). This is inferred from the address choices, not tested on hardware.

---

## Memory Map (48K)

| Range         | Use                                           |
|:--------------|:----------------------------------------------|
| `$0000–$0008` | Scratch                                       |
| `$0030–$0068` | Game state (see `game.s` zero-page map)       |
| `$0400–$06BF` | Tables and text (`Entry` JMP at `$0400`)      |
| `$06C0–$17C8` | Code                                          |
| `$9800–$9EFF` | Copy of TEXT charset while in HIRES           |
| `$9D00–$9E5F` | Explosion particle state (32 × 11 tables)     |
| `$A000–$BF3F` | HIRES bitmap (col 0 = paper attribute)        |
| `$B800–$B8DF` | Hi-score table, 8 × 28 bytes                  |
| `$B900/$B920` | Winner's score and name for hi-score entry    |
| `$BB80–$BFDF` | TEXT screen (menus, hi-scores)                |
| `$BF68–$BFDF` | HIRES-mode text rows: names, TIME, scores     |

The charset shuffle is the subtlest part of the game. Entering HIRES (`CharsetToHires`) copies `$B400–$BAFF` to `$9800–$9EFF` because the HIRES bitmap overlays the TEXT charset location. Leaving HIRES (`CharsetToText`) copies it back. The hi-score table at `$B800` rides along untouched in the alternate-set area. Before the copy back, `DecideWinner` stashes the winner's score and name at `$9D00`/`$9D20`, so they arrive at `$B900`/`$B920` ready for `HiscoreEntry`.

---

## Program Flow

```text
Start ─► DefineGlyphs, InitHiscores
  └► VolumeThenMenu: VolumeScreen (cursor up/down, RETURN)
       └► MainMenu: AskPlayers (1/2), AskSpeed (1–9), CharsetToHires,
            ClearHires, ResetScores
              └► RoundStart ◄──────────────────────────────┐
                   random starts, border, paper colour,     │
                   status rows, obstacles, engine sweep     │
                   └► GameLoop (per frame)                  │
                        MovePlayer P1, MovePlayer P2 (AI)   │
                        BonusBlocks, TickTime, FrameDelay,  │
                        EngineSound                         │
                        └► crash (PlotCheckCrash):          │
                             Explosion, award, life−1 ──────┘
                             lives = 0 → DecideWinner
                                  └► GameOver → HiscoreEntry → PlayAgain
                                       SPACE → MainMenu, V → VolumeThenMenu
```

---

## Gameplay Rules (as coded)

Each player steers a light cycle that leaves a permanent trail. Hitting any lit pixel crashes. Player 1 starts at x=25 heading right and player 2 at x=215 heading left, both at random heights. The arena is a 1-pixel frame (x 6–239, y 0–199), plus eight random-length diagonal walls aimed at the centre (`DrawObstacles`), plus "bonus" blocks that appear during play. Every 255 frames `BonusBlocks` picks a random empty 6×6 spot and animates a box → ring → dot → ring → box there, one frame per 25 ticks. The final box stays as a new obstacle.

Normal speed moves a cycle one pixel every second frame. Boost moves it every frame. A cycle's head is a 3-pixel arrow erased and redrawn each step. The trail is one pixel. Player 2's trail is dotted (plotted on alternate steps), so the two can be told apart in monochrome HIRES.

`TIME` counts up every 8 frames (speed 1–3) or 4 frames (speed 4–9). When a player crashes, the opponent scores `TIME + 200` and TIME resets. Each player has 5 lives. When either reaches 0, the higher score wins. The winner's name flashes, then the winner's score goes to the hi-score table. If the computer wins, its name is typed in automatically.

The computer (`ComputerAI`) looks 3 pixels ahead, 3 pixels wide. If blocked, it turns toward player 1 on the other axis. `AIAvoid` reverses that turn if it is also blocked. `AIBoost` boosts while it is 30 or more pixels from player 1 on either axis.

| Control | Player 1 | Player 2    |
|:--------|:---------|:------------|
| Up      | `2`      | `]`         |
| Down    | `A`      | Right SHIFT |
| Left    | `W`      | `;`         |
| Right   | `E`      | `'`         |
| Boost   | `R`      | `L`         |

---

## Routine Index (GAME block)

| Address | Name                 | Purpose                                     |
|:--------|:---------------------|:--------------------------------------------|
| `$06C0` | `Start`              | Cold start                                  |
| `$06FB` | `TextModeCls`        | Hide cursor, clear, TEXT mode               |
| `$0707` | `GameOver`           | Restore charset, hi-score, back to menu     |
| `$0724` | `InitHiscores`       | Default table into `$B800`                  |
| `$0742` | `WaitKey`            | Wait for ROM key                            |
| `$0764` | `Delay`              | ~0.15 s busy wait                           |
| `$0786` | `AskPlayers`         | 1 or 2 players                              |
| `$07C4` | `AskSpeed`           | Speed 1–9                                   |
| `$07E2` | `VolumeScreen`       | Volume slider with test tone                |
| `$08E1` | `HiresAddr`          | (x,y) → byte address + bit mask             |
| `$0956` | `AddDigit`           | ASCII decimal add on screen digits          |
| `$0974` | `EngineSound`        | Retune engines when boost changes           |
| `$09D9` | `StartSweep`         | Rising engine sweep at round start          |
| `$0A37` | `CharsetToText`      | `$9800` → `$B400`, 7 pages                  |
| `$0A58` | `CharsetToHires`     | `$B400` → `$9800`, switch to HIRES          |
| `$0A89` | `DrawLine`           | Bresenham line / single step                |
| `$0B0B` | `DrawObstacles`      | Eight random diagonal walls                 |
| `$0BC4` | `DrawStatusLine`     | HIRES text rows                             |
| `$0C06` | `Explosion`          | 32-particle explosion                       |
| `$0D48` | `ViaRestoreRom`      | ROM-style VIA + 100 Hz IRQ                  |
| `$0DC1` | `ViaGameSetup`       | IRQ off, VIA for matrix scan                |
| `$0DDB` | `Random`             | RNG step                                    |
| `$0DEA` | `DrawBorder`         | Arena frame                                 |
| `$0E1C` | `SetPaperColour`     | Random paper colour per round               |
| `$0E48` | `RandomStarts`       | Start positions and directions              |
| `$0EC9` | `PlotCheckCrash`     | Collision test → crash handling             |
| `$0F6A` | `DecideWinner`       | Compare scores, flash winner                |
| `$1041` | `ClearHires`         | Fill bitmap with `$40`                      |
| `$105E` | `UnplotPixel`        | Clear one pixel                             |
| `$106E` | `PlotPixel`          | Set one pixel                               |
| `$107B` | `ReadKeysP1`         | Matrix scan, player 1                       |
| `$10AB` | `ReadKeysP2`         | Matrix scan, player 2                       |
| `$10DB` | `BonusBlocks`        | Spawn/animate bonus obstacles               |
| `$1178` | `ComputerAI`         | Computer steering                           |
| `$131B` | `AIBoost`            | Computer boost decision                     |
| `$1356` | `MovePlayer`         | Input, move, crash test, draw               |
| `$1476` | `EraseHead`          | Remove the 3-pixel head                     |
| `$14DB` | `AyLoadAll`          | Load AY R0–R13 from a table                 |
| `$14F4` | `FrameDelay`         | `zSpeed` × 256 loops                        |
| `$14FF` | `AyWrite`            | Write one AY register                       |
| `$1534` | `PrintHiscores`      | Draw hi-score table                         |
| `$15C3` | `HiscoreEntry`       | Insert score, enter name                    |
| `$16C5` | `PlayAgain`          | SPACE / V prompt                            |
| `$1724` | `TickTime`           | Advance TIME counter                        |
| `$1755` | `RoundStart`         | Set up a round                              |
| `$177A` | `GameLoop`           | Per-frame loop                              |

---

## Quirks and Latent Bugs

None of these need to be carried into a port. They are listed so the port can match or deliberately fix them.

1. **Stack leak.** A crash `JMP`s out of `MovePlayer` → `PlotCheckCrash` (4 bytes) and `SP` is reset only at cold start. It wraps harmlessly within page 1.
2. **Uninitialised carry.** `DecideWinner` subtracts without `SEC`. It works because the preceding `CMP #$30` that ended the game always leaves carry set.
3. **Frame rate depends on CPU load.** `FrameDelay` is a fixed busy-wait on top of variable drawing work, so frames take roughly 6–20 ms depending on speed setting and activity (estimate, not measured).
4. **Dead code.** `DeadClearStatus` (`$0A7E`) and `DeadCharsetCopy` (`$1006`) are never called. Several tables (`$0403`, `$047C`, `$04E0`, `$0548`) are unreferenced.
5. **Hi-score init writes 9 slots, uses 8.** The ninth (`$B8E0`) is never shown.
