; Uses binary division to create an ascii decimal
; number from a binary value
; 
; Memory locations:
; define value (2 bytes)
; define mod10 (2 bytes)
; define decimal (4 bytes)
; define char_count (1 byte)
;
; Load number into value. decimal will contain ascii output bytes
divide:
    stz mod10          ; Initialize remainder to 0
    stz mod10 + 1
    clc
    ldx #16
div_loop:
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

    sec
    lda mod10
    sbc #10
    tay
    lda mod10 + 1
    sbc #0
    bcc ignore_result

    sty mod10
    sta mod10 + 1
ignore_result:
    dex
    bne div_loop
    rol value
    rol value + 1

    inc char_count
    ldy char_count

    lda mod10
    clc
    adc #"0"
    sta decimal,y
    
    lda value       ; if value != 0 continue dividing
    ora value + 1
    bne divide      ; branch if value != 0
    rts