; Light Cycle (C64) — keyboard matrix and joysticks
;
; Oric: ReadKeysP1 / ReadKeysP2 select a matrix row through VIA port B and
; a column through AY port A, then test PB3. C64: CIA1 port A selects a
; column (active low), port B reads the rows. Both produce the same zInput
; bits (IN_UP $08, IN_DOWN $04, IN_LEFT $02, IN_RIGHT $01, IN_BOOST $10).
;
; Keys keep the Oric layout's shape on the C64 keyboard:
;   P1  up 2   down A       left W   right E   boost R   + joystick port 2
;   P2  up @   down R-SHIFT left :   right ;   boost L   + joystick port 1
;
; Joystick port 1 shares CIA1 port B with the keyboard rows. zJoyIdle (port
; B with no column selected) masks rows held low by joystick 1, so moving
; it does not look like a key. Joystick 2 pulls port A lines low and can
; still make ghost keys if keys are pressed at the same time.

        .include "hw.inc"
        .include "zp.inc"

        .export InitInput, ReadKeysP1, ReadKeysP2, GetKey, WaitKey

        .segment "CODE"

InitInput:
        lda     #$FF
        sta     CIA1_DDRA               ; port A out: column select
        sta     CIA1_PRA
        lda     #$00
        sta     CIA1_DDRB               ; port B in: rows
        sta     zLastKey
        rts

; Player 1: keys + joystick 2. Result in zInput and A.
ReadKeysP1:
        ldx     #KeyTableP1 - KeyTables
        jsr     ScanPlayerKeys
        lda     #$FF
        sta     CIA1_PRA                ; release columns: port A now reads joystick 2
        lda     CIA1_PRA
        jmp     MergeJoystick

; Player 2: keys + joystick 1. Result in zInput and A.
ReadKeysP2:
        ldx     #KeyTableP2 - KeyTables
        jsr     ScanPlayerKeys
        lda     zJoyIdle                ; port B with no column = joystick 1
        ; fall through

; A = joystick port value (active low, bits 0-4 = up down left right fire).
; ORs the converted bits into zInput; returns zInput in A.
MergeJoystick:
        eor     #$FF
        and     #$1F
        tax
        lda     JoyToInput,x
        ora     zInput
        sta     zInput
        rts

; Scan the five keys at KeyTables+X (column, row mask, input bit, x5).
; Leaves the bits in zInput. Updates zJoyIdle.
ScanPlayerKeys:
        lda     #$FF
        sta     CIA1_PRA
        lda     CIA1_PRB
        sta     zJoyIdle
        lda     #0
        sta     zInput
        ldy     #5
@key:   lda     KeyTables,x             ; column select (one bit low)
        sta     CIA1_PRA
        lda     CIA1_PRB
        eor     #$FF                    ; 1 = row active
        and     zJoyIdle                ; ...but not held by joystick 1
        and     KeyTables + 1,x         ; this key's row
        beq     @next
        lda     KeyTables + 2,x
        ora     zInput
        sta     zInput
@next:  inx
        inx
        inx
        dey
        bne     @key
        lda     #$FF
        sta     CIA1_PRA
        rts

; Menu keyboard: scan the whole matrix and return a newly pressed key's
; code in A (0 = none, or the same key still held). Codes are ASCII for
; letters, digits and punctuation, plus KEY_* for control keys. Cursor
; keys with SHIFT give KEY_UP / KEY_LEFT, as the Oric's cursor keys did.
; Preserves nothing.
GetKey:
        lda     #$FF
        sta     CIA1_PRA
        lda     CIA1_PRB
        sta     zJoyIdle
        lda     #0
        sta     zTmp0                   ; key index + 1 (0 = none)
        sta     zTmp1                   ; shift held
        ldx     #0                      ; column
@col:   lda     ColumnSelect,x
        sta     CIA1_PRA
        lda     CIA1_PRB
        eor     #$FF
        and     zJoyIdle
        beq     @nextcol
        ldy     #0                      ; row
@row:   lsr     a
        bcc     @nextrow
        pha
        txa                             ; index = column * 8 + row
        asl     a
        asl     a
        asl     a
        sty     zTmp2
        ora     zTmp2
        cmp     #KEYIDX_LSHIFT
        beq     @shift
        cmp     #KEYIDX_RSHIFT
        beq     @shift
        clc
        adc     #1
        sta     zTmp0
        bne     @pulled
@shift: inc     zTmp1
@pulled:
        pla
@nextrow:
        iny
        cpy     #8
        bne     @row
@nextcol:
        inx
        cpx     #8
        bne     @col
        lda     #$FF
        sta     CIA1_PRA

        ldx     zTmp0
        beq     @none
        lda     KeyCodes - 1,x
        ldy     zTmp1
        beq     @edge
        cmp     #KEY_DOWN
        bne     :+
        lda     #KEY_UP
:       cmp     #KEY_RIGHT
        bne     @edge
        lda     #KEY_LEFT
@edge:  cmp     zLastKey
        beq     @held
        sta     zLastKey
        rts
@held:  lda     #0
        rts
@none:  sta     zLastKey                ; A = 0
        rts

; Block until a key is newly pressed; code in A. Oric equivalent: WaitKey
; (which read the ROM's IRQ keyboard). Preserves nothing.
WaitKey:
        jsr     GetKey
        beq     WaitKey
        rts

        .segment "RODATA"

ColumnSelect:
        .byte   $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

; Matrix index = column * 8 + row.
KEYIDX_LSHIFT = 1 * 8 + 7
KEYIDX_RSHIFT = 6 * 8 + 4

; Column select, row mask, zInput bit — five keys per player.
.macro KEY col, row, bit
        .byte   $FF ^ (1 << col), 1 << row, bit
.endmacro
KeyTables:
KeyTableP1:
        KEY 7, 3, IN_UP                 ; 2
        KEY 1, 2, IN_DOWN               ; A
        KEY 1, 1, IN_LEFT               ; W
        KEY 1, 6, IN_RIGHT              ; E
        KEY 2, 1, IN_BOOST              ; R
KeyTableP2:
        KEY 5, 6, IN_UP                 ; @
        KEY 6, 4, IN_DOWN               ; right SHIFT
        KEY 5, 5, IN_LEFT               ; :
        KEY 6, 2, IN_RIGHT              ; ;
        KEY 5, 2, IN_BOOST              ; L

; Joystick bits (up=1 down=2 left=4 right=8 fire=16, after inversion) to
; zInput bits.
JoyToInput:
        .repeat 32, j
        .byte   ((j & 1) * IN_UP) | (((j >> 1) & 1) * IN_DOWN) | (((j >> 2) & 1) * IN_LEFT) | (((j >> 3) & 1) * IN_RIGHT) | (((j >> 4) & 1) * IN_BOOST)
        .endrepeat

; Matrix index -> key code (unshifted). 0 = not used by the game.
KeyCodes:
        .byte   KEY_DEL, KEY_RETURN, KEY_RIGHT, 0, 0, 0, 0, KEY_DOWN   ; column 0
        .byte   "3", "W", "A", "4", "Z", "S", "E", 0                   ; column 1 (7 = L-SHIFT)
        .byte   "5", "R", "D", "6", "C", "F", "T", "X"                 ; column 2
        .byte   "7", "Y", "G", "8", "B", "H", "U", "V"                 ; column 3
        .byte   "9", "I", "J", "0", "M", "K", "O", "N"                 ; column 4
        .byte   "+", "P", "L", "-", ".", ":", "@", ","                 ; column 5
        .byte   "#", "*", ";", 0, 0, "=", "^", "/"                     ; column 6 (4 = R-SHIFT)
        .byte   "1", "_", 0, "2", " ", 0, "Q", KEY_STOP                ; column 7
