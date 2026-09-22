	ORG   0000h
REPEAT:
	mov     P2, #00h
	lcall   DELAY
	mov     P2, #0FFh
	lcall   DELAY
	sjmp    REPEAT
DELAY:
	mov     R2, #08h
L0:
	mov     R0, #0FFh
L1:
	mov     R1, #0FFh
L2:
	djnz    R1, L2
	djnz    R0, L1
	djnz    R2, L0
	ret
	end
