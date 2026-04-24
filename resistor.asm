; resistor.asm
; NASM 16-bit DOS .COM program
; Compile:
;   nasm -f bin resistor.asm -o resistor.com
;
; Run in DOSBox:
;   mount c .
;   c:
;   resistor.com

bits 16
org 100h

; =========================================================
; 電阻色碼常數
; Black  = 0
; Brown  = 1
; Red    = 2
; Orange = 3
; Yellow = 4
; Green  = 5
; Blue   = 6
; Violet = 7
; Gray   = 8
; White  = 9
; =========================================================

BLACK   equ 0
BROWN   equ 1
RED     equ 2
ORANGE  equ 3
YELLOW  equ 4
GREEN   equ 5
BLUE    equ 6
VIOLET  equ 7
GRAY    equ 8
WHITE   equ 9

; =========================================================
; 這裡改三個色環
;
; A = 第一位數
; B = 第二位數
; C = 乘上 10 的 C 次方
;
; 目前：
;   A = Blue   = 6
;   B = Yellow = 4
;   C = Red    = 2
;
; 所以：
;   R = 64 x 10^2 = 6400 ohm
; =========================================================

A equ BLUE
B equ YELLOW
C equ RED

start:
    ; .COM 程式通常 CS = DS = SS
    ; 這裡保險起見，明確讓 DS = CS
    push cs
    pop ds

    ; 確保 lodsb / stosw 是往前走
    ;Clear Direction Flag
    ;把方向旗標 DF 清成 0
    cld

    ; 設定 80x25 文字模式，順便清螢幕
    mov ax, 0003h
    int 10h

    ; VGA text mode memory = B800:0000
    ; 要讓 ES 指到 VGA 記憶體
    ;8086 不允許直接把立即值放進 segment register。必須透過一般暫存器
    mov ax, 0B800h
    mov es, ax

    ; DI 指向螢幕 offset
    xor di, di

    ; BX 後面會用 BL 當 index
    ; 所以先清空 BX，避免 BH 有垃圾值
    ; ES:DI = B800:0000 代表從螢幕左上角開始寫
    xor bx, bx

    ; BP 指向三個色環資料
    mov bp, ColorsR

    ; SI 指向要輸出的字串
    mov si, Resistor

default_color:
    ; 預設顏色：
    ; AH = 07h
    ; 黑底灰白字
    mov ah, 07h

next_char:
    ; AL = [DS:SI]
    ; SI++ 如果DF=0
    ;從 Resistor 字串中讀出一個字元
    lodsb

    ; 字串結束
    cmp al, 0
    je done

    ; 遇到 | 代表這裡要畫色環
    cmp al, '|'
    je color

    ; CR = 13，回到該行開頭
    cmp al, 13
    je carriage_return

    ; LF = 10，移到下一行
    cmp al, 10
    je line_feed

    ; 一般字元直接輸出
    ; VGA text mode 一格是：
    ;   AL = 字元
    ;   AH = 顏色
    ;stosw 是字串寫入指令
    ;[ES:DI] = AX
    ;DI = DI + 2   ; 如果 DF = 0
    stosw
    jmp next_char

color:
    ; 取出目前色環的電阻色碼
    ;
    ; 注意：
    ;   BP 預設使用 SS 段
    ;   所以這裡明確寫 ds:bp
    mov bl, [ds:bp]

    ; 移到下一個色環
    inc bp

    ; 根據電阻色碼，查 VGA 顏色
    ;
    ; 例如：
    ;   Blue = 6
    ;   ColorsMap[6] = 1
    ;   所以螢幕顏色變成藍色
    mov ah, [ColorsMap + bx]

    ; 如果你想讓色環比較粗，可以取消下面這行註解
    ; 219 是 CP437 的 full block 字元：█
    mov al, 219

    ; 輸出彩色的色環字元
    stosw

    ; 色環輸出完後，恢復預設顏色
    jmp default_color

carriage_return:
    ; 目標：
    ;   DI 回到目前這一行的開頭
    ;
    ; VGA text mode：
    ;   一行 80 字
    ;   一字 2 bytes
    ;   所以一行 = 160 bytes
    ;
    ; 做法：
    ;   DI / 160 = 目前行數
    ;   目前行數 * 160 = 該行開頭 offset


    ;交換 AX 和 DI。
    ;因為 div 預設使用 AX 當被除數，所以要先把 DI 放到 AX
    ;AX = 目前螢幕 offset，DI = 原本 AX 的值
    xchg ax, di

    ;16-bit div cx 的被除數，DX:AX
    ;先把DX 清零，DX:AX = 0000:AX
    xor dx, dx

    mov cx, 160 ; DX:AX / CX，AX = 商，DX = 餘數
    div cx
    mul cx ;AX=AX*CX
    xchg ax, di

    jmp next_char

line_feed:
    ; 下一行：
    ;   DI += 160
    add di, 160
    jmp next_char

done:
    ; 回到 DOS
    mov ax, 4C00h
    int 21h

; =========================================================
; 電阻色碼 -> VGA 顏色碼
;
; VGA foreground color:
;   0  black
;   1  blue
;   2  green
;   4  red
;   5  magenta
;   6  brown / dark yellow
;   8  gray
;   12 light red
;   14 yellow
;   15 white
; =========================================================

ColorsMap:
    db 0, 6, 4, 12, 14, 2, 1, 5, 8, 15
    ;  0  1  2   3   4  5  6  7  8   9
    ;  Bk Br R   Or  Y  G  Bl V  Gy  W

; 三個色環
ColorsR:
    db A, B, C

; =========================================================
; 要顯示的畫面資料
;
; 注意：
;   | 是色環佔位符
;   程式遇到 | 時，不是當普通字元處理
;   而是會去 ColorsR 取下一個色環顏色
; =========================================================

Resistor:
    db 13,10
    db "      Electronic Resistor Color Code",13,10
    db 13,10
    db "  Black  = 0    Brown  = 1    Red    = 2    Orange = 3",13,10
    db "  Yellow = 4    Green  = 5    Blue   = 6    Violet = 7",13,10
    db "  Gray   = 8    White  = 9",13,10
    db 13,10
    db "      Example:",13,10
    db "        A = Blue",13,10
    db "        B = Yellow",13,10
    db "        C = Red",13,10
    db 13,10
    db "          +-------------------+",13,10
    db "----------[  |   |   |        ]----------",13,10
    db "          +-------------------+",13,10
    db 13,10
    db "              R = ", '0' + A, '0' + B

    ; NASM 語法：
    ;   times C db '0'
    ;
    ; 如果 C = 2，就會產生：
    ;   db '0', '0'
    ;
    ; 所以 A=6, B=4, C=2 時：
    ;   R = 6400
    times C db '0'

    ; CP437 裡面 234 是 Omega 符號 Ω
    db 234

    db 0