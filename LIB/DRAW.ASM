; bx: pointer to
;   color db
;   x0 dw
;   y0 db
;   x1 dw
;   y1 db
;
draw_line:
    push bp
    mov bp, sp
    sub sp, 10

    ; local variables
    d_x equ [word bp-2]
    s_x equ [word bp-4]
    d_y equ [word bp-6]
    s_y equ [word bp-8]
    e_2 equ [word bp-10]

    ; parameters
    color   equ [si]
    x0      equ [si+2]
    y0      equ [si+4]
    x1      equ [si+6]
    y1      equ [si+8]

    mov si, bx

    ; d_x = abs(x1 - x0)
    mov ax, x1
    sub ax, x0
    test ax, ax
    jns .x1_gt_x0
    neg ax
.x1_gt_x0:
    mov d_x, ax

    ; s_x
    mov ax, x0
    cmp ax, x1
    jb .x0_lt_x1
    mov word s_x, -1
    jmp @f
.x0_lt_x1:
    mov word s_x, 1
@@:

    ; d_y = -abs(y1 - y0)
    mov ax, y1
    sub ax, y0
    test ax, ax
    jns .y1_gt_y0
    neg ax
.y1_gt_y0:
    neg ax
    mov d_y, ax

    ; s_y
    mov ax, y0
    cmp ax, y1
    jb .y0_lt_y1
    mov word s_y, -1
    jmp @f
.y0_lt_y1:
    mov word s_y, 1
@@:

    ; error = d_x + d_y
    mov bx, d_x
    add bx, d_y

.draw:
    mov ax, y0
    imul ax, VGA_WIDTH
    add ax, x0
    mov di, ax
    mov al, color
    stosb

    mov ax, x0
    cmp ax, x1
    jne @f
    mov ax, y0
    cmp ax, y1
    jne @f
    jmp .end
@@:
    ; x0 != x1 || y0 != y1
    mov ax, bx
    imul ax, 2 ; e_2 = 2 * error
    mov e_2, ax
    cmp ax, d_y
    jl .e_2_lt_dy
    mov ax, x0
    cmp ax, x1
    je .end
    add bx, d_y
    mov ax, x0
    add ax, s_x
    mov x0, ax ; x0 = x0 + sx
.e_2_lt_dy:
    mov ax, e_2
    cmp ax, d_x ; if e_2 <= dx
    jg .draw
    mov ax, y0
    cmp ax, y1
    je .end
    add bx, d_x ; error = error + dx
    mov ax, y0
    add ax, s_y ; y0 = y0 + sy
    mov y0, ax
    jmp .draw

.end:
    mov sp, bp
    pop bp

    ret
