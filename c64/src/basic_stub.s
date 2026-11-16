; Light Cycle (C64) — .prg load address and BASIC stub: 10 SYS 2061

        .segment "LOADADDR"
        .word   $0801

        .segment "EXEHDR"
        .import Start
        .word   NextLine                   ; link to next line
        .word   10                      ; line number
        .byte   $9E                     ; SYS token
        .byte   "2061"                  ; = $080D, first byte of CODE
        .byte   0
NextLine:  .word   0                       ; end of program

        .assert Start = 2061, error, "Start must be the first byte of CODE ($080D)"
