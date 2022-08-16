format MZ

entry main:start
stack 100h

segment main

include '..\LIB\VIDEO.ASM'
include '..\LIB\TEXT.ASM'
include '..\LIB\ADLIB.ASM'

start:
    mov ax, text
    mov ds, ax

    call Video_init
    jnc @f
    mov dx, nomem_string
    mov ah, 9h
    int 21h
    jmp quit
@@:
    mov [vbuffer], ax
    mov es, ax

    mov bx, Music_Song
    call Adlib_Init

MainLoop:

    ; clear screen
    xor di, di
    mov ax, 0
    mov cx, VGA_WIDTH * VGA_HEIGHT / 2
    rep stosw

    mov bx, scene_table
    add bx, [scene_index]
    call word [bx]

    call Video_vsync

    mov ax, [vbuffer]
    call Video_copy_buffer

    inc [framecounter]

    mov bx, Music_Song
    call Adlib_Update

    mov ah, 1h
    int 16h
    jz MainLoop

    mov ax, [vbuffer]
    call Video_deinit

quit:
    mov ah, 4ch
    int 21h
Scene1:
    mov si, Scene1_Str
    mov bx, char
    mov ah, VGA_HEIGHT/2
    mov byte [bx+1], ah
    mov ax, [Scene1_StrX]
    mov word [bx+2], ax
    mov byte [bx+4], 15
    mov cx, Scene1_StrLen
.PutStr:
    mov ah, byte [si]
    mov [bx], ah
    call Text_PutChar
    add word [bx+2], 8
    inc si
    mov ax, [bx+2]
    loop .PutStr

    dec [Scene1_StrX]
    cmp [Scene1_StrX], -Scene1_StrLen*8
    jg @f
    add [scene_index], 2
@@:
    ret

Scene2:
    cmp [Scene1_FadeRgb+0], 2
    jne @f
    mov word [Music_Song+Song_DrumPattern], Music_Drums2
@@:
    cmp [Scene1_FadeRgb+0], 62
    jbe @f
    add [scene_index], 2
@@:
    mov ax, [framecounter]
    mov bx, 8
    xor dx, dx
    div bx
    cmp dx, 0
    jnz @f
    mov dx, 03c8h
    mov ax, 6
    out dx, al
    inc dx
    mov al, [Scene1_FadeRgb+0]
    out dx, al
    mov al, [Scene1_FadeRgb+1]
    out dx, al
    mov al, [Scene1_FadeRgb+2]
    out dx, al
    inc [Scene1_FadeRgb+0] ; R

    movzx ax, byte [Scene1_FadeRgb+0]
    mov bl, 2
    div bl
    cmp ah, 0
    jne @f
    inc [Scene1_FadeRgb+1] ; G

    movzx ax, byte [Scene1_FadeRgb+0]
    mov bl, 3
    div bl
    cmp ah, 0
    jne @f
    inc [Scene1_FadeRgb+2] ; B

@@:
    xor bx, bx
@@:
    push bx
    call DrawRow
    pop bx
    inc bx
    cmp bx, VGA_HEIGHT
    jb @b

    cmp [Scene1_FadeRgb+0], 40
    jbe @f
    call Scene2_PrintStr
@@:
    ret

Scene2_PrintStr:
    mov si, Scene2_Str
    mov bx, char
    mov ah, VGA_HEIGHT/2
    mov byte [bx+1], ah
    mov ax, VGA_WIDTH/2-Scene2_StrLen/2*8
    mov word [bx+2], ax
    mov byte [bx+4], 15
    mov cx, Scene2_StrLen
.PutStr:
    mov ah, byte [si]
    mov [bx], ah
    call Text_PutChar
    add word [bx+2], 8
    inc si
    mov ax, [bx+2]
    loop .PutStr

    ret

Scene3:
    mov [SinEnable], 1
    mov word [Music_Track1+0], Music_Track1Pattern1
    mov word [Music_Song+Song_DrumPattern], Music_Drums1
@@:
    xor bx, bx
@@:
    push bx

    call DrawRow
    pop bx
    inc bx
    cmp bx, VGA_HEIGHT
    jb @b

    cmp [SinPhaseCounter], SinTableLen
    jae @f
    add [SinPhaseCounter], 3
@@:
    mov ax, [framecounter]
    mov bx, 32
    xor dx, dx
    div bx
    test dx, dx
    jnz @f
    mov [SinPhaseCounter], 0
    inc [Scene3_Counter]
@@:
    cmp [Scene3_Counter], 32
    jb @f
    mov [SinPhaseCounter], 0
    add [scene_index], 2
@@:
    ret

Scene4:
    mov [SinEnable], 1
    mov word [Music_Track1+0], Music_Track1Pattern2

    xor bx, bx
@@:
    push bx

    call DrawRow
    pop bx
    inc bx
    cmp bx, VGA_HEIGHT
    jb @b

    cmp [SinPhaseCounter], SinTableLen-1
    jb @f
    mov [SinPhaseCounter], 0
    inc [Scene4_Counter]
@@:
    inc [SinPhaseCounter]

    mov si, Scene4_WaveStrMid
    call RenderSineScroll

    cmp [Scene4_Counter], 0
    jne @f
    mov bx, Scene4_TopStrings
    mov ah, [bx]
    mov [Scene4_WaveStrTop.strlen], ah
    lea ax, [bx+1]
    mov [Scene4_WaveStrTop.str], ax
@@:

    cmp [Scene4_Counter], 10
    jb @f
    mov si, Scene4_WaveStrTop
    call RenderSineScroll
@@:
    cmp [Scene4_WaveStrTop.done], 1
    jne @f
    neg bx
    mov bx, [Scene4_WaveStrTop.str]
    movzx ax, [Scene4_WaveStrTop.strlen]
    add bx, ax
    mov ah, [bx]
    cmp ah, 0
    je @f
    mov [Scene4_WaveStrTop.strlen], ah
    inc bx
    mov [Scene4_WaveStrTop.str], bx
    mov [Scene4_WaveStrTop.x], VGA_WIDTH
    mov [Scene4_WaveStrTop.done], 0

@@:

    cmp [Scene4_WaveStrMid.done], 1
    jne @f
    mov [Scene4_WaveStrMid.x], VGA_WIDTH
    mov [Scene4_WaveStrMid.done], 0
@@:
    ret

; si: pointer to 6 byte struct
; {
;   dw  pointer to string
;   db  str len
;   db  y
;   dw  x
;   db  done (0/1)
; }
RenderSineScroll:
    push bp
    mov bp, sp
    sub sp, 2

    Str     equ word [si]
    StrLen  equ byte [si+2]
    Y       equ byte [si+3]
    X       equ word [si+4]
    Done    equ byte [si+6]
    Colors  equ byte [si+7]

    ; locals
    StrPtr equ [bp-2]

    mov bx, Str
    mov StrPtr, bx

    mov bx, char
    mov ah, Y
    mov byte [bx+1], ah
    mov ax, X
    mov word [bx+2], ax
    mov byte [bx+4], 15
    movzx cx, StrLen
.PutStr:
    mov ah, Y
    mov byte [bx+1], ah
    push bx
    mov bx, StrPtr
    mov ah, byte [bx]
    pop bx
    mov [bx], ah

    ; add y sine offset
    push bx
    mov ax, [framecounter]
    add ax, cx
    xor dx, dx
    mov bx, SinTableLen
    div bx
    mov bx, SinTable
    add bx, dx
    mov ah, [bx]
    pop bx
    add [bx+1], ah
    mov ax, [bx+2]
    cmp Colors, 1
    jne @f
    mov byte [bx+4], al
@@:
    call Text_PutChar
    add word [bx+2], 8
    inc word StrPtr
    loop .PutStr

    dec X
    movzx ax, StrLen
    mov dl, 8
    mul dl
    neg ax
    cmp X, ax
    jg @f
    mov Done, 1
@@:
    mov sp, bp
    pop bp
    ret

; bx: y
DrawRow:
    mov ax, bx
    mov cx, bx
    push ax

    mov bl, VGA_HEIGHT/8
    div bl
    test ah, ah
    jnz @f
    xor [RowOffset], VGA_WIDTH/8
@@:
    pop ax
    mov bx, VGA_WIDTH
    mul bx
    add ax, [RowOffset]

    ; add sine offset
    cmp byte [SinEnable], 1
    jne .NoSine
    push ax
    movzx ax, [SinPhaseCounter]
    cmp [SinPhaseCounter], SinTableLen
    jae @f
    add ax, cx
@@:
    xor dx, dx
    mov bx, SinTableLen
    div bx
    mov bx, SinTable
    add bx, dx
    movzx dx, [bx]
    shr dx, 2
    pop ax
    add ax, dx

.NoSine:
    mov di, ax
    mov al, 6
    mov cx, 4

    ; now draw row
.Draw:
    push cx

    mov cx, VGA_WIDTH/8
.DrawInner:
    cmp di, VGA_WIDTH*VGA_HEIGHT
    jae .Done

    stosb
    loop .DrawInner

    add di, VGA_WIDTH/8

    pop cx
    loop .Draw
.Done:
    ret

segment text
framecounter dw 0
vbuffer rw 1
RowOffset dw 0
char rb 5

scene_table dw Scene1, Scene2, Scene3, Scene4
scene_index dw 0


nomem_string db 'Failed to allocate double buffer', 0dh, 0ah, '$'

SinTable db \
     0,  0,  0,  0,  0,  1,  2,  3, \
     4,  6,  7,  9, 11, 13, 15, 18, \
    20, 23, 25, 27, 30, 32, 35, 37, \
    39, 41, 43, 44, 46, 47, 48, 49, \
    50, 50, 50, 50, 50, 49, 48, 47, \
    46, 44, 43, 41, 39, 37, 35, 32, \
    30, 27, 25, 23, 20, 18, 15, 13, \
    11,  9,  7,  6,  4,  3,  2,  1

SinTableLen = $-SinTable
SinPhaseCounter db 0
SinEnable db 0

Scene1_FadeRgb db 0, 0, 0
Scene1_StrX dw VGA_WIDTH
Scene1_Str db "Hello. Let's draw squares."
Scene1_StrLen = $-Scene1_Str

Scene2_Str db "And waves, please."
Scene2_StrLen = $-Scene2_Str

Scene3_Counter db 0

Scene4_StrMid1 db "Presenting square waves."
Scene4_StrMid1Len = $-Scene4_StrMid1

Scene4_TopStrings:
    db .s2-$-2 
    .s1 db "Well, look at those waves."
    db .s3-$-2
    .s2 db "The characters ARE supposed to have black background."
    db .s4-$-2
    .s3 db "You may think that they should have transparent background."
    db .s5-$-2
    .s4 db "But no, they should not."
    db .end-$-1
    .s5 db "Because."
    .end db 0
Scene4_Counter dw 0

Scene4_WaveStrMid:
    .str    dw Scene4_StrMid1
    .strlen db Scene4_StrMid1Len
    .y      db VGA_HEIGHT/6
    .x      dw VGA_WIDTH
    .done   db 0
    .colors db 1

Scene4_WaveStrTop:
    .str    rw 1
    .strlen rb 1
    .y      db VGA_HEIGHT/2
    .x      dw VGA_WIDTH
    .done   db 0
    .colors db 0

include '..\LIB\FONT.ASM'
include 'MUSIC.ASM'

