; Program Constants

; Stack memory locations - 0100 -> 01FF
; RAM memory locations - 0200 -> 3FFF (Full range 0000-3FFF)

; ROM memory addresses 8000 -> FFFF
    .org $8000
    jmp reset                       ; jump to reset method in bootstrap.s to boot
; Code libraries
    .include "./lib/1602a-lcd.4bit.s"    ; include 1602a library
    .include "./lib/bootstrap.4bit.s"    ; boot program

entrypoint:
    ldx #0
print:
    lda message,x
    beq loop
    jsr print_char
    inx
    jmp print
loop:
    jmp loop

message: .asciiz "Hello World!"

nmi:
    ; rti

irq:
exit_irq:
    bit PORTA
    rti                     ; Return from the Interrupt 

    .org $fffa
    .word nmi
    .word reset
    .word irq
