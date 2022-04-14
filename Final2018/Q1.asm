$modde0cv
dseg at 30H
    bcd :   ds 5
    x   :   ds 4

cseg at 1000H

h2b:
    clr a
    mov bcd+0, a
    mov bcd+1, a
    mov bcd+2, a
    mov bcd+3, a
    mov bcd+4, a
    mov r2, #32
h2b_L0:
    mov r1, #4
    mov r0, #(x+0)
h2b_L1:
    mov a, @r0
    rlc a
    mov @r0, a
    inc r0
    djnz r1, h2b_L1
    mov r1, #5
    mov r0, #(bcd+0)
h2b_L2:
    mov a, @r0
    addc a, @r0
    da a
    mov @r0, a
    inc r0
    djnz r1, h2b_L2
    djnz r2, h2b_L0

    ret



END