; I/O addresses 6000 -> 600F
PORTA   = $6001     
PORTB   = $6000
DDRA    = $6003
DDRB    = $6002
PCR     = $600c     ;   Peripherial Control Register -> 65c22
IFR     = $600d     ;   Interrupt Flag Register -> 65c22
IER     = $600e     ;   Interrupt Enable Register -> 65c22
E       = %10000000 ;   LCD Enable signal
RW      = %01000000 ;   LCD Read/Write Flag (H - Read, L - Write)
RS      = %00100000 ;   LCD Input Flag (H - Data, L - Instruction)

; LCD Characters
ROBO_SPRITE =   %11001110
GROUND_SPRITE = %01011111
HURDLE_SPRITE = %10101101

; LCD Instructions
LCD_SHIFT_DISPLAY_LEFT = %00011000

; Game Constants
DRAW_LOOP_WAIT_TIME = $30

; Stack memory locations - 0100 -> 01FF
; RAM memory locations - 0200 -> 3FFF (Full range 0000-3FFF)
char    = $0200     ; 2 bytes
robo_position   = $0202 ; 1 byte (6 bits to represent LCD screen cursor position)

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

    lda #%00001110  ;   Display on - Cursor off - Blink off 
    jsr lcd_instruction

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    jsr lcd_instruction

    lda #$01  ;   Clear display
    jsr lcd_instruction

    ; jsr sprite_test             ;   Prints the game sprites at the top of the screen
    
    jsr draw_init_screen

draw_loop:              ;   Draw loop
    ; draw robo sprite
    jsr draw_robo_sprite
    jsr wait
    jmp draw_loop
    
; 1602a LCD subroutines
set_cursor_address:
    ora #%01000000
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

; Game subroutines
sprite_test:
    lda #ROBO_SPRITE                 ;   Load first char
    sta char                        ;   Store first char in RAM
    jsr print_char                  ;   Print first char

    lda #GROUND_SPRITE
    jsr print_char

    lda #HURDLE_SPRITE
    jsr print_char

    rts

draw_init_screen:
    lda #%11000000          ; Set cursor 2nd row 1st char
    sta robo_position       ; Store initial robo_position
    inc robo_position
    jsr lcd_instruction
    lda #GROUND_SPRITE
    jsr print_char
    lda #ROBO_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    lda #HURDLE_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    lda #HURDLE_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    lda #GROUND_SPRITE
    jsr print_char
    rts

draw_robo_sprite:
    ;   Store previous robo position
    ldx robo_position
    ;   Increment robo counter
    inc robo_position
    ;   Reset counter if over address limit
    lda robo_position
    cmp #%11101000          ;   Reset counter at 11100111
    beq reset_robo_counter
draw_robo_sprite_corrected:
    ;   Clear previous robo position
    txa
    jsr set_cursor_address
    lda #GROUND_SPRITE
    jsr print_char
    ; Shift display/characters left 
    ; done while robo is off display to remove afterimage
    lda #LCD_SHIFT_DISPLAY_LEFT
    jsr lcd_instruction
    ;   draw robo at that counter
    lda robo_position
    jsr set_cursor_address
    lda #ROBO_SPRITE
    jsr print_char
    rts

reset_robo_counter:
    lda #%11000000          ; Set cursor 2nd row 1st char
    sta robo_position       ; Store initial robo_position
    jmp draw_robo_sprite_corrected

wait:
    ldx #DRAW_LOOP_WAIT_TIME
wait_loop:
    dex
    txa
    cmp #$00
    bne wait_loop
    rts

; Interrupt subroutines
increment_input_char:
    inc char                        ;   Pull character from RAM
    lda char
    jsr print_char
    jsr shift_cursor_left
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
