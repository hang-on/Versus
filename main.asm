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

           ; Make a 64K rom
           .rombankmap
           bankstotal 4
           banksize $4000
           banks 4
           .endro

; Organize variables:
           ; Variables are reset to 0 as part of the general
           ; memory initialization.
           .enum $c000 export
           SATBuffer dsb 16 + 32
           FrameInterruptFlag db

           Ball_X db
           Ball_Y db
           Ball_HorizontalSpeed db
           Ball_VerticalSpeed db
           Ball_HorizontalDirection db
           Ball_VerticalDirection db

           Hub_VDPStatus db
           Hub_GameState db
           Hub_LoopCounter db

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
           in a,$bf
           ld (Hub_VDPStatus),a
           ld a,1
           ld (FrameInterruptFlag),a
           ex af,af'
           ei
           ret

.orga $0066
; Pause interrupt handler:
           retn

.section "Minor routines and helper functions" free
           .include "MinorRoutines.inc"
.ends

; --------------------------------------------------------------
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

; --------------------------------------------------------------
.section "Main Loop" free
MainLoop:
           call WaitForFrameInterrupt
           call Loader
           call Ball
           call Hub
           jp MainLoop
.ends

; --------------------------------------------------------------
.section "Loader" free
Loader:
           ; Switch according to game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; Load assets for a match:
_0:        ; Update vdp register.
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

           ; Place the sprite terminator in sat.
           ld hl,$3f00+15
           call PrepareVRAM
           ld a,$d0
           ld c,$be
           out (c),a

           ; Set the border color.
           ld a,%11110000
           ld b,7
           call SetRegister
           jp _EndSwitch

; Match: Just keep the display enabled, update the sprite table
; and the score digits in the name table.
_1:        ld a,%11100000
           ld b,1
           call SetRegister

           ; Load buffer contents to SAT in VRAM.
           ld hl,$3f00
           call PrepareVRAM
           ld hl,SATBuffer
           ld b,16
           ld c,$be
           otir
           ld hl,$3f80
           call PrepareVRAM
           ld hl,SATBuffer+16
           ld b,32
           ld c,$be
           otir
           jp _EndSwitch

_2:        ; Unused at the moment
           jp _EndSwitch

_EndSwitch:
           ret

           _SwitchVectors: .dw _0 _1 _2
.ends

; --------------------------------------------------------------
.section "Ball" free
Ball:
           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; Initialize/reset the ball:
_0:        call _ResetBall
           jp _EndSwitch

; Match is playing - update the ball!
; Movement, bouncing of borders and paddles, scoring.
_1:        jp _EndSwitch

_EndSwitch:
           ; Update ball data in the SAT buffer.
           ld a,(Ball_Y)
           ld (SATBuffer),a
           ld a,(Ball_X)
           ld (SATBuffer+16),a

; Return from ball routine.
           ret

_ResetBall:
           ld a,127
           ld (Ball_X),a
           ld a,92
           ld (Ball_Y),a
           ld a,2
           ld (Ball_HorizontalSpeed),a
           ld (Ball_VerticalSpeed),a
           xor a
           ld (Ball_VerticalDirection),a
           
           ld a,(Ball_HorizontalDirection)
           or a
           jp nz,+
           inc a
           ld (Ball_HorizontalDirection),a
           ret
+          dec a
           ld (Ball_HorizontalDirection),a
           ret

           _SwitchVectors: .dw _0 _1
.ends

; --------------------------------------------------------------
.section "Hub" free
Hub:
           ; Increment loop counter at every loop.
           ld hl,Hub_LoopCounter
           inc (hl)

           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; State 0: Initialization.
_0:        ; Change game state to match.
           ld a,1
           ld (Hub_GameState),a
           jp _EndSwitch

; State 1: Match
_1:        jp _EndSwitch

; Unused:
_2:        jp _EndSwitch

_EndSwitch:

           ret

           _SwitchVectors: .dw _0 _1 _2
.ends


; --------------------------------------------------------------
.bank 1 slot 1
.section "Bank 1: Misc" free
ReleaseNotes:
.db "Pong. The world can never be saturated with clones of this"
.db " retro-gaming classic. May I present: Nya -versus- Ken!" 0
.ends


; --------------------------------------------------------------
.bank 2 slot 2
.section "Bank 2: Data" free
           .include "Data.inc"
.ends