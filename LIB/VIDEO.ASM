VGA_WIDTH   equ 320
VGA_HEIGHT  equ 200

; ----------------------------------------
; in:   none
; out:  ax - segment number or error code
; ----------------------------------------
Video_init:
    ; allocate double buffer
    mov ah, 4ah
    mov bx, 1000h
    int 21h
    mov ah, 48h
    mov bx, 1000h
    int 21h
    jc .error
    push ax

    ; init vga mode 13h
    mov ax, 13h
    int 10h

.error:
    pop ax
    ret

; ----------------------------------------
; in:   ax - segment number
; out:  none
; ----------------------------------------
Video_deinit:
    ; exit vga mode 13h
    mov ax, 3h
    int 10h

    push es
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    ret

; ----------------------------------------
; in:   none
; out:  none
; ----------------------------------------
Video_vsync:
@@:
    mov dx, 3dah
    in al, dx
    test al, 08
    jnz @b
@@:
    in al, dx
    test al, 08
    jz @b

    ret

; ----------------------------------------
; in:   ax - segment number
; out:  none
; ----------------------------------------
Video_copy_buffer:
    push es
    push ds
    mov ds, ax
    mov bx, 0a000h
    mov es, bx
    mov cx, VGA_WIDTH * VGA_HEIGHT / 2
    xor si, si
    xor di, di
    rep movsw
    pop ds
    pop es
    
    ret
