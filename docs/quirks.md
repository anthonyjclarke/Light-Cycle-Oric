# Light Cycle – Original Quirks

Places where the Oric code does something unintended or fragile, read from the disassembly, with what the C64 port
does about each. None is visible to a player as far as the code shows.

---

## The List

| #  | Quirk                                                       | Where            | C64 decision               |
|:---|:------------------------------------------------------------|:-----------------|:---------------------------|
| 1  | A crash `JMP`s out of two `JSR` levels; 4 stack bytes leak  | `PlotCheckCrash` | Fix: return a crash flag   |
| 2  | Score comparison subtracts without `SEC`                    | `DecideWinner`   | Fix: add `SEC`             |
| 3  | Frame time varies with drawing load and speed setting       | `FrameDelay`     | Fix: raster ticks          |
| 4  | Two routines are never called                               | `DeadClearStatus`, `DeadCharsetCopy` | Not ported |
| 5  | `InitHiscores` writes nine entries; eight are used          | `InitHiscores`   | Eight                      |
| 6  | Unreferenced tables and loader residue                      | `$0403`, `$047C`, `$04E0`, `$0975` | Not ported |

---

## Notes

**1.** `SP` is set only at cold start. Each crash leaves `MovePlayer`'s and `PlotCheckCrash`'s return addresses on the
stack, and `GameOver` never resets it either. The 6502 stack wraps within page 1, so nothing breaks, but the C64 game
loop will test a flag instead.

**2.** The loop at `DecideWinner` relies on the carry left by the `CMP #$30` that found a player out of lives, which is
always set (equal). It works by accident.

**3.** `FrameDelay` waits `zSpeed` × 256 loop passes on top of the frame's work. Pixel plotting divides by 6 in a loop,
so frames with more drawing run slower. The C64 version runs one game tick per raster frame and turns the speed setting
into pixels per tick; the table is to be calibrated against the Oric ([porting.md](porting.md)).

**5.** The ninth entry (`$B8E0`) is never shown or compared.
