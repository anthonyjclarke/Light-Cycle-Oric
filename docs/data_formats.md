# Light Cycle – Data Formats

The tape format and the Oric game's tables, read from the code. Labels are the disassembly's (`tools/symbols.py`).

---

## Tape Blocks

Each Oric tape block is a run of `$16` sync bytes, `$24`, a 9-byte header, a 0-terminated name, then the data. The end
address is inclusive. `tools/tap_extract.py` splits `CYCLE.TAP` this way, and `tools/build_tap.py` writes the
assembled source back out the same way (`make verify`).

| Header byte | Meaning                                    | `LIGHT CYCLE` | `GAME`  |
|:------------|:-------------------------------------------|:--------------|:--------|
| 0–1         | Unused                                     | `$00 $EC`     | `$34 $EC` |
| 2           | Type: `$00` BASIC, `$80` machine code      | `$00`         | `$80`   |
| 3           | Autorun flag                               | `$04`         | `$04`   |
| 4–5         | End address, high byte first               | `$0E80`       | `$1800` |
| 6–7         | Start address, high byte first             | `$0501`       | `$0400` |
| 8           | Unused                                     | `$FF`         | `$FF`   |

---

## HIRES Pixel Bytes

A HIRES byte with bit 6 set holds six pixels, bit 5 on the left. `HiresAddr` turns a pixel (x, y) into an address and a
mask: `$A000 + 40y + x div 6`, and `PixelMask[x mod 6]` (`$60 $50 $48 $44 $42 $41`, bit 6 kept set). `ClearHires` fills
with `$40`, an empty pixel byte.

---

## Tables in the GAME Block

| Label           | Address  | Size | Holds                                                     |
|:----------------|:---------|:-----|:----------------------------------------------------------|
| `ViaRegIdx`     | `$0424`  | 7    | VIA registers `ViaGameSetup` writes (overlaps next)       |
| `ViaRegVal`     | `$042A`  | 7    | Their values                                              |
| `BonusRowOfs`   | `$0430`  | 6    | Row offsets ×40 for the 6-line bonus block                |
| `BonusGfx`      | `$0436`  | 24   | Four 6-byte frames: three shapes and a blank             |
| `BonusFrameOfs` | `$044E`  | 6    | Animation order as offsets into `BonusGfx`                |
| `StatusText`    | `$0454`  | 40   | HIRES status row 0, with attributes; P2 name at `$0472`   |
| `TimeAttrL/R`   | `$0488`  | 3+3  | Attributes around `TIME`: double height, black on green   |
| `ExplodeDX`     | `$0490`  | 32   | Particle target x offsets, signed                         |
| `ExplodeAY`     | `$04B0`  | 14   | AY R0–R13 for the explosion                               |
| `ExplodeDY`     | `$04C0`  | 32   | Particle target y offsets, signed                         |
| `GlyphBike`     | `$04F0`  | 16   | Characters 123–124: the status-row cycle                  |
| `GlyphArrows`   | `$0550`  | 16   | Characters 125–126: down arrow, slider marker             |
| `PixelMask`     | `$05A1`  | 6    | HIRES bit per x mod 6                                     |
| `HiDefault`     | `$0608`  | 17   | Default hi-score entry                                    |
| `PaperColours`  | `$0619`  | 4    | Paper attributes: red, blue, magenta, black               |
| `RankInk`       | `$0620`  | 8    | Ink attribute per hi-score rank                           |
| `KeyRowP1`…     | `$06A0`  | 3×5  | P1 keys: matrix row, column mask, `zInput` bit            |
| `KeyRowP2`…     | `$06AF`  | 3×5  | P2 keys, same layout                                      |

Text tables (menus, prompts, the play-again rows) hold serial attributes inline: `$00–$07` set ink, `$08–$0F` the
character set and double height, `$10–$17` paper. Each attribute takes a character cell and shows as a space.

---

## Status Rows

In HIRES mode the three text rows start at `HIRES_STATUS0` (`$BF68`), `HIRES_STATUS1` and `HIRES_STATUS2`. Scores and
`TIME` are 8-character ASCII numbers kept in screen memory and added to digit by digit with `AddDigit`, which treats a
leading space as `0`.

| Field     | Row | Columns | Address        |
|:----------|:----|:--------|:---------------|
| P1 score  | 2   | 2–9     | `$BFBA–$BFC1`  |
| P1 lives  | 2   | 12      | `$BFC4`        |
| `TIME`    | 1–2 | 15–22   | `$BF9F`, `$BFC7` |
| P2 lives  | 2   | 27      | `$BFD3`        |
| P2 score  | 2   | 30–37   | `$BFD6–$BFDD`  |

`TIME` is written to both rows 1 and 2 under a double-height attribute. The C64 keeps these fields in RAM in the same
form (`ScoreP1`, `ScoreP2`, `TimeDigits`: 8 ASCII characters, right-aligned, spaces before the first digit; `LivesP1`,
`LivesP2`: one ASCII digit) and draws them into its side panels.

---

## Hi-Score Entry

`HISCORE_TAB` (`$B800`) holds 8 entries of 28 bytes; `InitHiscores` writes 9 from `HiDefault`. Bytes 0–7 are the score
(compared on bytes 1–7), byte 8 onward the name, ended by `$0D`. The default entry is a score of 500 and the name
`P.S.S.`. `PrintHiscores` shows rank, score, `---` and the name, in the rank's ink from `RankInk`.
