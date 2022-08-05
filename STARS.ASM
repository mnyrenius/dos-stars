format MZ

entry main:start
stack 100h

segment main

vga_width   equ 320
vga_height  equ 200
num_stars   equ 75
speed       equ 1
star_color  equ 11

start:
    mov ax, text
    mov ds, ax

    ; init vga mode 13h
    mov ax, 13h
    int 10h
    mov ax, 0a000h
    mov es, ax
    
    ; init prng
    mov ah, 0h
    int 1ah
    mov [rnd], dx

    ; init stars in random xyz positions
    mov cx, num_stars
    mov di, stars

init_star_loop:
    call init_star
    add di, 6
    loop init_star_loop

    call music_init

main_loop:

    ; wait for retrace
wait_retrace:
    mov dx, 3dah
    in al, dx
    test al, 08
    jnz wait_retrace
end_retrace:
    in al, dx
    test al, 08
    jz end_retrace

wait_retrace2:
    mov dx, 3dah
    in al, dx
    test al, 08
    jnz wait_retrace2
end_retrace2:
    in al, dx
    test al, 08
    jz end_retrace2


    ; clear screen
    xor di, di
    mov ax, 0
    mov cx, vga_width * vga_height / 2
    rep stosw

    ; update and render stars
    mov cx, num_stars
    mov bx, stars
render_star_loop:
    sub word [bx+4], speed
    cmp word [bx+4], 0
    jne @f
    mov di, bx
    push bx
    call init_star
    pop bx
@@:
    mov ax, [bx+4]
    mov [star_render+4], ax
    mov [star_render+6], cx
    ; project x
    mov ax, [bx]
    cwd
    idiv word [bx+4]
    add ax, 160
    mov [star_render], ax

    ; project y
    mov ax, [bx+2]
    cwd
    idiv word [bx+4]
    add ax, 100
    mov [star_render+2], ax

    cmp word [star_render], vga_width
    jg skip_star
    cmp word [star_render], 0
    jl skip_star
    cmp word [star_render+2], vga_height
    jg skip_star
    cmp word [star_render+2], 0
    jl skip_star

    ; draw pixel
    mov ax, [star_render+2]
    imul ax, vga_width
    add ax, [star_render]
    mov di, ax
    mov al, star_color
    stosb

    jmp render_end
skip_star:
    push bx
    mov di, bx
    call init_star
    pop bx
render_end:
    add bx, 6
    loop render_star_loop

    call music_update

    mov ah, 1h
    int 16h
    jz main_loop

    ; exit vga mode 13h
    mov ax, 3h
    int 10h


    mov ah, 4ch
    int 21h

init_star:
    ; x
    call get_random
    mov bx, vga_width
    xor dx, dx
    div bx
    sub dx, vga_width/2
    shl dx, 4
    mov [di+0], dx

    ; y
    call get_random
    mov bx, vga_height
    xor dx, dx
    div bx
    sub dx, vga_height/2
    shl dx, 4
    mov [di+2], dx

    ; z
    call get_random
    mov bx, 75
    xor dx, dx
    div bx
    add dx, 1
    mov word [di+4], dx

    ret

get_random:
    mov ax, 25173
    mul word [rnd]
    add ax, 13849
    mov [rnd], ax
    ret

; al: reg
; ah: data
adlib_write:
    pusha

    mov dx, 388h
    out dx, al
    mov cx, 6
@@:
    in al, dx
    loop @b
    shr ax, 8
    mov dx, 389h
    out dx, al
    mov cx, 35
@@:
    in al, dx
    loop @b

    popa
    ret

struc music_note note, octave, length {
    .note dw note
    .octave db octave
    .length db length
}

macro music_note note, octave, length {
    local lbl
    lbl music_note note, octave, length
}

struc music_track curr_rem, curr_note, notes, notes_len, areg, breg {
    .curr_rem db curr_rem
    .curr_note db curr_note
    .notes dw notes
    .notes_len db notes_len
    .areg db areg
    .breg db breg
}
NOTE_C  equ 342
NOTE_CS equ 363
NOTE_D  equ 385
NOTE_DS equ 408
NOTE_E  equ 432
NOTE_F  equ 458
NOTE_FS equ 485
NOTE_G  equ 514
NOTE_GS equ 544
NOTE_A  equ 577
NOTE_AS equ 611
NOTE_B  equ 647

music_init:
    mov cx, adlib_ch1_settings_size
    mov bx, adlib_ch1_settings
@@:
    mov ax, [bx]
    call adlib_write
    add bx, 2
    loop @b

    mov cx, adlib_ch2_settings_size
    mov bx, adlib_ch2_settings
@@:
    mov ax, [bx]
    call adlib_write
    add bx, 2
    loop @b

    mov cx, adlib_ch3_settings_size
    mov bx, adlib_ch3_settings
@@:
    mov ax, [bx]
    call adlib_write
    add bx, 2
    loop @b

    mov cx, adlib_ch4_settings_size
    mov bx, adlib_ch4_settings
@@:
    mov ax, [bx]
    call adlib_write
    add bx, 2
    loop @b

    mov al, 0xbd
    mov ah, 0x28 ; enable percussion mode
    call adlib_write

    and ah, 0xd7
    call adlib_write

music_update:
    mov cx, music_tracks_len
    mov si, music_tracks
    .update_track:
        mov bx, [si]
        call music_update_track
        add si, 2
        loop .update_track
     ret

; bx: track
music_update_track:
    pusha
    dec byte [bx] ; current_remaining
    cmp byte [bx], 0
    jg .end
    mov ah, [bx+1] ; current_note_index
    inc ah
    movzx ax, ah
    div byte [bx+4] ; track note len
    mov [bx+1], ah ; updated current_note_index
    shr ax, 8
    mov ah, 4
    imul ah ; note size
    movzx ax, al
    xor dx,dx
    mov si, [bx+2] ; track notes
    add si, ax
    mov ah, [si+3]
    mov [bx], ah ; current_remaining = note len
    mov al, [bx+5]
    mov ah, [si]
    call adlib_write
    mov al, [bx+6]
    mov ah, [si+2]
    shl ah, 2
    or ah, [si+1]
    or ah, 0x20
    call adlib_write
    and ah, 0xdf
    call adlib_write

.end:
    popa
    ret


segment text

rnd   rw 1
star_render rw 4
stars rw 3 * num_stars

adlib_ch1_settings dw 0x0220, \ ; modulator multiple = 2
                      0x1040, \ ; modulator level
                      0xf060, \ ; modulator attack
                      0x7380, \ ; modulator sustain/release
                      0x0123, \ ; carrier multiple
                      0x0043, \ ; carrier level
                      0xf063, \ ; carrier attack
                      0x7383    ; carrier sustain/release
adlib_ch1_settings_size = ($-adlib_ch1_settings)/2

adlib_ch2_settings dw 0x0121, \ ; modulator multiple = 2
                      0x1041, \ ; modulator level
                      0xf061, \ ; modulator attack
                      0x7381, \ ; modulator sustain/release
                      0x4124, \ ; carrier multiple
                      0x0044, \ ; carrier level
                      0xf064, \ ; carrier attack
                      0x7484    ; carrier sustain/release
adlib_ch2_settings_size = ($-adlib_ch2_settings)/2

; bass drum
adlib_ch3_settings dw 0x0130, \ ; modulator multiple = 2
                      0x1050, \ ; modulator level
                      0xf070, \ ; modulator attack
                      0x7390, \ ; modulator sustain/release
                      0x4133, \ ; carrier multiple
                      0x0053, \ ; carrier level
                      0xf073, \ ; carrier attack
                      0x7f93, \ ; carrier sustain/release
                      0x98a6, \ ;
                      0x11b6    ;
adlib_ch3_settings_size = ($-adlib_ch3_settings)/2

; snare
adlib_ch4_settings dw 0x0134, \ ; modulator multiple = 2
                      0x1054, \ ; modulator level
                      0xf074, \ ; modulator attack
                      0x7394    ; modulator sustain/release
adlib_ch4_settings_size = ($-adlib_ch4_settings)/2


music_tracks dw track1, track2
music_tracks_len = ($-music_tracks)/2
track1 music_track 0xff, 0xff, track1_notes, track1_notes_len, 0xa0, 0xb0
track2 music_track 0xff, 0xff, track2_notes, track2_notes_len, 0xa1, 0xb1

track1_notes music_note NOTE_A, 1, 64
             music_note NOTE_E, 2, 64
             music_note NOTE_C, 2, 64
             music_note NOTE_A, 1, 64

             music_note NOTE_A, 1, 64
             music_note NOTE_C, 3, 64
             music_note NOTE_A, 2, 64
             music_note NOTE_A, 2, 64
track1_notes_len = ($-track1_notes)/4

track2_notes music_note NOTE_E, 4, 32
             music_note NOTE_F, 4, 8
             music_note NOTE_E, 4, 8
             music_note NOTE_F, 4, 8
             music_note NOTE_E, 4, 8
             music_note NOTE_G, 4, 32
             music_note NOTE_D, 4, 8
             music_note NOTE_C, 4, 8
             music_note NOTE_D, 4, 8
             music_note NOTE_C, 4, 8
             music_note NOTE_E, 4, 128

track2_notes_len = ($-track2_notes)/4


