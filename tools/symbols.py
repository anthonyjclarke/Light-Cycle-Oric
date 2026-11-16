"""Symbol, range and comment tables for the Light Cycle (Oric) disassembly.

Consumed by tools/build_disasm.py. Addresses are as loaded in Oric RAM.
"""

# ---------------------------------------------------------------------------
# Shared symbols (hardware, ROM workspace, zero page) — both blocks
# ---------------------------------------------------------------------------
HW = {
    # 6522 VIA at $0300
    0x0300: ("VIA_ORB", "VIA port B: PB0-2 keyboard row, PB3 key sense, PB4 printer strobe, PB6 tape relay, PB7 tape out"),
    0x0302: ("VIA_DDRB", "VIA data direction B"),
    0x0303: ("VIA_DDRA", "VIA data direction A (AY data bus)"),
    0x0304: ("VIA_T1CL", "VIA timer 1 counter low"),
    0x0305: ("VIA_T1CH", "VIA timer 1 counter high"),
    0x0306: ("VIA_T1LL", "VIA timer 1 latch low"),
    0x0307: ("VIA_T1LH", "VIA timer 1 latch high"),
    0x030B: ("VIA_ACR", "VIA auxiliary control"),
    0x030C: ("VIA_PCR", "VIA peripheral control: CA2=AY BC1, CB2=AY BDIR"),
    0x030E: ("VIA_IER", "VIA interrupt enable"),
    0x030F: ("VIA_ORA_NH", "VIA port A, no handshake (AY data bus)"),
    # Oric ROM workspace (page 2) reused by the game
    0x020F: ("ROM_TMP20F", "ROM scratch byte, borrowed by PcrModify"),
    0x022B: ("ROM_VAR22B", "ROM system variable (set to $40 at start; meaning unverified)"),
    0x0269: ("ROM_CURCOL", "ROM text cursor column (unverified)"),
    0x026A: ("ROM_SCRFLAGS", "ROM screen/keyboard flags; bit 3 = keyclick off"),
    0x0271: ("ROM_TIMERS", "ROM IRQ countdown timers $0271-$0277"),
    0x0272: ("ROM_TIMERS1", "ROM timer slots (word pairs)"),
    0x0273: ("ROM_TIMERS1H", ""),
    0x02DF: ("ROM_KEY", "ROM IRQ keyboard: last key, bit 7 set = new key"),
    # Video memory (48K addresses; on a 16K Oric they mirror to $1800-$3FFF)
    0x9800: ("HIRES_CHARSET", "HIRES-mode character set (std $9800, alt $9C00)"),
    0x9D00: ("PART_LIFE", "Explosion particle tables (32 each) in HIRES alt-charset RAM"),
    0x9D20: ("PART_X", ""),
    0x9D40: ("PART_TX", ""),
    0x9D60: ("PART_Y", ""),
    0x9D80: ("PART_TY", ""),
    0x9DA0: ("PART_DX", ""),
    0x9DC0: ("PART_DY", ""),
    0x9DE0: ("PART_SX", ""),
    0x9E00: ("PART_SY", ""),
    0x9E20: ("PART_ERRX", ""),
    0x9E40: ("PART_ERRY", ""),
    0xA001: ("HIRES_ROW0_C1", "HIRES bitmap row 0, column 1"),
    0xB400: ("TEXT_CHARSET", "TEXT-mode standard character set"),
    0xB800: ("HISCORE_TAB", "High-score table: 8 x 28-byte entries in TEXT alt-charset RAM"),
    0xB808: ("HISCORE_NAME0", "Entry 0 name field"),
    0xB81C: ("HISCORE_ENTRY1", "Entry 1"),
    0xB900: ("NEW_SCORE", "Winner's score, carried across the charset shuffle"),
    0xB920: ("NEW_NAME", "Winner's name, carried across the charset shuffle"),
    0xBB80: ("TEXT_SCREEN", "TEXT screen 40x28"),
    0xBF68: ("HIRES_STATUS0", "HIRES-mode text row 0 (of 3)"),
    0xBF90: ("HIRES_STATUS1", "HIRES-mode text row 1"),
    0xBFB8: ("HIRES_STATUS2", "HIRES-mode text row 2"),
    0xBFDF: ("SCREEN_LAST", "Last screen byte: a $1A/$1E here switches TEXT/HIRES"),
}

ZP = {
    0x00: "zTmp0", 0x01: "zTmp1", 0x02: "zTmp2", 0x03: "zTmp3", 0x04: "zTmp4",
    0x05: "zTmp5", 0x06: "zTmp6", 0x07: "zTmp7", 0x08: "zTmp8",
    0x12: "zCurPtr", 0x13: "zCurPtrH",
    0x30: "zLoop", 0x31: "zX", 0x32: "zY", 0x33: "zDir", 0x34: "zPlayer",
    0x35: "zInput", 0x37: "zPix", 0x38: "zPixH", 0x39: "zMask",
    0x3A: "zP1Dir", 0x3B: "zP2Dir", 0x3C: "zSaveX", 0x3D: "zSaveY", 0x3E: "zSaveA",
    0x40: "zP1X", 0x41: "zP1Y", 0x42: "zP2X", 0x43: "zP2Y",
    0x44: "zBonusTmr", 0x46: "zBonusState", 0x47: "zBonusPtr", 0x48: "zBonusPtrH",
    0x4A: "zLX0", 0x4B: "zLX1", 0x4C: "zLY0", 0x4D: "zLY1", 0x4E: "zLDX",
    0x4F: "zLDY", 0x50: "zLErrX", 0x51: "zLErrY", 0x52: "zLSX", 0x53: "zLSY",
    0x54: "zSlowP1", 0x55: "zSlowP2", 0x56: "zFlicker", 0x57: "zDigPtr",
    0x58: "zDigPtrH", 0x59: "zDigTmp", 0x5A: "zObA", 0x5B: "zObB", 0x5C: "zObC",
    0x5D: "zObD", 0x5E: "zObE", 0x5F: "zObF", 0x60: "zLineStep",
    0x62: "zOnePlayer", 0x63: "zSliderPtrH", 0x64: "zLastSlowP1",
    0x65: "zLastSlowP2", 0x67: "zVolume", 0x68: "zSpeed",
    0xD2: "zRnd2", 0xD3: "zRnd3", 0xD4: "zRndEnd", 0xFF: "zFrame",
}

ZP_DOC = """\
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
"""

# ---------------------------------------------------------------------------
# GAME block ($0400-$1800)
# ---------------------------------------------------------------------------
# (start, end, type, name, block-comment)
GAME_RANGES = [
    (0x0400, 0x0402, "Code", "Entry", "Autorun entry point (CLOAD'd block starts here)."),
    (0x0403, 0x0423, "ByteTable", "Unused0403", "Unreferenced: leftover bytes."),
    (0x0424, 0x0429, "ByteTable", "ViaRegIdx", "ViaGameSetup: VIA register numbers (read with Y=6..0, overlaps next table)."),
    (0x042A, 0x042F, "ByteTable", "ViaRegVal", "ViaGameSetup: values for those VIA registers."),
    (0x0430, 0x0435, "ByteTable", "BonusRowOfs", "Row offsets (x40) for the 6-line bonus block. Byte 0 doubles as ViaRegVal[6]."),
    (0x0436, 0x044D, "ByteTable", "BonusGfx", "Bonus block frames: 6 HIRES bytes each (box / ring / dot / blank)."),
    (0x044E, 0x0453, "ByteTable", "BonusFrameOfs", "Animation sequence: offsets into BonusGfx."),
    (0x0454, 0x0471, "TextTable", "StatusText", "HIRES status row 0 (40 bytes incl. attributes): PLAYER 1 / TIME / P2 name."),
    (0x0472, 0x047B, "TextTable", "StatusP2Name", "P2 name slot inside StatusText; overwritten with COMPUTER or PLAYER 2."),
    (0x047C, 0x0487, "ByteTable", "Unused047C", "Unreferenced."),
    (0x0488, 0x048A, "ByteTable", "TimeAttrL", "Attributes left of TIME digits (double-height)."),
    (0x048B, 0x048F, "ByteTable", "TimeAttrR", "Attributes right of TIME digits."),
    (0x0490, 0x04AF, "ByteTable", "ExplodeDX", "Explosion: 32 signed X offsets for particle targets."),
    (0x04B0, 0x04BF, "ByteTable", "ExplodeAY", "Explosion: AY registers R0-R13 (noise on all channels, envelope decay)."),
    (0x04C0, 0x04DF, "ByteTable", "ExplodeDY", "Explosion: 32 signed Y offsets for particle targets."),
    (0x04E0, 0x04EF, "ByteTable", "Unused04E0", "Unreferenced."),
    (0x04F0, 0x04FF, "ByteTable", "GlyphBike", "Glyphs for chars '{' '|': little light-cycle icon on the status line."),
    (0x0500, 0x0527, "TextTable", "VolText1", "Volume screen text."),
    (0x0528, 0x0537, "TextTable", "VolText2", ""),
    (0x0538, 0x053F, "TextTable", "VolOff", ""),
    (0x0540, 0x054F, "TextTable", "VolLoud", ""),
    (0x0550, 0x055F, "ByteTable", "GlyphArrows", "Glyphs for '}' (down arrow) and '~' (slider marker / left arrow)."),
    (0x0560, 0x057F, "TextTable", "VolText3", ""),
    (0x0580, 0x05A0, "TextTable", "PlayersPrompt", "NUMBER OF PLAYERS (1 or 2)?"),
    (0x05A1, 0x05A7, "ByteTable", "PixelMask", "HIRES bit for x MOD 6 (bit 6 always set = pixel data byte)."),
    (0x05A8, 0x05CF, "TextTable", "SpeedPrompt", "SPEED (1-Fast TO 9-Slow)?"),
    (0x05D0, 0x05EE, "TextTable", "HiTitle", "LIGHT CYCLE HEROES title row."),
    (0x05EF, 0x05F7, "TextTable", "RankInkBase", "= RankInk - $31: indexed by ASCII '1'..'8'."),
    (0x05F8, 0x05FF, "TextTable", "NameComputer", ""),
    (0x0600, 0x0607, "TextTable", "NamePlayer2", ""),
    (0x0608, 0x0618, "TextTable", "HiDefault", "Default hi-score entry: 8-byte score field + name + CR."),
    (0x0619, 0x061F, "ByteTable", "PaperColours", "Random arena paper colour attribute: red / blue / magenta / black."),
    (0x0620, 0x062F, "ByteTable", "RankInk", "Ink colour per hi-score rank."),
    (0x0630, 0x067F, "TextTable", "PlayAgainText", "Bottom rows: PRESS SPACE BAR TO PLAY AGAIN / V TO ADJUST VOLUME."),
    (0x0680, 0x069F, "TextTable", "EnterNameText", "PLEASE ENTER YOUR NAME."),
    (0x06A0, 0x06A4, "ByteTable", "KeyRowP1", "P1 keys (2 up, A down, W left, E right, R boost): keyboard matrix row..."),
    (0x06A5, 0x06A9, "ByteTable", "KeyColP1", "...column mask (AY port A, active low)..."),
    (0x06AA, 0x06AE, "ByteTable", "KeyBitP1", "...and the zInput bit it sets."),
    (0x06AF, 0x06B3, "ByteTable", "KeyRowP2", "P2 keys (] up, R-SHIFT down, ; left, ' right, L boost)."),
    (0x06B4, 0x06B8, "ByteTable", "KeyColP2", ""),
    (0x06B9, 0x06BF, "ByteTable", "KeyBitP2", ""),
    (0x06C0, 0x0A7D, "Code", None, None),
    (0x0A7E, 0x0A88, "Code", "DeadClearStatus", "DEAD CODE (unreferenced): blank the 3 HIRES status rows."),
    (0x0A89, 0x1005, "Code", None, None),
    (0x1006, 0x1026, "Code", "DeadCharsetCopy", "DEAD CODE (unreferenced): earlier copy of CharsetToHires."),
    (0x1027, 0x17C8, "Code", None, None),
    (0x17C9, 0x1800, "ByteTable", "Padding", "Tape padding."),
]

GAME_LABELS = {
    0x06C0: ("Start", """\
Cold start: reset stack, clear game zero page $30-$70, keyclick off,
build custom glyphs and the hi-score table, then volume -> menu -> game."""),
    0x06E3: ("VolumeThenMenu", "'V' on the play-again screen re-enters here."),
    0x06E9: ("MainMenu", "Players + speed prompts, switch to HIRES, reset scores, play."),
    0x06FB: ("TextModeCls", "Hide cursor, clear text screen, force TEXT mode via last screen byte."),
    0x0707: ("GameOver", """\
After the winner flash: ~1.5 s pause, copy the HIRES charset area back to
$B400 (this also carries NEW_SCORE/NEW_NAME from $9D00/$9D20 to $B900/$B920),
then hi-score entry and back to the menu. NOTE: SP is never reset here, so
the 4 bytes leaked per crash (JMP out of nested JSRs) wrap harmlessly."""),
    0x0724: ("InitHiscores", "Fill 9 x 28-byte slots at $B800 with the 17-byte default entry."),
    0x0742: ("WaitKey", "Block until ROM IRQ delivers a key; return it in A (bit 7 stripped)."),
    0x0751: ("AskPlayersAndSpeed", ""),
    0x0764: ("Delay", "Busy-wait ~0.15 s (12 x 10 x 256 DEY loops)."),
    0x0777: ("HideCursor", "Blank the cursor cell and point the ROM cursor at $C0C0 (ROM) so it vanishes."),
    0x0786: ("AskPlayers", "1 -> zOnePlayer=1, P2 named COMPUTER; 2 -> PLAYER 2."),
    0x07C4: ("AskSpeed", "Digit 1-9 -> zSpeed."),
    0x07E2: ("VolumeScreen", """\
Volume screen: rainbow bar of 16 rows, '~' marker moved with cursor
up/down, plays a test tone through AY channel A; RETURN to accept."""),
    0x08E1: ("HiresAddr", """\
In: X = pixel x (0-239), Y = pixel y (0-199).
Out: zPix = $A000 + 40*y + x/6, zMask = PixelMask[x mod 6]. Preserves A/X/Y."""),
    0x0954: ("AddDigitUnits", "A added to the ASCII decimal number at (zDigPtr), units digit (Y=7)."),
    0x0956: ("AddDigit", "Add A to digit Y of the 8-char ASCII number at (zDigPtr), rippling carry left."),
    0x0974: ("EngineSound", "When either player's boost state changes, retune AY ch A (P1) / ch B (P2)."),
    0x09D9: ("StartSweep", "Round start: both engines sweep up in pitch while the volume ramps."),
    0x0A37: ("CharsetToText", "Copy 7 pages $9800 -> $B400 (HIRES charset area back to TEXT location)."),
    0x0A58: ("CharsetToHires", "Copy 7 pages $B400 -> $9800, then write $1E to switch to HIRES."),
    0x0A89: ("DrawLine", """\
Bresenham line (zLX0,zLY0) -> (zLX1,zLY1), plotting each point.
With zLineStep set it returns after one step (used by the explosion)."""),
    0x0AB3: ("LinePlot", ""),
    0x0AB6: ("LineStep", "Resume entry: one Bresenham step from saved state."),
    0x0B0B: ("DrawObstacles", """\
Four random-length diagonal walls from the top and bottom edges and four
from the side edges, all pointing toward the centre."""),
    0x0BC4: ("DrawStatusLine", "Fill the 3 HIRES text rows: names, TIME, lives and scores."),
    0x0BFB: ("PlotLinePoint", ""),
    0x0C06: ("Explosion", """\
32-particle explosion at (zX,zY). Each particle has a random life and a
target from ExplodeDX/DY; each tick it erases its pixel, steps one Bresenham
step toward its target and replots. Particle state lives at $9D00-$9E5F."""),
    0x0CEF: ("PartLoadEnds", ""),
    0x0D06: ("PartLoadState", ""),
    0x0D27: ("PartSaveState", ""),
    0x0D48: ("ViaRestoreRom", "Re-establish the ROM's VIA setup (100 Hz T1 IRQ, keyboard/AY idle)."),
    0x0DA4: ("SetRomTimer", "Store X/Y into ROM timer slot A (copy of the ROM routine)."),
    0x0DC1: ("ViaGameSetup", "Disable the T1 IRQ and program VIA for direct keyboard scanning."),
    0x0DDB: ("Random", "Additive RNG over $D0-$D3; callers read zRnd2/zRnd3."),
    0x0DEA: ("DrawBorder", "Arena frame: solid top/bottom HIRES rows, 1-pixel left/right edges."),
    0x0E1C: ("SetPaperColour", "Random paper colour attribute into column 0 of every HIRES row."),
    0x0E48: ("RandomStarts", "P1 at x=25 heading right, P2 at x=215 heading left, random heights."),
    0x0E72: ("SoundInit", "AY: tones A+B on, volume zVolume, base pitch."),
    0x0E96: ("ResetScores", "Scores to 0, lives to 5."),
    0x0EB2: ("DefineGlyphs", "Copy bike icon and arrow glyphs into the TEXT standard charset."),
    0x0EC9: ("PlotCheckCrash", """\
If the pixel at (X,Y) is already lit the current cycle crashes: explosion,
award the opponent, lose a life, next round or game over. Never returns
in that case (JMP out of two JSR levels)."""),
    0x0ED9: ("Crash", ""),
    0x0F14: ("AwardP1", "P2 crashed: add TIME + 200 to P1's score."),
    0x0F3F: ("AwardP2", "P1 crashed: add TIME + 200 to P2's score."),
    0x0F6A: ("DecideWinner", """\
A player is out of lives. Compare 7-digit scores (relies on carry set by
the preceding CMP #$30), flash the winner's name 25 times, stash the
winner's score and name at $9D00/$9D20 and go to GameOver."""),
    0x0FDF: ("FlashDelay", ""),
    0x0FEE: ("ResetTime", "TIME digits back to '    0'."),
    0x1027: ("ClearTextScreen", "Space-fill $BA00-$BFFF (covers the whole TEXT screen)."),
    0x1041: ("ClearHires", "Fill $A000-$BF3F with $40 (blank pixel bytes)."),
    0x105E: ("UnplotPixel", "Clear pixel (X,Y). Returns with Y restored."),
    0x106E: ("PlotPixel", "Set the pixel already addressed by zPix/zMask."),
    0x107B: ("ReadKeysP1", "Direct matrix scan of P1's 5 keys -> zInput."),
    0x10AB: ("ReadKeysP2", "Direct matrix scan of P2's 5 keys -> zInput."),
    0x10DB: ("BonusBlocks", """\
Every 255 frames try a random spot; if the 6x6 area is empty, animate a
block there (box/ring/dot/ring/box, one frame per 25 ticks). The final
frame stays on screen as a new obstacle."""),
    0x1159: ("DrawBonusFrame", ""),
    0x1178: ("ComputerAI", """\
Computer opponent. Look 3 pixels ahead (3-wide) in the current direction;
if blocked, turn toward P1 on the other axis (TurnVertical/TurnHorizontal),
then AIAvoid checks that turn and reverses it if also blocked."""),
    0x123F: ("TurnVertical", "Return 8 (up) if P1 is above, else 4 (down)."),
    0x124B: ("TurnHorizontal", "Return 2 (left) if P1 is left, else 1 (right)."),
    0x1257: ("PixelSet", "C=1 if pixel (X,Y) is lit."),
    0x1268: ("AIAvoid", ""),
    0x131B: ("AIBoost", "Computer boosts while it is 30+ pixels from P1 on either axis."),
    0x1351: ("SetDirection", ""),
    0x1356: ("MovePlayer", """\
Move the current cycle (zX,zY,zDir,zPlayer) one pixel. Reads keys or AI.
Normal speed moves on even frames only; boost moves every frame. A new
direction is accepted only if it isn't zero. Erases the 3-pixel head,
steps, crash-tests and redraws the head, then plots the trail pixel
(P2's trail is dotted: plotted on alternate steps)."""),
    0x1476: ("EraseHead", ""),
    0x14DB: ("AyLoadAll", "Load AY R0-R13 from table at (X lo, Y hi)."),
    0x14F4: ("FrameDelay", "Per-frame delay: zSpeed x 256 DEY loops."),
    0x14F6: ("DelayX", ""),
    0x14FF: ("AyWrite", """\
Write X to AY register A via VIA port A + PCR (BC1/BDIR on CA2/CB2).
R7 (mixer) always gets bit 6 set to keep AY port A as output (keyboard)."""),
    0x1534: ("PrintHiscores", "Print the 8 hi-score entries with rank, score and name."),
    0x15B0: ("PutChar", "Store A at (zLoop),Y and advance Y."),
    0x15B4: ("HiscoreTitle", "Double-height 'LIGHT CYCLE HEROES' title (rows 0-1)."),
    0x15C3: ("HiscoreEntry", """\
Insert NEW_SCORE into the table if it beats an entry, then let the player
type a name (or auto-type COMPUTER if the computer won)."""),
    0x16C5: ("PlayAgain", "Show table, wait for SPACE (menu) or V (volume)."),
    0x16F7: ("PcrModify", "VIA reg X = (reg X AND A) OR Y, with IRQs masked."),
    0x1708: ("FlashTitle", "Cycle the ink attribute of the title rows through 0-6."),
    0x1724: ("TickTime", "Add 1 to TIME every 4 frames (speed 4-9) or 8 frames (speed 1-3)."),
    0x1755: ("RoundStart", """\
Start a round: random starts, clear HIRES, border, paper colour, status
line, VIA to game mode, obstacles, sound, engine sweep. Runs with IRQs
masked: keyboard is scanned directly."""),
    0x177A: ("GameLoop", "One frame: move P1, move P2, frame++, bonus blocks, TIME, delay, sound."),
}

GAME_INLINE = {
    0x06C3: "clear $30-$70",
    0x06CC: "keyclick off",
    0x06D4: "volume 0",
    0x06F8: "-> round loop (never returns)",
    0x0701: "$1A = TEXT 50 Hz attribute",
    0x072F: "into TEXT alt charset RAM",
    0x0747: "strip 'new key' flag",
    0x077E: "cursor pointer -> ROM space",
    0x078B: "row 14 col 30",
    0x0794: "'1'",
    0x0798: "'2'",
    0x07D2: "accept '1'..'9'",
    0x07DD: "ASCII -> 1..9",
    0x081D: "16 rainbow rows",
    0x0827: "$10 = paper black after the bar",
    0x086A: "'~' slider marker",
    0x086E: "R7 mixer: tone A only",
    0x0875: "R8 vol A = zVolume",
    0x087C: "R0 tone A fine",
    0x0883: "R1 tone A coarse",
    0x088D: "cursor down",
    0x0891: "cursor up",
    0x0895: "RETURN",
    0x0899: "silence A",
    0x08EF: "zTmp0/1 = y*32, zTmp2/3 = y*8",
    0x090C: "divide x by 6 (repeated subtract)",
    0x0937: "+ $A000",
    0x095E: "treat leading space as '0'",
    0x0963: "carry out of this digit?",
    0x0A78: "$1E = HIRES 50 Hz attribute",
    0x0AF9: "single-step mode?",
    0x0B2B: "x=120: walls aim at screen centre",
    0x0C06: "AY explosion table $04B0 (skipped when volume is 0)",
    0x0C28: "life 5-20 ticks",
    0x0CAB: "particle left the arena?",
    0x0D4A: "DDRA all out",
    0x0D4F: "DDRB",
    0x0D5C: "disable all VIA IRQs",
    0x0D73: "timer slot 0 = 3",
    0x0D7A: "timer slot 1 = 19",
    0x0D8E: "enable T1 IRQ",
    0x0D93: "T1 = $2710 = 10000 us -> 100 Hz",
    0x0DC1: "disable T1 IRQ",
    0x0DEC: "%1111111 top and bottom rows",
    0x0E03: "left edge pixel",
    0x0E09: "right edge pixel",
    0x0E29: "$9FD8+40 = $A000: column 0 of each row",
    0x0E62: "P1 x=25",
    0x0E66: "P2 x=215",
    0x0E6A: "P1 right, P2 left",
    0x0ECE: "already lit?",
    0x0EE6: "P1 lives digit",
    0x0EF9: "P2 lives digit",
    0x0F06: "pause ~ 10 frames",
    0x0F11: "next round",
    0x0F34: "+200",
    0x0F6C: "P1 score - P2 score (7 digits)",
    0x0F94: "toggle inverse",
    0x104B: "$40 = blank pixel byte",
    0x1065: "clear just this bit",
    0x1084: "select keyboard row",
    0x108C: "AY R14 = column mask",
    0x1097: "PB3 = key down",
    0x10E3: "every 255 ticks",
    0x1122: "area must be empty",
    0x1326: "|dx| < 30?",
    0x1335: "|dy| < 30?",
    0x137B: "zSlowPn = NOT boost",
    0x137F: "odd frame and not boosting -> no move",
    0x13A9: "P2 flicker counter",
    0x1461: "P2 trail only on alternate steps",
    0x1509: "keep AY port A as output",
    0x1512: "PCR: BDIR+BC1 = latch address",
    0x1519: "PCR: inactive",
    0x1524: "PCR: BDIR = write data",
    0x15CE: "entry score - new score",
    0x15FC: "terminate name",
    0x164B: "'C': computer won -> auto name",
    0x165B: "DEL",
    0x16A0: "RETURN",
    0x16EB: "SPACE -> menu",
    0x16F0: "'V' -> volume",
    0x1768: "DDRB = 7: PB0-2 out (keyboard row)",
    0x177A: "--- P1 ---",
    0x1799: "--- P2 ---",
    0x17B8: "frame++",
}

# ---------------------------------------------------------------------------
# LOADER block ($0501-$0E80): BASIC + loader code + charset + title screen
# ---------------------------------------------------------------------------
LOADER_RANGES = [
    (0x0501, 0x0558, "ByteTable", "BasicProgram", """\
Tokenised BASIC:
  10 REM \\\\  Light  Cycle  //
  20 REM
  30 REM      16K OR 48K
  40 TEXT:INK7:PAPER0
  50 CALL #900
  60 CLOAD\"\""""),
    (0x0559, 0x05FF, "ByteTable", "Pad0559", "Tape padding."),
    (0x0600, 0x07FF, "ByteTable", "AltGlyphs", "64 glyphs -> TEXT alt charset chars 32-95 ($B900): title logo + game title."),
    (0x0800, 0x08A7, "ByteTable", "UnusedGlyphs", "Unreferenced glyph-like data (not copied)."),
    (0x08A8, 0x08B7, "ByteTable", "ChevronGlyphs", "-> std chars '|' (down chevron) and '}' (up chevron) for the key diagram."),
    (0x08B8, 0x08FF, "ByteTable", "Pad08B8", "Tape padding."),
    (0x0900, 0x0974, "Code", "LoaderStart", "CALL #900: install glyphs, draw the title/instructions screen, return to BASIC."),
    (0x0975, 0x09FF, "ByteTable", "LoaderJunk", "Unreferenced: leftover memory (assembler/editor residue)."),
    (0x0A00, 0x0E6F, "ByteTable", "TitleScreen", "Title / instructions screen image, 28 rows x 40 bytes, copied to $BB80."),
    (0x0E70, 0x0E80, "ByteTable", "Pad0E70", "Tape padding."),
]

LOADER_LABELS = {
    0x0952: ("BlockCopy", """\
Copy (zTmp4 + 256*zTmp5) bytes from (zTmp0) to (zTmp2): whole pages first,
then the remainder."""),
}

LOADER_INLINE = {
    0x0900: "$0600 -> $B900, 512 bytes",
    0x091B: "$08A8 -> $B7E0, 16 bytes",
    0x0936: "$0A00 -> $BB80, $470 bytes",
}
