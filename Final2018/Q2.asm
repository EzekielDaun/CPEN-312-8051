$modde0cv

push 0xD0
push 0xE0
push 0x00
mov a,R1
add a,R1
add a,#0x32
mov r0, A
djnz R0, $
pop 0x00
pop 0xE0
pop 0xD0
ret

END