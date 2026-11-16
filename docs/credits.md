# Light Cycle – Credits and Links

---

## The Game

*Light Cycle* for the Oric-1 and Atmos was written by A.J. Clarke. The game's own credit, on the title screen, reads
`AUTHOR - A.J.CLARKE`, under the PSS logo and the publisher's address in Coventry; the default hi-score name is
`P.S.S.`. Release year and other credits are still to be added by the owner.

---

## The Reconstruction

The disassembly, its annotations and the C64 port are Anthony Clarke's project; the details of who did what are for
the owner to fill in.

---

## The Documentation

These chapters and the handbook follow the documentation format of Anthony's C64 reconstructions (*Frak!*, *Thing On A
Spring*). The handbook generator and templates are carried over from those repositories unchanged.

---

## Tools

| Tool                                     | Use                                          |
|:-----------------------------------------|:---------------------------------------------|
| [cc65](https://cc65.github.io/)          | `ca65`, `ld65`, `da65`, `cl65`               |
| [VICE](https://vice-emu.sourceforge.io/) | `x64sc` emulation and captures, `c1541`      |
| [Python](https://www.python.org/)        | Tape, disassembly and figure tools           |
| [Pillow](https://python-pillow.org/)     | Figure rendering                             |
| [Node.js](https://nodejs.org/)           | Handbook generation                          |

---

## Libraries and Fonts

[Marked](https://marked.js.org/) 17.0.5 converts the Markdown and [Mermaid](https://mermaid.js.org/) 10.9.3 draws the
diagrams; both are vendored with their licences in `docs/tools/vendor/`. The handbook's C64 font option uses Style's
[C64 TrueType](https://style64.org/c64-truetype) fonts, embedded unmodified as their licence allows.

---

## Playing the Original

`CYCLE.TAP` runs in any Oric emulator that loads `.tap` files, such as Oricutron: load it and type `CLOAD""` if it does
not start by itself.
