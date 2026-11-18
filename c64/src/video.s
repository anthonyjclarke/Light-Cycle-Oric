; Light Cycle (C64) — video: VIC bank, modes, screens, colours, glyphs
;
; Replaces the Oric's TEXT/HIRES switch ($1A/$1E written to $BFDF), the
; charset shuffle (CharsetToHires / CharsetToText) and ClearHires /
; ClearTextScreen. The C64 keeps text screen, font and bitmap apart in
; VIC bank 1, so no shuffle is needed.

        .include "hw.inc"
        .include "zp.inc"

        .export InitVideo, BitmapOn, TextOn, ClearBitmap, ClearText
        .export SetArenaColour, SetPanelColour, SetCellColour, BitmapChar
        .export BitmapCharTall
        .export PrintText

        .segment "CODE"

; Select VIC bank 1, copy the ROM font to CHARSET, black border.
; Expects IRQs masked (called from InitPlatform).
InitVideo:
        lda     CIA2_DDRA
        ora     #%00000011
        sta     CIA2_DDRA
        lda     CIA2_PRA
        and     #%11111100
        ora     #VIC_BANK_BITS
        sta     CIA2_PRA
        lda     #MEM_CHARROM            ; font ROM visible at $D000, I/O hidden
        sta     CPU_PORT
        ldx     #0
@copy:
        .repeat 8, page
        lda     $D000 + page * $100,x
        sta     CHARSET + page * $100,x
        .endrepeat
        inx
        bne     @copy
        lda     #MEM_IO_ONLY
        sta     CPU_PORT
        lda     #COL_BLACK
        sta     VIC_BORDER
        sta     VIC_BG0
        rts

; Hires bitmap mode (the Oric's HIRES).
BitmapOn:
        lda     #MEMSETUP_BITMAP
        sta     VIC_MEMSETUP
        lda     #$C8                    ; 40 columns, no multicolour
        sta     VIC_CTRL2
        lda     #$3B                    ; bitmap, display on, 25 rows; raster bit 8 = 0
        sta     VIC_CTRL1
        rts

; Standard text mode (the Oric's TEXT).
TextOn:
        lda     #COL_BLACK              ; the intro picture sets a blue background
        sta     VIC_BG0
        lda     #MEMSETUP_TEXT
        sta     VIC_MEMSETUP
        lda     #$C8
        sta     VIC_CTRL2
        lda     #$1B
        sta     VIC_CTRL1
        rts

; Zero the whole bitmap ($6000-$7FFF). Oric equivalent: ClearHires.
ClearBitmap:
        lda     #0
        tax
@loop:
        .repeat 32, page
        sta     BITMAP + page * $100,x
        .endrepeat
        inx
        bne     @loop
        rts

; Fill the text screen with A (screen code) and colour RAM with X.
; Oric equivalent: ClearTextScreen.
ClearText:
        ldy     #0
@loop:  sta     TEXT_SCREEN,y
        sta     TEXT_SCREEN + $100,y
        sta     TEXT_SCREEN + $200,y
        sta     TEXT_SCREEN + $2E8,y
        pha
        txa
        sta     COLOUR_RAM,y
        sta     COLOUR_RAM + $100,y
        sta     COLOUR_RAM + $200,y
        sta     COLOUR_RAM + $2E8,y
        pla
        iny
        bne     @loop
        rts

; A = ink << 4 | paper for every arena cell (columns 5-34, all rows).
; Oric equivalent: SetPaperColour (paper attribute in column 0 of each row).
SetArenaColour:
        ldx     #ARENA_COL0
        ldy     #ARENA_COLS
        bne     FillColourColumns

; A = ink << 4 | paper for both side panels (columns 0-4 and 35-39).
SetPanelColour:
        pha
        ldx     #0
        ldy     #ARENA_COL0
        jsr     FillColourColumns
        pla
        ldx     #ARENA_COL0 + ARENA_COLS
        ldy     #40 - ARENA_COL0 - ARENA_COLS
        ; fall through

; Fill bitmap colour cells: A = value, X = first column, Y = column count,
; all 25 rows.
FillColourColumns:
        sta     zTmp0
        sty     zTmp1
        stx     zPtr
        lda     #>BITMAP_COLOURS
        sta     zPtr + 1
        ldx     #25
@row:   lda     zTmp0
        ldy     zTmp1
        dey
@col:   sta     (zPtr),y
        dey
        bpl     @col
        lda     zPtr
        clc
        adc     #40
        sta     zPtr
        bcc     :+
        inc     zPtr + 1
:       dex
        bne     @row
        rts

; Set one bitmap colour cell: A = ink << 4 | paper, X = column, Y = row.
; Preserves X and Y.
SetCellColour:
        pha
        lda     CellRowLo,y
        sta     zPtr
        lda     CellRowHi,y
        sta     zPtr + 1
        tya
        pha
        txa
        tay
        pla
        sta     zTmp0
        pla
        sta     (zPtr),y
        ldy     zTmp0
        rts

; Draw font glyph A (screen code) into the bitmap at cell X (0-39), Y (0-24).
; Used for the side panels, which replace the Oric's three text rows under
; HIRES. Preserves X and Y.
BitmapChar:
        jsr     GlyphAt
        ldy     #7
@copy:  lda     (zPtr),y
        sta     (zPix),y
        dey
        bpl     @copy
        ldx     zTmp1
        ldy     zTmp2
        rts

; Draw glyph A double height into cells (X, Y) and (X, Y + 1), each font
; row twice, as the Oric's double-height attribute shows its TIME digits.
; Preserves X and Y.
BitmapCharTall:
        jsr     GlyphAt
        jsr     TallHalf                ; font rows 0-3 into the upper cell
        lda     zPix
        clc
        adc     #<320
        sta     zPix
        lda     zPix + 1
        adc     #>320
        sta     zPix + 1
        lda     zPtr                    ; glyphs are 8-byte aligned: no carry
        ora     #4
        sta     zPtr
        jsr     TallHalf                ; rows 4-7 into the lower cell
        ldx     zTmp1
        ldy     zTmp2
        rts

TallHalf:
        lda     #3
        sta     zTmp0
@row:   ldy     zTmp0
        lda     (zPtr),y
        pha
        tya
        asl     a
        tay
        pla
        sta     (zPix),y
        iny
        sta     (zPix),y
        dec     zTmp0
        bpl     @row
        rts

; zPtr = glyph A in CHARSET, zPix = bitmap cell (X, Y); X, Y saved in
; zTmp1, zTmp2.
GlyphAt:
        stx     zTmp1
        sty     zTmp2
        ldx     #0
        stx     zTmp0
        asl     a
        rol     zTmp0
        asl     a
        rol     zTmp0
        asl     a
        rol     zTmp0
        sta     zPtr
        lda     zTmp0
        clc
        adc     #>CHARSET
        sta     zPtr + 1
        ldx     zTmp1
        ldy     zTmp2
        lda     BitmapRowLo,y
        clc
        adc     CellXLo,x
        sta     zPix
        lda     BitmapRowHi,y
        adc     CellXHi,x
        sta     zPix + 1
        rts

; Print a STR_END-terminated screen-code string to the text screen
; (not 0: '@' is screen code 0).
; zPtr = string, X = column, Y = row, A = colour.
PrintText:
        sta     zTmp3
        lda     CellRowLo,y             ; reuse the 40-byte row table, rebased
        clc
        adc     #<(TEXT_SCREEN - BITMAP_COLOURS)
        sta     zPix
        lda     CellRowHi,y
        adc     #>(TEXT_SCREEN - BITMAP_COLOURS)
        sta     zPix + 1
        txa
        clc
        adc     zPix
        sta     zPix
        bcc     :+
        inc     zPix + 1
:       ldy     #0
@loop:  lda     (zPtr),y
        cmp     #STR_END
        beq     @done
        sta     (zPix),y
        lda     zPix + 1                ; colour RAM = screen + ($D800 - $4400)
        pha
        clc
        adc     #>(COLOUR_RAM - TEXT_SCREEN)
        sta     zPix + 1
        lda     zTmp3
        sta     (zPix),y
        pla
        sta     zPix + 1
        iny
        bne     @loop
@done:  rts

        .segment "RODATA"

CellRowLo:
        .repeat 25, row
        .byte   <(BITMAP_COLOURS + row * 40)
        .endrepeat
CellRowHi:
        .repeat 25, row
        .byte   >(BITMAP_COLOURS + row * 40)
        .endrepeat
BitmapRowLo:
        .repeat 25, row
        .byte   <(BITMAP + row * 320)
        .endrepeat
BitmapRowHi:
        .repeat 25, row
        .byte   >(BITMAP + row * 320)
        .endrepeat
CellXLo:
        .repeat 40, col
        .byte   <(col * 8)
        .endrepeat
CellXHi:
        .repeat 40, col
        .byte   >(col * 8)
        .endrepeat
