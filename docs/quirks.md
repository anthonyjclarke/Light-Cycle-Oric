# Light Cycle – Original Quirks

Places where the Oric code does something unintended or fragile, read from the disassembly, with what the C64 port does
about each. None is visible to a player as far as the code shows.

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
| 7  | `DrawBonusFrame` uses `zSlowP1` as its loop counter         | `DrawBonusFrame` | Fix: own scratch byte      |
| 8  | A bonus block mid-animation carries over to the next round  | `RoundStart`     | Kept                       |
| 9  | The explosion's moving dots erase the pixels they cross     | `Explosion`      | Kept                       |
| 10 | A carry out of a score's eighth digit writes before it      | `AddDigit`       | Kept (unreachable)         |
| 11 | A tie goes to player 1                                      | `DecideWinner`   | Kept                       |

---

## Notes

**1.** `SP` is set only at cold start. Each crash leaves `MovePlayer`'s and `PlotCheckCrash`'s return addresses on the
stack, and `GameOver` never resets it either. The 6502 stack wraps within page 1, so nothing breaks. On the C64,
`PlotCheckCrash` sets `zCrashed` and returns from `MovePlayer`, and the game loop tests the flag.

**2.** The loop at `DecideWinner` relies on the carry left by the `CMP #$30` that found a player out of lives, which is
always set (equal). It works by accident.

**3.** `FrameDelay` waits `zSpeed` × 256 loop passes on top of the frame's work. Pixel plotting divides by 6 in a loop,
so frames with more drawing run slower. The C64 version measures the Oric's frame times and runs Oric frames against a
time budget on each raster tick, so the speed matches the Oric's on average without its jitter
([porting.md](porting.md)).

**5.** The ninth entry (`$B8E0`) is never shown or compared.

**7.** Leaving `zSlowP1` at `$FF` makes the next `EngineSound` see a change and retune player 1's engine for a frame
until `MovePlayer` sets it again. Harmless, but there is no reason to copy it.

**8.** `RoundStart` does not reset `zBonusState`, so a block that was animating when a cycle crashed finishes its
animation at the same spot in the new arena, even over a new wall or a start position.

**9.** Each explosion particle unplots its previous pixel, so it leaves small gaps in trails, walls and the arena frame.
A cycle can later pass through such a gap.

**10.** `AddDigit` ripples a carry left with `DEY` / `BPL`; past digit 0 it stores at offset `$FF`. A score would need
to pass 99,999,999 first.

**11.** `DecideWinner` declares player 1 the winner unless player 2's score is strictly higher.
