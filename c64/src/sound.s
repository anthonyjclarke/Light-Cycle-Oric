; Light Cycle (C64) — SID sound
;
; The Oric writes AY registers directly (AyWrite, AyLoadAll). AY and SID
; registers don't correspond, so the game calls these semantic routines
; instead. Pitches come from the Oric's AY periods: an AY tone of period P
; plays at 1 MHz / (16 * P); the SID value for frequency f is
; f * 2^24 / 985248 (PAL clock). Combined: SID = 1064250 / P. NTSC
; machines play about 4% sharp; not corrected.
;
;   Oric                         C64
;   EngineSound  R0-R3 retune    EngineTone  X = player, A = zSlowPn
;   SoundInit / VolumeScreen     InitSound, SetVolume, EnginesOn/Off
;   StartSweep   R0-R3 ramp      StartSweep  (blocking, ~2.5 s)
;   Explosion    AyLoadAll $04B0 ExplosionSfx
;
; Volume 0-15 maps straight onto the SID master volume, as zVolume did on
; the AY's R8/R9.

        .include "hw.inc"
        .include "zp.inc"

        .import WaitTicks
        .export InitSound, SetVolume, EnginesOn, EnginesOff, EngineTone
        .export ExplosionSfx, StartSweep

; AY period -> SID frequency value
.define SIDFREQ(period) (1064250 / (period))

ENGINE_NORMAL   = SIDFREQ($05FE)        ; Oric EngineSound, zSlowPn = 1 (~41 Hz)
ENGINE_BOOST    = SIDFREQ($0480)        ; Oric EngineSound, zSlowPn = 0 (~54 Hz)
NOISE_FREQ      = $0400                 ; low rumble; AY R6 = $1F (slowest noise)
WAVE_PULSE      = $40
WAVE_NOISE      = $80
GATE            = $01

SWEEP_STEPS     = 64
SWEEP_TICKS     = 2                     ; per step: 128 ticks = ~2.6 s PAL

        .segment "CODE"

; Silence the SID, voices 1-2 pulse 50% (engines), voice 3 noise
; (explosion). Volume 0.
InitSound:
        lda     #0
        ldx     #$18
@clear: sta     SID,x
        dex
        bpl     @clear
        sta     zVolume
        lda     #$08                    ; pulse width $0800 = 50%
        sta     SID_V1 + 3
        sta     SID_V2 + 3
        lda     #$00                    ; attack 2 ms, decay 6 ms
        sta     SID_V1 + 5
        sta     SID_V2 + 5
        lda     #$F0                    ; sustain 15, release 6 ms
        sta     SID_V1 + 6
        sta     SID_V2 + 6
        lda     #$0A                    ; explosion: attack 2 ms, decay 1.5 s to sustain 0
        sta     SID_V3 + 5
        lda     #$00
        sta     SID_V3 + 6
        lda     #<NOISE_FREQ
        sta     SID_V3 + 0
        lda     #>NOISE_FREQ
        sta     SID_V3 + 1
        rts

; A = volume 0-15. Preserves X, Y.
SetVolume:
        and     #$0F
        sta     zVolume
        sta     SID_VOLUME
        rts

; Gate both engine voices on at normal pitch. Preserves Y.
EnginesOn:
        lda     #1
        ldx     #0
        jsr     EngineTone
        lda     #1
        ldx     #1
        jsr     EngineTone
        lda     #WAVE_PULSE | GATE
        sta     SID_V1 + 4
        sta     SID_V2 + 4
        rts

EnginesOff:
        lda     #WAVE_PULSE
        sta     SID_V1 + 4
        sta     SID_V2 + 4
        rts

; X = player (0/1), A = 0 boosting / 1 normal (the Oric's zSlowP1/P2).
; Preserves Y.
EngineTone:
        cpx     #0
        beq     :+
        ldx     #7                      ; voice 2
:       cmp     #0
        beq     @boost
        lda     #<ENGINE_NORMAL
        sta     SID_V1 + 0,x
        lda     #>ENGINE_NORMAL
        sta     SID_V1 + 1,x
        rts
@boost: lda     #<ENGINE_BOOST
        sta     SID_V1 + 0,x
        lda     #>ENGINE_BOOST
        sta     SID_V1 + 1,x
        rts

; Engines off, noise burst with a long decay. The Oric's explosion also
; turns the tones off (mixer R7 = $07: noise only). Preserves X, Y.
ExplosionSfx:
        jsr     EnginesOff
        lda     #WAVE_NOISE             ; gate off first so the envelope restarts
        sta     SID_V3 + 4
        lda     #WAVE_NOISE | GATE      ; gate stays on: decays to sustain 0
        sta     SID_V3 + 4
        rts

; Round start: both engines rise from a low drone, as the Oric's
; StartSweep ramps AY periods $4FE -> $101 (A) and $5FF -> $202 (B).
; Blocking; needs the raster IRQ running. Leaves the engines gated on.
StartSweep:
        lda     #WAVE_PULSE | GATE
        sta     SID_V1 + 4
        sta     SID_V2 + 4
        ldy     #0
@step:  lda     SweepALo,y
        sta     SID_V1 + 0
        lda     SweepAHi,y
        sta     SID_V1 + 1
        lda     SweepBLo,y
        sta     SID_V2 + 0
        lda     SweepBHi,y
        sta     SID_V2 + 1
        ldx     #SWEEP_TICKS
        jsr     WaitTicks
        iny
        cpy     #SWEEP_STEPS
        bne     @step
        jmp     EnginesOn

        .segment "RODATA"

; Sweep tables: AY period falling linearly, as in the Oric loop.
.define SWEEP_A(i) SIDFREQ($04FE - ($04FE - $0101) * (i) / (SWEEP_STEPS - 1))
.define SWEEP_B(i) SIDFREQ($05FF - ($05FF - $0202) * (i) / (SWEEP_STEPS - 1))
SweepALo:
        .repeat SWEEP_STEPS, i
        .byte   <SWEEP_A(i)
        .endrepeat
SweepAHi:
        .repeat SWEEP_STEPS, i
        .byte   >SWEEP_A(i)
        .endrepeat
SweepBLo:
        .repeat SWEEP_STEPS, i
        .byte   <SWEEP_B(i)
        .endrepeat
SweepBHi:
        .repeat SWEEP_STEPS, i
        .byte   >SWEEP_B(i)
        .endrepeat
