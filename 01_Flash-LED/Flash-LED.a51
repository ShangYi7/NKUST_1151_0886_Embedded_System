ORG     0000h
REPEAT: MOV     P2,#00h
        LCALL   DELAY
        MOV     P2,#0FFh
        LCALL   DELAY
        SJMP    REPEAT
DELAY:  MOV      R0,#0FFh
L1:     MOV      R1,#0FFh
L2:     DJNZ     R1,L2
        DJNZ     R0,L1
        RET
        END
