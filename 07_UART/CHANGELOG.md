# Changelog

## 更新日期: 2026-10-18
### 更動項目
- 實作 8051 雙機 UART 串列通訊程式碼，實現按鍵觸發傳輸與 8-Bit LED Bar 即時接收顯示功能。
- 採用雙機自適應架構（Dual-Role Adaptive Architecture），使單一韌體可同時適用於 Proteus 中的發送端晶片（U3）與接收端晶片（U1）：
  - 發送端（U3）：輪詢 P1.0 按鍵輸入，實作 20ms 防彈跳判斷。短按觸發 8 位元計數值 +1 並透過 UART Mode 1（9600 bps）發送；按住超過 600ms 自動切換至高速連發模式（每 160ms 遞增發送一次）。
  - 接收端（U1）：隨時監聽 UART 接收中斷旗標（RI），收到位元組後透過 `CPL A` 取反碼，並輸出至 P2 驅動共陽極 LED-BARGRAPH-RED 進行二進位顯示。
- 配置 Timer 1 模式 2（8 位元自動重載模式，`TMOD = 20H`）作為串列傳輸鮑率產生器，設定 `TH1 = TL1 = 0FDH` 配合 11.0592MHz 晶振產生精準 9600 bps。
- 完成 `UART.a51` 組譯並產出機器碼檔案 `UART.hex` 與清單檔 `UART.lst`，並撰寫硬體腳位與模擬說明文件 `README.md`。
- 針對實體電路實作中按鍵放開彈跳與長按誤判卡死問題進行全面修復：
  - 在 `UART.a51` 的按鍵偵測流程中加入 `WAIT_RELEASE` 等待放開與 20ms 去彈跳機制，避免使用者放開按鍵時彈跳造成重複觸發或死等。
  - 發送常式加入前置清空 `TI` 旗標保護，防止在硬體時鐘異常時永久卡死於 `JNB TI, $`。
  - 新增專屬的純發送端韌體 `UART_TX.a51` 與純接收端韌體 `UART_RX.a51`，並組譯生成 `UART_TX.hex` 與 `UART_RX.hex`，杜絕實體電路中懸空腳位雜訊互相干擾。
- **修改檔案**：
  - `07_UART/UART.a51`
  - `07_UART/UART.hex`
  - `07_UART/UART.lst`
  - `07_UART/UART_TX.a51`
  - `07_UART/UART_TX.hex`
  - `07_UART/UART_TX.lst`
  - `07_UART/UART_RX.a51`
  - `07_UART/UART_RX.hex`
  - `07_UART/UART_RX.lst`
  - `07_UART/README.md`
  - `07_UART/CHANGELOG.md`

