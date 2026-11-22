# Light Cycle – Source Guide and Toolchain

---

## Repository

| Path                   | Holds                                                               |
|:-----------------------|:--------------------------------------------------------------------|
| `CYCLE.TAP`            | The original Oric tape: the reference for everything else           |
| `oric/game.s`          | Annotated disassembly of the `GAME` block (generated, committed)    |
| `oric/loader.s`        | Annotated disassembly of the `LIGHT CYCLE` block                    |
| `oric/light_cycle.bas` | The BASIC stub as text                                              |
| `tools/`               | Tape, disassembly, tape rebuild, timing, table export, intro tools  |
| `build/`               | `CYCLE.TAP` assembled from `oric/*.s` (`make tap`): never committed |
| `c64/src/`             | The C64 port (ca65)                                                 |
| `c64/cfg/c64.cfg`      | ld65 memory layout                                                  |
| `c64/build/`           | Build output, screenshots: never committed                          |
| `docs/`                | These chapters, the handbook and its tools                          |

---

## Toolchain

| Tool                           | Used for                                         |
|:-------------------------------|:-------------------------------------------------|
| cc65 (`ca65`, `ld65`, `da65`)  | Assembling the port; disassembling the Oric code |
| VICE (`x64sc`, `c1541`)        | Running and capturing the port; the `.d64`       |
| Python 3                       | Tape and disassembly tools (standard library)    |
| Pillow (Homebrew `python3.14`) | Decoding the Oric figures                        |
| Node.js 20+                    | Generating the HTML handbook                     |
| `just`                         | Documentation recipes                            |

---

## Building

The `Makefile` builds the C64 version and the Oric tape; the `justfile` wraps it and adds the documentation recipes
([html_documentation.md](html_documentation.md)).

| Command         | Does                                                                            |
|:----------------|:--------------------------------------------------------------------------------|
| `make`          | `c64/build/lightcycle.prg`, plus `lightcycle.map` and the VICE label file       |
| `make d64`      | `c64/build/lightcycle.d64`                                                      |
| `make run`      | Starts the build in VICE with the labels loaded into its monitor                |
| `make smoke`    | Headless boot; screenshots into `c64/build/` (`capture_screens.py`)             |
| `make oric`     | Splits the tape, regenerates `oric/*.s`, checks they rebuild byte for byte      |
| `make tap`      | `build/CYCLE.TAP` from `oric/loader.s` and `oric/game.s` (`tools/build_tap.py`) |
| `make verify`   | `make tap`, then checks `build/CYCLE.TAP` byte for byte against `CYCLE.TAP`     |
| `make oric-run` | Loads `build/CYCLE.TAP` in Auric, Oric-1 mode (`AURIC_DIR`)                     |
| `make intro`    | Redraws `c64/src/intro.rle` and its preview (`tools/make_intro.py`)             |
| `make tables`   | Re-exports `c64/src/oric_tables.inc` (`tools/export_tables.py`)                 |
| `make clean`    | Removes `c64/build/` and `build/`                                               |

`make oric` must report both blocks as `IDENTICAL`. It runs `tools/tap_extract.py`, then `tools/build_disasm.py`, which
writes a da65 info file from `tools/symbols.py`, disassembles, adds the comments and reassembles with `cl65`. Labels and
comments are changed in `tools/symbols.py` followed by `make oric`; `oric/*.s` is never edited by hand. `make verify`
then wraps the two assembled blocks in the original tape headers and confirms the tape matches.

---

## C64 Source Conventions

- One module per concern, each starting with a comment naming the Oric routines it replaces or ports. Platform:
  `platform.s`, `video.s`, `plot.s`, `timing.s`, `input.s`, `sound.s`. Game: `game.s` (rounds, timing budget),
  `player.s`, `ai.s`, `arena.s`, `explosion.s`, `bonus.s`, `score.s`, `hud.s`. Front end: `main.s` (attract cycle,
  demo), `intro.s`. Where a routine takes over an Oric routine's job, it keeps its name and its register contract.
- Ported game code follows the Oric line for line, including where it relies on the carry flag; changes are listed in
  [porting.md](porting.md) and marked in the comments.
- Generated sources are committed and never edited: `oric_tables.inc` (`tools/export_tables.py`) and `intro.rle`
  (`tools/make_intro.py`).
- Hardware addresses, memory layout and constants live in `hw.inc`; zero page is declared in `zp.s` and imported through
  `zp.inc`. No raw hardware addresses in code.
- Lookup tables are generated at assembly time with `.repeat`, so the arithmetic that defines them is in the source.
- `basic_stub.s` links first so `Start` lands at `$080D`; an `.assert` fails the link otherwise.
- Strings for the text screen use `screencodes.inc` and end with `STR_END` (`$FF`), because `@` is screen code 0.
- The BSS segment is zeroed by `ClearBss` at start-up: the loader leaves RAM as it was.
