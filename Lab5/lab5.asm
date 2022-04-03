$modde0cv

CSEG at 0
    ljmp init

DSEG at 30H

; inputs reserved for the math32 library
x:		ds	4
y:		ds	4

; input number from switches, 10 bcd digits
bcd:	ds	5

; store current function
FUNCTION: ds 1

BSEG

; math flag, reserved for the math32 library
mf:		dbit 1

$include(math32.asm)
$include(Read_sw6.asm)

CSEG
init:
    mov SP, #0x7f    		; Initialize the stack
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov bcd+4, a

	mov function, a

	lcall Display

	mov b, #0           	; 0:addition, 1:subtraction, 2:multiplication,
							; 3:division, 4:remainder, 5: sqrt
	setb LEDRA.0        	; Turn LEDR0 on to indicate addition

main_loop:
	jb KEY.3, no_funct  	; If 'Function' key not pressed, skip
	jnb KEY.3, $        	; Wait for release of 'Function' key
	lcall next_function
	ljmp main_loop          ; Go check for more input
no_funct:
	jb KEY.2, no_load       ; If 'Load' key not pressed, skip
	jnb KEY.2, $            ; Wait for user to release 'Load' key
	lcall bcd2hex           ; Convert the BCD number to hex in x
	lcall copy_xy           ; Copy x to y
	Load_X(0)               ; Clear x (this is a macro)
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_load:
	jb KEY.1, no_equal      ; If 'equal' key not pressed, skip
	jnb KEY.1, $            ; Wait for user to release 'equal' key
	lcall bcd2hex           ; Convert the BCD number to hex in x
	mov a, function         ; Check what function to be called
	cjne a, #0, no_add
	; ------addition------
	lcall add32             ; Perform x+y
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_add:
	cjne a, #1, no_subbtraction
	; ------subtraction------
	lcall sub32
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_subbtraction:
	cjne a, #2, no_multiplication
	; ------multiplication------
	lcall mul32
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_multiplication:
	cjne a, #3, no_division
	; ------division------
	lcall div32
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_division:
	cjne a, #4, no_remainder
	; ------remainder------
	lcall remainder32
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_remainder:
	cjne a, #5, no_sqrt
	; ------sqrt------
	lcall sqrt32
	lcall hex2bcd           ; Convert result in x to BCD
	lcall Display           ; Display the new BCD number
	ljmp main_loop          ; Go check for more input
no_sqrt:
							; Other operations maybe coded here
no_equal:
							; get more numbers
	lcall ReadNumber
	jnc no_new_digit    	; Indirect jump to 'main_loop'
	lcall Shift_Digits
	lcall Display
no_new_digit:
	ljmp main_loop

; This function increment FUNCTION and display current function on one of LEDR0..=5
next_function:
	inc FUNCTION
	mov a, FUNCTION
	cjne a, #6, next_function_no_reset
	mov FUNCTION, #0
next_function_no_reset:
	mov R0, FUNCTION
	mov R1, #1
next_function_rl:
	mov a, R0
	jz next_function_end
	dec R0
	mov a, R1
	rl a
	mov R1, a
	sjmp next_function_rl
next_function_end:
	mov LEDRA, R1
	ret

; x = x - (x / y * y)
remainder32:
	push acc
	push psw

	; save number x to [R5..R7]
	mov R4,x+0
	mov R5,x+1
	mov R6,x+2
	mov R7,x+3

	lcall div32
	lcall mul32

	clr c
	mov a, R4
	subb a, x+0
	mov x+0, a
	mov a, R5
	subb a, x+1
	mov x+1, a
	mov a, R6
	subb a, x+2
	mov x+2, a
	mov a, R7
	subb a, x+3
	mov x+3, a

	pop psw
	pop acc
	ret

sqrt32:
	;https://en.wikipedia.org/wiki/Integer_square_root#..._using_subtraction
	push acc
	push psw
	push y+3
	push y+2
	push y+1
	push y+0

	clr a
	mov y+3, a
	mov y+2, a
	mov y+1, a
	mov y+0, #5

	lcall mul32 ; a = 5 * y
sqrt32_loop:
	lcall x_gteq_y
	jnb mf, sqrt32_end
	lcall sub32
	clr c
	mov a, y+0
	addc a, #10
	mov y+0, a
	mov a, y+1
	addc a, #0
	mov y+1, a
	mov a, y+2
	addc a, #0
	mov y+2, a
	mov a, y+3
	addc a, #0
	mov y+3, a
	sjmp sqrt32_loop

sqrt32_end:
	lcall xchg_xy
	mov y+3, #0
	mov y+2, #0
	mov y+1, #0
	mov y+0, #10
	lcall div32

	pop y+0
	pop y+1
	pop y+2
	pop y+3
	pop psw
	pop acc
	ret

END