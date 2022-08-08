format MZ

entry main:start
stack 100h

VGA_WIDTH   equ 320
VGA_HEIGHT  equ 200
NUM_STARS   equ 75
SPEED       equ 1
STAR_COLOR  equ 11

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

segment main

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
    mov cx, NUM_STARS
    mov di, stars

init_star_loop:
    call init_star
    add di, 6
    loop init_star_loop

    ; configure opl channels
    call music_init

main_loop:

    ; wait for retrace.. twice.. because..
    mov cx, 2
vsync:
@@:
    mov dx, 3dah
    in al, dx
    test al, 08
    jnz @b
@@:
    in al, dx
    test al, 08
    jz @b

    loop vsync

    ; clear screen
    xor di, di
    mov ax, 0
    mov cx, VGA_WIDTH * VGA_HEIGHT / 2
    rep stosw

    ; update z position and render stars
    mov cx, NUM_STARS
    mov bx, stars
render_star_loop:
    sub word [bx+4], SPEED

    ; re-init star in new position when z becomes 0
    cmp word [bx+4], 0
    jne @f
    mov di, bx
    push bx
    call init_star
    pop bx
@@:
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

    cmp word [star_render], VGA_WIDTH
    jg skip_star
    cmp word [star_render], 0
    jl skip_star
    cmp word [star_render+2], VGA_HEIGHT
    jg skip_star
    cmp word [star_render+2], 0
    jl skip_star

    ; draw pixel
    mov ax, [star_render+2]
    imul ax, VGA_WIDTH
    add ax, [star_render]
    mov di, ax
    mov al, STAR_COLOR
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
    mov bx, VGA_WIDTH
    xor dx, dx
    div bx
    sub dx, VGA_WIDTH/2
    shl dx, 4
    mov [di+0], dx

    ; y
    call get_random
    mov bx, VGA_HEIGHT
    xor dx, dx
    div bx
    sub dx, VGA_HEIGHT/2
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

music_init:

    mov cx, music_channel_settings_len
    mov si, music_channel_settings
    .init_channel:
        mov bx, [si]
        @@:
            mov ax, [bx]
            call adlib_write
            add bx, 2
            cmp word [bx], 0xffff
            jne @b
        add si, 2
        loop .init_channel

music_update:
    mov cx, music_tracks_len
    mov si, music_tracks
    .update_track:
        mov bx, [si]
        call music_update_track
        add si, 2
        loop .update_track

    call music_update_drums

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
    mov si, [bx+2] ; track notes
    add si, ax
    mov ah, [si+3]
    mov [bx], ah ; current_remaining = note len

    ; write freq lsb
    mov al, [bx+5]
    mov ah, [si]
    call adlib_write

    ; write octave, freq msb and note on
    mov al, [bx+6]
    mov ah, [si+2]
    shl ah, 2
    or ah, [si+1]
    call adlib_write ; first set note off
    or ah, 0x20 ; then note on
    call adlib_write

.end:
    popa
    ret

music_update_drums:
    mov al, 0xbd
    mov ah, 0x20 ; enable percussion mode
    call adlib_write

    ; snare

    dec [music_sd_counter]
    cmp [music_sd_counter], 0
    jg @f
    mov [music_sd_counter], 32
    or ah, 0x08 ; sd on
@@:
    ; bass

    dec [music_bd_counter]
    cmp [music_bd_counter], 0
    jg @f
    mov [music_bd_counter], 32
    or ah, 0x10 ; bd on
@@:
    call adlib_write

    ret

segment text

rnd   rw 1
star_render rw 4
stars rw 3 * NUM_STARS

music_channel_settings dw music_ch1_settings, \
                          music_ch2_settings, \
                          music_bd_settings,  \
                          music_sd_settings
music_channel_settings_len = ($-music_channel_settings)/2

music_ch1_settings dw 0x0220, \ ; modulator multiple = 2
                      0x1040, \ ; modulator level
                      0xf060, \ ; modulator attack
                      0x0380, \ ; modulator sustain/release
                      0x0123, \ ; carrier multiple
                      0x0043, \ ; carrier level
                      0xf063, \ ; carrier attack
                      0x0383, \ ; carrier sustain/release
                      0xffff

music_ch2_settings dw 0x0121, \ ; modulator multiple = 2
                      0x1041, \ ; modulator level
                      0xf061, \ ; modulator attack
                      0x0381, \ ; modulator sustain/release
                      0x4124, \ ; carrier multiple
                      0x0044, \ ; carrier level
                      0xf064, \ ; carrier attack
                      0x0484, \ ; carrier sustain/release
                      0xffff

music_bd_settings dw 0x0130, \ ; modulator multiple = 2
                     0x1050, \ ; modulator level
                     0xf070, \ ; modulator attack
                     0x0390, \ ; modulator sustain/release
                     0x0233, \ ; carrier multiple
                     0x0053, \ ; carrier level
                     0xf073, \ ; carrier attack
                     0x0a93, \ ; carrier sustain/release
                     0x98a6, \ ; freq lsb
                     0x01b6, \
                     0xffff

music_sd_settings dw 0x0234, \ ; modulator multiple = 2
                     0x1054, \ ; modulator level
                     0xf074, \ ; modulator attack
                     0x0994, \ ; modulator sustain/release
                     0xffff

music_tracks dw music_track1, music_track2
music_tracks_len = ($-music_tracks)/2
music_track1 music_track 0xff, 0xff, music_track1_notes, music_track1_notes_len, 0xa0, 0xb0
music_track2 music_track 0xff, 0xff, music_track2_notes, music_track2_notes_len, 0xa1, 0xb1

music_track1_notes music_note NOTE_A, 1, 64
                   music_note NOTE_E, 2, 64
                   music_note NOTE_C, 2, 64
                   music_note NOTE_A, 1, 64

                   music_note NOTE_A, 1, 64
                   music_note NOTE_C, 3, 64
                   music_note NOTE_A, 2, 64
                   music_note NOTE_A, 2, 64
music_track1_notes_len = ($-music_track1_notes)/4

music_track2_notes music_note NOTE_E, 4, 32
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

music_track2_notes_len = ($-music_track2_notes)/4

music_bd_counter dw 0
music_sd_counter dw 16
