; Setup the SDSC tag, including correct chekcsum:
           .sdsctag 0.1, "aaa", "aaa", "Anders S. Jensen"

; Organize RAM and ROM maps, including banking:
           .memorymap
           defaultslot 0
           slotsize $4000
           slot 0 $0000
           slot 1 $4000
           slot 2 $8000
           slotsize $2000
           slot 3 $c000
           .endme

           .rombankmap
           bankstotal 2
           banksize $4000
           banks 2
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

           ld hl,$0000
           call PrepareVRAM
           ld hl,PlayfieldTiles
           ld bc,3*32
           call LoadVRAM

           ld hl,$0200
           call PrepareVRAM
           ld hl,ScoreTiles
           ld bc,60*32
           call LoadVRAM

           ld hl,$3800
           call PrepareVRAM
           ld hl,PlayfieldTilemap
           ld bc,32*24*2
           call LoadVRAM

           ld hl,$c000
           call PrepareVRAM
           ld hl,PlayfieldPalette
           ld bc,14
           call LoadVRAM

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
           ld a,1
           ld (Hub_GameState),a
           jp EndGameStateSwitch

GameState_1:

           jp EndGameStateSwitch

GameState_2:

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

           .include "MinorRoutines.inc"
           .include "Data.inc"
