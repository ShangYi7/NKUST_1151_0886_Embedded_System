; ==============================================================================
; 專案名稱: AT89C52 16 進制計數器與 PC 串列通訊 (UART with PC)
; 實驗平台: Proteus 模擬 / 實體 8051 開發板
; 晶片型號: AT89C52 (預設 11.0592MHz 或 12MHz 晶振)
;
; 硬體腳位配置:
;   - 共陰極 7 段顯示器 (Common Cathode 7-Segment, 陰極接地):
;       P2.0 -> a 段
;       P2.1 -> b 段
;       P2.2 -> c 段
;       P2.3 -> d 段
;       P2.4 -> e 段
;       P2.5 -> f 段
;       P2.6 -> g 段
;       P2.7 -> 空接 (dp 小數點)
;       (共陰極高電位 1 點亮，低電位 0 熄滅)
;
;   - UART 串列通訊介面 (連接至 PC Virtual Terminal):
;       P3.0 (RXD) -> 連接至 Virtual Terminal 的 TXD (接收 PC 指令)
;       P3.1 (TXD) -> 連接至 Virtual Terminal 的 RXD (發送資料至 PC)
;
; 系統功能與操作邏輯:
;   1. 開機後自動啟動 16 進制 (0 ~ F) 自動循環計數，每步間隔約 0.6 秒。
;   2. 七段顯示器即時顯示 0, 1, 2, ..., 9, A, b, C, d, E, F 循環。
;   3. 每次計數更新時，自動透過 UART 發送當前值至 Virtual Terminal 顯示。
;   4. PC 雙向終端機互動控制指令 (在 Virtual Terminal 視窗直接鍵入):
;      - '0' ~ '9' / 'A' ~ 'F' (或小寫 'a' ~ 'f'): 直接設定計數值。
;      - [空白鍵 Space] 或 'P' / 'p': 暫停 / 恢復自動計數。
;      - '+': 單步手動計數加 1。
;      - '-': 單步手動計數減 1。
;      - 'R' / 'r': 重置計數值歸零 (Count = 0)。
; ==============================================================================

    ORG     0000H
    LJMP    MAIN

; ------------------------------------------------------------------------------
; 內部 RAM 變數與旗標定義
; ------------------------------------------------------------------------------
COUNTER_VAL DATA    30H       ; 目前計數值 (00H ~ 0FH)
FLAGS       DATA    20H       ; 狀態旗標組 (可位元定址區 20H~2FH)
PAUSE_FLAG  BIT     FLAGS.0   ; 暫停旗標: 0 = 自動計數運行中, 1 = 暫停計數

; ------------------------------------------------------------------------------
; 主程式起始區段
; ------------------------------------------------------------------------------
    ORG     0030H
MAIN:
    MOV     SP, #60H          ; 設定堆疊指標
    MOV     COUNTER_VAL, #00H ; 初始計數值設為 0
    CLR     PAUSE_FLAG        ; 預設為自動運行模式

    ; --- 初始化 UART 與 Timer 1 鮑率產生器 ---
    ; TMOD: Timer 1 Mode 2 (8 位元自動重載)
    MOV     TMOD, #20H
    ; SCON: Mode 1 (8-bit UART), REN=1 (致能接收)
    MOV     SCON, #50H

    ; 鮑率設定 (9600 bps @ 11.0592MHz):
    MOV     TH1, #0FDH
    MOV     TL1, #0FDH
    SETB    TR1               ; 啟動 Timer 1

    ; 清空 UART 發送與接收旗標
    CLR     TI
    CLR     RI

    ; 初始更新 7 段顯示器
    ACALL   UPDATE_7SEG

    ; 透過 UART 向 PC 終端機發送開機迎賓選單
    ACALL   SEND_WELCOME_MSG

    ; 發送初始計數狀態
    ACALL   SEND_COUNT_VAL

; ------------------------------------------------------------------------------
; 主迴圈: 自動計數與即時輪詢處理
; ------------------------------------------------------------------------------
MAIN_LOOP:
    ; 檢查目前是否處於暫停模式
    JB      PAUSE_FLAG, PAUSE_PROCESS

    ; --- 自動運行模式 ---
    ; 延遲步進時間 (約 600ms)，並在延遲期間即時輪詢 UART 接收
    ACALL   DELAY_WITH_UART_POLL

    ; 延遲結束後，若在延遲期間被設定為暫停，則跳過累加
    JB      PAUSE_FLAG, MAIN_LOOP

    ; 計數值遞增 1
    INC     COUNTER_VAL
    MOV     A, COUNTER_VAL
    ANL     A, #0FH           ; 保持在 00H ~ 0FH 範圍 (16 進制 0~F 循環)
    MOV     COUNTER_VAL, A

    ; 更新 7 段顯示器並回報 PC 終端機
    ACALL   UPDATE_7SEG
    ACALL   SEND_COUNT_VAL

    SJMP    MAIN_LOOP

; ------------------------------------------------------------------------------
; 暫停模式處理: 專注監聽 PC 端指令
; ------------------------------------------------------------------------------
PAUSE_PROCESS:
    JNB     RI, PAUSE_PROCESS ; 等待 PC 端傳送字元
    ACALL   PROCESS_UART_CHAR ; 處理接收到的指令
    SJMP    MAIN_LOOP

; ------------------------------------------------------------------------------
; 子程式: 步進延遲 (約 600ms) 並即時輪詢 UART 接收
; 設計說明:
;   將 600ms 拆解為 30 個 20ms 區間，每 20ms 檢查一次 RI 旗標。
;   若有鍵盤輸入則立即處理，大幅提升系統反應即時性。
; ------------------------------------------------------------------------------
DELAY_WITH_UART_POLL:
    MOV     R4, #30           ; 30 * 20ms = 600ms
D_LOOP:
    ACALL   DELAY_20MS

    ; 檢查是否有 PC 端傳來的字元
    JNB     RI, D_NO_CHAR
    ACALL   PROCESS_UART_CHAR
    ; 若收到指令後變為暫停狀態，立即結束延遲
    JB      PAUSE_FLAG, D_EXIT

D_NO_CHAR:
    DJNZ    R4, D_LOOP
D_EXIT:
    RET

; ------------------------------------------------------------------------------
; 子程式: 處理 UART 接收字元 (PC 鍵盤指令解析)
; ------------------------------------------------------------------------------
PROCESS_UART_CHAR:
    CLR     RI                ; 清除接收中斷旗標
    MOV     A, SBUF           ; 讀取收到的 ASCII 字元

    ; 忽略換行與回車符號
    CJNE    A, #0DH, CHK_LF
    RET
CHK_LF:
    CJNE    A, #0AH, CHK_DIGIT
    RET

; --- 1. 檢查是否為 '0' ~ '9' ---
CHK_DIGIT:
    CJNE    A, #'0', CHK_D_GT
    SJMP    SET_DIGIT
CHK_D_GT:
    JC      CHK_PLUS          ; 小於 '0'，跳去檢查符號
    CJNE    A, #('9' + 1), CHK_D_VALID
CHK_D_VALID:
    JNC     CHK_UPPER         ; 大於 '9'，跳去檢查大寫字母
SET_DIGIT:
    CLR     C
    SUBB    A, #'0'           ; 轉換為數值 0 ~ 9
    MOV     COUNTER_VAL, A
    SJMP    CMD_UPDATE_COUNT

; --- 2. 檢查是否為大寫 'A' ~ 'F' ---
CHK_UPPER:
    CJNE    A, #'A', CHK_U_GT
    SJMP    SET_UPPER
CHK_U_GT:
    JC      CHK_LOWER         ; 小於 'A'，跳去檢查小寫字母
    CJNE    A, #('F' + 1), CHK_U_VALID
CHK_U_VALID:
    JNC     CHK_LOWER         ; 大於 'F'，跳去檢查小寫字母
SET_UPPER:
    CLR     C
    SUBB    A, #'A'
    ADD     A, #10            ; 轉換為數值 10 ~ 15 (0AH ~ 0FH)
    MOV     COUNTER_VAL, A
    SJMP    CMD_UPDATE_COUNT

; --- 3. 檢查是否為小寫 'a' ~ 'f' ---
CHK_LOWER:
    CJNE    A, #'a', CHK_L_GT
    SJMP    SET_LOWER
CHK_L_GT:
    JC      CHK_SPACE         ; 小於 'a'，跳去檢查空白鍵
    CJNE    A, #('f' + 1), CHK_L_VALID
CHK_L_VALID:
    JNC     CHK_SPACE         ; 大於 'f'，跳去檢查其他指令
SET_LOWER:
    CLR     C
    SUBB    A, #'a'
    ADD     A, #10            ; 轉換為數值 10 ~ 15 (0AH ~ 0FH)
    MOV     COUNTER_VAL, A
    SJMP    CMD_UPDATE_COUNT

; --- 4. 檢查是否為空白鍵 ' ' 或 'P' / 'p' (暫停/恢復切換) ---
CHK_SPACE:
    CJNE    A, #' ', CHK_KEY_P
    SJMP    TOGGLE_PAUSE
CHK_KEY_P:
    CJNE    A, #'P', CHK_KEY_P_LOW
    SJMP    TOGGLE_PAUSE
CHK_KEY_P_LOW:
    CJNE    A, #'p', CHK_PLUS
TOGGLE_PAUSE:
    CPL     PAUSE_FLAG        ; 切換暫停 / 運行狀態
    JB      PAUSE_FLAG, SEND_PAUSE_NOTIFY
    ; 發送恢復運行通知
    MOV     DPTR, #STR_RESUME
    ACALL   SEND_STRING
    RET
SEND_PAUSE_NOTIFY:
    MOV     DPTR, #STR_PAUSE
    ACALL   SEND_STRING
    RET

; --- 5. 檢查是否為 '+' (單步加一) ---
CHK_PLUS:
    CJNE    A, #'+', CHK_MINUS
    INC     COUNTER_VAL
    MOV     A, COUNTER_VAL
    ANL     A, #0FH
    MOV     COUNTER_VAL, A
    SJMP    CMD_UPDATE_COUNT

; --- 6. 檢查是否為 '-' (單步減一) ---
CHK_MINUS:
    CJNE    A, #'-', CHK_RESET
    DEC     COUNTER_VAL
    MOV     A, COUNTER_VAL
    ANL     A, #0FH
    MOV     COUNTER_VAL, A
    SJMP    CMD_UPDATE_COUNT

; --- 7. 檢查是否為 'R' / 'r' (重置歸零) ---
CHK_RESET:
    CJNE    A, #'R', CHK_RESET_LOW
    SJMP    DO_RESET
CHK_RESET_LOW:
    CJNE    A, #'r', CMD_UNKNOWN
DO_RESET:
    MOV     COUNTER_VAL, #00H
    MOV     DPTR, #STR_RESET
    ACALL   SEND_STRING
    ACALL   UPDATE_7SEG
    ACALL   SEND_COUNT_VAL
    RET

; --- 未知指令 ---
CMD_UNKNOWN:
    RET

; 指令更新計數值之共同出口
CMD_UPDATE_COUNT:
    ACALL   UPDATE_7SEG
    ACALL   SEND_COUNT_VAL
    RET

; ------------------------------------------------------------------------------
; 子程式: 更新共陰極 7 段顯示器 (P2 輸出)
; 邏輯:
;   - 共陰極 7 段顯示器高電位 (1) 點亮，低電位 (0) 熄滅。
;   - 腳位對應: P2.0~P2.6 對應 a~g 段。
; ------------------------------------------------------------------------------
UPDATE_7SEG:
    MOV     A, COUNTER_VAL
    ANL     A, #0FH           ; 確保 index 為 0~15
    MOV     DPTR, #TABLE_7SEG
    MOVC    A, @A+DPTR        ; 查表取得共陰極段碼
    MOV     P2, A             ; 輸出至 P2 驅動七段顯示器
    RET

; ------------------------------------------------------------------------------
; 子程式: 發送當前計數值至 PC 終端機 (格式: "Count = X\r\n")
; ------------------------------------------------------------------------------
SEND_COUNT_VAL:
    MOV     DPTR, #STR_COUNT_PREFIX
    ACALL   SEND_STRING

    ; 轉換 COUNTER_VAL (0~15) 為 ASCII 字元
    MOV     A, COUNTER_VAL
    ANL     A, #0FH
    CJNE    A, #10, CHK_VAL_10
CHK_VAL_10:
    JC      VAL_IS_DIGIT      ; 若 < 10 為數字 '0'~'9'
    ; 為 10~15 ('A'~'F')
    ADD     A, #('A' - 10)    ; A + 55 (37H) -> 10 + 55 = 65 = 'A'
    SJMP    TX_HEX_CHAR
VAL_IS_DIGIT:
    ADD     A, #'0'           ; A + '0' (30H)
TX_HEX_CHAR:
    ACALL   SEND_CHAR

    ; 發送換行回車符號
    MOV     A, #0DH           ; Carriage Return '\r'
    ACALL   SEND_CHAR
    MOV     A, #0AH           ; Line Feed '\n'
    ACALL   SEND_CHAR
    RET

; ------------------------------------------------------------------------------
; 子程式: 發送開機迎賓字串與操作功能選單
; ------------------------------------------------------------------------------
SEND_WELCOME_MSG:
    MOV     DPTR, #STR_WELCOME
    ACALL   SEND_STRING
    RET

; ------------------------------------------------------------------------------
; 子程式: 發送以 00H 結尾的字串常數 (DPTR 指向字串起始位址)
; ------------------------------------------------------------------------------
SEND_STRING:
    CLR     A
    MOVC    A, @A+DPTR
    JZ      SEND_STR_END      ; 遇到 00H (字串結束符) 則返回
    ACALL   SEND_CHAR
    INC     DPTR
    SJMP    SEND_STRING
SEND_STR_END:
    RET

; ------------------------------------------------------------------------------
; 子程式: 透過 UART 發送單一位元組 (字元儲存於暫存器 A)
; ------------------------------------------------------------------------------
SEND_CHAR:
    CLR     TI                ; 發送前確保 TI 清空
    MOV     SBUF, A           ; 寫入 SBUF 啟動硬體串列發送
WAIT_TI:
    JNB     TI, WAIT_TI       ; 等待發送完成旗標
    CLR     TI                ; 清除發送完成旗標
    RET

; ------------------------------------------------------------------------------
; 軟體延遲子程式 (適用於 11.0592MHz / 12MHz 晶振，精準約 20ms)
; ------------------------------------------------------------------------------
DELAY_20MS:
    MOV     R6, #40
D20_L1:
    MOV     R7, #250
    DJNZ    R7, $             ; 250 * 2us = 500us
    DJNZ    R6, D20_L1        ; 40 * 500us = 20ms
    RET

; ------------------------------------------------------------------------------
; 字串常數資料表 (ASCII 字串，以 00H 結束)
; ------------------------------------------------------------------------------
STR_WELCOME:
    DB      0DH, 0AH
    DB      "========================================", 0DH, 0AH
    DB      " AT89C52 16-Hex Counter with PC (UART) ", 0DH, 0AH
    DB      " Baud Rate: 9600 bps (8-N-1)           ", 0DH, 0AH
    DB      " Control Commands:                     ", 0DH, 0AH
    DB      "   [0~F]     : Set Counter Directly    ", 0DH, 0AH
    DB      "   [Space/P] : Pause / Resume Counting ", 0DH, 0AH
    DB      "   [+] / [-] : Step Inc (+1) / Dec (-1)", 0DH, 0AH
    DB      "   [R]       : Reset to 0              ", 0DH, 0AH
    DB      "========================================", 0DH, 0AH, 00H

STR_COUNT_PREFIX:
    DB      "Count = ", 00H

STR_PAUSE:
    DB      "[PAUSED] Counter Paused.", 0DH, 0AH, 00H

STR_RESUME:
    DB      "[RUNNING] Counter Resumed.", 0DH, 0AH, 00H

STR_RESET:
    DB      "[RESET] Counter Reset to 0.", 0DH, 0AH, 00H

; ------------------------------------------------------------------------------
; 共陰極 7 段顯示器 16 進制編碼表 (0 ~ F)
; 段碼順序 (P2.7 ~ P2.0) : dp, g, f, e, d, c, b, a
; 共陰極 (Common Cathode) : 1 = 點亮, 0 = 熄滅
; ------------------------------------------------------------------------------
TABLE_7SEG:
    DB      3FH               ; '0' : a, b, c, d, e, f
    DB      06H               ; '1' : b, c
    DB      5BH               ; '2' : a, b, d, e, g
    DB      4FH               ; '3' : a, b, c, d, g
    DB      66H               ; '4' : b, c, f, g
    DB      6DH               ; '5' : a, c, d, f, g
    DB      7DH               ; '6' : a, c, d, e, f, g
    DB      07H               ; '7' : a, b, c
    DB      7FH               ; '8' : a, b, c, d, e, f, g
    DB      6FH               ; '9' : a, b, c, d, f, g
    DB      77H               ; 'A' : a, b, c, e, f, g
    DB      7CH               ; 'b' : c, d, e, f, g
    DB      39H               ; 'C' : a, d, e, f
    DB      5EH               ; 'd' : b, c, d, e, g
    DB      79H               ; 'E' : a, d, e, f, g
    DB      71H               ; 'F' : a, e, f, g

    END

