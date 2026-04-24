#  DOS Resistor Color

這是一個使用 **NASM 16-bit Assembly** 撰寫的 DOS `.COM` 程式。

程式會直接寫入 VGA Text Mode 記憶體 `B800:0000`，在畫面上顯示一個彩色電阻圖，並依照三個色環顯示電阻值。

目前範例：

```text
A = Blue   = 6
B = Yellow = 4
C = Red    = 2

R = 64 × 10^2 = 6400Ω
````

---

## 檔案

```text
resistor.asm    # NASM 16-bit DOS .COM 原始碼
resistor.com    # 編譯後產生的 DOS 可執行檔
```

---

## 需求工具

需要安裝：

```text
NASM
DOSBox
```

### Linux / WSL

Ubuntu / Debian 可以使用：

```bash
sudo apt update
sudo apt install nasm dosbox
```

---

##  編譯方法

使用 NASM 將 `resistor.asm` 編譯成 DOS `.COM` 程式：

```bash
nasm -f bin resistor.asm -o resistor.com
```

參數說明：

| 參數                | 說明                 |
| ----------------- | ------------------ |
| `nasm`            | 使用 NASM 組譯器        |
| `-f bin`          | 輸出純 binary 格式      |
| `resistor.asm`    | 原始碼檔案              |
| `-o resistor.com` | 輸出成 `resistor.com` |

成功後會產生：

```text
resistor.com
```

注意：
這不是 Windows `.exe`，也不是 Linux ELF。
這是 16-bit DOS `.COM` 程式，需要在 DOSBox 之類的環境執行。

---

##  執行方法

### 方法一：在目前資料夾執行 DOSBox

假設 `resistor.com` 在目前資料夾：

```bash
dosbox .
```

進入 DOSBox 後輸入：

```text
mount c .
c:
resistor.com
```

---

##  修改電阻色環

在程式中找到：

```asm
A equ BLUE
B equ YELLOW
C equ RED
```

三個色環的意義：

| 色環  | 意義        |
| --- | --------- |
| `A` | 第一位數      |
| `B` | 第二位數      |
| `C` | 乘上 `10^C` |

例如：

```asm
A equ BROWN
B equ BLACK
C equ ORANGE
```

代表：

```text
Brown = 1
Black = 0
Orange = 3

R = 10 × 10^3 = 10000Ω
```

修改後重新編譯：

```bash
nasm -f bin resistor.asm -o resistor.com
```

再到 DOSBox 執行：

```text
resistor.com
```

---

##  PSP 解釋

### PSP 是什麼？

PSP 全名是：

```text
Program Segment Prefix
```

中文可以翻成：

```text
程式段前綴區
```

在 DOS 執行 `.COM` 程式時，DOS 不會把程式直接放在 offset `0000h` 開始的位置。

DOS 會先在程式前面建立一段 256 bytes 的 PSP。

記憶體配置大致如下：

```text
某個 DOS Segment
┌────────────────────────────┐
│ 0000h ~ 00FFh              │
│ PSP                        │
│ Program Segment Prefix     │
├────────────────────────────┤
│ 0100h                      │
│ .COM 程式真正開始的位置     │
└────────────────────────────┘
```

所以 `.COM` 程式通常會寫：

```asm
org 100h
```

意思是告訴組譯器：

```text
這個程式執行時會從 offset 0100h 開始
```

如果沒有寫 `org 100h`，程式中的 label 位址計算可能會錯誤。

---

### 為什麼 `.COM` 程式常用 `org 100h`？

因為 DOS `.COM` 程式的進入點固定在：

```text
CS:0100h
```

其中：

```text
CS = 程式所在的 segment
IP = 0100h
```

所以：

```asm
org 100h
```

是 `.COM` 程式非常重要的固定寫法。

---

##  組語功能總整理

| 類型      | 指令 / 語法            | 功能                             |
| ------- | ------------------ | ------------------------------ |
| 組譯設定    | `bits 16`          | 指定程式是 16-bit 組語                |
| 組譯設定    | `org 100h`         | 指定 `.COM` 程式從 offset `100h` 開始 |
| 常數定義    | `equ`              | 定義組譯時常數，不佔記憶體                  |
| 資料定義    | `db`               | Define Byte，定義 byte 資料或字串      |
| 重複資料    | `times`            | 重複產生資料                         |
| 搬移資料    | `mov`              | 將資料從來源搬到目的                     |
| 堆疊操作    | `push`             | 將資料放入 stack                    |
| 堆疊操作    | `pop`              | 從 stack 取出資料                   |
| 方向控制    | `cld`              | 清除方向旗標，使 `lodsb/stosw` 往前處理    |
| BIOS 呼叫 | `int 10h`          | 呼叫 BIOS 影片服務                   |
| DOS 呼叫  | `int 21h`          | 呼叫 DOS 系統服務                    |
| 清零技巧    | `xor reg, reg`     | 將暫存器清成 0                       |
| 字串讀取    | `lodsb`            | 從 `DS:SI` 讀取一個 byte 到 `AL`     |
| 字串寫入    | `stosw`            | 將 `AX` 寫入 `ES:DI`              |
| 比較      | `cmp`              | 比較兩個值並設定旗標                     |
| 條件跳躍    | `je`               | Jump if Equal，相等就跳轉            |
| 無條件跳躍   | `jmp`              | 直接跳轉                           |
| 加法      | `inc`              | 加 1                            |
| 加法      | `add`              | 加上指定數值                         |
| 交換      | `xchg`             | 交換兩個暫存器的值                      |
| 除法      | `div`              | 無號除法                           |
| 乘法      | `mul`              | 無號乘法                           |
| 記憶體定址   | `[ColorsMap + bx]` | 使用 `BX` 作為索引查表                 |
| 段覆寫     | `[ds:bp]`          | 明確指定從 `DS:BP` 讀取資料             |

---

##  暫存器角色總表

| 暫存器  | 用途                                 |
| ---- | ---------------------------------- |
| `AX` | 主要工作暫存器，也用於 BIOS/DOS interrupt     |
| `AH` | VGA 文字顏色屬性                         |
| `AL` | 目前讀到的字元                            |
| `BX` | 查表索引暫存器                            |
| `BL` | 儲存目前電阻色碼                           |
| `CX` | 儲存常數 `160`，用於計算一行的 byte 數          |
| `DX` | 配合 `DIV` 使用，作為 `DX:AX` 的高位部分       |
| `SI` | 指向 `Resistor` 字串資料                 |
| `DI` | 指向 VGA 螢幕記憶體 offset                |
| `BP` | 指向 `ColorsR` 色環資料                  |
| `CS` | Code Segment，程式碼段                  |
| `DS` | Data Segment，資料段                   |
| `ES` | Extra Segment，用來指向 VGA 記憶體 `B800h` |
| `SS` | Stack Segment，堆疊段                  |

---

##  VGA Text Mode 記憶體概念

VGA Text Mode 的畫面記憶體位置是：

```text
B800:0000
```

每一格文字佔 2 bytes：

```text
┌────────────┬────────────┐
│ 字元 byte  │ 顏色 byte  │
└────────────┴────────────┘
     AL            AH
```

所以程式使用：

```asm
stosw
```

一次寫入 2 bytes：

```text
AX = AH:AL

AL = 要顯示的字元
AH = 顏色屬性
```

例如：

```asm
mov al, 'A'
mov ah, 07h
stosw
```

代表在畫面上輸出：

```text
灰白色的 A
```

---

## 執行流程圖

```text
start
  |
  v
設定 DS = CS
  |
  v
cld
  |
  v
設定 VGA 80x25 text mode
  |
  v
ES = B800h
DI = 0
SI = Resistor
BP = ColorsR
  |
  v
default_color:
AH = 07h
  |
  v
next_char:
AL = [DS:SI]
SI++
  |
  v
┌───────────────────┐
│ AL == 0 ?          │
└───────────────────┘
  | 是
  v
done，回到 DOS

  | 否
  v
┌───────────────────┐
│ AL == '|' ?        │
└───────────────────┘
  | 是
  v
color:
BL = [DS:BP]
BP++
AH = ColorsMap[BL]
stosw
回到 default_color

  | 否
  v
┌───────────────────┐
│ AL == 13 ?         │
└───────────────────┘
  | 是
  v
carriage_return:
DI = 目前行開頭
回到 next_char

  | 否
  v
┌───────────────────┐
│ AL == 10 ?         │
└───────────────────┘
  | 是
  v
line_feed:
DI += 160
回到 next_char

  | 否
  v
一般字元：
stosw
回到 next_char
```

---

## 程式核心概念

這個程式的核心技巧是：

```text
把整張電阻圖當成字串輸出，
但把字串中的 | 當成特殊標記。
```

例如：

```asm
db "----------[  |   |   |       ]----------",13,10
```

三個 `|` 分別代表三個色環：

```text
第一個 | → A 色環
第二個 | → B 色環
第三個 | → C 色環
```

目前設定：

```asm
A equ BLUE
B equ YELLOW
C equ RED
```

所以畫面會顯示：

```text
[ Blue ][ Yellow ][ Red ]

R = 6400Ω
```

---

## 色碼對照表

### 電阻色碼

| 顏色     | 數字 |
| ------ | -: |
| Black  |  0 |
| Brown  |  1 |
| Red    |  2 |
| Orange |  3 |
| Yellow |  4 |
| Green  |  5 |
| Blue   |  6 |
| Violet |  7 |
| Gray   |  8 |
| White  |  9 |

---

### 電阻色碼轉 VGA 顏色

程式中的表格：

```asm
ColorsMap:
    db 0, 6, 4, 12, 14, 2, 1, 5, 8, 15
```

對應關係：

| 電阻顏色   | 電阻數字 | VGA 顏色碼 |
| ------ | ---: | ------: |
| Black  |    0 |       0 |
| Brown  |    1 |       6 |
| Red    |    2 |       4 |
| Orange |    3 |      12 |
| Yellow |    4 |      14 |
| Green  |    5 |       2 |
| Blue   |    6 |       1 |
| Violet |    7 |       5 |
| Gray   |    8 |       8 |
| White  |    9 |      15 |

---

##  總結

這份程式展示了幾個 16-bit DOS 組語的重要觀念：

1. `.COM` 程式與 `org 100h`
2. PSP 的基本概念
3. BIOS interrupt `int 10h`
4. DOS interrupt `int 21h`
5. VGA Text Mode 記憶體 `B800:0000`
6. `lodsb` 讀取字串
7. `stosw` 寫入螢幕
8. 使用 `DS:SI` 讀資料
9. 使用 `ES:DI` 寫畫面
10. 使用查表法將電阻色碼轉成 VGA 顏色
11. 使用 `|` 作為特殊佔位符來畫色環

