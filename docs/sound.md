# Light Cycle – Sound

The Oric game has no music: it has two engine drones, a start-of-round sweep, a volume test tone and an explosion. All
of it is written straight to the AY-3-8912 through the VIA (`AyWrite`, `AyLoadAll`). The C64 version replaces each with
a SID routine in `c64/src/sound.s`. No recordings yet: the C64 sounds have only been checked to build, not tuned by ear.

---

## The Oric Driver

`AyWrite` writes register A with value X: the register number goes out on VIA port A and is latched by setting the
PCR's CA2/CB2 lines (AY BC1/BDIR), then the value follows the same way. Writes to R7, the mixer, always keep bit 6 set,
because AY port A carries the keyboard column select. `AyLoadAll` writes R0–R13 from a 14-byte table.

| Effect            | Oric routine   | What it writes                                            |
|:------------------|:---------------|:----------------------------------------------------------|
| Engines           | `EngineSound`  | Tone A (P1), tone B (P2); period `$05FE`, `$0480` boosted  |
| Round start       | `StartSweep`   | Periods fall from `$4FE` (A) and `$5FF` (B) to ~`$101`    |
| Volume test tone  | `VolumeScreen` | Tone A, period `$047F`, at the chosen volume              |
| Explosion         | `Explosion`    | `ExplodeAY`: noise on all channels, tones off, envelope   |

An AY tone of period P plays at 1 MHz ÷ 16P, so the engines drone at about 41 Hz, rising to 54 Hz while boosting.
`EngineSound` only retunes a channel when that player's boost state changes. The explosion table sets noise period
`$1F` (the lowest), envelope period `$1904` and shape `$01`, a single decay of about 1.6 s. It is skipped when the
volume is 0.

---

## The SID Equivalents

The SID value for frequency f is f × 2²⁴ ÷ 985248 on a PAL machine, so an AY period P becomes `1064250 / P`
(`SIDFREQ` in `sound.s`). NTSC machines play about 4% sharp; that is not corrected.

| Oric           | C64            | How                                                          |
|:---------------|:---------------|:-------------------------------------------------------------|
| `EngineSound`  | `EngineTone`   | Voices 1 and 2, 50% pulse, the same two pitches               |
| `StartSweep`   | `StartSweep`   | 64 steps × 2 frames (~2.6 s), the same period ramp            |
| `Explosion`    | `ExplosionSfx` | Voice 3 noise, decay 1.5 s to sustain 0; engines gated off    |
| R8/R9 volume   | `SetVolume`    | SID master volume `$D418`, also 0–15                         |

The engines use the SID's envelope only as a gate (attack 0, sustain 15), as the AY tones had fixed volume.
