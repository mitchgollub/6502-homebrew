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
    
    .org $8000
reset:
    ldx #$ff    ;   load $ff into X
    txs         ;   transfer $ff as stack pointer
    cli

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


    lda #%00001110  ;   Display on - Cursor on - Blink off   
    jsr lcd_instruction

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    jsr lcd_instruction

    lda #$00000001  ;   Clear display
    jsr lcd_instruction

    ldx #0
    
print:
    lda message,x
    beq loop
    jsr print_char
    inx
    jmp print

loop:                               ;   End loop
    jmp loop
    
print_interrupt:
    ldx #0                          ;   Initialize X Register
print_interrupt_loop:
    lda interrupt_message,x         ;   Set A and X to interrupt 
    beq exit_irq
    jsr print_char
    inx
    jmp print_interrupt_loop
    
message: .asciiz "I love you!"
interrupt_message: .asciiz "Int"

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
    pha                     ; Push A onto stack since it's used                     
    jmp print_interrupt     ; Use `jmp` here, print_interrupt doesn't exit using rts    
exit_irq:
    bit PORTA
    pla                     ; Restore A register
    rti                     ; Is this the right command? Doesn't go back to loop 

    .org $fffa
    .word nmi
    .word reset
    .word irq