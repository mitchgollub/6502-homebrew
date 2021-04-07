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

; LCD Cursor Addresses
LCD_ADDR_FIRST_OVERFLOW = %10101000
LCD_ADDR_SECOND_OVERFLOW = %11101000
LCD_ADDR_LAST_ROW_LAST_CHAR = %11100111
LCD_ADDR_LAST_ROW_FIRST_CHAR = %11000000

; Game Constants
DRAW_LOOP_WAIT_TIME = $ff
ROBO_JUMP_UP_TIME   = $03
HURDLE_SPACING      = $07

; Stack memory locations - 0100 -> 01FF
; RAM memory locations - 0200 -> 3FFF (Full range 0000-3FFF)
robo_position   = $0200         ; 1 byte (6 bits to represent LCD screen cursor position)
robo_jump_time  = $0201         ; 1 byte (holds the remaing draw cycles robo is on top display line)
hurdle_spacing_count = $0202    ; 1 byte (set by `HURDLE_SPACING`, adds hurdle to course)
hurdle_spawn_position = $0203   ; 1 byte (holds hurdle spawn address)
init_draw_cursor    = $0204     ; 1 byte (used during init to draw the first screen)
hurdle_count    = $0205         ; 1 byte (# of hurdles present on screen)
hurdle_count_display_position = $0206 ; 1 byte
robo_score      = $0207         ; 1 byte (holds the player score)
hurdle_position = $0208         ; 4 bytes holds hurdle positions for collision check

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
    ; draw hurdle
    jsr draw_hurdle
    ; draw robo sprite
    jsr draw_robo_sprite
    ; calculate collision
    jsr calculate_collision
    ; draw loop wait
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
    lda #%10001111
    sta hurdle_count_display_position
    stz hurdle_count
    stz robo_score                      ; Initialize Robo Score
    stz hurdle_spacing_count            ; Initialize hurdle spacing count to 0
    stz robo_jump_time                  ; Initialize robo jump flag to 0
    stz hurdle_position                 ; Store hurdle position
    lda #%11010000                      ; Set to 2nd row 16th char 
    sta hurdle_spawn_position           ; Store hurdle spawn_position
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR   ; Set cursor 2nd row 1st char
    sta robo_position                   ; Store initial robo_position
    inc robo_position
    jsr lcd_instruction

    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR
    sta init_draw_cursor
; loop through 40H - 67H to draw game sprites
draw_init_course:
    cmp robo_position
    bne draw_ground
    ; if robo_position, draw robo sprite
    lda #ROBO_SPRITE
    jsr print_char
    jmp end_init_draw_check
; else draw ground
draw_ground:
    lda #GROUND_SPRITE
    jsr print_char
; end > 67H
end_init_draw_check:
    lda init_draw_cursor
    inc init_draw_cursor
    cmp #LCD_ADDR_LAST_ROW_LAST_CHAR
    bne draw_init_course
draw_init_end:
    rts

draw_hurdle:
    inc hurdle_spawn_position
    lda hurdle_spawn_position
    cmp #LCD_ADDR_LAST_ROW_LAST_CHAR   ; Reset counter at last address for line 2
    beq reset_hurdle_spawn
draw_hurdle_check_spacing:
    inc hurdle_spacing_count
    lda hurdle_spacing_count
    cmp #HURDLE_SPACING
    bne draw_hurdle_end
draw_hurdle_draw:
    stz hurdle_spacing_count    ; Reset `hurdle_spacing_count`
    lda hurdle_spawn_position   ; Load hurdle spawn
    jsr set_cursor_address
    lda #HURDLE_SPRITE
    jsr print_char
    ldy hurdle_count
    lda hurdle_spawn_position
    sta hurdle_position,y
    inc hurdle_count
    rts
draw_hurdle_end:
    lda hurdle_spawn_position   ; Load hurdle spawn
    jsr set_cursor_address
    lda #GROUND_SPRITE          ; No hurdle, draw ground
    jsr print_char
    rts

reset_hurdle_spawn:
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR  ; Set cursor 2nd row 1st char
    sta hurdle_spawn_position          ; Store hurdle_spawn_position
    jmp draw_hurdle_check_spacing

draw_robo_sprite:
    ; reset the position from any jump adjustment
    lda robo_position
    ora #%01000000
    sta robo_position
    ; Store previous robo position
    ldx robo_position
    ; Increment robo position in memory to current
    inc robo_position
    ; Reset position if over LCD address limit
    lda robo_position
    cmp #LCD_ADDR_SECOND_OVERFLOW   ; Reset counter if past last address for line 2
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
    rts

handle_robo_jump_time:
    dec robo_jump_time
    lda robo_position
    ; Set robo_position to line 1
    and #%10111111          ; 0 at D6 is line 1 for LCD
    sta robo_position
    jmp draw_robo_sprite_redraw

reset_robo_counter:
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR  ; Set cursor 2nd row 1st char
    sta robo_position                   ; Store initial robo_position
    jmp draw_robo_sprite_check_jump

calculate_collision:
    ; Check robo_position w/ closest hurdle
    lda robo_position
    cmp hurdle_position
    beq game_over

    ; draw hurdle count
    lda hurdle_count_display_position
    jsr set_cursor_address
    lda #BLANK_SPRITE
    jsr print_char
    inc hurdle_count_display_position
    lda hurdle_count_display_position
    cmp #LCD_ADDR_FIRST_OVERFLOW
    beq reset_count_display
draw_hurdle_count:
    lda hurdle_count_display_position
    jsr set_cursor_address
    ; lda hurdle_count
    lda robo_score
    adc #%00110000
    jsr print_char
    rts
reset_count_display:
    lda #%10000000
    sta hurdle_count_display_position
    jmp draw_hurdle_count

game_over:
    ldx #0
    lda robo_position
    and #%10111111          ; Set to line one
    jsr set_cursor_address
game_over_message_draw:
    lda game_over_message,x
    beq game_over_loop
    jsr print_char
    inx
    jmp game_over_message_draw
game_over_loop:
    jmp game_over_loop

game_over_message: .asciiz "Game Over"

wait:
    ldx #DRAW_LOOP_WAIT_TIME
    ldy #DRAW_LOOP_WAIT_TIME
wait_loop:
    dex
    txa
    cmp #$00
    bne wait_loop
    dey 
    tya
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
