# 6502 ASM Code
code = bytearray([
    0xa9, 0xff,         # lda #$ff    
    0x8d, 0x02, 0x60,   # sta $6002

    0xa9, 0x55,         # lda #$55
    0x8d, 0x00, 0x60,   # sta $6000

    0xa9, 0xaa,         # lda #$aa
    0x8d, 0x00, 0x60,   # sta $6000

    # 0x4c, 0x05, 0x80    # jmp $8005
])

# noop commands (0xea) for full ROM
rom = code + bytearray([0xea] * (32768 - len(code)))

# Program execution address read from 7ffc and 7ffd
# Processor will read the low-order byte first, 
#   then high-order byte (little endian).
# Below will start execution at address 8000 on ROM
rom[0x7ffc] = 0x00
rom[0x7ffd] = 0x80

# Video 1
# # LDA 42 -> Load 42 into A Register
# rom[0] = 0xa9
# rom[1] = 0x42

# # STA 6000 -> Store A Register into address 6000
# rom[2] = 0x8d
# rom[3] = 0x00
# rom[4] = 0x60

# Write the rom bytearray to `rom.bin`
with open("rom.bin", "wb") as out_file:
    out_file.write(rom)