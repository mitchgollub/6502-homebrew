; I/O addresses 6000 -> 600F
PORTA   = $6001     
PORTB   = $6000
DDRA    = $6003
DDRB    = $6002
PCR     = $600c     ;   Peripherial Control Register -> 65c22
IFR     = $600d     ;   Interrupt Flag Register -> 65c22
IER     = $600e     ;   Interrupt Enable Register -> 65c22
E       = %10000000 
RW      = %01000000
RS      = %00100000

; Stack memory locations - 0100 -> 01FF
; RAM memory locations - 0200 -> 3FFF (Full range 0000-3FFF)
char    = $0200     ; 2 bytes

; ROM memory addresses 8000 -> FFFF
    .org $8000
reset:
    ldx #$ff    ;   load $ff into X
    txs         ;   transfer $ff as stack pointer
    cli         ;   Clear Interrupt flag

    lda #%10000010  ;   Enable CA1 interrupt
    sta IER
    lda #$00        ;   Enable CA1 Negative Edge
    sta PCR

    lda #%11111111  ;   Set 8 pins on PORTB to output
    sta DDRB

    lda #%11100000  ;   Set 3 pins on PORTA to output
    sta DDRA

    lda #%00111000  ;   8-bit - 2 line - 5x8 font (001<DL><N><F>xx)   
    jsr lcd_instruction


    lda #%00001111  ;   Display on - Cursor on - Blink on   
    jsr lcd_instruction

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    jsr lcd_instruction

    lda #$01  ;   Clear display
    jsr lcd_instruction

    ldx #0

shift_cursor_left:
    lda #%01000001                  ;   Load first char
    sta char                        ;   Store first char in RAM
    jsr print_char
    lda #%00010000                  ;   shift cursor left
    jsr lcd_instruction

loop:                               ;   End loop
    jmp loop
    
increment_input_char:
    inc char                        ;   Pull character from RAM
    lda char
    jsr print_char
shift_cursor_left_sub:
    lda #%00010000    ;   shift cursor left
    jsr lcd_instruction
    rts

lcd_wait:
    pha
    lda #%00000000  ; Port B is input
    sta DDRB
lcdbusy:
    lda #RW
    sta PORTA
    lda #(RW | E)
    sta PORTA
    lda PORTB
    and #%10000000
    bne lcdbusy

    lda #RW
    sta PORTA
    lda #%11111111  ; Port B is output
    sta DDRB
    pla
    rts

lcd_instruction:
    jsr lcd_wait 
    sta PORTB
    lda #%0         ;   Clear RS/RW/E bits
    sta PORTA
    lda #E          ;   Enable bit ON   
    sta PORTA
    lda #%0         ;   Enable bit OFF   
    sta PORTA
    rts

print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS         ;   RS bit to write   
    sta PORTA
    lda #(RS | E)  ;   Set RS and E bits   
    sta PORTA
    lda #RS         ;   Latch Data   
    sta PORTA
    rts

nmi:
    ; rti

irq:
    jsr increment_input_char
exit_irq:
    bit PORTA
    rti                     ; Return from the Interrupt 

    .org $fffa
    .word nmi
    .word reset
    .word irq
