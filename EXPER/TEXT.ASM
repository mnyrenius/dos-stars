format MZ

entry main:start
stack 100h

segment main

include '..\LIB\VIDEO.ASM'
include '..\LIB\TEXT.ASM'

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
    mov dx, 03c8h
    mov ax, 0
    out dx, al
    inc dx

    mov al, 0
    out dx, al
    out dx, al
    out dx, al
    mov cx, 255
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

    cmp [framecounter], 300
    jb @f
    call RenderFadingText
@@:
    cmp [framecounter], 500
    jb @f
    call RenderRightScroll
@@:
    cmp [framecounter], 1000
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
    call Text_PutChar
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
    call Text_PutChar
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

    call Text_PutChar
    add word [bx+2], 8
    inc si
    loop .PutStr

    dec [x_pos_sine]
    cmp [x_pos_sine], -str_sine_len*8
    jg @f
    mov [x_pos_sine], VGA_WIDTH
@@:
    ret

RenderFadingText:
    mov dx, 03c8h
    mov al, 255
    out dx, al
    inc dx
    mov al, [fade_rgb]
    out dx, al
    out dx, al
    out dx, al

    ; fade every 4 frame
    mov ax, [framecounter]
    mov bx, 4
    xor dx, dx
    div bx
    test dx, dx
    jnz .SkipFade
    cmp [fade_dir], 1
    je .FadeIn
    dec [fade_rgb]
    cmp [fade_rgb], 0
    ja @f
    mov [fade_dir], 1
@@:
    jmp .FadeOut
.FadeIn:
    inc [fade_rgb]
    cmp [fade_rgb], 63
    jne @f
    mov [fade_dir], 0
@@:
.FadeOut:
.SkipFade:

    mov si, str_fading
    mov bx, char
    mov byte [bx+1], 20
    mov word [bx+2], 20
    mov byte [bx+4], 255
    mov cx, str_fading_len
.PutStr:
    mov ah, byte [si]
    mov [bx], ah
    call Text_PutChar
    add word [bx+2], 8
    inc si
    loop .PutStr

@@:
    ret

segment text
framecounter dw 0
vbuffer rw 1
char rb 5

x_pos dw VGA_WIDTH
y_pos db VGA_HEIGHT/2
mystring db 'This text seems to be scrolling from right to left, right?'
mystring_len = $-mystring

x_pos_rightscroll dw -str_rightscroll_len*8
y_pos_rightscroll db VGA_HEIGHT/4
str_rightscroll db '... and this should be scrolling from left to right!'
str_rightscroll_len = $-str_rightscroll

str_fading db 'This text fades in and out...'
str_fading_len = $-str_fading
fade_rgb db 0
fade_dir db 1

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
