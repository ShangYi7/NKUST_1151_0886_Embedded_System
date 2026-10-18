; ==============================================================================
; 專案名稱: AT89C52 雙機 UART 串列通訊 - 純發送端 (U3 Transmitter)
; 腳位定義:
;   - 按鈕: P1.0 (按下為低電位 0)
;   - 發送: P3.1 (TXD) 接至接收端 P3.0 (RXD)
; ==============================================================================

    ORG     0000H
    LJMP    MAIN

COUNTER_VAL DATA    30H
KEY_PIN     BIT     P1.0

    ORG     0030H
MAIN:
    MOV     SP, #60H
    MOV     COUNTER_VAL, #00H
    SETB    KEY_PIN

    ; Timer 1 Mode 2 (8-bit 自動重載)
    MOV     TMOD, #20H
    MOV     SCON, #40H          ; Mode 1, REN=0 (純發送，不接收)
    MOV     TH1, #0FDH          ; 9600 bps @ 11.0592MHz (或 12MHz 同步)
    MOV     TL1, #0FDH
    SETB    TR1
    CLR     TI

MAIN_LOOP:
    JB      KEY_PIN, MAIN_LOOP  ; 未按下則等待

    ACALL   DELAY_20MS          ; 按下防彈跳
    JB      KEY_PIN, MAIN_LOOP

    INC     COUNTER_VAL         ; 計數 +1
    MOV     A, COUNTER_VAL
    ACALL   UART_SEND_BYTE      ; 送出資料

WAIT_RELEASE:
    JNB     KEY_PIN, WAIT_RELEASE ; 等待完全放開按鈕
    ACALL   DELAY_20MS          ; 放開防彈跳

    SJMP    MAIN_LOOP

UART_SEND_BYTE:
    CLR     TI
    MOV     SBUF, A
WAIT_TX:
    JNB     TI, WAIT_TX
    CLR     TI
    RET

DELAY_20MS:
    MOV     R6, #40
D1:
    MOV     R7, #250
D2:
    DJNZ    R7, D2
    DJNZ    R6, D1
    RET

    END

