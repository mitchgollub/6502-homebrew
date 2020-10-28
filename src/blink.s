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

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    sta PORTB
    
    lda #%0         ;   Clear RS/RW/E bits
    sta PORTA

    lda #E          ;   Enable bit ON   
    sta PORTA

    lda #%0         ;   Enable bit OFF   
    sta PORTA

    lda #$00000001  ;   Clear display
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

    lda #"e"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"l"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"l"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"o"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #" "        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"W"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"o"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"r"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"l"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"d"        ;   H data
    sta PORTB
    
    lda #RS         ;   RS bit to write   
    sta PORTA

    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA

    lda #RS         ;   Latch Data   
    sta PORTA

    lda #"!"        ;   H data
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