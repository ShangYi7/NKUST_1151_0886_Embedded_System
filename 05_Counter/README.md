# 8051 9-Bit 二進位 LED 計數器 (Counter)

NKUST 嵌入式系統（Embedded System）課程實驗專案，使用 8051 組合語言（Assembly）撰寫，實現 9-Bit 二進位累加計數器，透過按鍵控制自動跑動與單步累加，數值從 `000000000B` 依序跑至 `111111111B`（511），並自動歸零循環。

---

## 一、功能說明

本專案核心程式為 `Counter.a51`，主要功能特點如下：

1. **9-Bit 二進位累加顯示**：
   - 計數數值由 `0` 依序遞增（`00` -> `01` -> `10` -> `11` ... 直到 `111111111`，即十進位 0 ~ 511）。
   - 滿 511 後再加 1 自動歸零並循環。
   - 二進位值 `1` 代表 LED 點亮，`0` 代表 LED 熄滅。
2. **共陽極 (Active-Low) 驅動**：
   - 配合 Proteus 常用之共陽極 LED Bar 接法（陽極接 +5V VCC），程式透過 `CPL`（取反碼）將二進位 `1` 轉為低電位 `0` 點亮 LED。
3. **按鈕控制模式**：
   - **按鈕 1 (P1.0 - 連續加一 / 暫停)**：按下後啟動「連續加一」自動計數（步長 +1，約 100ms 一步）；再次按下同一按鈕可即時暫停，方便觀察特定二進位狀態。
   - **按鈕 2 (P1.1 - 連續加二 / 暫停)**：按下後切換為「連續加二」自動計數（步長 +2，約 100ms 一步）；再次按下同一按鈕可即時暫停。
   - **無縫切換**：在運行中按下另一顆按鍵，會直接切換為該按鍵對應的步長繼續計數。

---

## 二、硬體腳位配置

| 訊號名稱 | 8051 腳位 | 實體 Pin 腳 | 連接元件與功能 |
| :--- | :--- | :--- | :--- |
| **KEY_RUN1** | `P1.0` | Pin 1 | 按鈕 1（連續加一 / 暫停），按下接地（低電位觸發） |
| **KEY_RUN2** | `P1.1` | Pin 2 | 按鈕 2（連續加二 / 暫停），按下接地（低電位觸發） |
| **LED 0 (LSB)** | `P2.0` | Pin 21 | LED-BARGRAPH Pin 1（最低位 Bit 0） |
| **LED 1** | `P2.1` | Pin 22 | LED-BARGRAPH Pin 2（Bit 1） |
| **LED 2** | `P2.2` | Pin 23 | LED-BARGRAPH Pin 3（Bit 2） |
| **LED 3** | `P2.3` | Pin 24 | LED-BARGRAPH Pin 4（Bit 3） |
| **LED 4** | `P2.4` | Pin 25 | LED-BARGRAPH Pin 5（Bit 4） |
| **LED 5** | `P2.5` | Pin 26 | LED-BARGRAPH Pin 6（Bit 5） |
| **LED 6** | `P2.6` | Pin 27 | LED-BARGRAPH Pin 7（Bit 6） |
| **LED 7** | `P2.7` | Pin 28 | LED-BARGRAPH Pin 8（Bit 7） |
| **LED 8 (MSB)** | `P1.2` | Pin 3 | LED-BARGRAPH Pin 9（**第 9 位最高位 Bit 8**） |
| **VCC (+5V)** | - | - | LED-BARGRAPH 陽極（Pin 11 ~ Pin 19 全部並聯至 +5V） |

> [!NOTE]
> 在 Proteus 電路中，10 段式 LED Bar 的前 8 段已接至 P2.0 ~ P2.7。請在 Proteus 中**拉一條導線將 AT89C52 的 Pin 3 (P1.2) 連接至 LED Bar 的 Pin 9**，以作為第 9 顆 LED 的信號線。

---

## 三、檔案說明

| 檔案名稱 | 說明 |
| :--- | :--- |
| `Counter.a51` | 8051 組合語言原始程式碼 |
| `Counter.hex` | 組譯產生的 Intel HEX 機器碼檔案（用於載入 Proteus 模擬或實體燒錄） |
| `Counter.lst` | 組譯清單檔（包含位址、機器碼與原始碼對照） |
| `pdsprj/` | Proteus 電路模擬專案資料夾 |
| `CHANGELOG.md` | 專案變更與更新紀錄 |

---

## 四、編譯與建置方式

使用 ASEM-51 組譯器進行組譯：

```powershell
asemw Counter.a51
```

組譯成功後會自動輸出 `Counter.hex` 與 `Counter.lst`，重新啟動 Proteus 模擬即可直接測試驗證。

