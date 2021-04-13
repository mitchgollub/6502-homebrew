; LCD Characters
ROBO_SPRITE =   %11001110
GROUND_SPRITE = %01011111
HURDLE_SPRITE = %10101101
BLANK_SPRITE =  %11111110

; Game Constants
DRAW_LOOP_WAIT_TIME = $aa       ; Controls game speed (lower value = faster game speed)
GAME_OVER_WAIT_TIME = $99       ; Controls the flicker animation on game over
ROBO_JUMP_UP_TIME   = 3         ; Spaces Robot can jump
HURDLE_SPACING      = 7         ; Spaces between hurdle spawns
HURDLE_POSITION_BYTES = 4       ; Bytes of hurdle_position

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
hurdle_position = $0208         ; 4 bytes holds hurdle positions for collision check (4 + 1 terminating zero-byte)

; ROM memory addresses 8000 -> FFFF
    .org $8000
    jmp reset                       ; jump to reset method in bootstrap.s to boot
; Code libraries
    .include "./lib/1602a-lcd.s"    ; include 1602a library
    .include "./lib/bootstrap.s"    ; boot program
    
entrypoint:
    jsr draw_init_screen

; Main Draw loop
draw_loop:
    jsr draw_hurdle             ; draw hurdle
    jsr draw_robo_sprite        ; draw robo sprite
    jsr draw_score              ; draw user score
    jsr calculate_collision     ; calculate collision
    lda #DRAW_LOOP_WAIT_TIME    ; set wait time
    jsr wait                    ; draw loop wait for game speed
    jmp draw_loop

; Game subroutines
draw_init_screen:
    lda #LCD_ADDR_TOP_RIGHT_CORNER
    sta robo_score_display_position     ; Initialize Robo score display position
    stz hurdle_count                    ; Initialize hurdle count to 0
    stz robo_score                      ; Initialize Robo Score to 0
    stz hurdle_spacing_count            ; Initialize hurdle spacing count to 0
    stz robo_jump_time                  ; Initialize robo jump flag to 0

    ldx #0                              ; Initialize hurdle positions to 0
init_hurdle_position_loop:
    stz hurdle_position,x
    inx
    cpx #HURDLE_POSITION_BYTES
    bne init_hurdle_position_loop

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
    bne draw_hurdle_check_spacing
reset_hurdle_spawn:
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR  ; Set cursor 2nd row 1st char
    sta hurdle_spawn_position          ; Store hurdle_spawn_position
draw_hurdle_check_spacing:
    inc hurdle_spacing_count
    lda hurdle_spacing_count
    cmp #HURDLE_SPACING
    bmi draw_hurdle_end
draw_hurdle_draw:
    lda hurdle_count                ; Make sure hurdle_count doesn't
    cmp #HURDLE_POSITION_BYTES - 1  ; go over hurdle_position size
    beq draw_hurdle_end
    stz hurdle_spacing_count        ; Reset `hurdle_spacing_count`
    lda hurdle_spawn_position       ; Load hurdle spawn
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

; Subroutine to calculate position and jumps to draw robo sprite
draw_robo_sprite:
    jsr set_robo_position_to_ground     ; Set Robo on ground
    ldx robo_position                   ; Store previous robo position
    inc robo_position                   ; Increment robo position in memory to current
    lda robo_position                   ; Reset position if over LCD address limit
    cmp #LCD_ADDR_SECOND_OVERFLOW       ; Reset counter if past last address for line 2
    bne draw_robo_sprite_check_jump
reset_robo_counter:
    lda #LCD_ADDR_LAST_ROW_FIRST_CHAR   ; Set cursor 2nd row 1st char
    sta robo_position                   ; Store initial robo_position
draw_robo_sprite_check_jump:
    lda robo_jump_time                  ; Check robo_jump_time
    cmp #0
    beq draw_robo_sprite_redraw
handle_robo_jump_time:
    dec robo_jump_time
    lda robo_position               ; Set robo_position to line 1
    and #%10111111                  ; 0 at D6 is line 1 for LCD
    sta robo_position
draw_robo_sprite_redraw:
    txa                             ; Clear previous robo sprite
    jsr set_cursor_address
    lda #GROUND_SPRITE              ; Draw ground on previous position
    jsr print_char
    txa 
    and #%10111111                  ; Clear top row sprite too
    jsr set_cursor_address
    lda #BLANK_SPRITE
    jsr print_char
    lda #LCD_SHIFT_DISPLAY_LEFT     ; Shift display/characters left 
    jsr lcd_instruction             ; done while robo is off display to remove afterimage
    lda robo_position               ; draw robo at new position
    jsr set_cursor_address
    lda #ROBO_SPRITE
    jsr print_char
set_robo_position_to_ground:
    lda robo_position                   ; reset the position from potential jump adjustment
    ora #%01000000                      ; Set to 2nd row
    sta robo_position                   ; Store position back to memory
    rts

; Draw player score
draw_score:
    dec robo_score_display_position     ; Go to old tens digit position
    lda robo_score_display_position
    cmp #%01111111                      ; Check if it was at starting position
    bne draw_score_clear_previous
    lda #LCD_ADDR_FIRST_OVERFLOW - 1    ; Move position to last position for BLANK overwrite
draw_score_clear_previous:
    jsr set_cursor_address
    lda #BLANK_SPRITE
    jsr print_char
    inc robo_score_display_position     ; Clear the old ones digit position
    lda robo_score_display_position
    jsr set_cursor_address
    lda #BLANK_SPRITE
    jsr print_char
    inc robo_score_display_position     ; Move position to new LCD screen position
    lda robo_score_display_position
    cmp #LCD_ADDR_FIRST_OVERFLOW        ; Check if new position is overflow
    bne draw_robo_score
reset_count_display:                    ; Reset new position to first LCD screen position
    clc                                 ; Clear carry bit to fix score overflow display bug
    lda #%10000000
    sta robo_score_display_position
draw_robo_score:
    ldx robo_score                      ; Initialize remainder
    ldy #0                              ; Initialize tens digit
    lda robo_score
draw_robo_score_loop:                   ; Check if tens digit is needed
    sbc #9
    bcs set_next_decimal
    lda robo_score_display_position     ; Set ones digit when < 10
    jsr set_cursor_address
    txa
    adc #"0"
    jsr print_char
    rts
set_next_decimal:
    tax
    dec robo_score_display_position
    lda robo_score_display_position
    cmp #%01111111
    bne set_next_decimal_draw
    lda #LCD_ADDR_FIRST_OVERFLOW - 1
set_next_decimal_draw:
    jsr set_cursor_address
    inc robo_score_display_position
    iny
    tya
    adc #"0" - 1
    jsr print_char
    txa
    jmp draw_robo_score_loop

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
clean_stale_hurdles_loop:
    lda hurdle_position,x       ; Load "Next" hurdle position       
    sta hurdle_position,y       ; Store "Next" back to "Current" hurdle position
    inx                         ; Move to next hurdle positions
    iny     
    lda hurdle_position,x       ; Peek at "Next" hurdle position
    cmp #0                      ; if empty, we've reached end of hurdles
    bne clean_stale_hurdles_loop; repeat until we've reached the end
    rts

; Game over, draw message and send to game over loop
game_over:
    jsr game_over_flicker
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
game_over_flicker:
    lda #0 
    .rept 3
    jsr wait
    lda #LCD_SCREEN_OFF
    jsr lcd_instruction
    lda #GAME_OVER_WAIT_TIME
    jsr wait
    lda #LCD_SCREEN_ON
    jsr lcd_instruction
    lda #GAME_OVER_WAIT_TIME
    .endr
    rts

game_over_message: .asciiz "Game Over"

; Subroutine for Draw loop to control game speed
; Load the time to wait into A before calling
wait:
    tax
    tay
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
; Sets robo jump flag if not already set
set_robo_jump_time:
    pha
    lda robo_jump_time
    cmp #0
    bne set_robo_jump_time_end  ; Only jump if robo_jump_time == 0
    lda #ROBO_JUMP_UP_TIME
    sta robo_jump_time
set_robo_jump_time_end:
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
