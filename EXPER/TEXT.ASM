format MZ

entry main:start
stack 100h

segment main

include '..\LIB\VIDEO.ASM'

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

    ; set palette
;    mov di, palette
;    mov ah, 63 ; r
;    mov al, 31 ; g
;    mov bh, 0  ; b

;    mov byte [di], 0
;    inc di
;    mov byte [di], 0
;    inc di
;    mov byte [di], 0
;    inc di
;    mov cx, 32
;.SetPalette:
;    mov [di], ah
;    inc di
;    mov [di], al
;    inc di
;    mov [di], bh
;    inc di
;    add bh,1

;    mov [di], ah
;    inc di
;    mov [di], al
;    inc di
;    mov [di], bh
;    inc di

;    add al, 1
;    add bh, 1
;    loop .SetPalette

;    mov si, palette
    mov dx, 03c8h
    mov ax, 0
    out dx, al
    inc dx

    mov al, 0
    out dx, al
    out dx, al
    out dx, al
    mov cx, 255
;    cld
;    rep outsb
    xor ax, ax
    mov ah, 31 ; g
    mov bh, 0  ; b
.Loop:
    mov al, 63
    out dx, al
    mov al, ah
    out dx, al
    mov al, bh
    out dx, al

    push ax
    mov al, cl
    mov bl, 4
    xor ah, ah
    div bl
    mov bl, ah
    test bl, bl
    jnz @f
    inc bh
@@:
    mov al, cl
    mov bl, 8
    xor ah, ah
    div bl
    mov bl, ah
    pop ax
    test bl, bl
    jnz @f
    inc ah
@@:
    loop .Loop

MainLoop:

    ; clear screen
    xor di, di
    mov ax, 0
    mov cx, VGA_WIDTH * VGA_HEIGHT / 2
    rep stosw

    call RenderLeftScroll

    cmp [framecounter], 500
    jb @f
    call RenderRightScroll
@@:
    cmp [framecounter], 1
    jb @f
    call RenderSineScroll
@@:
    call Video_vsync

    mov ax, [vbuffer]
    call Video_copy_buffer

    inc [framecounter]

    mov ah, 1h
    int 16h
    jz MainLoop

    mov ax, [vbuffer]
    call Video_deinit

quit:
    mov ah, 4ch
    int 21h

RenderLeftScroll:
    mov si, mystring
    mov bx, char
    mov ah, [y_pos]
    mov byte [bx+1], ah
    mov ax, [x_pos]
    mov word [bx+2], ax
    mov byte [bx+4], 1
    mov cx, mystring_len
.PutStr:
    mov ah, byte [si]
    mov [bx], ah
    call PutChar
    add word [bx+2], 8
    inc si
    mov ax, [bx+2]
    mov [bx+4], al ; color
    loop .PutStr

    dec [x_pos]
    cmp [x_pos], -mystring_len*8
    jg @f
    mov [x_pos], VGA_WIDTH

@@:
    ret

RenderRightScroll:
    mov si, str_rightscroll
    mov bx, char
    mov ah, [y_pos_rightscroll]
    mov byte [bx+1], ah
    mov ax, [x_pos_rightscroll]
    mov word [bx+2], ax
    mov byte [bx+4], 13
    mov cx, str_rightscroll_len
.PutStr:
    mov ah, byte [si]
    mov [bx], ah
    call PutChar
    add word [bx+2], 8
    inc si
    loop .PutStr

    inc [x_pos_rightscroll]
    cmp [x_pos_rightscroll], VGA_WIDTH ;str_rightscroll_len*8
    jl @f
    mov [x_pos_rightscroll], -str_rightscroll_len*8
@@:
    ret

RenderSineScroll:
    ; mod palette
;    mov dx, 03c8h
;    mov al, 11
;    out dx, al
;    inc dx
;    mov al, 63
;    out dx, al
;    mov al, 32
;    out dx, al
;    mov al, 0
;    out dx, al

    mov si, str_sine
    mov bx, char
    mov ah, [y_pos_sine]
    mov byte [bx+1], ah
    mov ax, [x_pos_sine]
    mov word [bx+2], ax
    mov byte [bx+4], 1
    mov cx, str_sine_len
.PutStr:
    mov ah, [y_pos_sine]
    mov byte [bx+1], ah
    mov ah, byte [si]
    mov [bx], ah

    ; add y sine offset
    push bx
    mov ax, [framecounter]
    add ax, cx
    xor dx, dx
    mov bx, 64
    div bx
    mov bx, sine_table
    add bx, dx
    mov ah, [bx]
    pop bx
    add [bx+1], ah
    mov ax, [bx+2]
    mov byte [bx+4], al

    call PutChar
    add word [bx+2], 8
    inc si
    loop .PutStr

    dec [x_pos_sine]
    cmp [x_pos_sine], -str_sine_len*8
    jg @f
    mov [x_pos_sine], VGA_WIDTH
@@:
    ret


; bx: pointer to
; char  db
; y     db
; x     dw
; color db
PutChar:
    pusha

    cmp word [bx+2], VGA_WIDTH-8
    ja .SkipRender
    cmp word [bx+2], 0
    jb .SkipRender

    movzx ax, byte [bx]
    imul ax, 8
    mov si, font8x8
    add si, ax
    movzx ax, byte [bx+1]
    imul ax, VGA_WIDTH
    add ax, word [bx+2]
    mov di, ax

    mov cx, 8
.outer:
    mov dx, 1
    push cx
    mov cx, 8
.inner:
    mov al, 0
    test [si], dx
    jz @f
    mov al, [bx+4]
@@:
    stosb
    shl dx, 1
    loop .inner
    inc si
    add di, VGA_WIDTH-8
    pop cx
    loop .outer

.SkipRender:
    popa
    ret

segment text
framecounter dw 0
vbuffer rw 1
char rb 5
palette rb 256*3

x_pos dw VGA_WIDTH
y_pos db VGA_HEIGHT/2
mystring db 'This text seems to be scrolling from right to left, right?'
mystring_len = $-mystring

x_pos_rightscroll dw -str_rightscroll_len*8
y_pos_rightscroll db VGA_HEIGHT/4
str_rightscroll db '... and this should be scrolling from left to right!'
str_rightscroll_len = $-str_rightscroll

x_pos_sine dw VGA_WIDTH
y_pos_sine db VGA_HEIGHT/3*2
str_sine db 'And this is just... awesome!'
str_sine_len = $-str_sine
blue_sine db 0
green_sine db 128
red_sine db 196
nomem_string db 'Failed to allocate double buffer', 0dh, 0ah, '$'
sine_table db 25, 27, 30, 32, 35, 37, 39, 41, \
              43, 44, 46, 47, 48, 49, 50, 50, \
              50, 50, 50, 49, 48, 47, 46, 44, \
              43, 41, 39, 37, 35, 32, 30, 27, \
              25, 23, 20, 18, 15, 13, 11, 09, \
              07, 06, 04, 03, 02, 01, 00, 00, \
              00, 00, 00, 01, 02, 03, 04, 06, \
              07, 09, 11, 13, 15, 18, 20, 23

include '..\LIB\FONT.ASM'
