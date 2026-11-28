# Light Cycle – Credits and Links

---

## The Game

I wrote *Light Cycle* for the Oric-1 and Atmos. The game's own credit on the title screen reads `AUTHOR - A.J.CLARKE`,
under the PSS logo and the publisher's address in Coventry, and the default hi-score name is `P.S.S.`. I wrote it in
1983 on an original Oric-1, by hand on paper, and typed it in with Oric-Mon, my machine code monitor
([original_release.md](original_release.md#oric-mon)). The C64 intro picture is based on the PSS cassette inlay for the Oric
release; I haven't yet credited the inlay's artist here.

---

## The Reconstruction

The disassembly, its annotations, the C64 port and these documents are my personal project.

---

## The Restoration Toolkit

I restore my own 1980s games with a private toolkit, *Old Code Restoration* (OldCode_Restoration). It covers two
machines, the Commodore C16 and the Oric-1, and holds the shared tools, a user guide, the commissioning briefs and the
`retro-restoration` skill for Claude Code. `new_project.py` copies the tools a game needs into its own `tools/` folder,
so each repository builds without the toolkit.

The toolkit grew out of the games. It started in January 2026 with *Dork's Dilemma* for the C16. That first attempt
converted a 1992 text export of the source, and it assembled, but the game never started. In October 2026 I captured
the original disks again with ZoomFloppy and OpenCBM. A new pipeline read the disk image directly, converted the
assembler syntax without fixing anything and compared every byte. It matched the original on 20 October 2026, and I
then used it for *Tycoon Tex*, *Xargon Wars* and *Xargon's Revenge*.

The Oric games came next, in November 2026. Only their cassettes survive, so the job was disassembly rather than a
rebuild from source. *Hopper* was first, as one tape block, and *Light Cycle* followed, as a BASIC stub plus the game.
On 20 and 22 November 2026 I wrote what the two games taught me back into the toolkit:

- the tape format and the Oric-1 ROM workspace both games use;
- the AY wiring and the two disassembly pipelines;
- the build gotchas;
- the habits the two games share.

The same pass added an Oric brief, written for *The Ultra* (written by a good friend of mine, John Marshall) and
*Oric-Mon* (which I pulled together!), which are next.

The toolkit's method borrows from two MIT-licensed projects:

- David Youd's [retro-archaeology-skills](https://github.com/c64cryptoboy/retro-archaeology-skills): the disassembly
  invariants, routine contracts, behaviour classes and 6502 helper scripts;
- Dave Agent's [MOSaic](https://github.com/Dave-Agent/MOSaic): the evidence ladder, the variable-role protocol and
  working in slices.

I read the C16 disks with [OpenCBM](https://github.com/OpenCBM/OpenCBM), the GPLv2 suite of drivers and tools for
Commodore serial drives. Its maintainers are Spiro Trikaliotis and RETRO Innovations (`go4retro`), and OpenCBM is the
successor of cbm4linux. The drive was connected through a [ZoomFloppy](https://github.com/go4retro/ZoomFloppy), the USB
interface designed by Nate Lawson and made by RETRO Innovations, whose schematic and PCB are released under CC BY-SA
4.0.

The toolkit's own tools build on [cc65](https://cc65.github.io/), [VICE](https://vice-emu.sourceforge.io/) and
[Auric](https://github.com/pugo/Auric). The user guide is rendered with [Marked](https://marked.js.org/) 17.0.5.

---

## The Documentation

These chapters and the handbook follow the documentation format of my C64 reconstructions (*Frak!*, *Thing On A
Spring*). The handbook generator and templates are carried over from those repositories unchanged.

---

## Tools

| Tool                                     | Use                                       |
|:-----------------------------------------|:------------------------------------------|
| [cc65](https://cc65.github.io/)          | `ca65`, `ld65`, `da65`, `cl65`            |
| [VICE](https://vice-emu.sourceforge.io/) | `x64sc` emulation and captures, `c1541`   |
| [Auric](https://github.com/pugo/Auric)   | Running the Oric original and the rebuild |
| [Python](https://www.python.org/)        | Tape, disassembly and figure tools        |
| [Pillow](https://python-pillow.org/)     | Figure rendering                          |
| [Node.js](https://nodejs.org/)           | Handbook generation                       |

---

## Libraries and Fonts

[Marked](https://marked.js.org/) 17.0.5 converts the Markdown and [Mermaid](https://mermaid.js.org/) 10.9.3 draws the
diagrams. Both are vendored with their licences in `docs/tools/vendor/`. The handbook's C64 font option uses Style's
[C64 TrueType](https://style64.org/c64-truetype) fonts, embedded unmodified as their licence allows.

---

## Playing the Original

`CYCLE.TAP` runs in any Oric emulator that loads `.tap` files, such as Auric or Oricutron. If it doesn't start by
itself, `CLOAD""` loads it. `make verify` builds the same tape from the source in `oric/`, as `build/CYCLE.TAP`, and
`make oric-run` starts it in Auric ([oric_specs.md](oric_specs.md) covers the ROMs and set-up).

The game's entry on [Oric.org](https://www.oric.org/software/light_cycle-1432.html), the Oric software archive, lists
the PSS release (1983, by A. J. Clarke) with in-game screenshots and the cassette cover.
