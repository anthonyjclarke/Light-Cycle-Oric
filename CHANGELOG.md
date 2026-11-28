# Changelog

---

## [Unreleased] 28-11-2026 – Writing voice

### Changed

- I've rewritten the README and the chapters in my own voice: first person where the work is mine (the 1983 game, the
  port, the toolkit and the open decisions), with the specs, tables and instructions left precise. This replaces the
  third-person wording from the 17-11-2026 pass. The two Oric appendices (`oric_history.md`, `oric_specs.md`) are
  unchanged, so they stay identical to *Hopper*'s copies.
- Oric-Mon, carried over from *Hopper*: a new Oric-Mon section in `original_release.md` (the monitor I typed both games
  in with, its two releases on oric.org and its place as the next restoration), and the README, docs index and
  `credits.md` now name it as the monitor *Light Cycle* was entered with.
- `credits.md`: the reconstruction is my personal project (the "who did what" placeholder is gone), and the toolkit
  section credits John Marshall for *The Ultra* and notes that I pulled *Oric-Mon* together.

---

## [Unreleased] 17-11-2026 – Original release material, Oric-style panels

### Added

- A root `README.md` for the GitHub repository, in the same form as *Hopper*'s. It presents the project as a C64 version
  of the game, with the Oric original and its source kept alongside and buildable for Oric emulators: the game, the C64
  keys, C64 and Oric screenshots, the versions and the port's progress, the history, and how to build and run both.
- `make tap`, `make verify` and `make oric-run` (with `just verify` and `just oric-run`): `tools/build_tap.py` assembles
  `oric/loader.s` and `oric/game.s` and wraps them in the original tape headers as `build/CYCLE.TAP`, which
  `make verify` checks byte for byte against `CYCLE.TAP` (it matches) and `make oric-run` loads in Auric. `build/` is
  gitignored.
- `docs/original_release.md`: how the game was written (1983, by hand on paper, entered with a machine code monitor),
  the PSS cassette instruction sheet, the PSS advert, two magazine reviews and a New Releases column cut to their
  *Light Cycle* parts, and the review's screen photographs matched against `DrawStatusLine`.
- The 1983 origin in the README's opening paragraph and in `credits.md`.
- `BitmapCharTall` (`video.s`): a glyph at double height over two cells, for the Oric's double-height `TIME`.
- `oric-game-screen.png`: a capture of the Oric game screen with its own ROM font, in `graphics.md` (The Oric
  Original) and `original_release.md` (The Screens in the Review).
- A link to the game's entry on Oric.org, in `credits.md` (Playing the Original) and `original_release.md`.
- `docs/oric.md`, an appendix on the Oric for readers new to it: history, specifications, memory map, serial attributes
  and the three video modes, the AY-3-8912 and how the VIA reaches it, BASIC examples (run on the Atmos ROM in Auric),
  running the original in an emulator (Auric, ROMs from oric.free.fr), how *Light Cycle* uses the machine, and further
  reading. Its figures (`oric-palette.png`, `oric-attributes.png`, `oric-envelopes.png`) come from the new
  `docs/tools/render_oric.py`, run by `just docs` and `just docs-graphics`.

### Changed

- `credits.md`: a Restoration Toolkit section on Anthony's private *Old Code Restoration* toolkit, how it grew from
  *Dork's Dilemma* to the Oric games, and its credits: retro-archaeology-skills, MOSaic, OpenCBM, ZoomFloppy, cc65,
  VICE, Auric and Marked.
- Links to the *Hopper* repository (github.com/anthonyjclarke/Hopper-Oric) where the game is named: the README's history
  and `original_release.md`'s advert.
- A documentation pass across every chapter: everything is written in the third person; the docs index and README lead
  with the C64 version and point to the Oric original and its build; `source_guide.md`, `data_formats.md` and
  `credits.md` cover the tape rebuild; the player's guide no longer says the original is untested in an emulator;
  `porting.md` drops the superseded speed-table plan and the finished Phase 2 and 3 plans, keeping Phases 4–6.
- The Oric appendix moves out of Reference into its own Appendix group in the handbook and index, and splits in two.
  `oric_history.md` ("History of Oric") is expanded into the full story: Tangerine and the Microtan, the Oric-1 and its
  French success, the 1983 factory fire, Edenspring and the Atmos, the peripherals, the Stratos and the receivers,
  Eureka and the Telestrat, the Pravetz 8D and Nova 64 clones, software and magazines, a timeline and today's community
  and hardware. `oric_specs.md` ("Oric Tech Specs") takes the specifications, memory map, graphics, sound and emulator
  sections, with new tables of the models and their storage. Both are general information on the Oric, with no game
  named, and the same files in every Oric reconstruction; the game's own screen gives way to an Auric capture of the
  HIRES BASIC example (`oric-basic-hires.png`). The founders are corrected to Paul Johnson, Mark Rainer and Nigel Penton
  Tilbury, with Barry Muncaster joining later.
- The status panels follow the Oric's status rows, as the review photographs show them: `TIME` in black on a white box
  over double-height digits on green, `P1` yellow and `P2` / `CPU` cyan beside the cycle icon, lives under the icon,
  score under the name, all at the foot of the panel on the round's paper colour (`ArenaPaper`). The `SCORE`, `LIVES`
  and `WINS` labels are gone, and the winner's name toggles 25 times and stays reversed, as on the Oric.
- The cycle icon's two halves now meet, as on the Oric.
- `graphics.md`: "The Status Layout: Oric and C64", the Oric's status rows against the C64 panels, with figures cropped
  by `render_graphics.py` (`status-oric.png`, `status-c64.png`), what differs and why.
- A replica of the Oric in-game screen (`oric-screen.png`) and its status rows, in place of the blurred review
  photograph: `render_graphics.py` runs the Oric's own `RoundStart` and first `GameLoop` frames on `tools/cpu6502.py`
  and draws the result with the Oric's serial attributes; letters use the C64 font squeezed to five pixels, since the
  Oric ROM font is not on the tape.

### Fixed

- The handbook logo (`bike-icon.png`) drew the cycle icon's two characters with a 2-pixel gap, splitting it in two.
  The game prints `{` and `|` side by side (`StatusText`), so `render_graphics.py` now joins them (`glyph_strip`'s
  `gap=0`).

---

## [Unreleased] 16-11-2026 – Phase 3

### Added

- Scores, lives and `TIME` (`score.s`): the Oric's `AddDigit` decimal arithmetic, `TickTime`, the awards (`TIME` + 200
  to the opponent), lives, `ResetScores`, `ResetTime` and `DecideWinner`.
- Status panels (`hud.s`): name, CPU marker, score, lives with the Oric's cycle icon, and `TIME`, each side of the
  arena; the winner's name flashes and WINS appears at the end of a match.
- Matches end when a player has no lives left; demo mode also keeps score.
- `Delay` in `timing.s`; `zTextPtr` for strings drawn with `BitmapChar`; `GlyphBike` exported from the tape.

### Fixed

- `DecideWinner` sets carry before comparing (Oric quirk 2).

---

## [Unreleased] 16-11-2026 – Phase 2

### Added

- C64 game logic ported line for line from the Oric: `arena.s` (`Random`, `DrawLine`, `DrawBorder`,
  `DrawObstacles`, `RandomStarts`), `player.s` (`MovePlayer`, `EraseHead`, `PlotCheckCrash`), `ai.s` (`ComputerAI`,
  `AIAvoid`, `AIBoost`), `explosion.s`, `bonus.s`, and `game.s` (rounds, `EngineSound`, the crash).
- Oric-time budget: `RunTick` runs Oric frames at the rate measured from the Oric code, so speed, boost and every
  frame counter match the original.
- Demo mode: the computer against itself in the attract cycle; the computer can now drive either player (`zAI`).
- Intro picture after the PSS cassette inlay (`intro.s`, `intro.rle`), drawn by `tools/make_intro.py`.
- `tools/cpu6502.py` and `tools/oric_timing.py`: a cycle-counting 6502 core and the Oric timing measurements.
- `tools/export_tables.py`: the Oric data tables exported to `c64/src/oric_tables.inc`.
- `ReadFire` in `input.s`; `make intro` and `make tables`.

### Changed

- `main.s` is now the attract cycle (intro, instructions, demo) and the game, replacing the Phase 1 harness.
- `TextOn` sets a black background; screenshots now show the intro, instructions and demo.
- `tools/trace6502.py` can be imported (its opcode table is shared with the 6502 core).

### Fixed

- Documentation: the explosion particles wait a random delay, then travel to their targets; the obstacles are four
  V-shaped wedges.

---

## [Unreleased] 16-11-2026 – Phase 1

### Added

- C64 Phase 1 platform layer in `c64/src/`: `platform.s` (machine takeover), `video.s` (VIC bank 1, text and bitmap
  modes, colour cells, panel glyphs), `plot.s` (Oric-coordinate pixel routines with lookup tables), `timing.s`
  (PAL/NTSC detection, raster tick), `input.s` (CIA keyboard matrix, both joysticks, menu keys), `sound.s` (SID
  engines, start sweep, explosion), `zp.s`.
- Phase 1 test harness in `c64/src/main.s`: title screen, bitmap arena with panels and two test cycles.
- HTML handbook `docs/LIGHT_CYCLE.html` in the shared reconstruction format: twelve chapters, `docs/handbook.json`,
  the shared generator and templates, `justfile` documentation recipes.
- `docs/tools/capture_screens.py` (headless VICE captures), `docs/tools/render_graphics.py` (figures decoded from the
  tape), `docs/tools/doc_names.py` (label check).

### Changed

- `docs/DISASSEMBLY.md` and `docs/C64_PORT_PLAN.md` split into the handbook chapters (`architecture.md`,
  `player_guide.md`, `data_formats.md`, `quirks.md`, `porting.md` and others).
- `make smoke` now runs `capture_screens.py` and writes its screenshots to `c64/build/`.
- Zero page segment widened to `$02–$FF`: BASIC and the KERNAL are banked out.

---

## [0.1.0] 16-11-2026

### Added

- Oric tape tooling: `tools/tap_extract.py` splits `CYCLE.TAP` and detokenises the BASIC stub.
- Annotated, byte-identical disassembly of both tape blocks (`oric/game.s`, `oric/loader.s`) generated by
  `tools/build_disasm.py`.
- `docs/DISASSEMBLY.md` and `docs/C64_PORT_PLAN.md`.
- C64 Phase 0 skeleton: ld65 config, BASIC `SYS` stub, boot code, `Makefile` with `prg`, `d64`, `run`, `smoke` and
  `oric` targets.
