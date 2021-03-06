$MODDE0CV

org 0x00
    ljmp init

org 0x0B ; Timer0 isr address
    ljmp tim0_handler

DSEG at 0x30
STATE: DS 1
TIM0DIV0: DS 1
TIM0DIV1: DS 1
TASK101STATE: DS 1
TASK110STATE: DS 1

BSEG
TIM0FLAG: DBIT 1
TASK01xFLAG: DBIT 1 ; default 1, means restart
TASK100FLAG: DBIT 1
TASK111RESETFLAG: DBIT 1
TASK111STATEFLAG: DBIT 1

CSEG
LUT_SEVEN_SEG:
    DB 01000000b, 01111001b, 00100100b, 00110000b ; 0..3
    DB 00011001b, 00010010b, 00000010b, 01111000b ; 4..7
    DB 00000000b, 00010000b, 00001000b, 00000011b ; 8..b
    DB 01000110b, 00100001b, 00000110b, 00001110b ; c..f
    DB 01111111b                                  ; off
    DB 00001100b, 01001000b, 00001001b, 01000111b ; p, n, H, L

SEVEN_SEG_DISP MAC ; SEVEN_SEG_DISP(HEXx, #val) set val according to LUT_SEVEN_SEG
    mov DPTR, #LUT_SEVEN_SEG
    mov A, %0
    movc A, @A+DPTR
    mov HEX%1, A
ENDMAC

SWAP_REG MAC
    mov A, %0
    mov B, %1
    mov %0, B
    mov %1, A
ENDMAC

tim0_handler:
    ;push ACC ; save ACC
    djnz TIM0DIV0, tim0_on_the_fly
    djnz TIM0DIV1, tim0_on_the_fly
tim0_finish:
    setb TIM0FLAG
tim0_on_the_fly:
    ;pop ACC
    reti

init:
    mov SP, #0x7f    ; Initialize the stack
    mov LEDRA, #0    ; Turn off LEDR[0..7]
    mov LEDRB, #0    ; Turn off LEDR[8..9]
    mov TMOD , #0x02 ; set 8-bit auto reload timer
    mov TH0, #214    ; set auto reload value = 256-42 for around 1Hz
    setb IE.7        ; enable global interrupt
    setb IE.1        ; enable TIM0 interrupt
    setb TCON.4      ; enable TIM0 interrupt

state_switch:
    ; save switch state
    mov A, SWA
    anl A, #0111b
    mov STATE, A
    ; reset flag bits
    setb TASK01xFLAG
    clr TASK100FLAG
    setb TASK111RESETFLAG
    clr TASK111STATEFLAG
    ; reset state bytes
    mov TASK101STATE, #0
    mov TASK110STATE, #0
    ; reset timer count
    setb TIM0FLAG
    mov TL0, #0
    mov TIM0DIV0, #0
    mov TIM0DIV1, #0
    ; clear all display
    mov LEDRA, #0
    mov LEDRB, #0
    mov HEX0, #0xFF
    mov HEX1, #0xFF
    mov HEX2, #0xFF
    mov HEX3, #0xFF
    mov HEX4, #0xFF
    mov HEX5, #0xFF

main_loop:
    jb SWA.3, set_2hz ; set frequency according to SW3
set_1hz:
    mov TH0, #214     ; set auto reload value = 256-42 for around 1Hz
    ljmp main_logic
set_2hz:
    mov TH0, #235     ; set auto reload value = 256-21 for around 2Hz
    ljmp main_logic

main_logic:
    ; Version 1: Response SWx in realtime
    ; mov A, SWA
    ; anl A, #0111b
    ; cjne A, STATE, state_switch

    ; Version 2: Latch SWx by KEY3
    mov A, STATE
    jb KEY.3, skip_switching
    ljmp state_switch

    ;---------------------------

skip_switching:
    jz task_000_hook
    dec A
    jz task_001_hook
    dec A
    jz task_010_hook
    dec A
    jz task_011_hook
    dec A
    jz task_100_hook
    dec A
    jz task_101_hook
    dec A
    jz task_110_hook
    dec A
    jz task_111_hook

    ljmp main_loop

task_000_hook:
    ljmp task_000
task_001_hook:
    ljmp task_001
task_010_hook:
    ljmp task_010
task_011_hook:
    ljmp task_011
task_100_hook:
    ljmp task_100
task_101_hook:
    ljmp task_101
task_110_hook:
    ljmp task_110
task_111_hook:
    ljmp task_111

; Display 6 MSD of the student number
task_000:
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#2,4)
    SEVEN_SEG_DISP(#4,3)
    SEVEN_SEG_DISP(#4,2)
    SEVEN_SEG_DISP(#8,1)
    SEVEN_SEG_DISP(#6,0)
    ljmp main_loop

; Display 2 LSD of the student number
task_001:
    SEVEN_SEG_DISP(#16,5)
    SEVEN_SEG_DISP(#16,4)
    SEVEN_SEG_DISP(#16,3)
    SEVEN_SEG_DISP(#16,2)
    SEVEN_SEG_DISP(#1,1)
    SEVEN_SEG_DISP(#3,0)
    ljmp main_loop

; Task01x: Rotating display of the student number
task_01x_restart_hook:
    ljmp task_01x_restart

task_010:
    jbc TASK01xFLAG, task_01x_restart_hook
    jnb TIM0FLAG, task_010_end
    clr TIM0FLAG
    push ACC
    SWAP_REG(R7,R6)
    SWAP_REG(R6,HEX5)
    SWAP_REG(HEX5,HEX4)
    SWAP_REG(HEX4,HEX3)
    SWAP_REG(HEX3,HEX2)
    SWAP_REG(HEX2,HEX1)
    SWAP_REG(HEX1,HEX0)
    pop ACC
task_010_end:
    ljmp main_loop

task_011:
    jbc TASK01xFLAG, task_01x_restart_hook
    jnb TIM0FLAG, task_011_end
    clr TIM0FLAG
    push ACC
    SWAP_REG(HEX0,HEX1)
    SWAP_REG(HEX1,HEX2)
    SWAP_REG(HEX2,HEX3)
    SWAP_REG(HEX3,HEX4)
    SWAP_REG(HEX4,HEX5)
    SWAP_REG(HEX5,R6)
    SWAP_REG(R6,R7)
    pop ACC
task_011_end:
    ljmp main_loop

task_01x_restart:
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#2,4)
    SEVEN_SEG_DISP(#4,3)
    SEVEN_SEG_DISP(#4,2)
    SEVEN_SEG_DISP(#8,1)
    SEVEN_SEG_DISP(#6,0)
    mov R7, #01111001b ; HEX code for 1
    mov R6, #00110000b ; HEX code for 3
    clr TIM0FLAG
    ljmp main_loop

; Blink 6 LSD of the student number
task_100:
    jnb TIM0FLAG, task_100_end
    clr TIM0FLAG
    cpl TASK100FLAG
    jb TASK100FLAG, task_100_on
task_100_off:
    mov HEX0, #0xFF
    mov HEX1, #0xFF
    mov HEX2, #0xFF
    mov HEX3, #0xFF
    mov HEX4, #0xFF
    mov HEX5, #0xFF
    ljmp main_loop
task_100_on:
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#4,4)
    SEVEN_SEG_DISP(#8,3)
    SEVEN_SEG_DISP(#6,2)
    SEVEN_SEG_DISP(#1,1)
    SEVEN_SEG_DISP(#3,0)
task_100_end:
    ljmp main_loop

; Gradually display 6 MSD of the student number
task_101:
    jnb TIM0FLAG, task_101_to_main
    clr TIM0FLAG

    mov A, TASK101STATE
    cjne A, #0, task_101_1
task_101_0:
    mov HEX0, #0xFF
    mov HEX1, #0xFF
    mov HEX2, #0xFF
    mov HEX3, #0xFF
    mov HEX4, #0xFF
    mov HEX5, #0xFF
    ljmp task_101_end
task_101_1:
    cjne A, #1, task_101_2
    SEVEN_SEG_DISP(#4,5)
    ljmp task_101_end
task_101_2:
    cjne A, #2, task_101_3
    SEVEN_SEG_DISP(#2,4)
    ljmp task_101_end
task_101_3:
    cjne A, #3, task_101_4
    SEVEN_SEG_DISP(#4,3)
    ljmp task_101_end
task_101_4:
    cjne A, #4, task_101_5
    SEVEN_SEG_DISP(#4,2)
    ljmp task_101_end
task_101_5:
    cjne A, #5, task_101_6
    SEVEN_SEG_DISP(#8,1)
    ljmp task_101_end
task_101_6:
    cjne A, #6, task_101_7
    SEVEN_SEG_DISP(#6,0)
    ljmp task_101_end
task_101_7:
    mov TASK101STATE, #0 ; only 7 states
    ljmp task_101_0
task_101_end:
    inc TASK101STATE
task_101_to_main:
    ljmp main_loop

task_110_end:
    inc TASK110STATE
task_110_to_main:
    ljmp main_loop
; Display HELLO -> CPN312 -> 6 MSD of the student number
task_110:
    jnb TIM0FLAG, task_110_to_main
    clr TIM0FLAG
    mov A, TASK110STATE
    cjne A, #0, task_110_1
task_110_0:
    ; Display "HELLO "
    SEVEN_SEG_DISP(#19,5)
    SEVEN_SEG_DISP(#14,4)
    SEVEN_SEG_DISP(#20,3)
    SEVEN_SEG_DISP(#20,2)
    SEVEN_SEG_DISP(#0,1)
    SEVEN_SEG_DISP(#16,0)
    ljmp task_110_end
task_110_1:
    cjne A, #1, task_110_2
    ; Display 6 MSD of the Student Number
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#2,4)
    SEVEN_SEG_DISP(#4,3)
    SEVEN_SEG_DISP(#4,2)
    SEVEN_SEG_DISP(#8,1)
    SEVEN_SEG_DISP(#6,0)
    ljmp task_110_end
task_110_2:
    cjne A, #2, task_110_3
    ; Display "CPN312"
    SEVEN_SEG_DISP(#12,5)
    SEVEN_SEG_DISP(#17,4)
    SEVEN_SEG_DISP(#18,3)
    SEVEN_SEG_DISP(#3,2)
    SEVEN_SEG_DISP(#1,1)
    SEVEN_SEG_DISP(#2,0)
    ljmp task_110_end
task_110_3:
    mov TASK110STATE, #0
    ljmp task_110_0

task_111_to_main:
    ljmp main_loop
task_111:
    jnb TASK111RESETFLAG, task_111_main_logic
    clr TASK111RESETFLAG
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#4,4)
    SEVEN_SEG_DISP(#8,3)
    SEVEN_SEG_DISP(#6,2)
    SEVEN_SEG_DISP(#1,1)
    SEVEN_SEG_DISP(#3,0)
    ljmp main_loop
task_111_main_logic:
    jnb TIM0FLAG, task_111_to_main
    clr TIM0FLAG

    jb TASK111STATEFLAG, task_111_low_freq
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#2,4)
    SEVEN_SEG_DISP(#4,3)
    SEVEN_SEG_DISP(#4,2)
    SEVEN_SEG_DISP(#8,1)
    SEVEN_SEG_DISP(#6,0)
    cpl TASK111STATEFLAG
    ljmp main_loop
task_111_low_freq:
    SEVEN_SEG_DISP(#4,5)
    SEVEN_SEG_DISP(#4,4)
    SEVEN_SEG_DISP(#8,3)
    SEVEN_SEG_DISP(#6,2)
    SEVEN_SEG_DISP(#1,1)
    SEVEN_SEG_DISP(#3,0)
    cpl TASK111STATEFLAG
    ljmp main_loop

task_reserved:
    ;jnb TIM0FLAG, main_loop
    ;clr TIM0FLAG
    ;cpl LEDRA.0
    ;ljmp main_loop

END

