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
LCD_ADDR_FIRST_ROW_FIRST_CHAR = %10000000
LCD_ADDR_LAST_ROW_FIRST_CHAR = %11000000
LCD_ADDR_LAST_ROW_LAST_CHAR = %11100111
LCD_ADDR_TOP_RIGHT_CORNER = %10001111

; Game Constants
DRAW_LOOP_WAIT_TIME = $aa       ; Controls game speed (lower value = faster game speed)
ROBO_JUMP_UP_TIME   = 3         ; Spaces Robot can jump
HURDLE_SPACING      = 7         ; Spaces between hurdle spawns

; Stack memory locations - 0100 -> 01FF
; RAM memory locations - 0200 -> 3FFF (Full range 0000-3FFF)
robo_position   = $0200         ; 1 byte (6 bits to represent LCD screen cursor position)
robo_jump_time  = $0201         ; 1 byte (holds the remaing draw cycles robo is on top display line)
hurdle_spacing_count = $0202    ; 1 byte (set by `HURDLE_SPACING`, adds hurdle to course)
hurdle_spawn_position = $0203   ; 1 byte (holds hurdle spawn address)
init_draw_cursor    = $0204     ; 1 byte (used during init to draw the first screen)
hurdle_count    = $0205         ; 1 byte (# of hurdles present on screen)
robo_score_display_position = $0206 ; 1 byte (holds the display position for the player score)
robo_score      = $0207         ; 1 byte (holds the player score)
hurdle_position = $0208         ; 4 bytes holds hurdle positions for collision check

; ROM memory addresses 8000 -> FFFF
    .org $8000
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

    lda #%11100000  ;   Set 3 pins on PORTA to output
    sta DDRA

    lda #%00111000  ;   8-bit - 2 line - 5x8 font (001<DL><N><F>xx)   
    jsr lcd_instruction

    lda #%00001100  ;   Display on - Cursor off - Blink off 
    jsr lcd_instruction

    lda #%00000110  ;   Increment and shift cursor - don't shift display
    jsr lcd_instruction

    lda #$01  ;   Clear display
    jsr lcd_instruction

    ; jsr sprite_test             ;   Prints the game sprites at the top of the screen
    
    jsr draw_init_screen

; Main Draw loop
draw_loop:
    jsr draw_hurdle             ; draw hurdle
    jsr draw_robo_sprite        ; draw robo sprite
    jsr draw_score              ; draw user score
    jsr calculate_collision     ; calculate collision
    jsr wait                    ; draw loop wait for game speed
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

; Game subroutines
sprite_test:
    lda #ROBO_SPRITE
    jsr print_char

    lda #GROUND_SPRITE
    jsr print_char

    lda #HURDLE_SPRITE
    jsr print_char

    rts

draw_init_screen:
    lda #LCD_ADDR_TOP_RIGHT_CORNER
    sta robo_score_display_position     ; Initialize Robo score display position
    stz hurdle_count                    ; Initialize hurdle count to 0
    stz robo_score                      ; Initialize Robo Score to 0
    stz hurdle_spacing_count            ; Initialize hurdle spacing count to 0
    stz robo_jump_time                  ; Initialize robo jump flag to 0
    stz hurdle_position                 ; Initialize hurdle positions to 0
    ldx #1                              ; TODO: Make this a loop to match hurdle_position size
    stz hurdle_position,x
    ldx #2
    stz hurdle_position,x
    ldx #3
    stz hurdle_position,x
    lda #%11010000                      ; Set to 2nd row 16th char 
    sta hurdle_spawn_position           ; Store hurdle spawn_position
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR   ; Set cursor 2nd row 1st char
    sta init_draw_cursor                ; Store beginning of draw screen
    sta robo_position                   ; Store initial robo_position
    inc robo_position
    jsr lcd_instruction                 ; Set starting cursor to 2nd row 1st char

; loop through 40H - 67H to draw game sprites
draw_init_course:
    cmp robo_position               ; if robo_position, draw robo sprite
    bne draw_ground                 ; otherwise draw ground sprite
    lda #ROBO_SPRITE
    jsr print_char
    jmp end_init_draw_check
; draw ground sprite
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

; Subroutine to calculate position and draw hurdle 
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

; Subroutine to calculate position and jumps to draw robo sprite
draw_robo_sprite:
    lda robo_position                  ; reset the position from potential jump adjustment
    ora #%01000000
    sta robo_position
    ; Store previous robo position
    ldx robo_position
    ; Increment robo position in memory to current
    inc robo_position
    ; Reset position if over LCD address limit
    lda robo_position
    cmp #LCD_ADDR_SECOND_OVERFLOW   ; Reset counter if past last address for line 2
    bne draw_robo_sprite_check_jump
reset_robo_counter:
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR  ; Set cursor 2nd row 1st char
    sta robo_position                   ; Store initial robo_position
draw_robo_sprite_check_jump:
    ; Check robo_jump_time
    lda robo_jump_time
    cmp #$00
    beq draw_robo_sprite_redraw
handle_robo_jump_time:
    dec robo_jump_time
    lda robo_position
    ; Set robo_position to line 1
    and #%10111111          ; 0 at D6 is line 1 for LCD
    sta robo_position
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
    lda #LCD_SHIFT_DISPLAY_LEFT         ; Shift display/characters left 
    jsr lcd_instruction                 ; done while robo is off display to remove afterimage
    lda robo_position                   ; draw robo at new position
    jsr set_cursor_address
    lda #ROBO_SPRITE
    jsr print_char
    lda robo_position                  ; reset the position from potential jump adjustment
    ora #%01000000
    sta robo_position
    rts

; Check robo_position w/ closest hurdle to determine game status
calculate_collision:
    lda robo_position           ; Compare Robo position (from ground) and closest hurdle
    cmp hurdle_position
    beq jump_check
    rts
jump_check:
    lda robo_jump_time
    cmp #0
    beq game_over               ; If Robo is jumping, clean up hurdles. Else game over
clean_stale_hurdles:
    ldx #1                      ; "Next" hurdle
    ldy #0                      ; "Current" hurdle
    dec hurdle_count            ; decrease total hurdles
    inc robo_score              ; Made it past a hurdle! +1!
clean_stale_hurdles_loop
    lda hurdle_position,x       ; Load "Next" hurdle position       
    sta hurdle_position,y       ; Store "Next" back to "Current" hurdle position
    inx                         ; Move to next hurdle positions
    iny
    lda hurdle_position,x       ; Peek at "Next" hurdle position
    cmp #0                      ; if empty, we've reached end of hurdles
    bne clean_stale_hurdles_loop; repeat until we've reached the end
    rts

; Draw player score
draw_score:
    lda robo_score_display_position
    jsr set_cursor_address
    lda #BLANK_SPRITE
    jsr print_char
    inc robo_score_display_position
    lda robo_score_display_position
    cmp #LCD_ADDR_FIRST_OVERFLOW
    bne draw_hurdle_count
reset_count_display:
    lda #%10000000
    sta robo_score_display_position
draw_hurdle_count:
    lda robo_score_display_position
    jsr set_cursor_address
    lda robo_score
    adc #%00110000
    jsr print_char
    rts

; Game over, draw message and send to game over loop
; TODO: implement screen flicker
game_over:
    ldx #0
    lda robo_position           ; print message above robo
    and #%10111111              ; Set to line one
    tay                         ; hold cursor address in Y
    jsr set_cursor_address
    jmp game_over_message_draw  ; No need to check cursor on first run
game_over_message_line_check:           ; check to make message print on one LCD line
    tya                                 ; hold cursor address in Y
    cmp #LCD_ADDR_FIRST_OVERFLOW
    bne game_over_message_draw          ; set cursor address to first row if on second row
    lda #LCD_ADDR_FIRST_ROW_FIRST_CHAR
    tay
    jsr set_cursor_address
game_over_message_draw:
    lda game_over_message,x             ; Loop over game over message string
    beq game_over_loop
    jsr print_char
    inx                                 ; increase message pointer
    iny                                 ; increase cursor pointer
    jmp game_over_message_line_check    ; check if we've left first row
game_over_loop:
    jmp game_over_loop

game_over_message: .asciiz "Game Over"

; Subroutine for Draw loop to control game speed
wait:
    ldx #DRAW_LOOP_WAIT_TIME
    ldy #DRAW_LOOP_WAIT_TIME
wait_loop:
    dex
    txa
    cmp #0
    bne wait_loop
    dey 
    tya
    cmp #0
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
