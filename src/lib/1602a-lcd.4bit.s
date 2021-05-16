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
    lda #%11110000  ; Port B (data) is input
    sta DDRB
lcdbusy:
    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB       ; Read high nibble
    pha             ; Push onto stack since it has busy flag

    lda #RW
    sta PORTB
    lda #(RW | E)
    sta PORTB
    lda PORTB       ; Read low nibble
    pla             ; Pull high nibble off stack
    and #%00001000  ; Read DB7 
    bne lcdbusy

    lda #RW
    sta PORTB
    lda #%11111111  ; Port B is output
    sta DDRB
    pla
    rts

lcd_init_four_bit:
    lda #%00000010  ; Initialize 4-bit mode
    sta PORTB
    ora #E          ; Enable bit ON   
    sta PORTB
    and #%00001111 
    sta PORTB
    rts

lcd_instruction:
    jsr lcd_wait 
    pha
    pha
    lsr
    lsr
    lsr
    lsr             ; Send high 4 bits
    sta PORTB
    ora #E          ; Enable bit ON   
    sta PORTB
    eor #E          ; Enable bit OFF   
    sta PORTB

    pla
    and #%00001111  ; Send low 4 bits
    sta PORTB
    ora #E          ; Enable bit ON   
    sta PORTB
    eor #E          ; Enable bit OFF   
    sta PORTB 
    pla
    rts

print_char:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr             ; Send high 4 bits
    ora #RS         ; Set RS
    sta PORTB
    ora #E          ; Set Enable ON
    sta PORTB
    eor #E          ; Set Enable OFF
    sta PORTB
    pla
    and #%00001111  ; Send low 4 bits
    ora #RS         ; Set RS
    sta PORTB
    ora #E          ; Set Enable ON
    sta PORTB
    eor #E          ; Set Enable OFF
    sta PORTB
    rts
