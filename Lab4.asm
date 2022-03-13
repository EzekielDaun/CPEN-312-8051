$MODDE0CV

org 0x00
    ljmp init

org 0x0B
    ljmp tim0_handler

DSEG at 0x30
STATE: DS 1
TIM0DIV0: DS 1
TIM0DIV1: DS 1

BSEG
TIM0FLAG: DBIT 1

CSEG
LUT_SEVEN_SEG:
    DB 01000000b, 01111001b, 00100100b, 00110000b ; 0..3
    DB 00011001b, 00010010b, 00000010b, 01111000b ; 4..7
    DB 00000000b, 00010000b, 00001000b, 00000011b ; 8..b
    DB 00100111b, 00100001b, 00000110b, 00001110b ; c..f
    DB 01111111b                                  ; off
STUDENT_NUMBER:
    DB 4,2,4,4,8,6,1,3

SEVEN_SEG_DISP MAC
    mov DPTR, #LUT_SEVEN_SEG
    mov A, %0
    movc A, @A+DPTR
    mov HEX%1, A
ENDMAC

init:
    mov SP, #0x7f    ; Initialize the stack
    mov LEDRA, #0    ; Turn off LEDR[0..7]
    mov LEDRB, #0    ; Turn off LEDR[8..9]
    mov TMOD , #0x02 ; set 8-bit auto reload timer
    mov TH0, #214    ; set auto reload value = 256-42
    setb IE.7        ; enable global interrupt
    setb IE.1        ; enable TIM0 interrupt
    setb TCON.4      ; enable TIM0 interrupt

state_switch:
    setb TIM0FLAG
    mov A, SWA
    anl A, #0111b
    mov STATE, A

    mov TL0, #0      ; reset timer count
    mov TIM0DIV0, #0 ; reset timer count
    mov TIM0DIV1, #0 ; reset timer count

    mov LEDRA, #0    ; Turn off LEDR[0..7]
    mov LEDRB, #0    ; Turn off LEDR[8..9]
    mov HEX0, #0xFF
    mov HEX1, #0xFF
    mov HEX2, #0xFF
    mov HEX3, #0xFF
    mov HEX4, #0xFF
    mov HEX5, #0xFF

main_loop:
    mov A, SWA
    anl A, #0111b
    cjne A, STATE, state_switch

    jz task_000
    dec A
    jz task_001
    dec A


tim0_handler:
    ;push ACC ; save ACC
    djnz TIM0DIV0, tim0_on_the_fly
    djnz TIM0DIV1, tim0_on_the_fly

tim0_finish:
    setb TIM0FLAG
tim0_on_the_fly:
    ;pop ACC
    reti

task_000:
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#2,4)
    SEVEN_SEG_DISP(#4,3)
    SEVEN_SEG_DISP(#4,2)
    SEVEN_SEG_DISP(#8,1)
    SEVEN_SEG_DISP(#6,0)
    ljmp main_loop

task_001:
    SEVEN_SEG_DISP(#16,5)
    SEVEN_SEG_DISP(#16,4)
    SEVEN_SEG_DISP(#16,3)
    SEVEN_SEG_DISP(#16,2)
    SEVEN_SEG_DISP(#1,1)
    SEVEN_SEG_DISP(#3,0)
    ljmp main_loop

task_reserved:
    jnb TIM0FLAG, main_loop
    clr TIM0FLAG
    cpl LEDRA.0
    ljmp main_loop

END

