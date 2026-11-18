# Light Cycle – Documentation

*Light Cycle* is a two-player light-cycle game for the Oric-1 and Atmos (16K or 48K), written by A.J. Clarke and
published on tape by PSS. It was written in 1983 on an original Oric-1, by hand on paper, and entered into the
machine with a machine code monitor ([original_release.md](original_release.md)). This repository holds a
byte-identical, commented disassembly of the original tape, and a Commodore 64 port built from it: the Oric game logic
re-hosted on a new C64 platform layer.

**[LIGHT_CYCLE.html](LIGHT_CYCLE.html)** gathers every document below, with the images embedded, into one page that
reads offline in a browser.

---

## The Game and Its Code

| Document                                   | Covers                                                     |
|:-------------------------------------------|:-----------------------------------------------------------|
| [player_guide.md](player_guide.md)         | How to play: menus, controls, rules, scoring, the computer |
| [original_release.md](original_release.md) | The PSS cassette sheet, advert and reviews                 |
| [graphics.md](graphics.md)                 | Oric figures decoded from the tape; C64 build screenshots  |
| [sound.md](sound.md)                       | The Oric's AY effects and their SID equivalents            |
| [architecture.md](architecture.md)         | Tape, boot, memory maps, program flow, both machines       |
| [data_formats.md](data_formats.md)         | Tape blocks, tables, screen rows, the hi-score entry       |
| [source_guide.md](source_guide.md)         | Repository layout, toolchain, build targets, conventions   |

---

## Reference

| Document                                       | Covers                                                      |
|:-----------------------------------------------|:------------------------------------------------------------|
| [porting.md](porting.md)                       | The C64 port plan: decisions, memory map, phases, risks     |
| [platform_layer.md](platform_layer.md)         | The C64 platform interface, routine by routine              |
| [quirks.md](quirks.md)                         | Places where the original does something unintended         |
| [oric.md](oric.md)                             | Appendix: the Oric's history, specs, graphics and sound     |
| [CHANGELOG.md](../CHANGELOG.md)                | Release history                                             |
| [html_documentation.md](html_documentation.md) | Regenerating the figures, screenshots and the handbook      |
| [credits.md](credits.md)                       | Who made the game and this repository; tools and links      |

Oric names and addresses follow the disassembly ([`oric/game.s`](../oric/game.s), [`oric/loader.s`](../oric/loader.s));
the names come from `tools/symbols.py`. C64 names follow `c64/src/`. Where a C64 routine replaces an Oric one it keeps
the Oric name.
