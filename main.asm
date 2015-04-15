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
           slotsize $2000 ; RAM
           slot 3 $c000
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
           VDPStatus db
           Joystick1 db
           Joystick2 db

           Ball_X db
           Ball_Y db
           Ball_HorizontalSpeed db
           Ball_VerticalSpeed db
           Ball_HorizontalDirection db
           Ball_VerticalDirection db
           Ball_Timer db
           Ball_Turbo db
           Ball_TurboDuration db

           Paddle1_Y db
           Paddle2_Y db

           Menu_Item db

           Score_Player1 db
           Score_Player2 db

           Hub_GameState db
           Hub_LoopCounter db
           Hub_Status db

           NameTableBuffer dsb 3*7*2
           .ende

; Libray of minor routines:
           .include "MinorRoutines.inc"

; sverx's PSG library:
           .include "PSGlib.inc"

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
           ld (VDPStatus),a
           ld a,1
           ld (FrameInterruptFlag),a
           ex af,af'
           ei
           ret

.orga $0066
; Pause interrupt handler:
           retn


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

           ; Set the border color.
           ld a,%11110000
           ld b,7
           call SetRegister

           ; Start main loop in state 5: Prepare title screen.
           ld a,5
           ld (Hub_GameState),a

           call PSGInit

           ei
           jp MainLoop
.ends

; --------------------------------------------------------------
.section "Main Loop" free                                      ;
; --------------------------------------------------------------
MainLoop:                                                      ;
           call WaitForFrameInterrupt                          ;
           call Loader                                         ;
           call Ball                                           ;
           call Paddles                                        ;
           call Menu                                           ;
           call Score                                          ;
           call Hub                                            ;                                                               ;
           call PSGSFXFrame                                    ;
           call PSGFrame                                       ;
           jp MainLoop                                         ;
.ends                                                          ;
; --------------------------------------------------------------



; --------------------------------------------------------------
.section "Loader" free
; --------------------------------------------------------------
Loader:
           ; Switch according to game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; Load assets for a match:
_0:        ; Get rid of pre-match menu overlay...
           ; Update the name table.
           ld hl,$3b80
           call PrepareVRAM
           ld hl,Menu0_Tilemap
           ld bc,10*32*2
           call LoadVRAM

           jp _EndSwitch

; Match: Just keep the display enabled, update the sprite table
; and the score digits in the name table.
_1:        ld a,%11100000
           ld b,1
           call SetRegister

           ; Load sprites from the SAT buffer.
           call _LoadSprites

           ; Draw the two score digits on the playfield.
           ld hl,$38da
           call PrepareVRAM
           ld hl,NameTableBuffer
           ld bc,14
           call LoadVRAM
           ld hl,$391a
           call PrepareVRAM
           ld hl,NameTableBuffer+14
           ld bc,14
           call LoadVRAM
           ld hl,$395a
           call PrepareVRAM
           ld hl,NameTableBuffer+28
           ld bc,14
           call LoadVRAM

           jp _EndSwitch

; Run pre-match menu: Behave just like match.
_2:        jp _1

; Initialize pre-match
_3:        ; Should we load Menu0? (Nya and Ken are both ready).
           ld a,(Score_Player1)
           ld b,a
           ld a,(Score_Player2)
           or b
           jp nz,+
           ; OK - load Menu0.
           ld hl,$0a00
           call PrepareVRAM
           ld hl,Menu1_Tiles
           ld bc,91*32
           call LoadVRAM
           ld hl,$3b80
           call PrepareVRAM
           ld hl,Menu1_Tilemap
           ld bc,10*32*2
           call LoadVRAM
           jp _EndSwitch

+          ; Player 2 (Ken) won last match.
           ld a,(Score_Player2)
           cp 9
           jp nz,+
           ld hl,$0a00
           call PrepareVRAM
           ld hl,Menu2_Tiles
           ld bc,96*32
           call LoadVRAM
           ld hl,$3b80
           call PrepareVRAM
           ld hl,Menu2_Tilemap
           ld bc,10*32*2
           call LoadVRAM
           jp _EndSwitch

+          ; Player 1 (Nya) won last match.
           ld hl,$0a00
           call PrepareVRAM
           ld hl,Menu3_Tiles
           ld bc,99*32
           call LoadVRAM
           ld hl,$3b80
           call PrepareVRAM
           ld hl,Menu3_Tilemap
           ld bc,10*32*2
           call LoadVRAM
           jp _EndSwitch

; Initialize session.
_4:        ; Update vdp register.
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

           ; Load the paddle tiles @ index 257.
           ld hl,$2020
           call PrepareVRAM
           ld hl,PaddleTiles
           ld bc,3 * 32
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

           jp _EndSwitch

; Prepare title screen:
_5:        ; Disable display.
           ld a,%10100000
           ld b,1
           call SetRegister

           ; Load the title screen tiles @ 0
           ld hl,$0000
           call PrepareVRAM
           ld hl,Titlescreen_Tiles
           ld bc,87*32
           call LoadVRAM

           ; Load title screen tilemap into name table.
           ld hl,$3800
           call PrepareVRAM
           ld hl,Titlescreen_Tilemap
           ld bc,32*24*2
           call LoadVRAM

           ; Load title screen colors into bank 1.
           ld hl,$c000
           call PrepareVRAM
           ld hl,Titlescreen_Palette
           ld bc,16
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

           jp _EndSwitch

; Run title screen:
_6:        ; Enable display.
           ld a,%11100000
           ld b,1
           call SetRegister

           call _LoadSprites

           jp _EndSwitch

_EndSwitch:

; Return to main loop:
           ret

_LoadSprites:
           ; Load SAT buffer contents to VRAM.
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
           ret

           _SwitchVectors: .dw _0 _1 _2 _3 _4 _5 _6
.ends

; --------------------------------------------------------------
.section "Ball" free
; --------------------------------------------------------------
Ball:      ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; Initialize match:
_0:        jp _EndSwitch

; Match is playing - update the ball!
_1:        ; If Ball_Timer is > 0, then, decrement it and skip
           ; all ball movements.
           ld a,(Ball_Timer)
           cp 0
           jp z,+
           dec a
           ld (Ball_Timer),a
           jp _EndSwitch

+          ; Determine if the ball is in turbo mode.
           ld a,(Ball_Turbo)
           cp 0
           jp nz,+
           ld a,2
           ld (Ball_HorizontalSpeed),a
           ld (Ball_VerticalSpeed),a
           jp ++

+          ; Ball IS in turbo mode.
           ld a,3
           ld (Ball_HorizontalSpeed),a
           ld (Ball_VerticalSpeed),a
           ld hl,Ball_Turbo
           dec (hl)

++         ; Resolve current state of the ball.
           ; See if ball collides with the bottom border.
           ld a,(Ball_Y)
           cp 169
           jp c,+

           ; Bounce ball against bottom border.
           ld a,169
           ld (Ball_Y),a
           ld a,1
           ld (Ball_VerticalDirection),a
           ld hl,SFX_Wall
           ld c,SFX_CHANNEL2
           call PSGSFXPlay
           jp ++

+          ; See if ball collides with the top border.
           ld a,(Ball_Y)
           cp 15
           jp nc,++

           ; Bounce ball against top border.
           ld a,15
           ld (Ball_Y),a
           ld a,0
           ld (Ball_VerticalDirection),a
           ld hl,SFX_Wall
           ld c,SFX_CHANNEL2
           call PSGSFXPlay

++         ; Second: Move the ball.
           ; Determine if ball should move up or down.
           ld a,(Ball_VerticalDirection)
           or a
           jp z,+

           ; Move ball up:
           ld a,(Ball_Y)
           ld hl,Ball_VerticalSpeed
           sub (hl)
           ld (Ball_Y),a
           jp ++

           ; Move ball down:
+          ld a,(Ball_Y)
           ld hl,Ball_VerticalSpeed
           add a,(hl)
           ld (Ball_Y),a

++         ; Determine if ball should move right or left.
           ld a,(Ball_HorizontalDirection)
           cp 0
           jp z,+

           ; Move ball right.
           ld a,(Ball_X)
           ld hl,Ball_HorizontalSpeed
           add a,(hl)
           ld (Ball_X),a
           jp ++

           ; Move ball left.
+          ld a,(Ball_X)
           ld hl,Ball_HorizontalSpeed
           sub (hl)
           ld (Ball_X),a
++         ; end of move ball section.

           ; Is the ball in player 1's goal zone?
           ld a,(Ball_X)
           cp 3
           jp nc,+
           call _ResetBall
           ld c,SFX_CHANNELS2AND3
           ld hl,SFX_Serve
           call PSGSFXPlay

           ; Signal to the hub that player 2 is scoring.
           ld a,(Hub_Status)
           or %00000010
           ld (Hub_Status),a

           ; Is ball x in player 2's goal zone?
+          ld a,(Ball_X)
           cp 253
           jp c,+
           call _ResetBall
           ld c,SFX_CHANNELS2AND3
           ld hl,SFX_Serve
           call PSGSFXPlay

           ; Signal to the hub that player 1 is scoring.
           ld a,(Hub_Status)
           or %00000001
           ld (Hub_Status),a

+          ; end of goal zone testing section.

           ; Check collision with paddle 1.
           ld hl,Paddle1_Y
           ld b,17
           ld c,1
           call _DetectCollision

           ; Check collision on paddle 2.
           ld hl,Paddle2_Y
           ld b,238
           ld c,0
           call _DetectCollision

           call _UpdateBallSprite

           jp _EndSwitch

_2:        jp _EndSwitch

; Initialize pre-match:
_3:        call _ResetBall
           call _UpdateBallSprite
           jp _EndSwitch

; Initialize session.
_4:        jp _EndSwitch

_5:

_6:

_EndSwitch:


; Return to main loop.
           ret

_UpdateBallSprite:
           ; Update ball data in the SAT buffer.
           ld a,(Ball_Y)
           ld (SATBuffer),a
           ld a,(Ball_X)
           ld (SATBuffer+16),a
           ret

_ResetBall:
           ; Make ball pause will serve sfx plays...
           ld a,60
           ld (Ball_Timer),a

           xor a
           ld (Ball_TurboDuration),a

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


_DetectCollision:
           ; Detect collision between a paddle and the ball, and
           ; bounce the ball in the event of a collision.

           ; First test: Is the ball within the paddle's
           ; horizontal collision zone?
           ld a,(Ball_X)
           sub b
           ret c
           ld a,(Ball_X)
           inc b
           inc b
           sub b
           ret nc

           ; Second test: Is the ball over the paddle?
           ; Math: (ball y + paddle height) - paddle y < 0.
           ld a,(Ball_Y)
           ld b,8
           add a,b
           sub (hl)
           ret c

           ; Third test: Is the ball under the paddle?
           ; Math: (paddle y + paddle height) - ball y < 0.
           ld a,(Ball_Y)
           ld d,a
           ld a,(hl)
           ld b,26
           add a,b
           sub d
           ret c

           ; If we get here, it means collision is happening!
           ; See if max turbo duration is already achieved.
           ld a,(Ball_TurboDuration)
           cp 70
           jp z,+
           ; Not maxed - increase turbo duration.
           add a,5
           ld (Ball_TurboDuration),a
+          ; Renew ball turbo.
           ld b,a
           ld a,(Ball_Turbo)
           add a,b
           ld (Ball_Turbo),a

          ; First, change the direction of the ball (bounce).
           ld a,c
           ld (Ball_HorizontalDirection),a

           ; Second, calculate where the ball hits the paddle,
           ; and adjust the ball's vertical direction,
           ; Math: (paddle y + half paddle height) -
           ; (ball y + ball height) < 0.
           ld a,(Ball_Y)
           add a,6
           ld b,a
           ld a,(hl)
           add a,13
           sub b
           jp nc,+
           ld a,0
           ld (Ball_VerticalDirection),a
           ld hl,SFX_Paddle0
           ld c,SFX_CHANNEL2
           call PSGSFXPlay
           ret
+          ld a,1
           ld (Ball_VerticalDirection),a
           ld hl,SFX_Paddle1
           ld c,SFX_CHANNEL2
           call PSGSFXPlay
           ret

           _SwitchVectors: .dw _0 _1 _2 _3 _4 _5 _6
.ends

; --------------------------------------------------------------
.section "Paddles" free
; --------------------------------------------------------------
Paddles:
; We will handle both paddles in this section.
           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; Initialize the paddles:
_0:        jp _EndSwitch

; Match mode. Make paddles respond to player/AI input:
_1:        ; Move paddle 1 with player 1 joystick.
           ld hl,Paddle1_Y
           ld a,(Joystick1)
           call _MovePaddle

           ; Move paddle 2 with player 2 joystick.
           ld hl,Paddle2_Y
           ld a,(Joystick1)
           rla
           rla
           rla
           call _MovePaddle

           call _UpdatePaddleSprites

           jp _EndSwitch

; Run pre-match.
_2:        ; Paddles can move while the menu is displayed.
           jp _1

; Initialize pre-match menu.
_3:        jp _EndSwitch

; Initialize session.
_4:        ld hl, PaddleSATInitializationData
           ld de,SATBuffer+18
           ld bc,12
           ldir

           ld a,96
           ld (Paddle1_Y),a
           ld (Paddle2_Y),a

           jp _EndSwitch

_5:

_6:

_EndSwitch:

; Return to main loop:
           ret

_UpdatePaddleSprites:
           ; Generate paddle sprites in the buffer.
           ld a,(Paddle1_Y)
           ld hl,SATBuffer+1
           call _SetPaddleSprite
           ld a,(Paddle2_Y)
           ld hl,SATBuffer+4
           call _SetPaddleSprite
           ret

_MovePaddle:
           ; Move paddle vertically by responding to a joystick.
           ; HL = pointer to paddle y-coordinate.
           ; A = bits 0 and 1 are up and down (from i/o port).
           push af
           bit 0,a
           jp nz,+
           ld a,16
           cp (hl)
           jp z,+
           dec (hl)
           dec (hl)
+          pop af
           bit 1,a
           jp nz,+
           ld a,150
           cp (hl)
           jp z,+
           inc (hl)
           inc (hl)
+          ret

_SetPaddleSprite:
           ; Updates vertical positions of a paddle's sprites.
           ; A = paddle y, HL = pointer to buffer.
           ld (hl),a           ; first vpos is the y-coordinate.
           inc hl              ; point to next vpos in buffer.
           add a,8             ; second sprite is 8 pixels below.
           ld (hl),a           ; put second vpos in the buffer.
           inc hl              ; point to third vpos.
           add a,8             ; again, this is 8 pixels below.
           ld (hl),a           ; put third vpos in the buffer.
           ret                 ; return.

           _SwitchVectors: .dw _0 _1 _2 _3 _4 _5 _6
.ends

; --------------------------------------------------------------
.section "Menu" free
; --------------------------------------------------------------
Menu:
           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; Prepare match:
_0:        ; Make the selector disappear.
           ld a,$d0
           ld (SATBuffer+7),a
           ld c,SFX_CHANNELS2AND3
           ld hl,SFX_Serve
           call PSGSFXPlay

           ret

_1:        ret

; Run pre-match menu:
_2:        ; Make selector respond to player 1's joystick.
           ld a,(Joystick1)
           bit 2,a
           jp nz,+
           ld a,(Menu_Item)
           cp 1
           jp nz,++
           ; Change menu item to 0 (Play).
           ld c,SFX_CHANNEL2
           ld hl,SFX_Paddle0
           call PSGSFXPlay
           ld a,$5e
           ld (SATBuffer+30),a
           xor a
           ld (Menu_Item),a
           jp ++
+          ld a,(Joystick1)
           bit 3,a
           jp nz,++
           ld a,(Menu_Item)
           cp 0
           jp nz,++
           ; Change menu item to 1 (Menu).
           ld c,SFX_CHANNEL2
           ld hl,SFX_Paddle1
           call PSGSFXPlay
           ld a,$85
           ld (SATBuffer+30),a
           ld a,1
           ld (Menu_Item),a
++         ret

; Initialize pre-match menu:
_3:        ld a,$ad
           ld (SATBuffer+7),a
           ld a,$5e
           ld (SATBuffer+30),a
           xor a
           ld (Menu_Item),a
           ret

_4:        ret

; Prepare title screen
_5:        ; Initialize the SAT buffer with menu selector.
           ld hl,Titlescreen_SATInitializationData
           ld de,SATBuffer
           ld bc,18
           ldir

           ; Point to first menu item.
           xor a
           ld (Menu_Item),a

           ret

_6:        ; Make selector respond to player 1's joystick.
           ld a,(Joystick1)
           bit 1,a
           jp nz,+
           ld hl,SATBuffer
           ld (hl),$8f
           ld a,1
           ld (Menu_Item),a
           jp ++
+          bit 0,a
           jp nz,++
           ld hl,SATBuffer
           ld (hl),$7f
           xor a
           ld (Menu_Item),a
++

           ret

_EndSwitch:

; Return to main loop:
           ret

           _SwitchVectors: .dw _0 _1 _2 _3 _4 _5 _6

.ends

; --------------------------------------------------------------
.section "Score" free
; --------------------------------------------------------------
Score:
           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

_0:        xor a
           ld (Score_Player1),a
           ld (Score_Player2),a
           jp _EndSwitch

_1:        ; Is player 1 scoring (status flag set by the ball)?
           ld a,(Hub_Status)
           bit 0,a
           jp z,+

           ; Increment score, and check if it is 9 (end match).
           ld a,(Score_Player1)
           inc a
           ld (Score_Player1),a
           cp 9
           jp nz,+
           ; Set status bit to signal match end.
           ld a,(Hub_Status)
           or %00000100
           ld (Hub_Status),a

+           ; Is player 2 scoring?
           ld a,(Hub_Status)
           bit 1,a
           jp z,+

           ; Increment score, and check if it is 9 (end match).
           ld a,(Score_Player2)
           inc a
           ld (Score_Player2),a
           cp 9
           jp nz,+
           ; Set status bit to signal match end.
           ld a,(Hub_Status)
           or %00000100
           ld (Hub_Status),a
+
           ; Update the name table buffer.
           ld a,(Score_Player1)
           cp 0
           jp z,+
           ld b,a
           xor a
-          add a,6
           djnz -
+          add a,16

           ; Now A holds the index of the first tile of the
           ; relevant digit.
           ld ix,NameTableBuffer
           ld (ix+0),a
           inc a
           ld (ix+2),a
           inc a
           ld (ix+14),a
           inc a
           ld (ix+16),a
           inc a
           ld (ix+28),a
           inc a
           ld (ix+30),a

           ; Point to correct tile index (6 * score + 16).
           ld a,(Score_Player2)
           cp 0
           jp z,+
           ld b,a
           xor a
-          add a,6
           djnz -
+          add a,16

           ; Now A holds the index of the first tile of the
           ; relevant digit.
           ld ix,NameTableBuffer
           ld (ix+10),a
           inc a
           ld (ix+12),a
           inc a
           ld (ix+24),a
           inc a
           ld (ix+26),a
           inc a
           ld (ix+38),a
           inc a
           ld (ix+40),a

           jp _EndSwitch

_2:        jp _EndSwitch

; Initialize pre-match:
_3:        jp _EndSwitch

; Initialize session.
_4:        ; Initialize the name table buffer (0:0).
           ld hl,NameTableInitializationData
           ld de,NameTableBuffer
           ld bc,3*7*2
           ldir
           ; Reset score.
           xor a
           ld (Score_Player1),a
           ld (Score_Player2),a


           jp _EndSwitch
_5:

_6:

_EndSwitch:

; Return to main loop:
           ret

           _SwitchVectors: .dw _0 _1 _2 _3 _4 _5 _6

.ends


; --------------------------------------------------------------
.section "Hub" free
; --------------------------------------------------------------
Hub:       ; Increment loop counter at every loop.
           ld hl,Hub_LoopCounter
           inc (hl)

           ; Read joystick port into ram.
           call ReadJoysticks

           ; Reset score signal.
           ld a,(Hub_Status)
           and %11111100
           ld (Hub_Status),a

           ; Switch according to current game state.
           ld a,(Hub_GameState)
           ld de,_SwitchVectors
           call GetVector
           jp (hl)

; State 0: Initialize match.
_0:        ; Put sprite terminator in the SAT buffer.
           ld hl,SATBuffer+15
           ld (hl),$d0

           ld a,1
           ld (Hub_GameState),a
           jp _EndSwitch

; State 1: Run Match.
_1:        ; See if match should end (one player has 9 points).
           ld a,(Hub_Status)
           bit 2,a
           jp z,+
           ld a,3
           ld (Hub_GameState),a
           ld a,(Hub_Status)
           and %11111011
           ld (Hub_Status),a
+
           jp _EndSwitch

; State 2: Pre-match menu.
_2:        ; Look for keypress.
           ld a,(Joystick1)
           bit 4,a
           jp nz,++

           ; Key pressed! Check current menu item.
           ld a,(Menu_Item)
           cp 0
           jp nz,+
           ; Start match.
           ld a,0
           ld (Hub_GameState),a
           jp ++
+          ; Return to title screen menu.
           ld a,5
           ld (Hub_GameState),a
++
           jp _EndSwitch

; State 3: Initialize pre-match menu.
_3:        ld a,2
           ld (Hub_GameState),a
           jp _EndSwitch

; State 4: Initialize session.
_4:        call PSGStop
           ld a,3
           ld (Hub_GameState),a
           jp _EndSwitch

; Prepare title screen.
_5:        ; Play title screen tune.
           ld hl,IntergalacticTableTennis
           call PSGPlay

           ld a,6
           ld (Hub_GameState),a
           jp _EndSwitch

; Run title screen.
_6:        ; Look for keypress.
           ld a,(Joystick1)
           bit 4,a
           jp nz,+

           ; Key pressed! Now start match in desired mode.
           ; Temp: For now, only allow two-player mode.
           ld a,(Menu_Item)
           cp 1
           jp nz,+

           ; Initialize session.
           ld a,4
           ld (Hub_GameState),a
+
_EndSwitch:

; Return to main loop:
           ret

           _SwitchVectors: .dw _0 _1 _2 _3 _4 _5 _6
.ends


; --------------------------------------------------------------
.bank 1 slot 1
.section "Bank 1: Titlescreen, music, sfx and misc." free

SFX_Wall .incbin "Wall.psg"
SFX_Paddle0 .incbin "Paddle0.psg"
SFX_Paddle1 .incbin "Paddle1.psg"
SFX_Serve .incbin "SFX_Serve.psg"

IntergalacticTableTennis .incbin "IntergalacticTableTennis.psg"

Titlescreen_Tiles .include "Titlescreen_Tiles.inc"
Titlescreen_Palette .include "Titlescreen_Palette.inc"
Titlescreen_Tilemap .include "Titlescreen_Tilemap.inc"

ReleaseNotes:
           .db "Pong. The world can never be saturated with clones of this"
           .db " retro-gaming classic. May I present: Nya -versus- Ken!" 0


.ends


; --------------------------------------------------------------
.bank 2 slot 2
.section "Bank 2: Data" free
           .include "Data.inc"
.ends

.bank 3 slot 2
.section "Unused bank" free

.ends
