# Changelog

## 更新日期: 2026-10-03
### 更動項目
- 新增專案說明文件 `README.md`，補齊 8051 LED 閃爍程式的功能解析、程式碼結構、延遲副程式原理與 ASEM-51 組譯建置說明。
- 建立 `README.md`，清楚記錄 Port 2 輸出高低電位控制 LED 全亮/全滅的原理、暫存器計數延遲機制及各專案檔案用途。
- **修改檔案**：
  - `01_Flash-LED/README.md`
  - `01_Flash-LED/CHANGELOG.md`

- 將 LED 閃爍間隔從 0.5 秒調整為 5 秒。
- 透過修改 `Flash-LED.a51` 中延遲副程式的最外層暫存器初值 `mov R3, #50`（原為 `#5`），使每次狀態切換（明/滅）的延遲時間延長至約 5.03 秒，並以 `asemw` 重新組譯生成 HEX 與 LST 檔。
- **修改檔案**：
  - `01_Flash-LED/Flash-LED.a51`
  - `01_Flash-LED/Flash-LED.hex`
  - `01_Flash-LED/Flash-LED.lst`

- 修復 LED 閃爍程式中延遲副程式（DELAY）因標籤放置錯誤導致無窮死迴圈、LED 完全不會閃爍的問題。
- 修改 `Flash-LED.a51`，將內層迴圈跳轉標籤 `L2` 移至 `djnz R1, L2` 指令處，避免每次遞減後又重新載入初值 `mov R1, #...`；同時移除混亂的多餘暫存器層級，簡化為標準三層巢狀延遲迴圈，並將計數參數設定為約 0.5 秒（以 12MHz 時脈計算），最後使用 `ASEMW.EXE` 重新組譯產出對應的 `Flash-LED.hex` 與 `Flash-LED.lst`。
- **修改檔案**：
  - `01_Flash-LED/Flash-LED.a51`
  - `01_Flash-LED/Flash-LED.hex`
  - `01_Flash-LED/Flash-LED.lst`
