; bx: pointer to
; char  db
; y     db
; x     dw
; color db
Text_PutChar:
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
