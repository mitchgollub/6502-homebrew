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
BLANK_SPRITE =   %11111110

; LCD Instructions
LCD_SHIFT_DISPLAY_LEFT = %00011000

; Game Constants
DRAW_LOOP_WAIT_TIME = $ff
ROBO_JUMP_UP_TIME   = $03

; Stack memory locations - 0100 -> 01FF
; RAM memory locations - 0200 -> 3FFF (Full range 0000-3FFF)
robo_position   = $0200 ; 1 byte (6 bits to represent LCD screen cursor position)
robo_jump_time  = $0201 ; 1 byte (holds the remaing draw cycles robo is on top display line)

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
    lda #ROBO_SPRITE                ;   Load first char
    jsr print_char                  ;   Print first char

    lda #GROUND_SPRITE
    jsr print_char

    lda #HURDLE_SPRITE
    jsr print_char

    rts

draw_init_screen:
    stz robo_jump_time      ; Initialize robo jump flag to 0
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
    ; Store previous robo position
    ldx robo_position
    ; Increment robo position in memory to current
    inc robo_position
    ; Reset position if over LCD address limit
    lda robo_position
    cmp #%11101000          ;   Reset counter at 11101000 (last address for line 2)
    beq reset_robo_counter
draw_robo_sprite_check_jump:
    ; Check robo_jump_time
    lda robo_jump_time
    cmp #$00
    bne handle_robo_jump_time
draw_robo_sprite_redraw:
    ; Clear previous robo position
    txa
    jsr set_cursor_address
    lda #GROUND_SPRITE
    jsr print_char
    ; Clear top row too
    txa
    and #%10111111
    jsr set_cursor_address
    lda #BLANK_SPRITE
    jsr print_char
    ; Shift display/characters left 
    ; done while robo is off display to remove afterimage
    lda #LCD_SHIFT_DISPLAY_LEFT
    jsr lcd_instruction
    ; draw robo at new position
    lda robo_position
    jsr set_cursor_address
    lda #ROBO_SPRITE
    jsr print_char
    ; reset the position from the jump adjustment (if needed?)
    lda robo_position
    ora #%01000000
    sta robo_position
    rts

handle_robo_jump_time:
    dec robo_jump_time
    lda robo_position
    ; Set robo_position to line 1
    and #%10111111          ; 0 at D6 is line 1 for LCD
    sta robo_position
    jmp draw_robo_sprite_redraw

reset_robo_counter:
    lda #%11000000          ; Set cursor 2nd row 1st char
    sta robo_position       ; Store initial robo_position
    jmp draw_robo_sprite_check_jump

wait:
    ldx #DRAW_LOOP_WAIT_TIME
wait_loop:
    dex
    txa
    cmp #$00
    bne wait_loop
    rts

; Interrupt subroutines
set_robo_jump_time:
    pha
    lda #ROBO_JUMP_UP_TIME
    sta robo_jump_time
    pla
    rts

nmi:
    ; rti

irq:
    jsr set_robo_jump_time
exit_irq:
    bit PORTA
    rti                     ; Return from the Interrupt 

    .org $fffa
    .word nmi
    .word reset
    .word irq
