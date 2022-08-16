; Constants
; ----------------------------------------

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

; Data structures
; ----------------------------------------
;
; Adlib_Note:
Note_note                   equ 0
Note_octave                 equ 2
Note_length                 equ 3

; Adlib_Pattern:
Pattern_CurrentRemaining    equ 0
Pattern_CurrentNote         equ 1
Pattern_Notes               equ 3
Pattern_NotesLen            equ 5
Pattern_Next                equ 6

; Adlib_Track:
Track_CurrentPattern        equ 0
Track_Areg                  equ 2
Track_Breg                  equ 3

; Adlib_Song:
Song_Settings               equ 0
Song_SettingsLen            equ 2
Song_MelodyTracks           equ 3
Song_MelodyTracksLen        equ 5
Song_DrumPattern            equ 6
Song_AdlibCounter           equ 8
Song_DrumCounter            equ 10
                                   
; Functions  
; ----------------------------------------

; ----------------------------------------
; in:   al - register
;       ah - value
; out:  none
; ----------------------------------------
Adlib_Write:
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

; ----------------------------------------
; in:   bx - Pointer to Adlib_Song
; out:  none
; ----------------------------------------
Adlib_Init:
    ; init counters
    mov word [bx+Song_AdlibCounter], 0xffff
    mov byte [bx+Song_DrumCounter], 0

    movzx cx, byte [bx+Song_SettingsLen]
    mov si, [bx+Song_Settings]
.init_channel:
    mov bx, [si]
@@:
    mov ax, [bx]
    call Adlib_Write
    add bx, 2
    cmp word [bx], 0xffff
    jne @b
    add si, 2
    loop .init_channel

    ret

; ----------------------------------------
; in:   bx - Pointer to Adlib_Song
; out:  none
; ----------------------------------------
Adlib_Update:
    push bx
    inc word [bx+Song_AdlibCounter]
    movzx cx, byte [bx+Song_MelodyTracksLen]
    mov si, [bx+Song_MelodyTracks]
.update_track:
    mov bx, [si]
    call Adlib_UpdateTrack
    add si, 2
    loop .update_track

    pop bx
    push bx
    mov ax, [bx+Song_AdlibCounter]
    mov bx, 8
    xor dx, dx
    div bx
    test dx, dx
    pop bx ; restore function parameter
    jnz @f
    call Adlib_UpdateDrums
@@:
    ret

; ----------------------------------------
; in:   bx - Pointer to Adlib_Track
; out:  none
; ----------------------------------------
Adlib_UpdateTrack:
    push bp
    mov bp, sp
    sub sp, 4

    pusha

    ; local variables
    Areg    equ [bp-2]
    Breg    equ [bp-3]
    Track   equ [bp-5]

    mov al, [bx+Track_Areg]
    mov Areg, al
    mov al, [bx+Track_Breg]
    mov Breg, al
    mov Track, bx

    mov bx, [bx+Track_CurrentPattern]
    cmp bx, 0
    jz .end ; invalid pattern

    dec byte [bx+Pattern_CurrentRemaining]
    cmp byte [bx+Pattern_CurrentRemaining], 0
    jg .end
    mov ax, [bx+Pattern_CurrentNote]             ; time for next note
    inc ax
    movzx cx, byte [bx+Pattern_NotesLen]
    cmp ax, cx                                   ; end of pattern? 
    jb @f
    mov dx, [bx+Pattern_Next]                    ; set current pattern to next
    mov bx, Track
    mov [bx+Track_CurrentPattern], dx
    mov ax, 0
    mov bx, [bx+Track_CurrentPattern]
@@:
    mov [bx+Pattern_CurrentNote], ax
    shl ax, 2                                    ; multiply by note size (4)
    mov si, [bx+Pattern_Notes]                   ; track notes
    add si, ax
    mov ah, [si+Note_length]
    mov [bx+Pattern_CurrentRemaining], ah        ; current_remaining = note len

    ; write freq lsb
    mov al, Areg
    mov ah, [si+Note_note]
    call Adlib_Write

    ; write octave, freq msb and note on
    mov al, Breg
    mov ah, [si+Note_octave]
    shl ah, 2
    or ah, [si+Note_note+1]                      ; note msb
    call Adlib_Write                             ; first set note off
    or ah, 0x20                                  ; then note on
    call Adlib_Write

.end:
    popa
    mov sp, bp
    pop bp
    ret

; ----------------------------------------
; in:   bx - Pointer to Adlib_Song
; out:  none
; ----------------------------------------
Adlib_UpdateDrums:
    mov si, [bx+Song_DrumPattern]
    test si, si
    jz .end                                      ; no active drum pattern
    movzx cx, byte [bx+Song_DrumCounter]
    mov dh, [si]                                 ; pattern length
    add si, cx ; + counter
    add si, 1                                    ; skip first byte = pattern length
    mov dl, [si]

    mov al, 0xbd
    mov ah, 0x60                                 ; enable percussion mode
    or ah, dl                                    ; Set drum bits according to drum track
    call Adlib_Write

    ; inc drum counter
    movzx ax, [bx+Song_DrumCounter]
    inc ax
    div dh
    mov [bx+Song_DrumCounter], ah
.end:

    ret
