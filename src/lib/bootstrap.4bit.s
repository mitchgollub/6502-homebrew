; I/O addresses 6000 -> 600F
PORTA   = $6001     
PORTB   = $6000
DDRA    = $6003
DDRB    = $6002
PCR     = $600c     ;   Peripherial Control Register -> 65c22
IFR     = $600d     ;   Interrupt Flag Register -> 65c22
IER     = $600e     ;   Interrupt Enable Register -> 65c22

; Entrypoint for the program
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

    lda #%00000000  ;   Set 0 pins on PORTA to output (input pins)
    sta DDRA

    jsr lcd_init_four_bit
    ; lda #%00000010  ;   Initialize 4-bit mode
    ; jsr lcd_instruction

    lda #%00101000  ;   4-bit - 2 line - 5x8 font (001<DL><N><F>xx)   
    jsr lcd_instruction

    lda #%00001110  ;   Display on - Cursor on - Blink off
    jsr lcd_instruction

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    jsr lcd_instruction

    lda #$01  ;   Clear display
    jsr lcd_instruction

    jmp entrypoint