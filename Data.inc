; --------------------------------------------------------------
; DATA
; --------------------------------------------------------------
; Initial values for the 11 vdp registers.

RegisterInitValues:
           .db %00100110   ; reg. 0, display and interrupt mode.
                           ; bit 4 = line interrupt (disabled).
                           ; 5 = blank left column (enabled).
                           ; 6 = hori. scroll inhibit (disabled).
                           ; 7 = vert. scroll inhibit (disabled).

           .db %10100000   ; reg. 1, display and interrupt mode.
                           ; bit 0 = zoomed sprites (disabled).
                           ; 1 = 8 x 16 sprites (disabled).
                           ; 5 = frame interrupt (enabled).
                           ; 6 = display (blanked).

           .db $ff         ; reg. 2, name table address.
                           ; $ff = name table at $3800.

           .db $ff         ; reg. 3, n.a.
                           ; always set it to $ff.

           .db $ff         ; reg. 4, n.a.
                           ; always set it to $ff.

           .db $ff         ; reg. 5, sprite attribute table.
                           ; $ff = sprite attrib. table at $3F00.

           .db $ff         ; reg. 6, sprite tile address.
                           ; $ff = sprite tiles in bank 2.

           .db %11110011   ; reg. 7, border color.
                           ; set to color 3 in bank 2.

           .db $00         ; reg. 8, horizontal scroll value = 0.

           .db $00         ; reg. 9, vertical scroll value = 0.

           .db $ff         ; reg. 10, raster line interrupt.
                           ; turn off line int. requests.

; Graphics for the playfield.

PlayfieldPalette .include "Playfield_Palette.inc"
PlayfieldTiles .include "Playfield_Tiles.inc"
PlayfieldTilemap .include "Playfield_Tilemap.inc"
ScoreTiles .include "DigitTiles.inc"

SpritePalette .include "Sprites_Palette.inc"
BallTile .include "Balltile.inc"
PaddleTiles .include "PaddleTiles.inc"

PaddleSATInitializationData:
           .db 11 01 11 02 11 03
           .db 244 01 244 02 244 03

NameTableInitializationData:
           .db 16 00 17 00 01 00 02 00 01 00 16 00 17 00
           .db 18 00 19 00 01 00 02 00 01 00 18 00 19 00
           .db 20 00 21 00 01 00 02 00 01 00 20 00 21 00

; Pre-match menu, different variations of Nya and Ken.
; Menu0: Clear the menu by writing 10 bottom rows of playfield.
Menu0_Tilemap:
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0002 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001
           .dw $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000 $0000
           .dw $0000 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001 $0001

Menu1_Tiles .include "Menu1_Tiles.inc"
Menu1_Tilemap .include "Menu1_Tilemap.inc"

