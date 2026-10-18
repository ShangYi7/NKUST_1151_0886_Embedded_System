# Changelog

## 更新日期: 2026-10-19
### 更動項目
- 實作 PC 透過 UART 串列通訊操控 16 進制計數器加減與數值設定功能：
  - 支援 PC 終端鍵入 `+` / `-` 實現手動單步累加與遞減計數。
  - 支援 PC 終端鍵入 `0`~`9` / `A`~`F`（含小寫 `a`~`f`）直跳指定數值、空白鍵 / `P` 暫停與恢復自動計數、`R` 歸零重置。
  - 將步進延遲拆解為 30 次 20ms 輪詢，在延遲期間監聽 UART 接收旗標 `RI`，收到 PC 鍵盤字元時即時解析並反饋。
- 根據 Proteus 電路腳位連線配置七段顯示器驅動：
  - 將 P2.0 ~ P2.6 分別對應 7 段顯示器之 a ~ g 段，因共陰極接地，以高電位 1 點亮、低電位 0 熄滅。
  - 建立 0 ~ F 之 16 進制共陰極段碼表 `TABLE_7SEG`（`3FH, 06H, 5BH, 4FH, 66H, 6DH, 7DH, 07H, 7FH, 6FH, 77H, 7CH, 39H, 5EH, 79H, 71H`），以查表指令 `MOVC A, @A+DPTR` 輸出至 P2。
- 實作 Timer 1 模式 2（8 位元自動重載，`TMOD = 20H`）產生 9600 bps 鮑率（`TH1 = TL1 = 0FDH`），UART 設定為模式 1（`SCON = 50H`）。
- 開機後自動以 0.6 秒間隔循環累加 0~F，每次計數同步向 Virtual Terminal 發送 `Count = X\r\n`。
- 完成 `UART-with-PC.a51` 組譯並生成機器碼 `UART-with-PC.hex` 與清單檔 `UART-with-PC.lst`。
- 新增 `README.md`，提供完整電路引腳對照、共陰極真值表、鮑率計算公式與 Proteus 模擬操作指南。
- **修改檔案**：
  - `08_UART-with-PC/UART-with-PC.a51`
  - `08_UART-with-PC/UART-with-PC.hex`
  - `08_UART-with-PC/UART-with-PC.lst`
  - `08_UART-with-PC/pdsprj/UART-with-PC.pdsprj`
  - `08_UART-with-PC/pdsprj/UART-with-PC.pdsprj.SHANGYI-PC.ast10.9.workspace`
  - `08_UART-with-PC/README.md`
  - `08_UART-with-PC/CHANGELOG.md`


