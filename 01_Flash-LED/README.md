# 8051 LED 閃爍控制 (Flash-LED)

NKUST 嵌入式系統（Embedded System）課程實驗專案，使用 8051 組合語言（Assembly）撰寫，實現控制 Port 2 的 LED 燈進行週期性全亮與全滅閃爍。

---

## 一、功能說明

本專案核心程式為 `Flash-LED.a51`，主要實現以下功能：

1. **LED 全亮控制**：向 `P2` 埠寫入 `00H`（低電位），使連接在 Port 2 上的 8 顆 LED 同時點亮（共陽極接法）。
2. **延遲保持**：呼叫 `DELAY` 軟體延遲副程式維持點亮狀態。
3. **LED 全滅控制**：向 `P2` 埠寫入 `0FFH`（高電位），使 8 顆 LED 同時熄滅。
4. **延遲保持與循環**：再次呼叫 `DELAY` 副程式維持熄滅狀態後，透過 `SJMP REPEAT` 形成無窮迴圈，達成 LED 持續閃爍的效果。

---

## 二、程式結構與原理

### 1. 主程式邏輯 (`Flash-LED.a51`)

```assembly
ORG     0000h           ; 程式起始位址（重置向量）
REPEAT: MOV     P2,#00h ; P2 輸出 0x00，點亮 LED
        LCALL   DELAY   ; 呼叫延遲副程式
        MOV     P2,#0FFh; P2 輸出 0xFF，熄滅 LED
        LCALL   DELAY   ; 呼叫延遲副程式
        SJMP    REPEAT  ; 重複執行閃爍流程
```

### 2. 延遲副程式 (`DELAY`)

採用雙層巢狀暫存器計數迴圈：

- 外層暫存器 `R0` 設定為 `0FFH`（255）。
- 內層暫存器 `R1` 設定為 `0FFH`（255）。
- 透過 `DJNZ`（Decrement and Jump if Not Zero）指令進行倒數，利用 CPU 週期消耗達成軟體延遲效果。

```assembly
DELAY:  MOV      R0,#0FFh
L1:     MOV      R1,#0FFh
L2:     DJNZ     R1,L2
        DJNZ     R0,L1
        RET
        END
```

---

## 三、檔案說明

| 檔案名稱        | 說明                                                  |
| :-------------- | :---------------------------------------------------- |
| `Flash-LED.a51` | 8051 組合語言原始程式碼                               |
| `Flash-LED.hex` | 組譯產生的 Intel HEX 機器碼檔案（用於燒錄或模擬載入） |
| `Flash-LED.lst` | 組譯清單檔（包含位址、機器碼與原始碼對照）            |
| `pdsprj/`       | Proteus 電路模擬專案資料夾                            |
| `CHANGELOG.md`  | 專案變更與更新紀錄                                    |

---

## 四、編譯與建置方式

使用 ASEM-51 組譯器進行組譯：

```powershell
asemw Flash-LED.a51
```

組譯成功後會自動輸出 `Flash-LED.hex` 與 `Flash-LED.lst` 檔案，即可載入 Proteus 模擬或燒錄至 8051 實體開發板進行驗證。
