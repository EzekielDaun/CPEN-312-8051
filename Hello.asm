$MODDE0CV

L_H equ 00001001b
L_E equ 00000110b
L_L equ 01000111b
L_O equ 01000000b

org 0x0
    ljmp init

init:
    mov SP, #0x7f ; Initialize the stack
    mov LEDRA, #0 ; Turn off LEDR[0..7]
    mov LEDRB, #0 ; Turn off LEDR[8..9]

    ; mov HEX4, #L_H
    ; mov HEX3, #L_E
    ; mov HEX2, #L_L
    ; mov HEX1, #L_L
    ; mov HEX0, #L_O

    mov HEX5, #L_F
    mov HEX4, #L_E
    mov HEX3, #L_D
    mov HEX2, #L_C
    mov HEX1, #L_B
    mov HEX0, #L_A

    mov R7, #0
    mov DPTR, #SEVEN_SEG_TABLE
    clr A
loop:
    movc A, @A+DPTR
    mov HEX0, A
    mov A, R7
    inc A
    anl A, #00001111b
    mov R7, A

    mov R0, #150
L3: mov R1, #148
L2: mov R2, #250
L1: djnz R2, L1
    djnz R1, L2
    djnz R0, L3

    ljmp loop


SEVEN_SEG_TABLE:
    DB 01000000b, 01111001b, 00100100b, 00110000b ; 0..3
    DB 00011001b, 00010010b, 00000010b, 01111000b ; 4..7
    DB 00000000b, 00010000b, 00001000b, 00000011b ; 8..b
    DB 00100111b, 00100001b, 00000110b, 00001110b ; c..f

END