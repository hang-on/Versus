; Setup the SDSC tag, including correct chekcsum:
           .sdsctag 0.1, "Versus", ReleaseNotes, "Anders S. Jensen"

; Organize read only memory:
           ; Three rom slots a' 16K. Assume standard Sega mapper
           ; with bankswitching in slot 2.
           .memorymap
           defaultslot 0
           slotsize $4000
           slot 0 $0000
           slot 1 $4000
           slot 2 $8000
           .endme

           ; Make a 128K rom
           .rombankmap
           bankstotal 8
           banksize $4000
           banks 8
           .endro

; Organize variables:
           ; Variables are reset to 0 as part of the general
           ; memory initialization.
           .enum $c000 export
           FrameInterruptFlag db

           Hub_VDPStatus db
           Hub_GameState db
           Hub_FrameCounter db
           Hub_Suspend db

           Loader_Program db
           .ende

; Beginning of ROM:
.bank 0 slot 0
.org 0
           di
           im 1
           ld sp,$dff0
           jp InitializeFramework

.orga $0038
; Frame interrupt handler:
           ex af,af'
           exx
           in a,$bf
           ld (Hub_VDPStatus),a
           ld a,1
           ld (FrameInterruptFlag),a
           call Loader
           exx
           ex af,af'
           ei
           ret

.orga $0066
; Pause interrupt handler:
           retn

.section "Minor routines and helper functions" free
           .include "MinorRoutines.inc"
.ends

.section "Memory initialization" free
InitializeFramework:
           ; Overwrite 4K of RAM with zeroes.
           ld hl,$c000
           ld bc,$1000
           ld a,0
           call FillMemory

           ; Use the initialized ram to clean all of vram.
           ld hl,$0000
           call PrepareVRAM
           ld b,4
-          push bc
           ld hl,$c000
           ld bc,$1000
           call LoadVRAM
           pop bc
           djnz -

           ; Initialize the VDP registers:
           ld hl,RegisterInitValues
           ld b,11
           ld c,$80
-          ld a,(hl)
           out ($bf),a
           ld a,c
           out ($bf),a
           inc hl
           inc c
           djnz -

           ei
           jp MainLoop
.ends

.section "Main Loop" free
; Main program loop. Processed on a frame-by-frame basis.
MainLoop:  call WaitForFrameInterrupt
           call Hub
           jp MainLoop
_Program0:
.ends

.section "Loader" free
; VRAM loader routine. Called by the frame interrupt handler.
Loader:
           ; Turn screen on - big job vram loader programs turn
           ; the screen off to avoid graphic glitches.
           ld a,%11100000
           ld b,1
           call SetRegister

           ; Switch according to program selector setting.
           ld a,(Loader_Program)
           ld de,ProgramVectors
           call GetVector
           jp (hl)

; Loader is OFF. Return from loader routine now.
_Program0:
           ld a,(Loader_Program)
           or a
           ret z

; Normal (for in-game graphics processing).
_Program1:

           jp EndProgramSwitch

; Load match assets. This is a big job!
_Program2:
           ; Turn screen off.
           ld a,%10100000
           ld b,1
           call SetRegister

           ; Load the playfield tiles @ 0
           ld hl,$0000
           call PrepareVRAM
           ld hl,PlayfieldTiles
           ld bc,3*32
           call LoadVRAM

           ; Load the score tiles @ index 16.
           ld hl,$0200
           call PrepareVRAM
           ld hl,ScoreTiles
           ld bc,60*32
           call LoadVRAM

           ; Load playfield tilemap into name table.
           ld hl,$3800
           call PrepareVRAM
           ld hl,PlayfieldTilemap
           ld bc,32*24*2
           call LoadVRAM

           ; Load playfield/background colors into bank 1.
           ld hl,$c000
           call PrepareVRAM
           ld hl,PlayfieldPalette
           ld bc,14
           call LoadVRAM

           ; Load sprite colors into bank 2.
           ld hl,$c010
           call PrepareVRAM
           ld hl,SpritePalette
           ld bc,4
           call LoadVRAM

           ; Load the ball tiles @ index 256.
           ld hl,$2000
           call PrepareVRAM
           ld hl,BallTile
           ld bc,32
           call LoadVRAM

           ; Load the paddle tiles @ index 257.
           ld hl,$2020
           call PrepareVRAM
           ld hl,PaddleTiles
           ld bc,3 * 32
           call LoadVRAM
           
           ; Set the border color.
           ld a,%11110000
           ld b,7
           call SetRegister

           ; When the assets are processed, Loader switches
           ; itself into program 1 (Normal).
           ld a,1
           ld (Loader_Program),a
           jp EndProgramSwitch

_Program3:

           jp EndProgramSwitch

EndProgramSwitch:
           ret

ProgramVectors:
           .dw _Program0 _Program1 _Program2 _Program3
.ends

.section "Hub" free
; The Hub is the program's central routine.
Hub:
           ; Reset the suspend switch.
           xor a
           ld (Hub_Suspend),a

           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,GameStateVectors
           call GetVector
           jp (hl)

GameState_0:
           ; Gamestate 0 - this is the very first frame!
           ; Select "Load match assets" program on the loader.
           ld a,2
           ld (Loader_Program),a

           ; Change game state to 1 (object initialization).
           ; The game objects will never experience GameState 0.
           ld a,1
           ld (Hub_GameState),a
           jp EndGameStateSwitch

GameState_1:
           ; We have just had the initialization cycle.
           ; Now change game state to match mode.
           ld a,2
           ld (Hub_GameState),a
           jp EndGameStateSwitch

GameState_2:
           ; Match mode.
           jp EndGameStateSwitch

GameState_3:

           jp EndGameStateSwitch

GameState_4:

           jp EndGameStateSwitch

EndGameStateSwitch:

           ; Increment frame counter.
           ld hl,Hub_FrameCounter
           inc (hl)

           ret

GameStateVectors:
           .dw GameState_0 GameState_1 GameState_2 GameState_3 GameState_4
.ends

.bank 1 slot 1
.section "Bank 1: Misc" free
ReleaseNotes:
.db "Pong. The world can never be saturated with clones of this"
.db " retro-gaming classic. May I present: Nya -versus- Ken!" 0


.ends

.bank 2 slot 2
.section "Bank 2: Data" free
           .include "Data.inc"
.ends