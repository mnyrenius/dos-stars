Music_Instruments dw \
    Music_InstrumentMelody, \
    Music_InstrumentChords, \
    Music_InstrumentBassDrum, \
    Music_InstrumentSnareDrum, \
    Music_InstrumentHihat, \
    Music_InstrumentTomtom, \
    Music_InstrumentCymbal

Music_InstrumentsLen = ($-Music_Instruments)/2

Music_InstrumentMelody dw \
    0x4220, \ ; modulator multiple = 2
    0x1040, \ ; modulator level
    0xf060, \ ; modulator attack
    0x0880, \ ; modulator sustain/release
    0x0123, \ ; carrier multiple
    0x0043, \ ; carrier level
    0xf063, \ ; carrier attack
    0x0383, \ ; carrier sustain/release
    0xffff

Music_InstrumentChords dw \
    0x0121, \ ; modulator multiple = 2
    0x1041, \ ; modulator level
    0xf061, \ ; modulator attack
    0x0381, \ ; modulator sustain/release
    0x4124, \ ; carrier multiple
    0x0044, \ ; carrier level
    0xf064, \ ; carrier attack
    0x0484, \ ; carrier sustain/release
    0xffff

Music_InstrumentBassDrum dw \
    0x0130, \ ; modulator multiple = 2
    0x1050, \ ; modulator level
    0xf070, \ ; modulator attack
    0x0390, \ ; modulator sustain/release
    0x0233, \ ; carrier multiple
    0x0053, \ ; carrier level
    0xf073, \ ; carrier attack
    0x0993, \ ; carrier sustain/release
    0x98a6, \ ; freq lsb
    0x01b6, \ ; freq msb + octave
    0xffff

Music_InstrumentSnareDrum dw \
    0x0234, \ ; modulator multiple = 2
    0x1054, \ ; modulator level
    0xf074, \ ; modulator attack
    0x0794, \ ; modulator sustain/release
    0x98a7, \ ; freq lsb
    0x07b7, \ ; freq msb + octave
    0xffff

Music_InstrumentHihat dw \
    0x0231, \ ; modulator multiple = 2
    0x1051, \ ; modulator level
    0xf071, \ ; modulator attack
    0x0991, \ ; modulator sustain/release
    0xffff

Music_InstrumentCymbal dw \
    0x0235, \ ; modulator multiple = 2
    0x1055, \ ; modulator level
    0xf075, \ ; modulator attack
    0x0595, \ ; modulator sustain/release
    0xffff

Music_InstrumentTomtom dw \
    0x0232, \ ; modulator multiple = 2
    0x1052, \ ; modulator level
    0xf072, \ ; modulator attack
    0x0392, \ ; modulator sustain/release
    0x56a8, \ ; freq lsb
    0x0ab8, \ ; freq msb + octave
    0xffff

Music_Tracks dw Music_Track1, Music_Track2
Music_TracksLen = ($-Music_Tracks)/2

Music_Track1Pattern1:
    db 0xff
    dw 0xffff
    dw Music_Track1Pattern1Notes
    db Music_Track1Pattern1NotesLen
    dw Music_Track1Pattern1

Music_Track1Pattern2:
    db 0xff
    dw 0xffff
    dw Music_Track1Pattern2Notes
    db Music_Track1Pattern2NotesLen
    dw Music_Track1Pattern2

Music_Track1:
    dw 0
    db 0xa0
    db 0xb0

Music_Track2Pattern1:
    db 0xff
    dw 0xffff
    dw Music_Track2Pattern1Notes
    db Music_Track2Pattern1NotesLen
    dw Music_Track2Pattern1

Music_Track2:
    dw Music_Track2Pattern1
    db 0xa1
    db 0xb1

Music_Track1Pattern1Notes:
    dw NOTE_C
    db 4
    db 80
    dw NOTE_D
    db 4
    db 16
    dw NOTE_E
    db 4
    db 16
    dw NOTE_F
    db 4
    db 16

    dw NOTE_E
    db 4
    db 80
    dw NOTE_A
    db 4
    db 16
    dw NOTE_G
    db 4
    db 16
    dw NOTE_F
    db 4
    db 16

    dw NOTE_D
    db 4
    db 80
    dw NOTE_C
    db 4
    db 16
    dw NOTE_G
    db 4
    db 16
    dw NOTE_B
    db 4
    db 16

    dw NOTE_A
    db 4
    db 80
    dw NOTE_G
    db 4
    db 16
    dw NOTE_F
    db 4
    db 16
    dw NOTE_C
    db 4
    db 16
Music_Track1Pattern1NotesLen = ($-Music_Track1Pattern1Notes)/4

Music_Track1Pattern2Notes:
    dw NOTE_C
    db 4
    db 64
    dw NOTE_G
    db 4
    db 64

    dw NOTE_A
    db 4
    db 64
    dw NOTE_E
    db 4
    db 16
        dw NOTE_C
        db 4
        db 16
        dw NOTE_E
        db 4
        db 16
        dw NOTE_G
        db 4
        db 16
        
    dw NOTE_D
    db 4
    db 64
    dw NOTE_B
    db 3
    db 64

    dw NOTE_D
    db 4
    db 64
    dw NOTE_C
    db 4
    db 64

Music_Track1Pattern2NotesLen = ($-Music_Track1Pattern2Notes)/4
macro arp_note note1, oct1, note2, oct2, note3, oct3, len {
    dw note1
    db oct1
    db 2
    dw note2
    db oct2
    db 2
    dw note3
    db oct3
    db 2
    dw note1
    db oct1
    db len-6
}
Music_Track2Pattern1Notes:
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16

    arp_note NOTE_E, 4, NOTE_A, 4, NOTE_B, 4, 16
    arp_note NOTE_E, 5, NOTE_A, 5, NOTE_B, 5, 16
    arp_note NOTE_E, 4, NOTE_A, 4, NOTE_B, 4, 16
    arp_note NOTE_E, 5, NOTE_A, 5, NOTE_B, 5, 16
    arp_note NOTE_E, 4, NOTE_A, 4, NOTE_B, 4, 16
    arp_note NOTE_E, 5, NOTE_A, 5, NOTE_B, 5, 16
    arp_note NOTE_E, 4, NOTE_A, 4, NOTE_B, 4, 16
    arp_note NOTE_E, 5, NOTE_A, 5, NOTE_B, 5, 16

    arp_note NOTE_B, 3, NOTE_D, 4, NOTE_G, 4, 16
    arp_note NOTE_B, 4, NOTE_D, 5, NOTE_G, 5, 16
    arp_note NOTE_B, 3, NOTE_D, 4, NOTE_G, 4, 16
    arp_note NOTE_B, 4, NOTE_D, 5, NOTE_G, 5, 16
    arp_note NOTE_B, 3, NOTE_D, 4, NOTE_G, 4, 16
    arp_note NOTE_B, 4, NOTE_D, 5, NOTE_G, 5, 16
    arp_note NOTE_B, 3, NOTE_D, 4, NOTE_G, 4, 16
    arp_note NOTE_B, 4, NOTE_D, 5, NOTE_G, 5, 16

    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16
    arp_note NOTE_C, 4, NOTE_E, 4, NOTE_G, 4, 16
    arp_note NOTE_C, 5, NOTE_E, 5, NOTE_G, 5, 16

Music_Track2Pattern1NotesLen = ($-Music_Track2Pattern1Notes)/4

Music_Drums1:
    db 16
    db 00010000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00011000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00010000b
    db 00000000b
    db 00000000b
    db 00000000b

    db 00011000b
    db 00000000b
    db 00000000b
    db 00000000b

Music_Drums2:
    db 4
    db 00000001b
    db 00000000b
    db 00000000b
    db 00000000b

Music_Drums dw Music_Drums2
Music_DrumsLen = ($-Music_Drums)/2

Music_Song:
    dw Music_Instruments
    db Music_InstrumentsLen
    dw Music_Tracks
    db Music_TracksLen
    dw 0
    rb 4
