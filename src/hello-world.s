PORTA   = $6001
PORTB   = $6000
DDRA    = $6003
DDRB    = $6002
E       = %10000000
RW      = %01000000
RS      = %00100000
    .org $8000

reset:
    lda #%11111111  ;   Set 8 pins on PORTB to output
    sta DDRB

    lda #%11100000  ;   Set 3 pins on PORTA to output
    sta DDRA

    lda #%00111000  ;   8-bit - 2 line - 5x8 font (001<DL><N><F>xx)   
    jsr lcd_instruction


    lda #%00001110  ;   Display on - Cursor on - Blink off   
    jsr lcd_instruction

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    jsr lcd_instruction

    lda #$00000001  ;   Clear display
    jsr lcd_instruction


    lda #"H"        ;   H data
    jsr print_char

    lda #"e"        ;   H data
    jsr print_char

    lda #"l"        ;   H data
    jsr print_char

    lda #"l"        ;   H data
    jsr print_char

    lda #"o"        ;   H data
    jsr print_char

    lda #" "        ;   H data
    jsr print_char

    lda #"W"        ;   H data
    jsr print_char

    lda #"o"        ;   H data
    jsr print_char

    lda #"r"        ;   H data
    jsr print_char

    lda #"l"        ;   H data
    jsr print_char

    lda #"d"        ;   H data
    jsr print_char

    lda #"!"        ;   H data
    jsr print_char

loop:
    jmp loop


lcd_instruction:
    sta PORTB
    lda #%0         ;   Clear RS/RW/E bits
    sta PORTA
    lda #E          ;   Enable bit ON   
    sta PORTA
    lda #%0         ;   Enable bit OFF   
    sta PORTA
    rts

print_char:
    sta PORTB
    lda #RS         ;   RS bit to write   
    sta PORTA
    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA
    lda #RS         ;   Latch Data   
    sta PORTA
    rts

    .org $fffc
    .word reset
    .word $0000