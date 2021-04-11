; LCD Command flags
E       = %10000000 ;   LCD Enable signal
RW      = %01000000 ;   LCD Read/Write Flag (H - Read, L - Write)
RS      = %00100000 ;   LCD Input Flag (H - Data, L - Instruction)

; LCD Instructions
LCD_SHIFT_DISPLAY_LEFT = %00011000
LCD_SCREEN_OFF = %00001000
LCD_SCREEN_ON = %00001100

; LCD Cursor Addresses
LCD_ADDR_FIRST_OVERFLOW = %10101000
LCD_ADDR_SECOND_OVERFLOW = %11101000
LCD_ADDR_FIRST_ROW_FIRST_CHAR = %10000000
LCD_ADDR_LAST_ROW_FIRST_CHAR = %11000000
LCD_ADDR_LAST_ROW_LAST_CHAR = %11100111
LCD_ADDR_TOP_RIGHT_CORNER = %10001111

; 1602a LCD subroutines
set_cursor_address:
    jsr lcd_instruction
    rts

shift_display_left:
    pha
    lda #%00011000    ;   shift display left (cursor follows)
    jsr lcd_instruction
    pla
    rts

shift_cursor_left:
    pha
    lda #%00010000    ;   shift cursor left
    jsr lcd_instruction
    pla
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
    pha
    jsr lcd_wait 
    sta PORTB
    lda #%0         ;   Clear RS/RW/E bits
    sta PORTA
    lda #E          ;   Enable bit ON   
    sta PORTA
    lda #%0         ;   Enable bit OFF   
    sta PORTA
    pla
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
