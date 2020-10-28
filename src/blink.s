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
    sta PORTB
    
    lda #%0         ;   Clear RS/RW/E bits   
    sta PORTA

    lda #E          ;   Enable bit ON   
    sta PORTA

    lda #%0         ;   Enable bit OFF   
    sta PORTA


    lda #%00001110  ;   Display on - Cursor on - Blink off   
    sta PORTB
    
    lda #%0         ;   Clear RS/RW/E bits   
    sta PORTA

    lda #E          ;   Enable bit ON   
    sta PORTA

    lda #%0         ;   Enable bit OFF   
    sta PORTA

; Bug is here
; 0110000000000000    00000110   6000  w 06 ; lda 00000110 -> sta PORTB
; 1000000000110111    10101001   8037  r a9
; 1000000000111000    00000000   8038  r 00
; 1000000000111001    10001101   8039  r 8d
; 1000000000111010    00000001   803a  r 01
; 1000000000111011    01100000   803b  r 60
; 0110000000000001    00000000   6001  w 00
; 1000000000111100    10101001   803c  r a9
; 1000000000111101    10000000   803d  r 80
; 1000000000111110    10001101   803e  r 8d
; 1000000000111111    00000001   803f  r 01
; 1000000001000000    00000000   8040  r 00 ; should be 0110000 for 60 ; hexdump shows 60
; 0000000000000001    10000000   0001  w 80
; 1000000001000001    00000000   8041  r 00 ; why is it still reading x00 here? ; hexdump shows a9 at 8041, not 00

; Memory read from programmer shows the write is correct? YES
; Are the address connections to the EEPROM correct for 8040? YES
; Chip Enable is HIGH for 8040... why?

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    sta PORTB
    
    lda #%0         ;   Clear RS/RW/E bits
    sta PORTA

    lda #E          ;   Enable bit ON   
    sta PORTA

    lda #%0         ;   Enable bit OFF   
    sta PORTA


    lda #"H"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

loop:
    jmp loop

    .org $fffc
    .word reset
    .word $0000