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

    mov HEX4, #L_H
    mov HEX3, #L_E
    mov HEX2, #L_L
    mov HEX1, #L_L
    mov HEX0, #L_O

END