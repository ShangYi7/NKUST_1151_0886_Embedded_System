; ==============================================================================
; 專案名稱: AT89C52 雙機 UART 串列通訊 - 純接收端 (U1 Receiver)
; 腳位定義:
;   - 接收: P3.0 (RXD) 接自發送端 P3.1 (TXD)
;   - 輸出: P2.0 ~ P2.7 接至共陽極 LED Bar (低電位 0 點亮)
; ==============================================================================

    ORG     0000H
    LJMP    MAIN

RECV_BUF    DATA    30H

    ORG     0030H
MAIN:
    MOV     SP, #60H
    MOV     P2, #0FFH           ; 初始 LED 全滅

    ; Timer 1 Mode 2 (8-bit 自動重載)
    MOV     TMOD, #20H
    MOV     SCON, #50H          ; Mode 1, REN=1 (致能接收)
    MOV     TH1, #0FDH          ; 9600 bps @ 11.0592MHz (或 12MHz 同步)
    MOV     TL1, #0FDH
    SETB    TR1
    CLR     RI

MAIN_LOOP:
    JNB     RI, MAIN_LOOP       ; 等待接收到資料
    CLR     RI                  ; 清除接收中斷旗標
    MOV     A, SBUF             ; 讀取 SBUF 資料
    MOV     RECV_BUF, A
    CPL     A                   ; 取反碼 (共陽極低電位亮)
    MOV     P2, A               ; 輸出至 LED 顯示
    SJMP    MAIN_LOOP

    END

