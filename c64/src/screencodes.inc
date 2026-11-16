; Light Cycle (C64) — map string literals to screen codes
; Letters A-Z are screen codes $01-$1A; digits, space and most punctuation
; are the same as ASCII. Include in a file before its .byte "TEXT" strings.

.repeat 26, i
        .charmap $41 + i, $01 + i
.endrepeat
        .charmap $40, $00               ; @
