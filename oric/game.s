; Light Cycle (Oric) — Game block 'GAME' $0400-$1800
; Annotated disassembly — reassembles byte-identical with:
;   cl65 -t none --start-addr <load address> -o out.bin <this file>



        .setcpu "6502"
; Zero page map (game). $00-$08 are scratch. Names with a slash are reused:
;   zX/zY/zDir/zPlayer  $31-$34  "current cycle" while MovePlayer runs
;   zInput     $35      direction bits 8=up 4=down 2=left 1=right, $10=boost
;   zPix/zMask $37-$39  result of HiresAddr: byte pointer and bit mask
;   zP1X..zP2Y $40-$43  cycle positions (also the hi-score entry pointer)
;   zLX0..zLSY $4A-$53  Bresenham line state
;   zSlowP1/2  $54/$55  0 = boosting this frame, 1 = normal speed
;   zLineStep  $60      non-zero: DrawLine returns after one step (particles)
;   zOnePlayer $62      1 = human vs computer (volume screen uses $62/$63 as ptr)
;   zVolume    $67      AY volume 0-15
;   zSpeed     $68      1 (fast) .. 9 (slow): FrameDelay outer count
;   $D0-$D3             random number generator state
;   zFrame     $FF      frame counter

zTmp0           := $0000
zTmp1           := $0001
zTmp2           := $0002
zTmp3           := $0003
zTmp4           := $0004
zTmp5           := $0005
zTmp6           := $0006
zTmp7           := $0007
zTmp8           := $0008
zCurPtr         := $0012
zCurPtrH        := $0013
zLoop           := $0030
zX              := $0031
zY              := $0032
zDir            := $0033
zPlayer         := $0034
zInput          := $0035
zPix            := $0037
zPixH           := $0038
zMask           := $0039
zP1Dir          := $003A
zP2Dir          := $003B
zSaveX          := $003C
zSaveY          := $003D
zSaveA          := $003E
zP1X            := $0040
zP1Y            := $0041
zP2X            := $0042
zP2Y            := $0043
zBonusTmr       := $0044
zBonusState     := $0046
zBonusPtr       := $0047
zBonusPtrH      := $0048
zLX0            := $004A
zLX1            := $004B
zLY0            := $004C
zLY1            := $004D
zLDX            := $004E
zLDY            := $004F
zLErrX          := $0050
zLErrY          := $0051
zLSX            := $0052
zLSY            := $0053
zSlowP1         := $0054
zSlowP2         := $0055
zFlicker        := $0056
zDigPtr         := $0057
zDigPtrH        := $0058
zDigTmp         := $0059
zObA            := $005A
zObB            := $005B
zObC            := $005C
zObD            := $005D
zObE            := $005E
zObF            := $005F
zLineStep       := $0060
zOnePlayer      := $0062
zSliderPtrH     := $0063
zLastSlowP1     := $0064
zLastSlowP2     := $0065
zVolume         := $0067
zSpeed          := $0068
zRnd2           := $00D2
zRnd3           := $00D3
zRndEnd         := $00D4
zFrame          := $00FF
ROM_TMP20F      := $020F    ; ROM scratch byte, borrowed by PcrModify
ROM_VAR22B      := $022B    ; ROM system variable (set to $40 at start; meaning unverified)
ROM_CURCOL      := $0269    ; ROM text cursor column (unverified)
ROM_SCRFLAGS    := $026A    ; ROM screen/keyboard flags; bit 3 = keyclick off
ROM_TIMERS      := $0271    ; ROM IRQ countdown timers $0271-$0277
ROM_TIMERS1     := $0272    ; ROM timer slots (word pairs)
ROM_TIMERS1H    := $0273
ROM_KEY         := $02DF    ; ROM IRQ keyboard: last key, bit 7 set = new key
VIA_ORB         := $0300    ; VIA port B: PB0-2 keyboard row, PB3 key sense, PB4 printer strobe, PB6 tape relay, PB7 tape out
VIA_DDRB        := $0302    ; VIA data direction B
VIA_DDRA        := $0303    ; VIA data direction A (AY data bus)
VIA_T1CL        := $0304    ; VIA timer 1 counter low
VIA_T1CH        := $0305    ; VIA timer 1 counter high
VIA_T1LL        := $0306    ; VIA timer 1 latch low
VIA_T1LH        := $0307    ; VIA timer 1 latch high
VIA_ACR         := $030B    ; VIA auxiliary control
VIA_PCR         := $030C    ; VIA peripheral control: CA2=AY BC1, CB2=AY BDIR
VIA_IER         := $030E    ; VIA interrupt enable
VIA_ORA_NH      := $030F    ; VIA port A, no handshake (AY data bus)
HIRES_CHARSET   := $9800    ; HIRES-mode character set (std $9800, alt $9C00)
PART_LIFE       := $9D00    ; Explosion particle tables (32 each) in HIRES alt-charset RAM
PART_X          := $9D20
PART_TX         := $9D40
PART_Y          := $9D60
PART_TY         := $9D80
PART_DX         := $9DA0
PART_DY         := $9DC0
PART_SX         := $9DE0
PART_SY         := $9E00
PART_ERRX       := $9E20
PART_ERRY       := $9E40
HIRES_ROW0_C1   := $A001    ; HIRES bitmap row 0, column 1
TEXT_CHARSET    := $B400    ; TEXT-mode standard character set
HISCORE_TAB     := $B800    ; High-score table: 8 x 28-byte entries in TEXT alt-charset RAM
HISCORE_NAME0   := $B808    ; Entry 0 name field
HISCORE_ENTRY1  := $B81C    ; Entry 1
NEW_SCORE       := $B900    ; Winner's score, carried across the charset shuffle
NEW_NAME        := $B920    ; Winner's name, carried across the charset shuffle
TEXT_SCREEN     := $BB80    ; TEXT screen 40x28
HIRES_STATUS0   := $BF68    ; HIRES-mode text row 0 (of 3)
HIRES_STATUS1   := $BF90    ; HIRES-mode text row 1
HIRES_STATUS2   := $BFB8    ; HIRES-mode text row 2
SCREEN_LAST     := $BFDF    ; Last screen byte: a $1A/$1E here switches TEXT/HIRES

; --------------------------------------------------------------------------
; Autorun entry point (CLOAD'd block starts here).
; --------------------------------------------------------------------------
Entry:  jmp     Start                   ; 0400


; --------------------------------------------------------------------------
; Unreferenced: leftover bytes.
; --------------------------------------------------------------------------
Unused0403:
        .byte   $FF,$93,$0C,$10,$27,$48,$9C,$40; 0403
        .byte   $40,$DD,$22,$C0,$FE,$00,$00,$00; 040B
        .byte   $00,$00,$00,$00,$00,$00,$00,$00; 0413
        .byte   $00,$00,$00,$00,$00,$00,$00,$00; 041B
        .byte   $00                     ; 0423

; --------------------------------------------------------------------------
; ViaGameSetup: VIA register numbers (read with Y=6..0, overlaps next table).
; --------------------------------------------------------------------------
ViaRegIdx:
        .byte   $05,$04,$0B,$02,$0C,$08 ; 0424

; --------------------------------------------------------------------------
; ViaGameSetup: values for those VIA registers.
; --------------------------------------------------------------------------
ViaRegVal:
        .byte   $00,$D0,$C0,$FF,$10,$F4 ; 042A

; --------------------------------------------------------------------------
; Row offsets (x40) for the 6-line bonus block. Byte 0 doubles as ViaRegVal[6].
; --------------------------------------------------------------------------
BonusRowOfs:
        .byte   $00,$28,$50,$78,$A0,$C8 ; 0430

; --------------------------------------------------------------------------
; Bonus block frames: 6 HIRES bytes each (box / ring / dot / blank).
; --------------------------------------------------------------------------
BonusGfx:
        .byte   $7F,$61,$6D,$6D,$61,$7F,$7F,$73; 0436
        .byte   $61,$61,$73,$7F,$7F,$73,$6D,$6D; 043E
        .byte   $73,$7F,$40,$40,$40,$40,$40,$40; 0446

; --------------------------------------------------------------------------
; Animation sequence: offsets into BonusGfx.
; --------------------------------------------------------------------------
BonusFrameOfs:
        .byte   $00,$06,$0C,$06,$00,$12 ; 044E

; --------------------------------------------------------------------------
; HIRES status row 0 (40 bytes incl. attributes): PLAYER 1 / TIME / P2 name.
; --------------------------------------------------------------------------
StatusText:
        .byte   $14,$03                 ; 0454
        .byte   "PLAYER 1  {|  "        ; 0456
                                        ; 045E
        .byte   $00,$17                 ; 0464
        .byte   "TIME"                  ; 0466
        .byte   $06,$14                 ; 046A
        .byte   "  {|  "                ; 046C

; --------------------------------------------------------------------------
; P2 name slot inside StatusText; overwritten with COMPUTER or PLAYER 2.
; --------------------------------------------------------------------------
StatusP2Name:
        .byte   "COMPUTER  "            ; 0472
                                        ; 047A

; --------------------------------------------------------------------------
; Unreferenced.
; --------------------------------------------------------------------------
Unused047C:
        .byte   $02,$06,$04,$0C,$08,$09,$01,$03; 047C
        .byte   $FF,$FF,$FF,$55         ; 0484

; --------------------------------------------------------------------------
; Attributes left of TIME digits (double-height).
; --------------------------------------------------------------------------
TimeAttrL:
        .byte   $0A,$00,$12             ; 0488

; --------------------------------------------------------------------------
; Attributes right of TIME digits.
; --------------------------------------------------------------------------
TimeAttrR:
        .byte   $07,$10,$08,$55,$55     ; 048B

; --------------------------------------------------------------------------
; Explosion: 32 signed X offsets for particle targets.
; --------------------------------------------------------------------------
ExplodeDX:
        .byte   $0F,$0A,$08,$05,$03,$00,$FE,$FD; 0490
        .byte   $FE,$F9,$F8,$F7,$F5,$FB,$F7,$FE; 0498
        .byte   $F8,$FD,$01,$05,$06,$05,$0A,$F3; 04A0
        .byte   $03,$0C,$0E,$0B,$F9,$01,$F2,$ED; 04A8

; --------------------------------------------------------------------------
; Explosion: AY registers R0-R13 (noise on all channels, envelope decay).
; --------------------------------------------------------------------------
ExplodeAY:
        .byte   $00,$00,$00,$00,$00,$00,$1F,$07; 04B0
        .byte   $10,$10,$10,$04,$19,$01,$A2,$55; 04B8

; --------------------------------------------------------------------------
; Explosion: 32 signed Y offsets for particle targets.
; --------------------------------------------------------------------------
ExplodeDY:
        .byte   $00,$FE,$FB,$FA,$F6,$F9,$F5,$FE; 04C0
        .byte   $F4,$F7,$FA,$FF,$FC,$01,$03,$03; 04C8
        .byte   $06,$08,$05,$02,$05,$08,$02,$02; 04D0
        .byte   $FD,$06,$F5,$0C,$0B,$F0,$F5,$FE; 04D8

; --------------------------------------------------------------------------
; Unreferenced.
; --------------------------------------------------------------------------
Unused04E0:
        .byte   $20,$00,$20,$00,$20,$00,$20,$00; 04E0
        .byte   $00,$00,$00,$55,$55,$55,$55,$55; 04E8

; --------------------------------------------------------------------------
; Glyphs for chars '{' '|': little light-cycle icon on the status line.
; --------------------------------------------------------------------------
GlyphBike:
        .byte   $00,$00,$03,$04,$1F,$27,$27,$18; 04F0
        .byte   $00,$00,$30,$3C,$3E,$39,$39,$06; 04F8

; --------------------------------------------------------------------------
; Volume screen text.
; --------------------------------------------------------------------------
VolText1:
        .byte   $04,$13                 ; 0500
        .byte   "SET VOLUME LEVEL USING:- ^ CURS"; 0502
                                        ; 050A
                                        ; 0512
                                        ; 051A
        .byte   "OR UP"                 ; 0521
        .byte   $00                     ; 0526
        .byte   " "                     ; 0527
VolText2:
        .byte   $04,$13                 ; 0528
        .byte   "} CURSOR DOWNU"        ; 052A
                                        ; 0532
VolOff: .byte   $07,$11                 ; 0538
        .byte   "OFF "                  ; 053A
        .byte   $10,$00                 ; 053E
VolLoud:.byte   $07,$11                 ; 0540
        .byte   "LOUD "                 ; 0542
        .byte   $10,$00,$00,$00,$00,$00,$00,$00; 0547
        .byte   $00                     ; 054F

; --------------------------------------------------------------------------
; Glyphs for '}' (down arrow) and '~' (slider marker / left arrow).
; --------------------------------------------------------------------------
GlyphArrows:
        .byte   $00,$00,$08,$08,$08,$2A,$14,$08; 0550
        .byte   $00,$00,$08,$10,$3F,$10,$08,$00; 0558
VolText3:
        .byte   $04,$12                 ; 0560
        .byte   "PRESS"                 ; 0562
        .byte   $00                     ; 0567
        .byte   "RETURN"                ; 0568
        .byte   $04                     ; 056E
        .byte   "WHEN FINISHED "        ; 056F
                                        ; 0577
        .byte   $10                     ; 057D
        .byte   "UU"                    ; 057E

; --------------------------------------------------------------------------
; NUMBER OF PLAYERS (1 or 2)?
; --------------------------------------------------------------------------
PlayersPrompt:
        .byte   $05,$13                 ; 0580
        .byte   "NUMBER OF PLAYERS"     ; 0582
                                        ; 058A
                                        ; 0592
        .byte   $00                     ; 0593
        .byte   "(1 or 2)"              ; 0594
        .byte   $05                     ; 059C
        .byte   "?"                     ; 059D
        .byte   $00,$11                 ; 059E
        .byte   " "                     ; 05A0

; --------------------------------------------------------------------------
; HIRES bit for x MOD 6 (bit 6 always set = pixel data byte).
; --------------------------------------------------------------------------
PixelMask:
        .byte   $60,$50,$48,$44,$42,$41,$55; 05A1

; --------------------------------------------------------------------------
; SPEED (1-Fast TO 9-Slow)?
; --------------------------------------------------------------------------
SpeedPrompt:
        .byte   $01                     ; 05A8
        .byte   " SPEED"                ; 05A9
        .byte   $02                     ; 05AF
        .byte   "(1-Fast"               ; 05B0
        .byte   $03                     ; 05B7
        .byte   " TO "                  ; 05B8
        .byte   $05                     ; 05BC
        .byte   "9-Slow)"               ; 05BD
        .byte   $06                     ; 05C4
        .byte   "?"                     ; 05C5
        .byte   $07                     ; 05C6
        .byte   " "                     ; 05C7
        .byte   $00                     ; 05C8
        .byte   "UUUUUUU"               ; 05C9

; --------------------------------------------------------------------------
; LIGHT CYCLE HEROES title row.
; --------------------------------------------------------------------------
HiTitle:.byte   $11,$07,$0A             ; 05D0
        .byte   "       LIGHT CYCLE HEROES   "; 05D3
                                        ; 05DB
                                        ; 05E3
                                        ; 05EB

; --------------------------------------------------------------------------
; = RankInk - $31: indexed by ASCII '1'..'8'.
; --------------------------------------------------------------------------
RankInkBase:
        .byte   "        "              ; 05EF
        .byte   $00                     ; 05F7
NameComputer:
        .byte   "COMPUTER"              ; 05F8
NamePlayer2:
        .byte   "PLAYER 2"              ; 0600

; --------------------------------------------------------------------------
; Default hi-score entry: 8-byte score field + name + CR.
; --------------------------------------------------------------------------
HiDefault:
        .byte   "  "                    ; 0608
        .byte   $10                     ; 060A
        .byte   "  500  P.S.S."         ; 060B
                                        ; 0613
        .byte   $0D                     ; 0618

; --------------------------------------------------------------------------
; Random arena paper colour attribute: red / blue / magenta / black.
; --------------------------------------------------------------------------
PaperColours:
        .byte   $11,$14,$15,$10,$00,$00,$00; 0619

; --------------------------------------------------------------------------
; Ink colour per hi-score rank.
; --------------------------------------------------------------------------
RankInk:.byte   $01,$02,$03,$04,$05,$06,$05,$04; 0620
        .byte   $03,$02,$01,$55,$55,$55,$55,$55; 0628

; --------------------------------------------------------------------------
; Bottom rows: PRESS SPACE BAR TO PLAY AGAIN / V TO ADJUST VOLUME.
; --------------------------------------------------------------------------
PlayAgainText:
        .byte   $14,$07                 ; 0630
        .byte   "PRESS"                 ; 0632
        .byte   $00,$17,$0C             ; 0637
        .byte   "SPACE BAR"             ; 063A
                                        ; 0642
        .byte   $08,$07,$14             ; 0643
        .byte   "TO PLAY AGAIN     "    ; 0646
                                        ; 064E
                                        ; 0656
        .byte   $14,$07                 ; 0658
        .byte   "            "          ; 065A
                                        ; 0662
        .byte   $00                     ; 0666
        .byte   " "                     ; 0667
        .byte   $17,$0C                 ; 0668
        .byte   "V"                     ; 066A
        .byte   $08,$07,$14             ; 066B
        .byte   "TO ADJUST VOLUME"      ; 066E
                                        ; 0676
        .byte   $0C,$0C                 ; 067E

; --------------------------------------------------------------------------
; PLEASE ENTER YOUR NAME.
; --------------------------------------------------------------------------
EnterNameText:
        .byte   $0C,$06                 ; 0680
        .byte   "PLEASE ENTER YOUR NAME"; 0682
                                        ; 068A
                                        ; 0692
        .byte   $10,$07                 ; 0698
        .byte   "UUUUUU"                ; 069A

; --------------------------------------------------------------------------
; P1 keys (2 up, A down, W left, E right, R boost): keyboard matrix row...
; --------------------------------------------------------------------------
KeyRowP1:
        .byte   $02,$06,$06,$06,$01     ; 06A0

; --------------------------------------------------------------------------
; ...column mask (AY port A, active low)...
; --------------------------------------------------------------------------
KeyColP1:
        .byte   $BF,$DF,$7F,$F7,$FB     ; 06A5

; --------------------------------------------------------------------------
; ...and the zInput bit it sets.
; --------------------------------------------------------------------------
KeyBitP1:
        .byte   $08,$04,$02,$01,$10     ; 06AA

; --------------------------------------------------------------------------
; P2 keys (] up, R-SHIFT down, ; left, ' right, L boost).
; --------------------------------------------------------------------------
KeyRowP2:
        .byte   $05,$07,$03,$03,$07     ; 06AF
KeyColP2:
        .byte   $BF,$EF,$FB,$7F,$FD     ; 06B4
KeyBitP2:
        .byte   $08,$04,$02,$01,$10,$55,$55; 06B9

; --------------------------------------------------------------------------
; Cold start: reset stack, clear game zero page $30-$70, keyclick off,
; build custom glyphs and the hi-score table, then volume -> menu -> game.
; --------------------------------------------------------------------------
Start:  ldx     #$FF                    ; 06C0
        txs                             ; 06C2
        ldx     #$40                    ; 06C3  clear $30-$70
        lda     #$00                    ; 06C5
L06C7:  sta     zLoop,x                 ; 06C7
        dex                             ; 06C9
        bpl     L06C7                   ; 06CA
        lda     #$08                    ; 06CC  keyclick off
        ora     ROM_SCRFLAGS            ; 06CE
        sta     ROM_SCRFLAGS            ; 06D1
        lda     #$00                    ; 06D4  volume 0
        sta     zVolume                 ; 06D6
        lda     #$40                    ; 06D8
        sta     ROM_VAR22B              ; 06DA
        jsr     InitHiscores            ; 06DD
        jsr     DefineGlyphs            ; 06E0

; --------------------------------------------------------------------------
; 'V' on the play-again screen re-enters here.
; --------------------------------------------------------------------------
VolumeThenMenu:
        jsr     ClearTextScreen         ; 06E3
        jsr     VolumeScreen            ; 06E6

; --------------------------------------------------------------------------
; Players + speed prompts, switch to HIRES, reset scores, play.
; --------------------------------------------------------------------------
MainMenu:
        jsr     TextModeCls             ; 06E9
        jsr     AskPlayersAndSpeed      ; 06EC
        jsr     CharsetToHires          ; 06EF
        jsr     ClearHires              ; 06F2
        jsr     ResetScores             ; 06F5
        jmp     RoundStart              ; 06F8  -> round loop (never returns)


; --------------------------------------------------------------------------
; Hide cursor, clear text screen, force TEXT mode via last screen byte.
; --------------------------------------------------------------------------
TextModeCls:
        jsr     HideCursor              ; 06FB
        jsr     ClearTextScreen         ; 06FE
        lda     #$1A                    ; 0701  $1A = TEXT 50 Hz attribute
        sta     SCREEN_LAST             ; 0703
        rts                             ; 0706


; --------------------------------------------------------------------------
; After the winner flash: ~1.5 s pause, copy the HIRES charset area back to
; $B400 (this also carries NEW_SCORE/NEW_NAME from $9D00/$9D20 to $B900/$B920),
; then hi-score entry and back to the menu. NOTE: SP is never reset here, so
; the 4 bytes leaked per crash (JMP out of nested JSRs) wrap harmlessly.
; --------------------------------------------------------------------------
GameOver:
        lda     #$0A                    ; 0707
        sta     zTmp1                   ; 0709
L070B:  jsr     Delay                   ; 070B
        dec     zTmp1                   ; 070E
        bne     L070B                   ; 0710
        jsr     CharsetToText           ; 0712
        jsr     TextModeCls             ; 0715
        jsr     TextModeCls             ; 0718
        jsr     HideCursor              ; 071B
        jsr     HiscoreEntry            ; 071E
        jmp     MainMenu                ; 0721


; --------------------------------------------------------------------------
; Fill 9 x 28-byte slots at $B800 with the 17-byte default entry.
; --------------------------------------------------------------------------
InitHiscores:
        lda     #$08                    ; 0724
        sta     zTmp0                   ; 0726
        ldy     #$00                    ; 0728
L072A:  ldx     #$00                    ; 072A
L072C:  lda     HiDefault,x             ; 072C
        sta     HISCORE_TAB,y           ; 072F  into TEXT alt charset RAM
        inx                             ; 0732
        iny                             ; 0733
        cpx     #$11                    ; 0734
        bne     L072C                   ; 0736
        tya                             ; 0738
        clc                             ; 0739
        adc     #$0B                    ; 073A
        tay                             ; 073C
        dec     zTmp0                   ; 073D
        bpl     L072A                   ; 073F
        rts                             ; 0741


; --------------------------------------------------------------------------
; Block until ROM IRQ delivers a key; return it in A (bit 7 stripped).
; --------------------------------------------------------------------------
WaitKey:lda     ROM_KEY                 ; 0742
        beq     WaitKey                 ; 0745
        and     #$7F                    ; 0747  strip 'new key' flag
        pha                             ; 0749
        lda     #$00                    ; 074A
        sta     ROM_KEY                 ; 074C
        pla                             ; 074F
        rts                             ; 0750

AskPlayersAndSpeed:
        jsr     ClearTextScreen         ; 0751
        jsr     AskPlayers              ; 0754
        jsr     Delay                   ; 0757
        jsr     ClearTextScreen         ; 075A
        jsr     AskSpeed                ; 075D
        jsr     Delay                   ; 0760
        rts                             ; 0763


; --------------------------------------------------------------------------
; Busy-wait ~0.15 s (12 x 10 x 256 DEY loops).
; --------------------------------------------------------------------------
Delay:  lda     #$0C                    ; 0764
        sta     zTmp0                   ; 0766
L0768:  ldx     #$0A                    ; 0768
        ldy     #$00                    ; 076A
L076C:  dey                             ; 076C
        bne     L076C                   ; 076D
        dex                             ; 076F
        bne     L076C                   ; 0770
        dec     zTmp0                   ; 0772
        bne     L0768                   ; 0774
        rts                             ; 0776


; --------------------------------------------------------------------------
; Blank the cursor cell and point the ROM cursor at $C0C0 (ROM) so it vanishes.
; --------------------------------------------------------------------------
HideCursor:
        lda     #$20                    ; 0777
        ldy     #$00                    ; 0779
        sta     (zCurPtr),y             ; 077B
        sei                             ; 077D
        lda     #$C0                    ; 077E  cursor pointer -> ROM space
        sta     zCurPtr                 ; 0780
        sta     zCurPtrH                ; 0782
        cli                             ; 0784
        rts                             ; 0785


; --------------------------------------------------------------------------
; 1 -> zOnePlayer=1, P2 named COMPUTER; 2 -> PLAYER 2.
; --------------------------------------------------------------------------
AskPlayers:
        ldx     #$20                    ; 0786
L0788:  lda     PlayersPrompt,x         ; 0788
        sta     $BDB6,x                 ; 078B  row 14 col 30
        dex                             ; 078E
        bpl     L0788                   ; 078F
L0791:  jsr     WaitKey                 ; 0791
        cmp     #$31                    ; 0794  '1'
        beq     L079E                   ; 0796
        cmp     #$32                    ; 0798  '2'
        beq     L07B1                   ; 079A
        bne     L0791                   ; 079C
L079E:  sta     $BDD6                   ; 079E
        lda     #$01                    ; 07A1
        sta     zOnePlayer              ; 07A3
        ldx     #$07                    ; 07A5
L07A7:  lda     NameComputer,x          ; 07A7
        sta     StatusP2Name,x          ; 07AA
        dex                             ; 07AD
        bpl     L07A7                   ; 07AE
        rts                             ; 07B0

L07B1:  sta     $BDD6                   ; 07B1
        lda     #$00                    ; 07B4
        sta     zOnePlayer              ; 07B6
        ldx     #$07                    ; 07B8
L07BA:  lda     NamePlayer2,x           ; 07BA
        sta     StatusP2Name,x          ; 07BD
        dex                             ; 07C0
        bpl     L07BA                   ; 07C1
        rts                             ; 07C3


; --------------------------------------------------------------------------
; Digit 1-9 -> zSpeed.
; --------------------------------------------------------------------------
AskSpeed:
        ldx     #$20                    ; 07C4
L07C6:  lda     SpeedPrompt,x           ; 07C6
        sta     $BDB6,x                 ; 07C9
        dex                             ; 07CC
        bpl     L07C6                   ; 07CD
L07CF:  jsr     WaitKey                 ; 07CF
        cmp     #$31                    ; 07D2  accept '1'..'9'
        bcc     L07CF                   ; 07D4
        cmp     #$3A                    ; 07D6
        bcs     L07CF                   ; 07D8
        sta     $BDD6                   ; 07DA
        and     #$0F                    ; 07DD  ASCII -> 1..9
        sta     zSpeed                  ; 07DF
        rts                             ; 07E1


; --------------------------------------------------------------------------
; Volume screen: rainbow bar of 16 rows, '~' marker moved with cursor
; up/down, plays a test tone through AY channel A; RETURN to accept.
; --------------------------------------------------------------------------
VolumeScreen:
        jsr     HideCursor              ; 07E2
        ldx     #$27                    ; 07E5
L07E7:  lda     VolText1,x              ; 07E7
        sta     $BBA8,x                 ; 07EA
        dex                             ; 07ED
        bpl     L07E7                   ; 07EE
        ldx     #$0E                    ; 07F0
L07F2:  lda     VolText2,x              ; 07F2
        sta     $BBE9,x                 ; 07F5
        dex                             ; 07F8
        bpl     L07F2                   ; 07F9
        ldx     #$06                    ; 07FB
L07FD:  lda     VolOff,x                ; 07FD
        sta     $BC2A,x                 ; 0800
        dex                             ; 0803
        bpl     L07FD                   ; 0804
        ldx     #$07                    ; 0806
L0808:  lda     VolLoud,x               ; 0808
        sta     $BE81,x                 ; 080B
        dex                             ; 080E
        bpl     L0808                   ; 080F
        lda     #$32                    ; 0811
        sta     zTmp0                   ; 0813
        lda     #$BC                    ; 0815
        sta     zTmp1                   ; 0817
        lda     #$11                    ; 0819
        sta     zTmp2                   ; 081B
        ldx     #$0F                    ; 081D  16 rainbow rows
L081F:  lda     zTmp2                   ; 081F
        ldy     #$00                    ; 0821
        sta     (zTmp0),y               ; 0823
        ldy     #$03                    ; 0825
        lda     #$10                    ; 0827  $10 = paper black after the bar
        sta     (zTmp0),y               ; 0829
        clc                             ; 082B
        lda     zTmp0                   ; 082C
        adc     #$28                    ; 082E
        bcc     L0834                   ; 0830
        inc     zTmp1                   ; 0832
L0834:  sta     zTmp0                   ; 0834
        ldy     zTmp2                   ; 0836
        iny                             ; 0838
        cpy     #$17                    ; 0839
        bne     L083F                   ; 083B
        ldy     #$11                    ; 083D
L083F:  sty     zTmp2                   ; 083F
        dex                             ; 0841
        bpl     L081F                   ; 0842
        ldx     #$1D                    ; 0844
L0846:  lda     VolText3,x              ; 0846
        sta     $BEF6,x                 ; 0849
        dex                             ; 084C
        bpl     L0846                   ; 084D
        lda     #$0E                    ; 084F
        sta     zOnePlayer              ; 0851
        lda     #$BC                    ; 0853
        sta     zSliderPtrH             ; 0855
        ldx     zVolume                 ; 0857
        inx                             ; 0859
L085A:  clc                             ; 085A
        lda     zOnePlayer              ; 085B
        adc     #$28                    ; 085D
        bcc     L0863                   ; 085F
        inc     zSliderPtrH             ; 0861
L0863:  sta     zOnePlayer              ; 0863
        dex                             ; 0865
        bne     L085A                   ; 0866
        ldy     #$00                    ; 0868
        lda     #$7E                    ; 086A  '~' slider marker
        sta     (zOnePlayer),y          ; 086C
L086E:  lda     #$07                    ; 086E  R7 mixer: tone A only
        ldx     #$F8                    ; 0870
        jsr     AyWrite                 ; 0872
        lda     #$08                    ; 0875  R8 vol A = zVolume
        ldx     zVolume                 ; 0877
        jsr     AyWrite                 ; 0879
        lda     #$00                    ; 087C  R0 tone A fine
        ldx     #$7F                    ; 087E
        jsr     AyWrite                 ; 0880
        lda     #$01                    ; 0883  R1 tone A coarse
        ldx     #$04                    ; 0885
        jsr     AyWrite                 ; 0887
L088A:  jsr     WaitKey                 ; 088A
        cmp     #$0A                    ; 088D  cursor down
        beq     L08C1                   ; 088F
        cmp     #$0B                    ; 0891  cursor up
        beq     L08A1                   ; 0893
        cmp     #$0D                    ; 0895  RETURN
        bne     L088A                   ; 0897
        lda     #$08                    ; 0899  silence A
        ldx     #$00                    ; 089B
        jsr     AyWrite                 ; 089D
        rts                             ; 08A0

L08A1:  lda     zVolume                 ; 08A1
        cmp     #$00                    ; 08A3
        beq     L088A                   ; 08A5
        dec     zVolume                 ; 08A7
        lda     #$20                    ; 08A9
        ldy     #$00                    ; 08AB
        sta     (zOnePlayer),y          ; 08AD
        sec                             ; 08AF
        lda     zOnePlayer              ; 08B0
        sbc     #$28                    ; 08B2
        bcs     L08B8                   ; 08B4
        dec     zSliderPtrH             ; 08B6
L08B8:  sta     zOnePlayer              ; 08B8
        lda     #$7E                    ; 08BA
        sta     (zOnePlayer),y          ; 08BC
        jmp     L086E                   ; 08BE

L08C1:  lda     zVolume                 ; 08C1
        cmp     #$0F                    ; 08C3
        bcs     L088A                   ; 08C5
        inc     zVolume                 ; 08C7
        lda     #$20                    ; 08C9
        ldy     #$00                    ; 08CB
        sta     (zOnePlayer),y          ; 08CD
        clc                             ; 08CF
        lda     zOnePlayer              ; 08D0
        adc     #$28                    ; 08D2
        bcc     L08D8                   ; 08D4
        inc     zSliderPtrH             ; 08D6
L08D8:  sta     zOnePlayer              ; 08D8
        lda     #$7E                    ; 08DA
        sta     (zOnePlayer),y          ; 08DC
        jmp     L086E                   ; 08DE


; --------------------------------------------------------------------------
; In: X = pixel x (0-239), Y = pixel y (0-199).
; Out: zPix = $A000 + 40*y + x/6, zMask = PixelMask[x mod 6]. Preserves A/X/Y.
; --------------------------------------------------------------------------
HiresAddr:
        stx     zSaveX                  ; 08E1
        sty     zSaveY                  ; 08E3
        sta     zSaveA                  ; 08E5
        stx     zTmp4                   ; 08E7
        sty     zTmp0                   ; 08E9
        lda     #$00                    ; 08EB
        sta     zTmp1                   ; 08ED
        ldx     #$05                    ; 08EF  zTmp0/1 = y*32, zTmp2/3 = y*8
L08F1:  asl     zTmp0                   ; 08F1
        rol     zTmp1                   ; 08F3
        cpx     #$03                    ; 08F5
        bne     L0901                   ; 08F7
        lda     zTmp0                   ; 08F9
        sta     zTmp2                   ; 08FB
        lda     zTmp1                   ; 08FD
        sta     zTmp3                   ; 08FF
L0901:  dex                             ; 0901
        bne     L08F1                   ; 0902
        lda     #$00                    ; 0904
        sta     zTmp5                   ; 0906
        ldx     zTmp4                   ; 0908
        stx     zTmp6                   ; 090A
L090C:  lda     zTmp6                   ; 090C  divide x by 6 (repeated subtract)
        sec                             ; 090E
        sbc     #$06                    ; 090F
        bcc     L091A                   ; 0911
        inc     zTmp5                   ; 0913
        sta     zTmp6                   ; 0915
        jmp     L090C                   ; 0917

L091A:  clc                             ; 091A
        lda     zTmp1                   ; 091B
        adc     zTmp3                   ; 091D
        sta     zTmp8                   ; 091F
        clc                             ; 0921
        lda     zTmp0                   ; 0922
        adc     zTmp2                   ; 0924
        bcc     L092A                   ; 0926
        inc     zTmp8                   ; 0928
L092A:  sta     zTmp7                   ; 092A
        clc                             ; 092C
        lda     zTmp5                   ; 092D
        adc     zTmp7                   ; 092F
        bcc     L0935                   ; 0931
        inc     zTmp8                   ; 0933
L0935:  sta     zTmp7                   ; 0935
        clc                             ; 0937  + $A000
        lda     zTmp8                   ; 0938
        adc     #$A0                    ; 093A
        sta     zTmp8                   ; 093C
        ldx     zTmp6                   ; 093E
        lda     PixelMask,x             ; 0940
        sta     zMask                   ; 0943
        lda     zTmp7                   ; 0945
        sta     zPix                    ; 0947
        lda     zTmp8                   ; 0949
        sta     zPixH                   ; 094B
        ldx     zSaveX                  ; 094D
        ldy     zSaveY                  ; 094F
        lda     zSaveA                  ; 0951
        rts                             ; 0953


; --------------------------------------------------------------------------
; A added to the ASCII decimal number at (zDigPtr), units digit (Y=7).
; --------------------------------------------------------------------------
AddDigitUnits:
        ldy     #$07                    ; 0954

; --------------------------------------------------------------------------
; Add A to digit Y of the 8-char ASCII number at (zDigPtr), rippling carry left.
; --------------------------------------------------------------------------
AddDigit:
        sta     zDigTmp                 ; 0956
        lda     (zDigPtr),y             ; 0958
        cmp     #$20                    ; 095A
        bne     L0960                   ; 095C
        lda     #$30                    ; 095E  treat leading space as '0'
L0960:  clc                             ; 0960
        adc     zDigTmp                 ; 0961
        cmp     #$3A                    ; 0963  carry out of this digit?
        bmi     L0971                   ; 0965
        sec                             ; 0967
        sbc     #$0A                    ; 0968
        sta     (zDigPtr),y             ; 096A
        lda     #$01                    ; 096C
        dey                             ; 096E
        bpl     AddDigit                ; 096F
L0971:  sta     (zDigPtr),y             ; 0971
        rts                             ; 0973


; --------------------------------------------------------------------------
; When either player's boost state changes, retune AY ch A (P1) / ch B (P2).
; --------------------------------------------------------------------------
EngineSound:
        lda     zSlowP1                 ; 0974
        cmp     zLastSlowP1             ; 0976
        beq     L09A6                   ; 0978
        lda     #$08                    ; 097A
        ldx     zVolume                 ; 097C
        jsr     AyWrite                 ; 097E
        lda     zSlowP1                 ; 0981
        sta     zLastSlowP1             ; 0983
        bne     L0998                   ; 0985
        lda     #$01                    ; 0987
        ldx     #$04                    ; 0989
        jsr     AyWrite                 ; 098B
        lda     #$00                    ; 098E
        ldx     #$80                    ; 0990
        jsr     AyWrite                 ; 0992
        jmp     L09A6                   ; 0995

L0998:  lda     #$01                    ; 0998
        ldx     #$05                    ; 099A
        jsr     AyWrite                 ; 099C
        lda     #$00                    ; 099F
        ldx     #$FE                    ; 09A1
        jsr     AyWrite                 ; 09A3
L09A6:  lda     zSlowP2                 ; 09A6
        cmp     zLastSlowP2             ; 09A8
        beq     L09D8                   ; 09AA
        lda     #$09                    ; 09AC
        ldx     zVolume                 ; 09AE
        jsr     AyWrite                 ; 09B0
        lda     zSlowP2                 ; 09B3
        sta     zLastSlowP2             ; 09B5
        bne     L09CA                   ; 09B7
        lda     #$03                    ; 09B9
        ldx     #$05                    ; 09BB
        jsr     AyWrite                 ; 09BD
        lda     #$02                    ; 09C0
        ldx     #$80                    ; 09C2
        jsr     AyWrite                 ; 09C4
        jmp     L09D8                   ; 09C7

L09CA:  lda     #$03                    ; 09CA
        ldx     #$05                    ; 09CC
        jsr     AyWrite                 ; 09CE
        lda     #$02                    ; 09D1
        ldx     #$FE                    ; 09D3
        jsr     AyWrite                 ; 09D5
L09D8:  rts                             ; 09D8


; --------------------------------------------------------------------------
; Round start: both engines sweep up in pitch while the volume ramps.
; --------------------------------------------------------------------------
StartSweep:
        lda     #$08                    ; 09D9
        ldx     zVolume                 ; 09DB
        jsr     AyWrite                 ; 09DD
        lda     #$01                    ; 09E0
        ldx     #$04                    ; 09E2
        jsr     AyWrite                 ; 09E4
        lda     #$09                    ; 09E7
        ldx     zVolume                 ; 09E9
        jsr     AyWrite                 ; 09EB
        lda     #$03                    ; 09EE
        ldx     #$04                    ; 09F0
        jsr     AyWrite                 ; 09F2
        ldx     #$04                    ; 09F5
        sta     zTmp2                   ; 09F7
        inx                             ; 09F9
        stx     zTmp3                   ; 09FA
L09FC:  ldx     #$FE                    ; 09FC
        stx     zTmp0                   ; 09FE
        inx                             ; 0A00
        stx     zTmp1                   ; 0A01
L0A03:  lda     #$03                    ; 0A03
        ldx     zTmp3                   ; 0A05
        jsr     AyWrite                 ; 0A07
        lda     #$00                    ; 0A0A
        ldx     zTmp0                   ; 0A0C
        jsr     AyWrite                 ; 0A0E
        lda     #$01                    ; 0A11
        ldx     zTmp2                   ; 0A13
        jsr     AyWrite                 ; 0A15
        lda     #$02                    ; 0A18
        ldx     zTmp1                   ; 0A1A
        jsr     AyWrite                 ; 0A1C
        ldy     #$00                    ; 0A1F
L0A21:  nop                             ; 0A21
        nop                             ; 0A22
        dey                             ; 0A23
        bne     L0A21                   ; 0A24
        dec     zTmp1                   ; 0A26
        dec     zTmp0                   ; 0A28
        bne     L0A03                   ; 0A2A
        dec     zTmp2                   ; 0A2C
        dec     zTmp3                   ; 0A2E
        lda     zTmp3                   ; 0A30
        cmp     #$01                    ; 0A32
        bne     L09FC                   ; 0A34
        rts                             ; 0A36


; --------------------------------------------------------------------------
; Copy 7 pages $9800 -> $B400 (HIRES charset area back to TEXT location).
; --------------------------------------------------------------------------
CharsetToText:
        lda     #$00                    ; 0A37
        sta     zTmp0                   ; 0A39
        sta     zTmp2                   ; 0A3B
        lda     #$98                    ; 0A3D
        sta     zTmp1                   ; 0A3F
        lda     #$B4                    ; 0A41
        sta     zTmp3                   ; 0A43
        ldx     #$07                    ; 0A45
        ldy     #$00                    ; 0A47
L0A49:  lda     (zTmp0),y               ; 0A49
        sta     (zTmp2),y               ; 0A4B
        dey                             ; 0A4D
        bne     L0A49                   ; 0A4E
        inc     zTmp1                   ; 0A50
        inc     zTmp3                   ; 0A52
        dex                             ; 0A54
        bne     L0A49                   ; 0A55
        rts                             ; 0A57


; --------------------------------------------------------------------------
; Copy 7 pages $B400 -> $9800, then write $1E to switch to HIRES.
; --------------------------------------------------------------------------
CharsetToHires:
        lda     #$00                    ; 0A58
        sta     zTmp0                   ; 0A5A
        sta     zTmp2                   ; 0A5C
        lda     #$B4                    ; 0A5E
        sta     zTmp1                   ; 0A60
        lda     #$98                    ; 0A62
        sta     zTmp3                   ; 0A64
        ldx     #$07                    ; 0A66
        ldy     #$00                    ; 0A68
L0A6A:  lda     (zTmp0),y               ; 0A6A
        sta     (zTmp2),y               ; 0A6C
        dey                             ; 0A6E
        bne     L0A6A                   ; 0A6F
        inc     zTmp1                   ; 0A71
        inc     zTmp3                   ; 0A73
        dex                             ; 0A75
        bne     L0A6A                   ; 0A76
        lda     #$1E                    ; 0A78  $1E = HIRES 50 Hz attribute
        sta     SCREEN_LAST             ; 0A7A
        rts                             ; 0A7D


; --------------------------------------------------------------------------
; DEAD CODE (unreferenced): blank the 3 HIRES status rows.
; --------------------------------------------------------------------------
DeadClearStatus:
        ldx     #$77                    ; 0A7E
        lda     #$20                    ; 0A80
L0A82:  sta     HIRES_STATUS0,x         ; 0A82
        dex                             ; 0A85
        bpl     L0A82                   ; 0A86
        rts                             ; 0A88


; --------------------------------------------------------------------------
; Bresenham line (zLX0,zLY0) -> (zLX1,zLY1), plotting each point.
; With zLineStep set it returns after one step (used by the explosion).
; --------------------------------------------------------------------------
DrawLine:
        ldx     #$01                    ; 0A89
        sec                             ; 0A8B
        lda     zLX1                    ; 0A8C
        sbc     zLX0                    ; 0A8E
        bcs     L0A98                   ; 0A90
        eor     #$FF                    ; 0A92
        adc     #$01                    ; 0A94
        ldx     #$FF                    ; 0A96
L0A98:  sta     zLDX                    ; 0A98
        sta     zLErrY                  ; 0A9A
        stx     zLSX                    ; 0A9C
        ldx     #$01                    ; 0A9E
        sec                             ; 0AA0
        lda     zLY1                    ; 0AA1
        sbc     zLY0                    ; 0AA3
        bcs     L0AAD                   ; 0AA5
        eor     #$FF                    ; 0AA7
        adc     #$01                    ; 0AA9
        ldx     #$FF                    ; 0AAB
L0AAD:  sta     zLDY                    ; 0AAD
        sta     zLErrX                  ; 0AAF
        stx     zLSY                    ; 0AB1
LinePlot:
        jsr     PlotLinePoint           ; 0AB3

; --------------------------------------------------------------------------
; Resume entry: one Bresenham step from saved state.
; --------------------------------------------------------------------------
LineStep:
        lda     zLErrY                  ; 0AB6
        cmp     zLErrX                  ; 0AB8
        bcc     L0AD0                   ; 0ABA
        clc                             ; 0ABC
        lda     zLErrX                  ; 0ABD
        adc     zLDY                    ; 0ABF
        sta     zLErrX                  ; 0AC1
        clc                             ; 0AC3
        lda     zLX0                    ; 0AC4
        adc     zLSX                    ; 0AC6
        sta     zLX0                    ; 0AC8
        lda     zLErrX                  ; 0ACA
        cmp     zLErrY                  ; 0ACC
        bcc     L0AEE                   ; 0ACE
L0AD0:  clc                             ; 0AD0
        lda     zLErrY                  ; 0AD1
        adc     zLDX                    ; 0AD3
        sta     zLErrY                  ; 0AD5
        clc                             ; 0AD7
        lda     zLY0                    ; 0AD8
        adc     zLSY                    ; 0ADA
        sta     zLY0                    ; 0ADC
        lda     zLErrX                  ; 0ADE
        cmp     zLErrY                  ; 0AE0
        bcc     L0AEE                   ; 0AE2
        sbc     zLErrY                  ; 0AE4
        sta     zLErrX                  ; 0AE6
        lda     #$00                    ; 0AE8
        sta     zLErrY                  ; 0AEA
        beq     L0AF9                   ; 0AEC
L0AEE:  sec                             ; 0AEE
        lda     zLErrY                  ; 0AEF
        sbc     zLErrX                  ; 0AF1
        sta     zLErrY                  ; 0AF3
        lda     #$00                    ; 0AF5
        sta     zLErrX                  ; 0AF7
L0AF9:  lda     zLineStep               ; 0AF9  single-step mode?
        beq     L0AFE                   ; 0AFB
        rts                             ; 0AFD

L0AFE:  lda     zLX0                    ; 0AFE
        cmp     zLX1                    ; 0B00
        bne     LinePlot                ; 0B02
        lda     zLY0                    ; 0B04
        cmp     zLY1                    ; 0B06
        bne     LinePlot                ; 0B08
        rts                             ; 0B0A


; --------------------------------------------------------------------------
; Four random-length diagonal walls from the top and bottom edges and four
; from the side edges, all pointing toward the centre.
; --------------------------------------------------------------------------
DrawObstacles:
        lda     #$00                    ; 0B0B
        sta     zLineStep               ; 0B0D
        jsr     Random                  ; 0B0F
        lda     zRnd2                   ; 0B12
        and     #$0F                    ; 0B14
        adc     #$5A                    ; 0B16
        sta     zObA                    ; 0B18
        lda     #$F0                    ; 0B1A
        sbc     zObA                    ; 0B1C
        sta     zObC                    ; 0B1E
        jsr     Random                  ; 0B20
        lda     zRnd2                   ; 0B23
        and     #$07                    ; 0B25
        adc     #$07                    ; 0B27
        sta     zObF                    ; 0B29
        lda     #$78                    ; 0B2B  x=120: walls aim at screen centre
        sta     zLX1                    ; 0B2D
        lda     zObF                    ; 0B2F
        sta     zLY1                    ; 0B31
        lda     zObA                    ; 0B33
        sta     zLX0                    ; 0B35
        lda     #$00                    ; 0B37
        sta     zLY0                    ; 0B39
        jsr     DrawLine                ; 0B3B
        lda     #$00                    ; 0B3E
        sta     zLY0                    ; 0B40
        lda     zObC                    ; 0B42
        sta     zLX0                    ; 0B44
        jsr     DrawLine                ; 0B46
        lda     #$78                    ; 0B49
        sta     zLX1                    ; 0B4B
        lda     #$C7                    ; 0B4D
        sbc     zObF                    ; 0B4F
        sta     zLY1                    ; 0B51
        lda     zObA                    ; 0B53
        sta     zLX0                    ; 0B55
        lda     #$C7                    ; 0B57
        sta     zLY0                    ; 0B59
        jsr     DrawLine                ; 0B5B
        lda     zObC                    ; 0B5E
        sta     zLX0                    ; 0B60
        lda     #$C7                    ; 0B62
        sta     zLY0                    ; 0B64
        jsr     DrawLine                ; 0B66
        jsr     Random                  ; 0B69
        lda     zRnd2                   ; 0B6C
        and     #$0F                    ; 0B6E
        adc     #$50                    ; 0B70
        sta     zObB                    ; 0B72
        lda     #$C7                    ; 0B74
        sbc     zObB                    ; 0B76
        sta     zObD                    ; 0B78
        jsr     Random                  ; 0B7A
        lda     zRnd2                   ; 0B7D
        and     #$07                    ; 0B7F
        adc     #$13                    ; 0B81
        sta     zObE                    ; 0B83
        lda     #$64                    ; 0B85
        sta     zLY1                    ; 0B87
        lda     zObE                    ; 0B89
        sta     zLX1                    ; 0B8B
        lda     zObB                    ; 0B8D
        sta     zLY0                    ; 0B8F
        lda     #$06                    ; 0B91
        sta     zLX0                    ; 0B93
        jsr     DrawLine                ; 0B95
        lda     #$06                    ; 0B98
        sta     zLX0                    ; 0B9A
        lda     zObD                    ; 0B9C
        sta     zLY0                    ; 0B9E
        jsr     DrawLine                ; 0BA0
        lda     #$64                    ; 0BA3
        sta     zLY1                    ; 0BA5
        lda     #$F6                    ; 0BA7
        sbc     zObE                    ; 0BA9
        sta     zLX1                    ; 0BAB
        lda     zObB                    ; 0BAD
        sta     zLY0                    ; 0BAF
        lda     #$EF                    ; 0BB1
        sta     zLX0                    ; 0BB3
        jsr     DrawLine                ; 0BB5
        lda     #$EF                    ; 0BB8
        sta     zLX0                    ; 0BBA
        lda     zObD                    ; 0BBC
        sta     zLY0                    ; 0BBE
        jsr     DrawLine                ; 0BC0
        rts                             ; 0BC3


; --------------------------------------------------------------------------
; Fill the 3 HIRES text rows: names, TIME, lives and scores.
; --------------------------------------------------------------------------
DrawStatusLine:
        ldx     #$27                    ; 0BC4
L0BC6:  lda     StatusText,x            ; 0BC6
        sta     HIRES_STATUS0,x         ; 0BC9
        dex                             ; 0BCC
        bpl     L0BC6                   ; 0BCD
        ldx     #$02                    ; 0BCF
L0BD1:  lda     TimeAttrL,x             ; 0BD1
        sta     $BF9E,x                 ; 0BD4
        sta     $BFC6,x                 ; 0BD7
        lda     TimeAttrR,x             ; 0BDA
        sta     $BFA7,x                 ; 0BDD
        sta     $BFCF,x                 ; 0BE0
        dex                             ; 0BE3
        bpl     L0BD1                   ; 0BE4
        lda     zTmp3                   ; 0BE6
        sta     HIRES_STATUS0           ; 0BE8
        sta     $BFA8                   ; 0BEB
        sta     HIRES_STATUS1           ; 0BEE
        sta     $BF7F                   ; 0BF1
        sta     HIRES_STATUS2           ; 0BF4
        sta     $BFD0                   ; 0BF7
        rts                             ; 0BFA

PlotLinePoint:
        ldx     zLX0                    ; 0BFB
        ldy     zLY0                    ; 0BFD
        jsr     HiresAddr               ; 0BFF
        jsr     PlotPixel               ; 0C02
        rts                             ; 0C05


; --------------------------------------------------------------------------
; 32-particle explosion at (zX,zY). Each particle has a random life and a
; target from ExplodeDX/DY; each tick it erases its pixel, steps one Bresenham
; step toward its target and replots. Particle state lives at $9D00-$9E5F.
; --------------------------------------------------------------------------
Explosion:
        ldx     #$B0                    ; 0C06  AY explosion table $04B0 (skipped when volume is 0)
        ldy     #$04                    ; 0C08
        lda     zVolume                 ; 0C0A
        beq     L0C11                   ; 0C0C
        jsr     AyLoadAll               ; 0C0E
L0C11:  lda     #$01                    ; 0C11
        sta     zLineStep               ; 0C13
        lda     #$23                    ; 0C15
        sta     zObC                    ; 0C17
        lda     #$1F                    ; 0C19
        sta     zObA                    ; 0C1B
        sta     zObB                    ; 0C1D
L0C1F:  jsr     Random                  ; 0C1F
        lda     zRnd2                   ; 0C22
        and     #$0F                    ; 0C24
        adc     #$05                    ; 0C26
        ldx     zObB                    ; 0C28  life 5-20 ticks
        sta     PART_LIFE,x             ; 0C2A
        lda     zX                      ; 0C2D
        sta     PART_X,x                ; 0C2F
        lda     ExplodeDX,x             ; 0C32
        clc                             ; 0C35
        adc     zX                      ; 0C36
        sta     PART_TX,x               ; 0C38
        lda     zY                      ; 0C3B
        sta     PART_Y,x                ; 0C3D
        lda     ExplodeDY,x             ; 0C40
        clc                             ; 0C43
        adc     zY                      ; 0C44
        sta     PART_TY,x               ; 0C46
        dec     zObB                    ; 0C49
        bpl     L0C1F                   ; 0C4B
L0C4D:  lda     zObA                    ; 0C4D
        sta     zObB                    ; 0C4F
L0C51:  ldx     zObB                    ; 0C51
        ldy     PART_LIFE,x             ; 0C53
        cpy     #$01                    ; 0C56
        beq     L0C82                   ; 0C58
        cpy     #$00                    ; 0C5A
        beq     L0C7B                   ; 0C5C
        dec     PART_LIFE,x             ; 0C5E
        lda     PART_LIFE,x             ; 0C61
        cmp     #$01                    ; 0C64
        bne     L0C7B                   ; 0C66
        jsr     PartLoadEnds            ; 0C68
        jsr     DrawLine                ; 0C6B
        jsr     PartSaveState           ; 0C6E
        lda     zLX0                    ; 0C71
        sta     PART_X,x                ; 0C73
        lda     zLY0                    ; 0C76
        sta     PART_Y,x                ; 0C78
L0C7B:  dec     zObB                    ; 0C7B
        bpl     L0C51                   ; 0C7D
        jmp     L0CD1                   ; 0C7F

L0C82:  jsr     PartLoadEnds            ; 0C82
        jsr     PartLoadState           ; 0C85
        ldx     zLX0                    ; 0C88
        ldy     zLY0                    ; 0C8A
        jsr     UnplotPixel             ; 0C8C
        jsr     LineStep                ; 0C8F
        jsr     PartSaveState           ; 0C92
        ldx     zLX0                    ; 0C95
        ldy     zLY0                    ; 0C97
        jsr     HiresAddr               ; 0C99
        jsr     PlotPixel               ; 0C9C
        ldx     zObB                    ; 0C9F
        lda     zLX0                    ; 0CA1
        sta     PART_X,x                ; 0CA3
        lda     zLY0                    ; 0CA6
        sta     PART_Y,x                ; 0CA8
        ldx     zLX0                    ; 0CAB  particle left the arena?
        cpx     #$08                    ; 0CAD
        bcc     L0CDE                   ; 0CAF
        cpx     #$EE                    ; 0CB1
        bcs     L0CDE                   ; 0CB3
        ldy     zLY0                    ; 0CB5
        cpy     #$02                    ; 0CB7
        bcc     L0CDE                   ; 0CB9
        cpy     #$C6                    ; 0CBB
        bcs     L0CDE                   ; 0CBD
        lda     zLX0                    ; 0CBF
        cmp     zLX1                    ; 0CC1
        bne     L0CCE                   ; 0CC3
        lda     zLY0                    ; 0CC5
        cmp     zLY1                    ; 0CC7
        bne     L0CCE                   ; 0CC9
        jmp     L0CDE                   ; 0CCB

L0CCE:  jmp     L0C7B                   ; 0CCE

L0CD1:  ldx     #$14                    ; 0CD1
        jsr     DelayX                  ; 0CD3
        dec     zObC                    ; 0CD6
        beq     L0CDD                   ; 0CD8
        jmp     L0C4D                   ; 0CDA

L0CDD:  rts                             ; 0CDD

L0CDE:  ldx     zLX0                    ; 0CDE
        ldy     zLY0                    ; 0CE0
        jsr     UnplotPixel             ; 0CE2
        lda     #$00                    ; 0CE5
        ldx     zObB                    ; 0CE7
        sta     PART_LIFE,x             ; 0CE9
        jmp     L0C7B                   ; 0CEC

PartLoadEnds:
        ldx     zObB                    ; 0CEF
        lda     PART_X,x                ; 0CF1
        sta     zLX0                    ; 0CF4
        lda     PART_Y,x                ; 0CF6
        sta     zLY0                    ; 0CF9
        lda     PART_TX,x               ; 0CFB
        sta     zLX1                    ; 0CFE
        lda     PART_TY,x               ; 0D00
        sta     zLY1                    ; 0D03
        rts                             ; 0D05

PartLoadState:
        ldx     zObB                    ; 0D06
        lda     PART_DX,x               ; 0D08
        sta     zLDX                    ; 0D0B
        lda     PART_DY,x               ; 0D0D
        sta     zLDY                    ; 0D10
        lda     PART_SX,x               ; 0D12
        sta     zLSX                    ; 0D15
        lda     PART_SY,x               ; 0D17
        sta     zLSY                    ; 0D1A
        lda     PART_ERRX,x             ; 0D1C
        sta     zLErrX                  ; 0D1F
        lda     PART_ERRY,x             ; 0D21
        sta     zLErrY                  ; 0D24
        rts                             ; 0D26

PartSaveState:
        ldx     zObB                    ; 0D27
        lda     zLDX                    ; 0D29
        sta     PART_DX,x               ; 0D2B
        lda     zLDY                    ; 0D2E
        sta     PART_DY,x               ; 0D30
        lda     zLErrX                  ; 0D33
        sta     PART_ERRX,x             ; 0D35
        lda     zLErrY                  ; 0D38
        sta     PART_ERRY,x             ; 0D3A
        lda     zLSX                    ; 0D3D
        sta     PART_SX,x               ; 0D3F
        lda     zLSY                    ; 0D42
        sta     PART_SY,x               ; 0D44
        rts                             ; 0D47


; --------------------------------------------------------------------------
; Re-establish the ROM's VIA setup (100 Hz T1 IRQ, keyboard/AY idle).
; --------------------------------------------------------------------------
ViaRestoreRom:
        lda     #$FF                    ; 0D48
        sta     VIA_DDRA                ; 0D4A  DDRA all out
        lda     #$F7                    ; 0D4D
        sta     VIA_DDRB                ; 0D4F  DDRB
        lda     #$B7                    ; 0D52
        sta     VIA_ORB                 ; 0D54
        lda     #$DD                    ; 0D57
        sta     VIA_PCR                 ; 0D59
        lda     #$7F                    ; 0D5C  disable all VIA IRQs
        sta     VIA_IER                 ; 0D5E
        lda     #$00                    ; 0D61
        sta     VIA_ACR                 ; 0D63
        ldy     #$05                    ; 0D66
        lda     #$00                    ; 0D68
L0D6A:  sta     ROM_TIMERS1,y           ; 0D6A
        dey                             ; 0D6D
        bpl     L0D6A                   ; 0D6E
        lda     #$00                    ; 0D70
        tax                             ; 0D72
        ldy     #$03                    ; 0D73  timer slot 0 = 3
        jsr     SetRomTimer             ; 0D75
        lda     #$01                    ; 0D78
        ldy     #$13                    ; 0D7A  timer slot 1 = 19
        jsr     SetRomTimer             ; 0D7C
        lda     #$00                    ; 0D7F
        sta     ROM_TIMERS              ; 0D81
        lda     VIA_ACR                 ; 0D84
        and     #$7F                    ; 0D87
        ora     #$40                    ; 0D89
        sta     VIA_ACR                 ; 0D8B
        lda     #$C0                    ; 0D8E  enable T1 IRQ
        sta     VIA_IER                 ; 0D90
        lda     #$10                    ; 0D93  T1 = $2710 = 10000 us -> 100 Hz
        sta     VIA_T1LL                ; 0D95
        sta     VIA_T1CL                ; 0D98
        lda     #$27                    ; 0D9B
        sta     VIA_T1LH                ; 0D9D
        sta     VIA_T1CH                ; 0DA0
        rts                             ; 0DA3


; --------------------------------------------------------------------------
; Store X/Y into ROM timer slot A (copy of the ROM routine).
; --------------------------------------------------------------------------
SetRomTimer:
        pha                             ; 0DA4
        txa                             ; 0DA5
        pha                             ; 0DA6
        tya                             ; 0DA7
        pha                             ; 0DA8
        tsx                             ; 0DA9
        lda     $0103,x                 ; 0DAA
        asl     a                       ; 0DAD
        tay                             ; 0DAE
        pla                             ; 0DAF
        pha                             ; 0DB0
        sei                             ; 0DB1
        sta     ROM_TIMERS1,y           ; 0DB2
        lda     $0102,x                 ; 0DB5
        sta     ROM_TIMERS1H,y          ; 0DB8
        cli                             ; 0DBB
        pla                             ; 0DBC
        tay                             ; 0DBD
        pla                             ; 0DBE
        pla                             ; 0DBF
        rts                             ; 0DC0


; --------------------------------------------------------------------------
; Disable the T1 IRQ and program VIA for direct keyboard scanning.
; --------------------------------------------------------------------------
ViaGameSetup:
        lda     #$40                    ; 0DC1  disable T1 IRQ
        sta     VIA_IER                 ; 0DC3
        ldy     #$06                    ; 0DC6
        sei                             ; 0DC8
L0DC9:  ldx     ViaRegIdx,y             ; 0DC9
        lda     ViaRegVal,y             ; 0DCC
        sta     VIA_ORB,x               ; 0DCF
        dey                             ; 0DD2
        bpl     L0DC9                   ; 0DD3
        lda     #$40                    ; 0DD5
        sta     VIA_ORB                 ; 0DD7
        rts                             ; 0DDA


; --------------------------------------------------------------------------
; Additive RNG over $D0-$D3; callers read zRnd2/zRnd3.
; --------------------------------------------------------------------------
Random: ldy     #$29                    ; 0DDB
        ldx     #$FC                    ; 0DDD
L0DDF:  tya                             ; 0DDF
        ldy     zRndEnd,x               ; 0DE0
        adc     zRndEnd,x               ; 0DE2
        sta     zRndEnd,x               ; 0DE4
        inx                             ; 0DE6
        bne     L0DDF                   ; 0DE7
        rts                             ; 0DE9


; --------------------------------------------------------------------------
; Arena frame: solid top/bottom HIRES rows, 1-pixel left/right edges.
; --------------------------------------------------------------------------
DrawBorder:
        ldx     #$26                    ; 0DEA
        lda     #$7F                    ; 0DEC  %1111111 top and bottom rows
L0DEE:  sta     HIRES_ROW0_C1,x         ; 0DEE
        sta     $BF19,x                 ; 0DF1
        dex                             ; 0DF4
        bpl     L0DEE                   ; 0DF5
        lda     #$A0                    ; 0DF7
        sta     zTmp1                   ; 0DF9
        lda     #$29                    ; 0DFB
        sta     zTmp0                   ; 0DFD
        ldx     #$C6                    ; 0DFF
L0E01:  ldy     #$00                    ; 0E01
        lda     #$60                    ; 0E03  left edge pixel
        sta     (zTmp0),y               ; 0E05
        ldy     #$26                    ; 0E07
        lda     #$41                    ; 0E09  right edge pixel
        sta     (zTmp0),y               ; 0E0B
        clc                             ; 0E0D
        lda     zTmp0                   ; 0E0E
        adc     #$28                    ; 0E10
        bcc     L0E16                   ; 0E12
        inc     zTmp1                   ; 0E14
L0E16:  sta     zTmp0                   ; 0E16
        dex                             ; 0E18
        bne     L0E01                   ; 0E19
        rts                             ; 0E1B


; --------------------------------------------------------------------------
; Random paper colour attribute into column 0 of every HIRES row.
; --------------------------------------------------------------------------
SetPaperColour:
        jsr     Random                  ; 0E1C
        lda     zRnd3                   ; 0E1F
        and     #$03                    ; 0E21
        tay                             ; 0E23
        lda     PaperColours,y          ; 0E24
        sta     zTmp3                   ; 0E27
        lda     #$9F                    ; 0E29  $9FD8+40 = $A000: column 0 of each row
        sta     zTmp1                   ; 0E2B
        lda     #$D8                    ; 0E2D
        sta     zTmp0                   ; 0E2F
        ldx     #$C9                    ; 0E31
L0E33:  ldy     #$00                    ; 0E33
        lda     zTmp3                   ; 0E35
        sta     (zTmp0),y               ; 0E37
        clc                             ; 0E39
        lda     zTmp0                   ; 0E3A
        adc     #$28                    ; 0E3C
        bcc     L0E42                   ; 0E3E
        inc     zTmp1                   ; 0E40
L0E42:  sta     zTmp0                   ; 0E42
        dex                             ; 0E44
        bne     L0E33                   ; 0E45
        rts                             ; 0E47


; --------------------------------------------------------------------------
; P1 at x=25 heading right, P2 at x=215 heading left, random heights.
; --------------------------------------------------------------------------
RandomStarts:
        jsr     Random                  ; 0E48
        lda     zRnd3                   ; 0E4B
        cmp     #$C0                    ; 0E4D
        bcs     RandomStarts            ; 0E4F
        adc     #$03                    ; 0E51
        sta     zP1Y                    ; 0E53
L0E55:  jsr     Random                  ; 0E55
        lda     zRnd2                   ; 0E58
        cmp     #$C0                    ; 0E5A
        bcs     L0E55                   ; 0E5C
        adc     #$03                    ; 0E5E
        sta     zP2Y                    ; 0E60
        lda     #$19                    ; 0E62  P1 x=25
        sta     zP1X                    ; 0E64
        lda     #$D7                    ; 0E66  P2 x=215
        sta     zP2X                    ; 0E68
        ldx     #$01                    ; 0E6A  P1 right, P2 left
        stx     zP1Dir                  ; 0E6C
        inx                             ; 0E6E
        stx     zP2Dir                  ; 0E6F
        rts                             ; 0E71


; --------------------------------------------------------------------------
; AY: tones A+B on, volume zVolume, base pitch.
; --------------------------------------------------------------------------
SoundInit:
        lda     #$07                    ; 0E72
        ldx     #$F8                    ; 0E74
        jsr     AyWrite                 ; 0E76
        lda     #$08                    ; 0E79
        ldx     zVolume                 ; 0E7B
        jsr     AyWrite                 ; 0E7D
        lda     #$09                    ; 0E80
        ldx     zVolume                 ; 0E82
        jsr     AyWrite                 ; 0E84
        lda     #$01                    ; 0E87
        ldx     #$04                    ; 0E89
        jsr     AyWrite                 ; 0E8B
        lda     #$03                    ; 0E8E
        ldx     #$04                    ; 0E90
        jsr     AyWrite                 ; 0E92
        rts                             ; 0E95


; --------------------------------------------------------------------------
; Scores to 0, lives to 5.
; --------------------------------------------------------------------------
ResetScores:
        lda     #$30                    ; 0E96
        sta     $BFCE                   ; 0E98
        sta     $BFA6                   ; 0E9B
        ldx     #$02                    ; 0E9E
L0EA0:  sta     $BFBF,x                 ; 0EA0
        sta     $BFDB,x                 ; 0EA3
        dex                             ; 0EA6
        bpl     L0EA0                   ; 0EA7
        lda     #$35                    ; 0EA9
        sta     $BFC4                   ; 0EAB
        sta     $BFD3                   ; 0EAE
        rts                             ; 0EB1


; --------------------------------------------------------------------------
; Copy bike icon and arrow glyphs into the TEXT standard charset.
; --------------------------------------------------------------------------
DefineGlyphs:
        ldx     #$0F                    ; 0EB2
L0EB4:  lda     GlyphBike,x             ; 0EB4
        sta     $B7D8,x                 ; 0EB7
        dex                             ; 0EBA
        bpl     L0EB4                   ; 0EBB
        ldx     #$0F                    ; 0EBD
L0EBF:  lda     GlyphArrows,x           ; 0EBF
        sta     $B7E8,x                 ; 0EC2
        dex                             ; 0EC5
        bpl     L0EBF                   ; 0EC6
        rts                             ; 0EC8


; --------------------------------------------------------------------------
; If the pixel at (X,Y) is already lit the current cycle crashes: explosion,
; award the opponent, lose a life, next round or game over. Never returns
; in that case (JMP out of two JSR levels).
; --------------------------------------------------------------------------
PlotCheckCrash:
        jsr     HiresAddr               ; 0EC9
        lda     zMask                   ; 0ECC
        ldy     #$00                    ; 0ECE  already lit?
        and     (zPix),y                ; 0ED0
        cmp     zMask                   ; 0ED2
        beq     Crash                   ; 0ED4
        ldy     zSaveY                  ; 0ED6
        rts                             ; 0ED8

Crash:  jsr     ViaRestoreRom           ; 0ED9
        jsr     Explosion               ; 0EDC
        lda     zPlayer                 ; 0EDF
        bne     L0EF6                   ; 0EE1
        jsr     AwardP2                 ; 0EE3
        dec     $BFC4                   ; 0EE6  P1 lives digit
        lda     $BFC4                   ; 0EE9
        cmp     #$30                    ; 0EEC
        bne     L0EF3                   ; 0EEE
        jmp     DecideWinner            ; 0EF0

L0EF3:  jmp     L0F06                   ; 0EF3

L0EF6:  jsr     AwardP1                 ; 0EF6
        dec     $BFD3                   ; 0EF9  P2 lives digit
        lda     $BFD3                   ; 0EFC
        cmp     #$30                    ; 0EFF
        bne     L0F06                   ; 0F01
        jmp     DecideWinner            ; 0F03

L0F06:  lda     #$0A                    ; 0F06  pause ~ 10 frames
        sta     zLoop                   ; 0F08
L0F0A:  jsr     FrameDelay              ; 0F0A
        dec     zLoop                   ; 0F0D
        bne     L0F0A                   ; 0F0F
        jmp     RoundStart              ; 0F11  next round


; --------------------------------------------------------------------------
; P2 crashed: add TIME + 200 to P1's score.
; --------------------------------------------------------------------------
AwardP1:lda     #$BA                    ; 0F14
        sta     zDigPtr                 ; 0F16
        lda     #$BF                    ; 0F18
        sta     zDigPtrH                ; 0F1A
        ldx     #$07                    ; 0F1C
L0F1E:  lda     $BFC7,x                 ; 0F1E
        cmp     #$20                    ; 0F21
        beq     L0F34                   ; 0F23
        sec                             ; 0F25
        sbc     #$30                    ; 0F26
        stx     zObA                    ; 0F28
        ldy     zObA                    ; 0F2A
        jsr     AddDigit                ; 0F2C
        ldx     zObA                    ; 0F2F
        dex                             ; 0F31
        bpl     L0F1E                   ; 0F32
L0F34:  lda     #$02                    ; 0F34  +200
        ldy     #$05                    ; 0F36
        jsr     AddDigit                ; 0F38
        jsr     ResetTime               ; 0F3B
        rts                             ; 0F3E


; --------------------------------------------------------------------------
; P1 crashed: add TIME + 200 to P2's score.
; --------------------------------------------------------------------------
AwardP2:lda     #$D6                    ; 0F3F
        sta     zDigPtr                 ; 0F41
        lda     #$BF                    ; 0F43
        sta     zDigPtrH                ; 0F45
        ldx     #$07                    ; 0F47
L0F49:  lda     $BFC7,x                 ; 0F49
        cmp     #$20                    ; 0F4C
        beq     L0F5F                   ; 0F4E
        sec                             ; 0F50
        sbc     #$30                    ; 0F51
        stx     zObA                    ; 0F53
        ldy     zObA                    ; 0F55
        jsr     AddDigit                ; 0F57
        ldx     zObA                    ; 0F5A
        dex                             ; 0F5C
        bpl     L0F49                   ; 0F5D
L0F5F:  lda     #$02                    ; 0F5F
        ldy     #$05                    ; 0F61
        jsr     AddDigit                ; 0F63
        jsr     ResetTime               ; 0F66
        rts                             ; 0F69


; --------------------------------------------------------------------------
; A player is out of lives. Compare 7-digit scores (relies on carry set by
; the preceding CMP #$30), flash the winner's name 25 times, stash the
; winner's score and name at $9D00/$9D20 and go to GameOver.
; --------------------------------------------------------------------------
DecideWinner:
        ldy     #$07                    ; 0F6A
L0F6C:  lda     $BFBA,y                 ; 0F6C  P1 score - P2 score (7 digits)
        sbc     $BFD6,y                 ; 0F6F
        dey                             ; 0F72
        bne     L0F6C                   ; 0F73
        bcc     L0FAB                   ; 0F75
        ldx     #$07                    ; 0F77
L0F79:  lda     $BFBA,x                 ; 0F79
        sta     PART_LIFE,x             ; 0F7C
        dex                             ; 0F7F
        bpl     L0F79                   ; 0F80
        ldx     #$07                    ; 0F82
L0F84:  lda     $BF6A,x                 ; 0F84
        sta     PART_X,x                ; 0F87
        dex                             ; 0F8A
        bpl     L0F84                   ; 0F8B
        ldx     #$19                    ; 0F8D
L0F8F:  ldy     #$07                    ; 0F8F
L0F91:  lda     $BF6A,y                 ; 0F91
        eor     #$80                    ; 0F94  toggle inverse
        sta     $BF6A,y                 ; 0F96
        dey                             ; 0F99
        bpl     L0F91                   ; 0F9A
        jsr     FlashDelay              ; 0F9C
        dex                             ; 0F9F
        bne     L0F8F                   ; 0FA0
        jsr     Delay                   ; 0FA2
        jsr     Delay                   ; 0FA5
        jmp     GameOver                ; 0FA8

L0FAB:  ldx     #$07                    ; 0FAB
L0FAD:  lda     $BFD6,x                 ; 0FAD
        sta     PART_LIFE,x             ; 0FB0
        dex                             ; 0FB3
        bpl     L0FAD                   ; 0FB4
        ldx     #$07                    ; 0FB6
L0FB8:  lda     $BF86,x                 ; 0FB8
        sta     PART_X,x                ; 0FBB
        dex                             ; 0FBE
        bpl     L0FB8                   ; 0FBF
        ldx     #$19                    ; 0FC1
L0FC3:  ldy     #$07                    ; 0FC3
L0FC5:  lda     $BF86,y                 ; 0FC5
        eor     #$80                    ; 0FC8
        sta     $BF86,y                 ; 0FCA
        dey                             ; 0FCD
        bpl     L0FC5                   ; 0FCE
        jsr     FlashDelay              ; 0FD0
        dex                             ; 0FD3
        bne     L0FC3                   ; 0FD4
        jsr     Delay                   ; 0FD6
        jsr     Delay                   ; 0FD9
        jmp     GameOver                ; 0FDC

FlashDelay:
        stx     zTmp0                   ; 0FDF
        ldx     #$50                    ; 0FE1
        ldy     #$00                    ; 0FE3
L0FE5:  dey                             ; 0FE5
        bne     L0FE5                   ; 0FE6
        dex                             ; 0FE8
        bne     L0FE5                   ; 0FE9
        ldx     zTmp0                   ; 0FEB
        rts                             ; 0FED


; --------------------------------------------------------------------------
; TIME digits back to '    0'.
; --------------------------------------------------------------------------
ResetTime:
        ldx     #$00                    ; 0FEE
        lda     #$20                    ; 0FF0
L0FF2:  sta     $BFC9,x                 ; 0FF2
        sta     $BFA1,x                 ; 0FF5
        inx                             ; 0FF8
        cpx     #$05                    ; 0FF9
        bne     L0FF2                   ; 0FFB
        lda     #$30                    ; 0FFD
        sta     $BFC9,x                 ; 0FFF
        sta     $BFA1,x                 ; 1002
        rts                             ; 1005


; --------------------------------------------------------------------------
; DEAD CODE (unreferenced): earlier copy of CharsetToHires.
; --------------------------------------------------------------------------
DeadCharsetCopy:
        lda     #$00                    ; 1006
        sta     zTmp0                   ; 1008
        sta     zTmp2                   ; 100A
        lda     #$B4                    ; 100C
        sta     zTmp1                   ; 100E
        lda     #$98                    ; 1010
        sta     zTmp3                   ; 1012
        ldx     #$07                    ; 1014
        ldy     #$00                    ; 1016
L1018:  lda     (zTmp2),y               ; 1018
        sta     (zTmp0),y               ; 101A
        dey                             ; 101C
        bne     L1018                   ; 101D
        inc     zTmp1                   ; 101F
        inc     zTmp3                   ; 1021
        dex                             ; 1023
        bne     L1018                   ; 1024
        rts                             ; 1026


; --------------------------------------------------------------------------
; Space-fill $BA00-$BFFF (covers the whole TEXT screen).
; --------------------------------------------------------------------------
ClearTextScreen:
        ldy     #$00                    ; 1027
        lda     #$20                    ; 1029
L102B:  sta     $BA00,y                 ; 102B
        sta     $BB00,y                 ; 102E
        sta     $BC00,y                 ; 1031
        sta     $BD00,y                 ; 1034
        sta     $BE00,y                 ; 1037
        sta     $BF00,y                 ; 103A
        dey                             ; 103D
        bne     L102B                   ; 103E
        rts                             ; 1040


; --------------------------------------------------------------------------
; Fill $A000-$BF3F with $40 (blank pixel bytes).
; --------------------------------------------------------------------------
ClearHires:
        lda     #$00                    ; 1041
        sta     zTmp0                   ; 1043
        lda     #$BF                    ; 1045
        sta     zTmp1                   ; 1047
        ldx     #$1F                    ; 1049
        lda     #$40                    ; 104B  $40 = blank pixel byte
        ldy     #$3F                    ; 104D
L104F:  sta     (zTmp0),y               ; 104F
        dey                             ; 1051
        cpy     #$FF                    ; 1052
        bne     L104F                   ; 1054
        dec     zTmp1                   ; 1056
        dex                             ; 1058
        cpx     #$FF                    ; 1059
        bne     L104F                   ; 105B
        rts                             ; 105D


; --------------------------------------------------------------------------
; Clear pixel (X,Y). Returns with Y restored.
; --------------------------------------------------------------------------
UnplotPixel:
        jsr     HiresAddr               ; 105E
        lda     zMask                   ; 1061
        ldy     #$00                    ; 1063
        eor     #$3F                    ; 1065  clear just this bit
        and     (zPix),y                ; 1067
        sta     (zPix),y                ; 1069
        ldy     zSaveY                  ; 106B
        rts                             ; 106D


; --------------------------------------------------------------------------
; Set the pixel already addressed by zPix/zMask.
; --------------------------------------------------------------------------
PlotPixel:
        tya                             ; 106E
        pha                             ; 106F
        lda     zMask                   ; 1070
        ldy     #$00                    ; 1072
        ora     (zPix),y                ; 1074
        sta     (zPix),y                ; 1076
        pla                             ; 1078
        tay                             ; 1079
        rts                             ; 107A


; --------------------------------------------------------------------------
; Direct matrix scan of P1's 5 keys -> zInput.
; --------------------------------------------------------------------------
ReadKeysP1:
        ldx     #$04                    ; 107B
        lda     #$00                    ; 107D
        sta     zTmp1                   ; 107F
L1081:  lda     KeyRowP1,x              ; 1081
        sta     VIA_ORB                 ; 1084  select keyboard row
        lda     KeyColP1,x              ; 1087
        stx     zTmp0                   ; 108A
        ldy     #$0E                    ; 108C  AY R14 = column mask
        tax                             ; 108E
        tya                             ; 108F
        jsr     AyWrite                 ; 1090
        ldx     zTmp0                   ; 1093
        lda     #$08                    ; 1095
        bit     VIA_ORB                 ; 1097  PB3 = key down
        beq     L10A3                   ; 109A
        lda     KeyBitP1,x              ; 109C
        ora     zTmp1                   ; 109F
        sta     zTmp1                   ; 10A1
L10A3:  dex                             ; 10A3
        bpl     L1081                   ; 10A4
        lda     zTmp1                   ; 10A6
        sta     zInput                  ; 10A8
        rts                             ; 10AA


; --------------------------------------------------------------------------
; Direct matrix scan of P2's 5 keys -> zInput.
; --------------------------------------------------------------------------
ReadKeysP2:
        ldx     #$04                    ; 10AB
        lda     #$00                    ; 10AD
        sta     zTmp1                   ; 10AF
L10B1:  lda     KeyRowP2,x              ; 10B1
        sta     VIA_ORB                 ; 10B4
        lda     KeyColP2,x              ; 10B7
        stx     zTmp0                   ; 10BA
        ldy     #$0E                    ; 10BC
        tax                             ; 10BE
        tya                             ; 10BF
        jsr     AyWrite                 ; 10C0
        ldx     zTmp0                   ; 10C3
        lda     #$08                    ; 10C5
        bit     VIA_ORB                 ; 10C7
        beq     L10D3                   ; 10CA
        lda     KeyBitP2,x              ; 10CC
        ora     zTmp1                   ; 10CF
        sta     zTmp1                   ; 10D1
L10D3:  dex                             ; 10D3
        bpl     L10B1                   ; 10D4
        lda     zTmp1                   ; 10D6
        sta     zInput                  ; 10D8
        rts                             ; 10DA


; --------------------------------------------------------------------------
; Every 255 frames try a random spot; if the 6x6 area is empty, animate a
; block there (box/ring/dot/ring/box, one frame per 25 ticks). The final
; frame stays on screen as a new obstacle.
; --------------------------------------------------------------------------
BonusBlocks:
        lda     zBonusState             ; 10DB
        bne     L1131                   ; 10DD
        inc     zBonusTmr               ; 10DF
        lda     zBonusTmr               ; 10E1
        cmp     #$FF                    ; 10E3  every 255 ticks
        beq     L10E8                   ; 10E5
L10E7:  rts                             ; 10E7

L10E8:  lda     #$00                    ; 10E8
        sta     zBonusTmr               ; 10EA
        inc     zBonusState             ; 10EC
        jsr     Random                  ; 10EE
        lda     zRnd2                   ; 10F1
        and     #$1F                    ; 10F3
        clc                             ; 10F5
        adc     #$03                    ; 10F6
        sta     zBonusPtr               ; 10F8
L10FA:  jsr     Random                  ; 10FA
        lda     zRnd3                   ; 10FD
        cmp     #$A0                    ; 10FF
        bcs     L10FA                   ; 1101
        adc     #$12                    ; 1103
        tay                             ; 1105
        ldx     #$00                    ; 1106
L1108:  clc                             ; 1108
        lda     zBonusPtr               ; 1109
        adc     #$28                    ; 110B
        bcc     L1110                   ; 110D
        inx                             ; 110F
L1110:  sta     zBonusPtr               ; 1110
        dey                             ; 1112
        bne     L1108                   ; 1113
        txa                             ; 1115
        clc                             ; 1116
        adc     #$A0                    ; 1117
        sta     zBonusPtrH              ; 1119
        ldx     #$05                    ; 111B
L111D:  ldy     BonusRowOfs,x           ; 111D
        lda     (zBonusPtr),y           ; 1120
        cmp     #$40                    ; 1122  area must be empty
        bne     L112A                   ; 1124
        dex                             ; 1126
        bpl     L111D                   ; 1127
        rts                             ; 1129

L112A:  lda     #$00                    ; 112A
        sta     zBonusState             ; 112C
        sta     zBonusTmr               ; 112E
        rts                             ; 1130

L1131:  inc     zBonusTmr               ; 1131
        lda     zBonusTmr               ; 1133
        cmp     #$19                    ; 1135
        bne     L10E7                   ; 1137
        lda     #$00                    ; 1139
        sta     zBonusTmr               ; 113B
        ldy     zBonusState             ; 113D
        dey                             ; 113F
        ldx     BonusFrameOfs,y         ; 1140
        jsr     DrawBonusFrame          ; 1143
        inc     zBonusState             ; 1146
        lda     zBonusState             ; 1148
        cmp     #$06                    ; 114A
        beq     L114F                   ; 114C
        rts                             ; 114E

L114F:  lda     #$00                    ; 114F
        ldx     #$05                    ; 1151
L1153:  sta     zBonusTmr,x             ; 1153
        dex                             ; 1155
        bpl     L1153                   ; 1156
        rts                             ; 1158

DrawBonusFrame:
        stx     zLoop                   ; 1159
        txa                             ; 115B
        clc                             ; 115C
        adc     #$05                    ; 115D
        tax                             ; 115F
        lda     #$05                    ; 1160
        sta     zSlowP1                 ; 1162
L1164:  txa                             ; 1164
        ldx     zSlowP1                 ; 1165
        ldy     BonusRowOfs,x           ; 1167
        tax                             ; 116A
        lda     BonusGfx,x              ; 116B
        sta     (zBonusPtr),y           ; 116E
        dec     zSlowP1                 ; 1170
        dex                             ; 1172
        cpx     zLoop                   ; 1173
        bpl     L1164                   ; 1175
        rts                             ; 1177


; --------------------------------------------------------------------------
; Computer opponent. Look 3 pixels ahead (3-wide) in the current direction;
; if blocked, turn toward P1 on the other axis (TurnVertical/TurnHorizontal),
; then AIAvoid checks that turn and reverses it if also blocked.
; --------------------------------------------------------------------------
ComputerAI:
        lda     zDir                    ; 1178
        ldx     #$00                    ; 117A
        stx     zInput                  ; 117C
        cmp     #$01                    ; 117E
        bne     L11AE                   ; 1180
        ldx     zX                      ; 1182
        inx                             ; 1184
        inx                             ; 1185
        inx                             ; 1186
        stx     zLX0                    ; 1187
        ldy     zY                      ; 1189
        jsr     PixelSet                ; 118B
        bcs     L11A5                   ; 118E
        ldx     zLX0                    ; 1190
        ldy     zY                      ; 1192
        dey                             ; 1194
        jsr     PixelSet                ; 1195
        bcs     L11A5                   ; 1198
        ldx     zLX0                    ; 119A
        ldy     zY                      ; 119C
        iny                             ; 119E
        jsr     PixelSet                ; 119F
        bcs     L11A5                   ; 11A2
        rts                             ; 11A4

L11A5:  jsr     TurnVertical            ; 11A5
        sta     zInput                  ; 11A8
        jsr     AIAvoid                 ; 11AA
        rts                             ; 11AD

L11AE:  cmp     #$02                    ; 11AE
        bne     L11DE                   ; 11B0
        ldx     zX                      ; 11B2
        dex                             ; 11B4
        dex                             ; 11B5
        dex                             ; 11B6
        stx     zLX0                    ; 11B7
        ldy     zY                      ; 11B9
        jsr     PixelSet                ; 11BB
        bcs     L11D5                   ; 11BE
        ldx     zLX0                    ; 11C0
        ldy     zY                      ; 11C2
        dey                             ; 11C4
        jsr     PixelSet                ; 11C5
        bcs     L11D5                   ; 11C8
        ldx     zLX0                    ; 11CA
        ldy     zY                      ; 11CC
        iny                             ; 11CE
        jsr     PixelSet                ; 11CF
        bcs     L11D5                   ; 11D2
        rts                             ; 11D4

L11D5:  jsr     TurnVertical            ; 11D5
        sta     zInput                  ; 11D8
        jsr     AIAvoid                 ; 11DA
        rts                             ; 11DD

L11DE:  cmp     #$04                    ; 11DE
        bne     L120E                   ; 11E0
        ldx     zX                      ; 11E2
        ldy     zY                      ; 11E4
        iny                             ; 11E6
        iny                             ; 11E7
        iny                             ; 11E8
        sty     zLX0                    ; 11E9
        jsr     PixelSet                ; 11EB
        bcs     L1205                   ; 11EE
        ldx     zX                      ; 11F0
        dex                             ; 11F2
        ldy     zLX0                    ; 11F3
        jsr     PixelSet                ; 11F5
        bcs     L1205                   ; 11F8
        ldx     zX                      ; 11FA
        inx                             ; 11FC
        ldy     zLX0                    ; 11FD
        jsr     PixelSet                ; 11FF
        bcs     L1205                   ; 1202
        rts                             ; 1204

L1205:  jsr     TurnHorizontal          ; 1205
        sta     zInput                  ; 1208
        jsr     AIAvoid                 ; 120A
        rts                             ; 120D

L120E:  cmp     #$08                    ; 120E
        beq     L1213                   ; 1210
        rts                             ; 1212

L1213:  ldx     zX                      ; 1213
        ldy     zY                      ; 1215
        dey                             ; 1217
        dey                             ; 1218
        dey                             ; 1219
        sty     zLX0                    ; 121A
        jsr     PixelSet                ; 121C
        bcs     L1236                   ; 121F
        ldx     zX                      ; 1221
        dex                             ; 1223
        ldy     zLX0                    ; 1224
        jsr     PixelSet                ; 1226
        bcs     L1236                   ; 1229
        ldx     zX                      ; 122B
        inx                             ; 122D
        ldy     zLX0                    ; 122E
        jsr     PixelSet                ; 1230
        bcs     L1236                   ; 1233
        rts                             ; 1235

L1236:  jsr     TurnHorizontal          ; 1236
        sta     zInput                  ; 1239
        jsr     AIAvoid                 ; 123B
        rts                             ; 123E


; --------------------------------------------------------------------------
; Return 8 (up) if P1 is above, else 4 (down).
; --------------------------------------------------------------------------
TurnVertical:
        lda     zY                      ; 123F
        cmp     zP1Y                    ; 1241
        bcc     L1248                   ; 1243
        lda     #$08                    ; 1245
        rts                             ; 1247

L1248:  lda     #$04                    ; 1248
        rts                             ; 124A


; --------------------------------------------------------------------------
; Return 2 (left) if P1 is left, else 1 (right).
; --------------------------------------------------------------------------
TurnHorizontal:
        lda     zX                      ; 124B
        cmp     zP1X                    ; 124D
        bcc     L1254                   ; 124F
        lda     #$02                    ; 1251
        rts                             ; 1253

L1254:  lda     #$01                    ; 1254
        rts                             ; 1256


; --------------------------------------------------------------------------
; C=1 if pixel (X,Y) is lit.
; --------------------------------------------------------------------------
PixelSet:
        jsr     HiresAddr               ; 1257
        ldy     #$00                    ; 125A
        lda     zMask                   ; 125C
        and     (zPix),y                ; 125E
        cmp     zMask                   ; 1260
        beq     L1266                   ; 1262
        clc                             ; 1264
        rts                             ; 1265

L1266:  sec                             ; 1266
        rts                             ; 1267

AIAvoid:lda     zInput                  ; 1268
        cmp     #$08                    ; 126A
        bne     L1296                   ; 126C
        ldx     zX                      ; 126E
        ldy     zY                      ; 1270
        dey                             ; 1272
        dey                             ; 1273
        dey                             ; 1274
        sty     zLX0                    ; 1275
        jsr     PixelSet                ; 1277
        bcs     L1291                   ; 127A
        ldx     zX                      ; 127C
        dex                             ; 127E
        ldy     zLX0                    ; 127F
        jsr     PixelSet                ; 1281
        bcs     L1291                   ; 1284
        ldx     zX                      ; 1286
        inx                             ; 1288
        ldy     zLX0                    ; 1289
        jsr     PixelSet                ; 128B
        bcs     L1291                   ; 128E
        rts                             ; 1290

L1291:  lda     #$04                    ; 1291
        sta     zInput                  ; 1293
        rts                             ; 1295

L1296:  cmp     #$04                    ; 1296
        bne     L12C2                   ; 1298
        ldx     zX                      ; 129A
        ldy     zY                      ; 129C
        iny                             ; 129E
        iny                             ; 129F
        iny                             ; 12A0
        sty     zLX0                    ; 12A1
        jsr     PixelSet                ; 12A3
        bcs     L12BD                   ; 12A6
        ldx     zX                      ; 12A8
        dex                             ; 12AA
        ldy     zLX0                    ; 12AB
        jsr     PixelSet                ; 12AD
        bcs     L12BD                   ; 12B0
        ldx     zX                      ; 12B2
        inx                             ; 12B4
        ldy     zLX0                    ; 12B5
        jsr     PixelSet                ; 12B7
        bcs     L12BD                   ; 12BA
        rts                             ; 12BC

L12BD:  lda     #$08                    ; 12BD
        sta     zInput                  ; 12BF
        rts                             ; 12C1

L12C2:  cmp     #$02                    ; 12C2
        bne     L12EE                   ; 12C4
        ldx     zX                      ; 12C6
        dex                             ; 12C8
        dex                             ; 12C9
        dex                             ; 12CA
        stx     zLX0                    ; 12CB
        ldy     zY                      ; 12CD
        jsr     PixelSet                ; 12CF
        bcs     L12E9                   ; 12D2
        ldx     zLX0                    ; 12D4
        ldy     zY                      ; 12D6
        dey                             ; 12D8
        jsr     PixelSet                ; 12D9
        bcs     L12E9                   ; 12DC
        ldx     zLX0                    ; 12DE
        ldy     zY                      ; 12E0
        iny                             ; 12E2
        jsr     PixelSet                ; 12E3
        bcs     L12E9                   ; 12E6
        rts                             ; 12E8

L12E9:  lda     #$01                    ; 12E9
        sta     zInput                  ; 12EB
        rts                             ; 12ED

L12EE:  cmp     #$01                    ; 12EE
        beq     L12F3                   ; 12F0
        rts                             ; 12F2

L12F3:  ldx     zX                      ; 12F3
        inx                             ; 12F5
        inx                             ; 12F6
        inx                             ; 12F7
        stx     zLX0                    ; 12F8
        ldy     zY                      ; 12FA
        jsr     PixelSet                ; 12FC
        bcs     L1316                   ; 12FF
        ldx     zLX0                    ; 1301
        ldy     zY                      ; 1303
        dey                             ; 1305
        jsr     PixelSet                ; 1306
        bcs     L1316                   ; 1309
        ldx     zLX0                    ; 130B
        ldy     zY                      ; 130D
        iny                             ; 130F
        jsr     PixelSet                ; 1310
        bcs     L1316                   ; 1313
        rts                             ; 1315

L1316:  lda     #$02                    ; 1316
        sta     zInput                  ; 1318
        rts                             ; 131A


; --------------------------------------------------------------------------
; Computer boosts while it is 30+ pixels from P1 on either axis.
; --------------------------------------------------------------------------
AIBoost:lda     zX                      ; 131B
        sec                             ; 131D
        sbc     zP1X                    ; 131E
        bcs     L1326                   ; 1320
        eor     #$FF                    ; 1322
        adc     #$01                    ; 1324
L1326:  cmp     #$1E                    ; 1326  |dx| < 30?
        bcs     L134A                   ; 1328
        lda     zY                      ; 132A
        sec                             ; 132C
        sbc     zP1Y                    ; 132D
        bcs     L1335                   ; 132F
        eor     #$FF                    ; 1331
        adc     #$01                    ; 1333
L1335:  cmp     #$1E                    ; 1335  |dy| < 30?
        bcs     L134A                   ; 1337
        lda     #$10                    ; 1339
        and     zInput                  ; 133B
        cmp     #$10                    ; 133D
        beq     L1342                   ; 133F
        rts                             ; 1341

L1342:  lda     zInput                  ; 1342
        sec                             ; 1344
        sbc     #$10                    ; 1345
        sta     zInput                  ; 1347
        rts                             ; 1349

L134A:  lda     #$10                    ; 134A
        ora     zInput                  ; 134C
        sta     zInput                  ; 134E
        rts                             ; 1350

SetDirection:
        sta     zDir                    ; 1351
        jmp     L13A9                   ; 1353


; --------------------------------------------------------------------------
; Move the current cycle (zX,zY,zDir,zPlayer) one pixel. Reads keys or AI.
; Normal speed moves on even frames only; boost moves every frame. A new
; direction is accepted only if it isn't zero. Erases the 3-pixel head,
; steps, crash-tests and redraws the head, then plots the trail pixel
; (P2's trail is dotted: plotted on alternate steps).
; --------------------------------------------------------------------------
MovePlayer:
        lda     zPlayer                 ; 1356
        bne     L1360                   ; 1358
        jsr     ReadKeysP1              ; 135A
        jmp     L1370                   ; 135D

L1360:  lda     zOnePlayer              ; 1360
        beq     L136D                   ; 1362
        jsr     ComputerAI              ; 1364
        jsr     AIBoost                 ; 1367
        jmp     L1370                   ; 136A

L136D:  jsr     ReadKeysP2              ; 136D
L1370:  lda     zInput                  ; 1370
        pha                             ; 1372
        and     #$10                    ; 1373
        ldx     zPlayer                 ; 1375
        lsr     a                       ; 1377
        lsr     a                       ; 1378
        lsr     a                       ; 1379
        lsr     a                       ; 137A
        eor     #$01                    ; 137B  zSlowPn = NOT boost
        sta     zSlowP1,x               ; 137D
        lda     zFrame                  ; 137F  odd frame and not boosting -> no move
        and     zSlowP1,x               ; 1381
        beq     L1387                   ; 1383
        pla                             ; 1385
        rts                             ; 1386

L1387:  pla                             ; 1387
        and     #$0F                    ; 1388
        beq     L13A6                   ; 138A
        jsr     EraseHead               ; 138C
        lda     zInput                  ; 138F
        and     #$0F                    ; 1391
        cmp     #$08                    ; 1393
        beq     SetDirection            ; 1395
        cmp     #$04                    ; 1397
        beq     SetDirection            ; 1399
        cmp     #$02                    ; 139B
        beq     SetDirection            ; 139D
        cmp     #$01                    ; 139F
        beq     SetDirection            ; 13A1
        jmp     L13A9                   ; 13A3

L13A6:  jsr     EraseHead               ; 13A6
L13A9:  lda     zPlayer                 ; 13A9  P2 flicker counter
        beq     L13AF                   ; 13AB
        inc     zFlicker                ; 13AD
L13AF:  lda     zDir                    ; 13AF
        cmp     #$08                    ; 13B1
        bne     L13B7                   ; 13B3
        dec     zY                      ; 13B5
L13B7:  cmp     #$04                    ; 13B7
        bne     L13BD                   ; 13B9
        inc     zY                      ; 13BB
L13BD:  cmp     #$02                    ; 13BD
        bne     L13C3                   ; 13BF
        dec     zX                      ; 13C1
L13C3:  cmp     #$01                    ; 13C3
        bne     L13C9                   ; 13C5
        inc     zX                      ; 13C7
L13C9:  lda     zDir                    ; 13C9
        cmp     #$08                    ; 13CB
        bne     L13F1                   ; 13CD
        ldx     zX                      ; 13CF
        ldy     zY                      ; 13D1
        dey                             ; 13D3
        dey                             ; 13D4
        jsr     PlotCheckCrash          ; 13D5
        jsr     PlotPixel               ; 13D8
        dex                             ; 13DB
        iny                             ; 13DC
        jsr     PlotCheckCrash          ; 13DD
        jsr     PlotPixel               ; 13E0
        inx                             ; 13E3
        inx                             ; 13E4
        jsr     PlotCheckCrash          ; 13E5
        jsr     PlotPixel               ; 13E8
        dex                             ; 13EB
        jsr     PlotCheckCrash          ; 13EC
        lda     zDir                    ; 13EF
L13F1:  cmp     #$04                    ; 13F1
        bne     L1417                   ; 13F3
        ldx     zX                      ; 13F5
        ldy     zY                      ; 13F7
        dex                             ; 13F9
        iny                             ; 13FA
        jsr     PlotCheckCrash          ; 13FB
        jsr     PlotPixel               ; 13FE
        inx                             ; 1401
        iny                             ; 1402
        jsr     PlotCheckCrash          ; 1403
        jsr     PlotPixel               ; 1406
        inx                             ; 1409
        dey                             ; 140A
        jsr     PlotCheckCrash          ; 140B
        jsr     PlotPixel               ; 140E
        dex                             ; 1411
        jsr     PlotCheckCrash          ; 1412
        lda     zDir                    ; 1415
L1417:  cmp     #$02                    ; 1417
        bne     L143D                   ; 1419
        ldx     zX                      ; 141B
        ldy     zY                      ; 141D
        dey                             ; 141F
        dex                             ; 1420
        jsr     PlotCheckCrash          ; 1421
        jsr     PlotPixel               ; 1424
        dex                             ; 1427
        iny                             ; 1428
        jsr     PlotCheckCrash          ; 1429
        jsr     PlotPixel               ; 142C
        inx                             ; 142F
        iny                             ; 1430
        jsr     PlotCheckCrash          ; 1431
        jsr     PlotPixel               ; 1434
        dey                             ; 1437
        jsr     PlotCheckCrash          ; 1438
        lda     zDir                    ; 143B
L143D:  cmp     #$01                    ; 143D
        bne     L1461                   ; 143F
        ldx     zX                      ; 1441
        ldy     zY                      ; 1443
        inx                             ; 1445
        dey                             ; 1446
        jsr     PlotCheckCrash          ; 1447
        jsr     PlotPixel               ; 144A
        inx                             ; 144D
        iny                             ; 144E
        jsr     PlotCheckCrash          ; 144F
        jsr     PlotPixel               ; 1452
        dex                             ; 1455
        iny                             ; 1456
        jsr     PlotCheckCrash          ; 1457
        jsr     PlotPixel               ; 145A
        dey                             ; 145D
        jsr     PlotCheckCrash          ; 145E
L1461:  lda     zPlayer                 ; 1461  P2 trail only on alternate steps
        beq     L146B                   ; 1463
        lda     zFlicker                ; 1465
        and     #$01                    ; 1467
        bne     L1475                   ; 1469
L146B:  ldx     zX                      ; 146B
        ldy     zY                      ; 146D
        jsr     HiresAddr               ; 146F
        jsr     PlotPixel               ; 1472
L1475:  rts                             ; 1475

EraseHead:
        lda     zDir                    ; 1476
        cmp     #$08                    ; 1478
        bne     L1491                   ; 147A
        ldx     zX                      ; 147C
        ldy     zY                      ; 147E
        dey                             ; 1480
        dey                             ; 1481
        jsr     UnplotPixel             ; 1482
        dex                             ; 1485
        iny                             ; 1486
        jsr     UnplotPixel             ; 1487
        inx                             ; 148A
        inx                             ; 148B
        jsr     UnplotPixel             ; 148C
        lda     zDir                    ; 148F
L1491:  cmp     #$04                    ; 1491
        bne     L14AA                   ; 1493
        ldx     zX                      ; 1495
        ldy     zY                      ; 1497
        dex                             ; 1499
        iny                             ; 149A
        jsr     UnplotPixel             ; 149B
        inx                             ; 149E
        iny                             ; 149F
        jsr     UnplotPixel             ; 14A0
        inx                             ; 14A3
        dey                             ; 14A4
        jsr     UnplotPixel             ; 14A5
        lda     zDir                    ; 14A8
L14AA:  cmp     #$02                    ; 14AA
        bne     L14C3                   ; 14AC
        ldx     zX                      ; 14AE
        ldy     zY                      ; 14B0
        dey                             ; 14B2
        dex                             ; 14B3
        jsr     UnplotPixel             ; 14B4
        dex                             ; 14B7
        iny                             ; 14B8
        jsr     UnplotPixel             ; 14B9
        inx                             ; 14BC
        iny                             ; 14BD
        jsr     UnplotPixel             ; 14BE
        lda     zDir                    ; 14C1
L14C3:  cmp     #$01                    ; 14C3
        bne     L14DA                   ; 14C5
        ldx     zX                      ; 14C7
        ldy     zY                      ; 14C9
        inx                             ; 14CB
        dey                             ; 14CC
        jsr     UnplotPixel             ; 14CD
        inx                             ; 14D0
        iny                             ; 14D1
        jsr     UnplotPixel             ; 14D2
        dex                             ; 14D5
        iny                             ; 14D6
        jsr     UnplotPixel             ; 14D7
L14DA:  rts                             ; 14DA


; --------------------------------------------------------------------------
; Load AY R0-R13 from table at (X lo, Y hi).
; --------------------------------------------------------------------------
AyLoadAll:
        php                             ; 14DB
        sei                             ; 14DC
        stx     zTmp0                   ; 14DD
        sty     zTmp1                   ; 14DF
        ldy     #$00                    ; 14E1
L14E3:  lda     (zTmp0),y               ; 14E3
        tax                             ; 14E5
        tya                             ; 14E6
        pha                             ; 14E7
        jsr     AyWrite                 ; 14E8
        pla                             ; 14EB
        tay                             ; 14EC
        iny                             ; 14ED
        cpy     #$0E                    ; 14EE
        bne     L14E3                   ; 14F0
        plp                             ; 14F2
        rts                             ; 14F3


; --------------------------------------------------------------------------
; Per-frame delay: zSpeed x 256 DEY loops.
; --------------------------------------------------------------------------
FrameDelay:
        ldx     zSpeed                  ; 14F4
DelayX: ldy     #$00                    ; 14F6
L14F8:  dey                             ; 14F8
        bne     L14F8                   ; 14F9
        dex                             ; 14FB
        bne     L14F8                   ; 14FC
        rts                             ; 14FE


; --------------------------------------------------------------------------
; Write X to AY register A via VIA port A + PCR (BC1/BDIR on CA2/CB2).
; R7 (mixer) always gets bit 6 set to keep AY port A as output (keyboard).
; --------------------------------------------------------------------------
AyWrite:php                             ; 14FF
        sei                             ; 1500
        sta     VIA_ORA_NH              ; 1501
        cmp     #$07                    ; 1504
        bne     L150E                   ; 1506
        txa                             ; 1508
        ora     #$40                    ; 1509  keep AY port A as output
        jmp     L150F                   ; 150B

L150E:  txa                             ; 150E
L150F:  pha                             ; 150F
        ldx     #$0C                    ; 1510
        ldy     #$EE                    ; 1512  PCR: BDIR+BC1 = latch address
        lda     #$11                    ; 1514
        jsr     PcrModify               ; 1516
        ldy     #$CC                    ; 1519  PCR: inactive
        lda     #$11                    ; 151B
        jsr     PcrModify               ; 151D
        pla                             ; 1520
        sta     VIA_ORA_NH              ; 1521
        ldy     #$EC                    ; 1524  PCR: BDIR = write data
        lda     #$11                    ; 1526
        jsr     PcrModify               ; 1528
        ldy     #$CC                    ; 152B
        lda     #$11                    ; 152D
        jsr     PcrModify               ; 152F
        plp                             ; 1532
        rts                             ; 1533


; --------------------------------------------------------------------------
; Print the 8 hi-score entries with rank, score and name.
; --------------------------------------------------------------------------
PrintHiscores:
        lda     #$00                    ; 1534
        sta     zDir                    ; 1536
        lda     #$21                    ; 1538
        sta     zLoop                   ; 153A
        lda     #$BC                    ; 153C
        sta     zX                      ; 153E
        lda     #$31                    ; 1540
        sta     zY                      ; 1542
L1544:  ldy     #$00                    ; 1544
        ldx     zY                      ; 1546
        lda     RankInkBase,x           ; 1548
        jsr     PutChar                 ; 154B
        ldx     zDir                    ; 154E
        iny                             ; 1550
        iny                             ; 1551
        lda     zY                      ; 1552
        jsr     PutChar                 ; 1554
        lda     #$2E                    ; 1557
        jsr     PutChar                 ; 1559
        iny                             ; 155C
        lda     #$08                    ; 155D
        sta     zInput                  ; 155F
L1561:  lda     HISCORE_TAB,x           ; 1561
        jsr     PutChar                 ; 1564
        inx                             ; 1567
        dec     zInput                  ; 1568
        bne     L1561                   ; 156A
        iny                             ; 156C
        lda     #$2D                    ; 156D
        jsr     PutChar                 ; 156F
        jsr     PutChar                 ; 1572
        jsr     PutChar                 ; 1575
        iny                             ; 1578
L1579:  lda     HISCORE_TAB,x           ; 1579
        cmp     #$0D                    ; 157C
        beq     L1586                   ; 157E
        jsr     PutChar                 ; 1580
        inx                             ; 1583
        bne     L1579                   ; 1584
L1586:  lda     zLoop                   ; 1586
        clc                             ; 1588
        adc     #$50                    ; 1589
        sta     zLoop                   ; 158B
        bcc     L1591                   ; 158D
        inc     zX                      ; 158F
L1591:  inc     zY                      ; 1591
        lda     zDir                    ; 1593
        cmp     zP1X                    ; 1595
        bne     L15A3                   ; 1597
        lda     zLoop                   ; 1599
        sta     zCurPtr                 ; 159B
        lda     zX                      ; 159D
        sta     zCurPtrH                ; 159F
        lda     zDir                    ; 15A1
L15A3:  clc                             ; 15A3
        adc     #$1C                    ; 15A4
        sta     zDir                    ; 15A6
        cmp     #$E0                    ; 15A8
        beq     L15AF                   ; 15AA
        jmp     L1544                   ; 15AC

L15AF:  rts                             ; 15AF


; --------------------------------------------------------------------------
; Store A at (zLoop),Y and advance Y.
; --------------------------------------------------------------------------
PutChar:sta     (zLoop),y               ; 15B0
        iny                             ; 15B2
        rts                             ; 15B3


; --------------------------------------------------------------------------
; Double-height 'LIGHT CYCLE HEROES' title (rows 0-1).
; --------------------------------------------------------------------------
HiscoreTitle:
        ldx     #$27                    ; 15B4
L15B6:  lda     HiTitle,x               ; 15B6
        sta     TEXT_SCREEN,x           ; 15B9
        sta     $BBA8,x                 ; 15BC
        dex                             ; 15BF
        bpl     L15B6                   ; 15C0
        rts                             ; 15C2


; --------------------------------------------------------------------------
; Insert NEW_SCORE into the table if it beats an entry, then let the player
; type a name (or auto-type COMPUTER if the computer won).
; --------------------------------------------------------------------------
HiscoreEntry:
        lda     #$00                    ; 15C3
        sta     zP1X                    ; 15C5
        lda     #$B8                    ; 15C7
        sta     zP1Y                    ; 15C9
L15CB:  ldy     #$07                    ; 15CB
        sec                             ; 15CD
L15CE:  lda     (zP1X),y                ; 15CE  entry score - new score
        sbc     NEW_SCORE,y             ; 15D0
        dey                             ; 15D3
        bne     L15CE                   ; 15D4
        bcc     L15E7                   ; 15D6
        lda     zP1X                    ; 15D8
        clc                             ; 15DA
        adc     #$1C                    ; 15DB
        sta     zP1X                    ; 15DD
        sec                             ; 15DF
        cmp     #$C5                    ; 15E0
        bcc     L15CB                   ; 15E2
        jmp     PlayAgain               ; 15E4

L15E7:  lda     zP1X                    ; 15E7
        cmp     #$C4                    ; 15E9
        beq     L15FA                   ; 15EB
        ldx     #$C4                    ; 15ED
L15EF:  dex                             ; 15EF
        lda     HISCORE_TAB,x           ; 15F0
        sta     HISCORE_ENTRY1,x        ; 15F3
        cpx     zP1X                    ; 15F6
        bne     L15EF                   ; 15F8
L15FA:  ldx     zP1X                    ; 15FA
        lda     #$0D                    ; 15FC  terminate name
        sta     HISCORE_NAME0,x         ; 15FE
        ldy     #$07                    ; 1601
L1603:  lda     NEW_SCORE,y             ; 1603
        sta     (zP1X),y                ; 1606
        dey                             ; 1608
        cpy     #$01                    ; 1609
        bne     L1603                   ; 160B
        jsr     ClearTextScreen         ; 160D
        ldx     #$1A                    ; 1610
L1612:  lda     EnterNameText,x         ; 1612
        sta     $BF94,x                 ; 1615
        dex                             ; 1618
        bpl     L1612                   ; 1619
        ldx     #$07                    ; 161B
L161D:  lda     NEW_NAME,x              ; 161D
        sta     $BFAE,x                 ; 1620
        dex                             ; 1623
        bpl     L161D                   ; 1624
        jsr     PrintHiscores           ; 1626
        jsr     HiscoreTitle            ; 1629
        lda     #$00                    ; 162C
        sta     ROM_CURCOL              ; 162E
        lda     zCurPtr                 ; 1631
        sec                             ; 1633
        sbc     #$3D                    ; 1634
        sta     zCurPtr                 ; 1636
        bcs     L163C                   ; 1638
        dec     zCurPtrH                ; 163A
L163C:  lda     #$B8                    ; 163C
        sta     zP1Y                    ; 163E
        lda     #$08                    ; 1640
        sta     zP2X                    ; 1642
        sta     ROM_KEY                 ; 1644
        cli                             ; 1647
        lda     PART_X                  ; 1648
        cmp     #$43                    ; 164B  'C': computer won -> auto name
        beq     L1677                   ; 164D
L164F:  lda     ROM_KEY                 ; 164F
        bpl     L164F                   ; 1652
        and     #$7F                    ; 1654
        ldy     #$00                    ; 1656
        sty     ROM_KEY                 ; 1658
        cmp     #$7F                    ; 165B  DEL
        bne     L16A0                   ; 165D
        dec     zP2X                    ; 165F
        lda     zP2X                    ; 1661
        cmp     #$07                    ; 1663
        bne     L166C                   ; 1665
        inc     zP2X                    ; 1667
        jmp     L164F                   ; 1669

L166C:  lda     #$20                    ; 166C
        sta     (zCurPtr),y             ; 166E
        dec     zCurPtr                 ; 1670
        sta     (zCurPtr),y             ; 1672
        jmp     L164F                   ; 1674

L1677:  ldx     #$00                    ; 1677
L1679:  lda     NameComputer,x          ; 1679
        ldy     zP2X                    ; 167C
        sta     (zP1X),y                ; 167E
        inc     zP2X                    ; 1680
        ldy     #$00                    ; 1682
        sta     (zCurPtr),y             ; 1684
        inc     zCurPtr                 ; 1686
        txa                             ; 1688
        pha                             ; 1689
        jsr     Delay                   ; 168A
        jsr     Delay                   ; 168D
        pla                             ; 1690
        tax                             ; 1691
        inx                             ; 1692
        cpx     #$08                    ; 1693
        bne     L1679                   ; 1695
        ldy     zP2X                    ; 1697
        lda     #$0D                    ; 1699
        sta     (zP1X),y                ; 169B
        jmp     PlayAgain               ; 169D

L16A0:  cmp     #$0D                    ; 16A0  RETURN
        beq     L16C1                   ; 16A2
        cmp     #$20                    ; 16A4
        bcs     L16AB                   ; 16A6
        jmp     L164F                   ; 16A8

L16AB:  ldy     zP2X                    ; 16AB
        cpy     #$1B                    ; 16AD
        bne     L16B4                   ; 16AF
        jmp     L164F                   ; 16B1

L16B4:  sta     (zP1X),y                ; 16B4
        inc     zP2X                    ; 16B6
        ldy     #$00                    ; 16B8
        sta     (zCurPtr),y             ; 16BA
        inc     zCurPtr                 ; 16BC
        jmp     L164F                   ; 16BE

L16C1:  ldy     zP2X                    ; 16C1
        sta     (zP1X),y                ; 16C3

; --------------------------------------------------------------------------
; Show table, wait for SPACE (menu) or V (volume).
; --------------------------------------------------------------------------
PlayAgain:
        jsr     ClearTextScreen         ; 16C5
        jsr     HiscoreTitle            ; 16C8
        jsr     PrintHiscores           ; 16CB
        jsr     HideCursor              ; 16CE
        ldx     #$62                    ; 16D1
L16D3:  lda     PlayAgainText,x         ; 16D3
        sta     $BF92,x                 ; 16D6
        dex                             ; 16D9
        bpl     L16D3                   ; 16DA
L16DC:  jsr     FlashTitle              ; 16DC
        lda     ROM_KEY                 ; 16DF
        beq     L16DC                   ; 16E2
        and     #$7F                    ; 16E4
        ldx     #$00                    ; 16E6
        stx     ROM_KEY                 ; 16E8
        cmp     #$20                    ; 16EB  SPACE -> menu
        bne     L16F0                   ; 16ED
        rts                             ; 16EF

L16F0:  cmp     #$56                    ; 16F0  'V' -> volume
        bne     L16DC                   ; 16F2
        jmp     VolumeThenMenu          ; 16F4


; --------------------------------------------------------------------------
; VIA reg X = (reg X AND A) OR Y, with IRQs masked.
; --------------------------------------------------------------------------
PcrModify:
        php                             ; 16F7
        sei                             ; 16F8
        and     VIA_ORB,x               ; 16F9
        sta     ROM_TMP20F              ; 16FC
        tya                             ; 16FF
        ora     ROM_TMP20F              ; 1700
        sta     VIA_ORB,x               ; 1703
        plp                             ; 1706
        rts                             ; 1707


; --------------------------------------------------------------------------
; Cycle the ink attribute of the title rows through 0-6.
; --------------------------------------------------------------------------
FlashTitle:
        ldy     #$28                    ; 1708
L170A:  dey                             ; 170A
        bne     L170A                   ; 170B
        lda     TEXT_SCREEN             ; 170D
        cmp     #$16                    ; 1710
        beq     L171B                   ; 1712
        inc     TEXT_SCREEN             ; 1714
        inc     $BBA8                   ; 1717
        rts                             ; 171A

L171B:  lda     #$10                    ; 171B
        sta     TEXT_SCREEN             ; 171D
        sta     $BBA8                   ; 1720
        rts                             ; 1723


; --------------------------------------------------------------------------
; Add 1 to TIME every 4 frames (speed 4-9) or 8 frames (speed 1-3).
; --------------------------------------------------------------------------
TickTime:
        lda     zSpeed                  ; 1724
        cmp     #$04                    ; 1726
        bcc     L1733                   ; 1728
        lda     zFrame                  ; 172A
        and     #$03                    ; 172C
        cmp     #$03                    ; 172E
        beq     L173C                   ; 1730
        rts                             ; 1732

L1733:  lda     zFrame                  ; 1733
        and     #$07                    ; 1735
        cmp     #$07                    ; 1737
        beq     L173C                   ; 1739
        rts                             ; 173B

L173C:  lda     #$C7                    ; 173C
        sta     zDigPtr                 ; 173E
        lda     #$BF                    ; 1740
        sta     zDigPtrH                ; 1742
        lda     #$01                    ; 1744
        jsr     AddDigitUnits           ; 1746
        ldx     #$07                    ; 1749
L174B:  lda     $BFC7,x                 ; 174B
        sta     $BF9F,x                 ; 174E
        dex                             ; 1751
        bpl     L174B                   ; 1752
        rts                             ; 1754


; --------------------------------------------------------------------------
; Start a round: random starts, clear HIRES, border, paper colour, status
; line, VIA to game mode, obstacles, sound, engine sweep. Runs with IRQs
; masked: keyboard is scanned directly.
; --------------------------------------------------------------------------
RoundStart:
        sei                             ; 1755
        jsr     RandomStarts            ; 1756
        jsr     ClearHires              ; 1759
        jsr     DrawBorder              ; 175C
        jsr     SetPaperColour          ; 175F
        jsr     DrawStatusLine          ; 1762
        jsr     ViaGameSetup            ; 1765
        lda     #$07                    ; 1768  DDRB = 7: PB0-2 out (keyboard row)
        sta     VIA_DDRB                ; 176A
        jsr     DrawObstacles           ; 176D
        jsr     SoundInit               ; 1770
        lda     zVolume                 ; 1773
        beq     GameLoop                ; 1775
        jsr     StartSweep              ; 1777

; --------------------------------------------------------------------------
; One frame: move P1, move P2, frame++, bonus blocks, TIME, delay, sound.
; --------------------------------------------------------------------------
GameLoop:
        lda     #$00                    ; 177A  --- P1 ---
        sta     zPlayer                 ; 177C
        lda     zP1X                    ; 177E
        sta     zX                      ; 1780
        lda     zP1Y                    ; 1782
        sta     zY                      ; 1784
        lda     zP1Dir                  ; 1786
        sta     zDir                    ; 1788
        jsr     MovePlayer              ; 178A
        lda     zY                      ; 178D
        sta     zP1Y                    ; 178F
        lda     zX                      ; 1791
        sta     zP1X                    ; 1793
        lda     zDir                    ; 1795
        sta     zP1Dir                  ; 1797
        lda     #$01                    ; 1799  --- P2 ---
        sta     zPlayer                 ; 179B
        lda     zP2X                    ; 179D
        sta     zX                      ; 179F
        lda     zP2Y                    ; 17A1
        sta     zY                      ; 17A3
        lda     zP2Dir                  ; 17A5
        sta     zDir                    ; 17A7
        jsr     MovePlayer              ; 17A9
        lda     zY                      ; 17AC
        sta     zP2Y                    ; 17AE
        lda     zX                      ; 17B0
        sta     zP2X                    ; 17B2
        lda     zDir                    ; 17B4
        sta     zP2Dir                  ; 17B6
        inc     zFrame                  ; 17B8  frame++
        jsr     BonusBlocks             ; 17BA
        jsr     TickTime                ; 17BD
        jsr     FrameDelay              ; 17C0
        jsr     EngineSound             ; 17C3
        jmp     GameLoop                ; 17C6


; --------------------------------------------------------------------------
; Tape padding.
; --------------------------------------------------------------------------
Padding:.byte   $FF,$55,$55,$55,$55,$55,$55,$55; 17C9
        .byte   $55,$55,$55,$55,$55,$55,$55,$55; 17D1
        .byte   $55,$55,$55,$55,$55,$55,$55,$55; 17D9
        .byte   $55,$55,$55,$55,$55,$55,$55,$55; 17E1
        .byte   $55,$55,$55,$55,$55,$55,$55,$55; 17E9
        .byte   $55,$55,$55,$55,$55,$55,$55,$55; 17F1
        .byte   $55,$55,$55,$55,$55,$55,$55,$55; 17F9
