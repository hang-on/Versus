; -------------------------------------------------------------;
;                      PONG                                    ;
; -------------------------------------------------------------;

.sdsctag 0.1, "Versus", "Pong clone", "Anders S. Jensen"

.memorymap
       defaultslot 0
       slotsize $4000
       slot 0 $0000        ; rom bank 0 (0-16 kb).
       slot 1 $4000        ; rom bank 1 (16-32 kb).
       slot 2 $8000        ; rom bank 2 (32-48 kb).
       slotsize $2000
       slot 3 $c000        ; 8 kb ram.
.endme

.rombankmap                ; map rom to 2 x 16 kb banks.
       bankstotal 2
       banksize $4000
       banks 2
.endro

.equ top 16                ; top border.
.equ bottom 167            ; bottom border.
.equ TRUE 1
.equ FALSE 0

.enum $c000 export
       pfctrl db           ; playfield control register.
       status db           ; the vdp status flags.
       menu db             ; menu on/off
       
       ballx db            ; ball's x-coordinate.
       bally db            ; ball's y-coordinate.
       xspeed db           ; ball's horizontal speed.
       yspeed db           ; ball's vertical speed.
       vdir db             ; ball's vertical direction.
       hdir db             ; ball's horisontal direction.

       padbuf dsb 6        ; paddle buffer (y-coordinates).
       pad1y db            ; paddle 1 y-coordinate.
       pad2y db            ; paddle 2 y-coordinate.
       
       joy1 db             ; joystick port 1 ram mirror.
       joy2 db             ; joystick port 2 ram mirror.

       p1 db               ; player 1 score.
       p2 db               ; player 2 score.
       nambuf dsb 3*7*2    ; name table buffer for two digits.
.ende

.bank 0 slot 0
.org 0
       di                  ; disable interrupts.
       im 1                ; interrupt mode 1.
       ld sp,$dff0         ; default stack pointer address.
       jp inigam           ; initialize game.

; Read the vdp status flag at every frame interrupt.

.orga $0038                ; frame interrupt address.
       ex af,af'           ; save accumulator in its shadow reg.
       exx
       in a,$bf            ; get vdp status / satisfy interrupt.
       ld (status),a       ; save vdp status in ram.
       call ldvram         ; load vram.
       exx
       ex af,af'           ; restore accumulator.
       ei                  ; enable interrupts.
       ret                 ; return from interrupt.

; Disable the pause button - this is an unforgiving game!

.orga $0066                ; pause button interrupt.
       retn                ; disable pause button.

; Initialize game.
; Overwrite the first 4 kb of ram with zeroes.

inigam ld hl,$c000         ; point to beginning of ram.
       ld bc,$1000         ; 4 kb to fill.
       ld a,0              ; with value 0.
       call mfill          ; do it!

; Use the initialized ram to clean all of vram.

       ld hl,$0000         ; prepare vram for data at $0000.
       call vrampr
       ld b,4              ; write 4 x 4 kb = 16 kb.
-      push bc             ; save the counter.
       ld hl,$c000         ; source = freshly initialized ram.
       ld bc,$1000         ; 4 kb of zeroes.
       call vramwr         ; purge vram.
       pop bc              ; retrieve counter.
       djnz -

; Initialize the VDP registers.

       ld hl,regdat        ; point to register init data.
       ld b,11             ; 11 bytes of register data.
       ld c,$80            ; VDP register command byte.

-:     ld a,(hl)           ; load one byte of data into A.
       out ($bf),a         ; output data to VDP command port.
       ld a,c              ; load the command byte.
       out ($bf),a         ; output it to the VDP command port.
       inc hl              ; inc. pointer to next byte of data.
       inc c               ; inc. command byte to next register.
       djnz -              ; jump back to '-' if b > 0.

; Load playfield specific assets into vram.

       ld hl,$0000         ; first tile @ index 0.
       call vrampr         ; prepare vram.
       ld hl,pftile        ; playfield tile data.
       ld bc,3*32          ; 3 tiles, each tiles is 32 bytes.
       call vramwr         ; write playfield tiles to vram.

       ld hl,$0200         ; first tile @ index 16.
       call vrampr         ; prepare vram.
       ld hl,dgtile        ; digit tile data.
       ld bc,60*32         ; 60 tiles, each tiles is 32 bytes.
       call vramwr         ; write playfield tiles to vram.

       ld hl,$0a00         ; first tile @ index 80.
       call vrampr         ; prepare vram.
       ld hl,over1         ; overlay 1 tile data.
       ld bc,93*32         ; 93 tiles, each tiles is 32 bytes.
       call vramwr         ; write playfield tiles to vram.

       ld hl,$3800         ; point to name table.
       call vrampr         ; prepare vram.
       ld hl,pfmap         ; playfield tile map data.
       ld bc,32*24*2       ; 32 x 24 tiles, each is 2 bytes.
       call vramwr         ; write name table to vram.


       ld hl,$c000         ; color bank 1, color 0.
       call vrampr         ; prepare vram.
       ld hl,pfpal         ; playfield palette.
       ld bc,14            ; 14 colors.
       call vramwr         ; load playfield colors into bank 1.

; Load sprite specific assets into vram.
; Start by loading the sprite palette.

       ld hl,$c010         ; color bank 2, color 0.
       call vrampr         ; prepare vram.
       ld hl,sprpal        ; use the sprite palette
       ld bc,4             ; 4 colors.
       call vramwr         ; load playfield colors into bank 2.

; Load the ball tiles.

       ld hl,$2000         ; first tile @ index 256.
       call vrampr         ; prepare vram.
       ld hl,ballti        ; ball tile data.
       ld bc,32            ; one tile is 32 bytes.
       call vramwr         ; write the tile to vram.

; Load the paddle tiles.

       ld hl,$2020         ; first tile @ index 257.
       call vrampr         ; prepare vram.
       ld hl,padti         ; paddle tile data.
       ld bc,3 * 32        ; the paddle is 3 tiles high.
       call vramwr         ; write the paddle tiles to vram.

; Put the sprite terminator into the sprite attribute table.

       ld hl,$3f07         ; at sprite index 7.
       call vrampr         ; prepare vram.
       ld hl,termin        ; point to terminator byte $d0.
       ld bc,1             ; 1 byte.
       call vramwr         ; write it to sat.

; Initialize the paddles' charcodes and hpos in sat.

       ld hl,$3f82         ; point to sat vpos.
       call vrampr         ; prepare vram.

       ld hl,inipad        ; point to paddle init data.
       ld bc,12            ; 12 bytes (3x2x2).
       call vramwr         ; write to vram.


; Set the border color.

       ld a,%11110000      ; border color = 0.
       ld b,7              ; register 7.
       call setreg         ; set register.

; Initialize variables once per session.

       call resess              ; reset game session.

; Turn on screen to show the playfield.

       ld a,%11100000      ; enable screen.
       ld b,1              ; register 1.
       call setreg         ; set register.


       ei                  ; enable interrupts.

; From here on code is executed at every new game.


; Main loop.
; This is Versus' main loop. I'm going for a one-loop style
; structure inspired by the Combat disassembly (ATARI 2600).
;
mloop  halt                ; let the vram loader do its thing!
       ;
       call getkey         ; read controllers.
       call chkobj         ; check objects.
       call movobj         ; move the game objects.
       call gengfx         ; generate graphics, ready for vram.
       ;
       jp mloop


; --------------------------------------------------------------
; SUBROUTINES
;
; VIDEO OUTPUT (ldvram).
; Handle sprite and background drawing during vblank.
       ; Proces playfield control register. These are the valid
       ; settings: 0 = do nothing, 1 = draw standard playfield,
       ;           2 = draw match menu, 3 = draw title screen.
       ;
ldvram ld a,(pfctrl)       ; get playfield control register.
       ld de,vect0         ; point to vector table.
       jp switch           ; switch case A.
       ;
idlepf jp drwbal           ; skip to next video out section.
       ;
       ; Draw the standard playfield.
       ;
stdpf  ld hl,$3800         ; point to name table.
       call vrampr         ; prepare vram.
       ld hl,pfmap         ; playfield tile map data.
       ld bc,32*24*2       ; 32 x 24 tiles, each is 2 bytes.
       call vramwr         ; write name table to vram.
       xor a               ; clear A.
       ld (pfctrl),a       ; reset playfield control register.
       ; Profiling info - here we are at 256/262 lines!
       ; Skip rest of video tasks this frame, to avoid drawing
       ; outside vblank.
       jp endvid
       ;
       ; Draw the playfield menu.
       ;
mmpf   ld hl,$3b00         ; point to overlay in name table.
       call vrampr         ; prepare vram.
       ld hl,over1m        ; overlay tile map data.
       ld bc,32*11*2       ; 32 x 11 tiles, each is 2 bytes.
       call vramwr         ; write name table to vram.
       xor a               ; clear A.
       ld (pfctrl),a       ; reset playfield control register.
       jp drwbal
       ;
       ; Draw the ball. The ball occupies 1 hardware sprite.
       ;
drwbal ld hl,$3f00         ; first sprite's vpos.
       call vrampr         ; prepare vram.
       ld a,(bally)        ; get ball's y-coordinate.
       out ($be),a         ; load it into sat.
       ld hl,$3f80         ; first sprite's hpos.
       call vrampr         ; prepare vram.
       ld a,(ballx)        ; get ball's x-coordinate.
       out ($be),a         ; load it into sat.
       ;
       ; Draw the two score digits on the playfield.
       ;
drwsc  ld hl,$38da         ; name table address.
       call vrampr         ; prepare vram for writing.
       ld hl,nambuf        ; point to name table buffer.
       ld bc,14            ; 14 bytes (7 words) from here.
       call vramwr         ; write to vram.
       ;
       ld hl,$391a         ; second line in name table...
       call vrampr
       ld hl,nambuf+14
       ld bc,14
       call vramwr
       ;
       ld hl,$395a         ; third line in name table...
       call vrampr
       ld hl,nambuf+28
       ld bc,14
       call vramwr
       ;
       ; Draw the paddles. A paddle occupies 3 hardware sprites.
       ; Uses the paddle buffer.
       ;
drwpad ld hl,$3f01         ; second sprite's vpos.
       call vrampr         ; prepare vram.
       ld hl,padbuf        ; point to paddle buffer.
       ld c,$be            ; write to vram data port.
       ld b,6              ; 2 * 3 = 6 bytes.
       otir                ; do it.
       ;
       ; Wrap up the video out processing.
       ;
endvid
       ret

; CHECK OBJECTS (CHKOBJ)
; Check positions of objects (mainly the ball), and respond.
; Check the score.



; First ball test: Is it in one of the goal zones?
; Is ball x in player 1's goal zone?

chkobj
goal0  ld a,(ballx)        ; get ball x-coordinate.
       cp 3                ; player 1 goal zone: 0-2.
       jp nc,goal1         ; jump to next test if ball x > 2.
       call rsball         ; reset ball.
       ld hl,p2
       inc (hl)
; Is ball x in player 2's goal zone?

goal1  ld a,(ballx)        ; get ball x-coordinate.
       cp 253              ; player 2 goal zone: 253-255.
       jp c,goal2          ; end goal zone tests if ball x < 253.
       call rsball         ; reset ball.
       ld hl,p1
       inc (hl)
goal2                      ; end of goal zone testing section.

; Second ball test: Is it at the top or bortom border?
; Does the ball touch the bottom border?

bordr0 ld a,(bally)        ; load ball y into accumulator.
       cp bottom           ; is the ball over the bottom border
       jp c,bordr1         ; no? - forward to next border test.

; Ball hits bottom border. Now bounce the ball.

       ld a,bottom         ; load bottom border constant.
       ld (bally),a        ; set ball y = bottom border.
       ld a,1              ; load a non-zero value into vdir,
       ld (vdir),a         ; to make ball travel upwards.
       jp bordr2           ; forward to end of border tests.

; Does the ball touch the top border?

bordr1 ld a,(bally)        ; load ball y into accumulator.
       cp top              ; is the ball over the top border?
       jp nc,bordr2        ; no? - skip forward

; Ball hits top border. Now bounce the ball.

       ld a,top            ; load top border constant.
       ld (bally),a        ; set ball y = top border.
       ld a,0              ; set vdir = 0 to make the ball
       ld (vdir),a         ; travel downwards.
bordr2                     ; end of border testing.

; Third ball test: Is it colliding with one of the paddles?
; Check collision on paddle 1.

       ld hl,pad1y         ; point to paddle 1 y-coordinate.
       ld b,17             ; load left border of coll. zone.
       ld c,1              ; ball will bounce right.
       call collis         ; collision test and bouncing.

; Check collision on paddle 2.

       ld hl,pad2y         ; point to paddle 2 y-coordinate.
       ld b,238            ; left border of coll. zone.
       ld c,0              ; ball will bounce left.
       call collis         ; collision test and bouncing.

; Check players' score.

       ld a,(p1)           ; get player 1 score.
       cp 9                ; is it 9?
       call z,newgam         ; yes - then start new game.
       ld a,(p2)           ; get player 2 score.
       cp 9                ; is it 9?
       call z,newgam         ; yes - then start new game.
       ret


newgam
       ld a,1
       ld (menu),a         ; turn menu mode on
       inc a
       ld (pfctrl),a

       call remat          ; reset match.

       xor a
       ld (yspeed),a
       ld (xspeed),a
       ret


; MOVE OBJECTS (MOVOBJ)
; Reposition paddles according to joystick input.
; Position paddle 1.

movobj ld hl,pad1y         ; point to paddle 1 y coordinate.
       ld a,(joy1)         ; get joystick port 1 (rev. bits).
       call padpos         ; make paddle 1 respond to joystick.

; Position paddle 2.

       ld hl,pad2y         ; point to paddle 2 y coordinate.
       ld a,(joy1)         ; get joystick port 1 (rev. bits).
       rla                 ; rotate the bits three times so
       rla                 ; bits 0 and 1 is up and down on
       rla                 ; player 2's joystick.
       call padpos         ; make paddle 2 respond to joystick.

; Move ball 0) vertically, 1) horizontally and 2) finish.
; Check the ball's vertical direction.

movbl0 ld a,(vdir)         ; load vertical direction.
       cp 0                ; is the ball going down (=0)?
       jp z,down           ; yes - then jump forward.

; Move ball up.

up     ld a,(bally)        ; get ball y coordinate.
       ld hl,yspeed        ; point to y speed variable.
       sub (hl)            ; subtract yspeed from ball y.
       ld (bally),a        ; load the result back into ball y.
       jp movbl1           ; forward to horizontal direction.

; Move ball down.

down   ld a,(bally)        ; get ball y coordinate.
       ld hl,yspeed        ; point to y speed variable.
       add a,(hl)          ; add yspeed to ball y.
       ld (bally),a        ; load the result back into ball y.

; Check the ball's horizontal direction.

movbl1 ld a,(hdir)         ; load horizontal direction.
       cp 0                ; is ball going left (=0)?
       jp z,left           ; yes - then jump, else...

; Move ball right.

right  ld a,(ballx)        ; get ball x coordinate.
       ld hl,xspeed        ; point to xspeed variable.
       add a,(hl)          ; add xspeed to ball x.
       ld (ballx),a        ; load the result back into ball x.
       jp movbl2           ; skip the left-moving part.

; Move ball left.

left   ld a,(ballx)        ; get ball x coordinate.
       ld hl,xspeed        ; point to xspeed variable.
       sub (hl)            ; subtract xspeed from ball x.
       ld (ballx),a        ; load the result back into ballx.
movbl2                     ; end of move ball section.
       ret

; GENERATE GRAPHICS (GENGFX).
; Update various buffers so they are ready to be loaded into
; vram during vblank (by the ldvram routine).
; UPDATE SCORE NAME TABLE BUFFER.
; Point to correct tile index (6 * score + 16).

gengfx ld a,(p1)           ; get score (player 1).
       cp 0                ; special case = score is 0.
       jp z,+              ; if score = 0, then skip multiply.
       ld b,a              ; put score in counter (B).
       xor a               ; reset A.
-      add a,6             ; add 6 to A,
       djnz -              ; for every point the player has got.
+      add a,16            ; add 16 to the product.

; Now A holds the index of the first tile of the relevant digit.

       ld ix,nambuf        ; point IX to the name table buffer.
       ld (ix+0),a         ; put digit tile into buffer.
       inc a               ; next digit tile.
       ld (ix+2),a         ; put it into the buffer, etc...
       inc a
       ld (ix+14),a
       inc a
       ld (ix+16),a
       inc a
       ld (ix+28),a
       inc a
       ld (ix+30),a

; Point to correct tile index (6 * score + 16).

       ld a,(p2)           ; get score (player 2).
       cp 0                ; special case = score is 0.
       jp z,+              ; if score = 0, then skip multiply.
       ld b,a              ; put score in counter (B).
       xor a               ; reset A.
-      add a,6             ; add 6 to A,
       djnz -              ; for every point the player has got.
+      add a,16            ; add 16 to the product.

; Now A holds the index of the first tile of the relevant digit.

       ld ix,nambuf        ; point IX to the name table buffer.
       ld (ix+10),a         ; put digit tile into buffer.
       inc a               ; next digit tile.
       ld (ix+12),a         ; put it into the buffer, etc...
       inc a
       ld (ix+24),a
       inc a
       ld (ix+26),a
       inc a
       ld (ix+38),a
       inc a
       ld (ix+40),a

; Update paddle sprite positions.

       ld a,(pad1y)        ; load player 1 paddle y.
       ld hl,padbuf        ; point to player 1 vpos in buffer.
       call upad           ; update the paddle buffer.

       ld a,(pad2y)        ; load player 2 paddle y.
       ld hl,padbuf+3      ; point to player 2 vpos in buffer.
       call upad           ; update the paddle buffer.
       ret




; RESET GAME SESSION (RESESS).
; A game session consists of 1 or more matches.
; This routine resets score, paddles and the ball.

; Initialize the players' score.

resess xor a
       ld (p1),a
       ld (p2),a

; Initialize the name table buffer (for the score tiles).

       ld hl,ininam        ; score is 0:0.
       ld de,nambuf        ; point to buffer.
       ld bc,3*7*2         ; write those name table words.
       ldir

; Reset paddles.

       ld a,96             ; put the paddles at the center.
       ld (pad1y),a
       ld (pad2y),a

; Update the paddle buffer.

       ld a,(pad1y)        ; load player 1 paddle y.
       ld hl,padbuf        ; point to player 1 vpos in buffer.
       call upad           ; update the paddle buffer.

       ld a,(pad2y)        ; load player 2 paddle y.
       ld hl,padbuf+3      ; point to player 2 vpos in buffer.
       call upad           ; update the paddle buffer.

; Reset ball.

       call rsball

       call newgam
       ret


; RESET MATCH (REMAT).
; This routine resets score and the ball.

; Initialize the players' score.

remat  xor a
       ld (p1),a
       ld (p2),a

; Initialize the name table buffer (for the score tiles).

       ld hl,ininam        ; score is 0:0.
       ld de,nambuf        ; point to buffer.
       ld bc,3*7*2         ; write those name table words.
       ldir


; Reset ball.

       call rsball

       ret

; UPDATE SCORE NAME TABLE BUFFER.
; Point to correct tile index (6 * score + 16).

uscore ld a,(p1)           ; get score (player 1).
       cp 0                ; special case = score is 0.
       jp z,+              ; if score = 0, then skip multiply.
       ld b,a              ; put score in counter (B).
       xor a               ; reset A.
-      add a,6             ; add 6 to A,
       djnz -              ; for every point the player has got.
+      add a,16            ; add 16 to the product.

; Now A holds the index of the first tile of the relevant digit.

       ld ix,nambuf        ; point IX to the name table buffer.
       ld (ix+0),a         ; put digit tile into buffer.
       inc a               ; next digit tile.
       ld (ix+2),a         ; put it into the buffer, etc...
       inc a
       ld (ix+14),a
       inc a
       ld (ix+16),a
       inc a
       ld (ix+28),a
       inc a
       ld (ix+30),a

; Point to correct tile index (6 * score + 16).

       ld a,(p2)           ; get score (player 2).
       cp 0                ; special case = score is 0.
       jp z,+              ; if score = 0, then skip multiply.
       ld b,a              ; put score in counter (B).
       xor a               ; reset A.
-      add a,6             ; add 6 to A,
       djnz -              ; for every point the player has got.
+      add a,16            ; add 16 to the product.

; Now A holds the index of the first tile of the relevant digit.

       ld ix,nambuf        ; point IX to the name table buffer.
       ld (ix+10),a         ; put digit tile into buffer.
       inc a               ; next digit tile.
       ld (ix+12),a         ; put it into the buffer, etc...
       inc a
       ld (ix+24),a
       inc a
       ld (ix+26),a
       inc a
       ld (ix+38),a
       inc a
       ld (ix+40),a
       ret

; COLLISION DETECTION (COLLIS).
; Detect collision between a paddle and the ball, and bounce
; the ball (change the ball's hdir) in the event of a collision.
; HL = pointer to paddle y,
; B = collision zone left border, C = new hdir for bouncing.

; First test: Is the ball within the paddle's horizontal
; collision zone?

collis ld a,(ballx)        ; load ball x-coordinate.
       sub b               ; ball to the left of the zone?
       ret c               ; yes? - return.
       ld a,(ballx)        ; no? - load ball x again.
       inc b               ; increment B to right border of
       inc b               ; collision zone.
       sub b               ; ball to the right of the zone?
       ret nc              ; yes? - return.

; Second test: Is the ball over the paddle?
; Math: (ball y + paddle height) - paddle y < 0.

       ld a,(bally)        ; get ball y-coordinate.
       ld b,8              ; get ball height (one tile).
       add a,b             ; add them together in accumulator.
       sub (hl)            ; subtract paddle y from accumulator.
       ret c               ; return if ball is over paddle.

; Third test: Is the ball under the paddle?
; Math: (paddle y + paddle height) - ball y < 0.

       ld a,(bally)        ; get ball y-coordinate.
       ld d,a              ; save it in D for later.
       ld a,(hl)           ; get paddle y-coordinate.
       ld b,26             ; get paddle height (ca. 3 tiles).
       add a,b             ; put the sum in the accumulator.
       sub d               ; subtract ball y from accumulator.
       ret c               ; return if ball is under paddle.

; If we get here, it means that the ball and paddle collides!
; First, change the direction of the ball (bounce).

       ld a,c              ; load the bounce direction into A.
       ld (hdir),a         ; update hdir with new value.

; Second, calculate where on the paddle the ball hits, and
; adjust the vertical direction accordingly.
; (paddle y + half paddle height) - (ball y + ball height) < 0.

       ld a,(bally)        ; get ball y-coordinate.
       add a,6             ; add ball height.
       ld b,a              ; save it in B for later.
       ld a,(hl)           ; store paddle y in accumulator.
       add a,13            ; add half paddle height.
       sub b               ; subtract (refer to the equation).
       jp nc,+             ; >= 0? Lower part of paddle is hit.
       ld a,0              ; < 0? Upper part of paddle is hit,
       ld (vdir),a         ; so make the ball go north,
       ret                 ; and return.
+      ld a,1              ; make the ball go south by adjusting
       ld (vdir),a         ; the vertical direction.
       ret                 ; return.

; UPDATE PADDLE POSITION (PADPOS).
; Update the position of a paddle by responding to a joystick.
; HL = pointer to paddle y-coordinate.
; A = bits 0 and 1 are up and down (as read from i/o port).

padpos push af
       bit 0,a             ; is player 1 pressing up?
       jp nz,+             ; no? skip the following.
       ld a,24             ; yes? load paddle top limit.
       cp (hl)             ; is paddle at the top limit?
       jp z,+              ; yes? skip the following.
       dec (hl)            ; no? decrease paddle's y-coordinate
       dec (hl)            ; two times.
+      pop af              ; get joystick port 1 (rev. bits).
       bit 1,a             ; is player 1 pressing down?
       jp nz,+             ; no? skip the following.
       ld a,144            ; yes? load paddle bottom limit.
       cp (hl)             ; is paddle at the bottom limit?
       jp z,+              ; yes? skip the following.
       inc (hl)            ; no? increase paddle's y-coordinate
       inc (hl)            ; two times.
+      ret

; GET KEYS.
; Read the two joystick ports (port $dc and $dd) into ram.

getkey in a,$dc            ; read joystick port 1.
       ld (joy1),a         ; let variable mirror port status.

       in a,$dd            ; read joystick port 2.
       ld (joy2),a         ; let varable mirror port status.
       ret                 ; return.

; UPDATE PADDLE BUFFER (UPPAD).
; Update a paddle's sprites' positions in the paddle buffer, based
; on the paddle's y-coordinate.
; HL = points to paddle buffer.
; A = y-coordinate of the paddle.

upad  ld (hl),a           ; first vpos is the y-coordinate.
       inc hl              ; point to next vpos in buffer.
       add a,8             ; second sprite is 8 pixels below.
       ld (hl),a           ; put second vpos in the buffer.
       inc hl              ; point to third vpos.
       add a,8             ; again, this is 8 pixels below.
       ld (hl),a           ; put third vpos in the buffer.
       ret                 ; return.

; RESET BALL.
; Ball restarts from the middle of the playfield with initial
; values for xspeed and yspeed.

rsball ld a,2              ; set initial speed for the ball.
       ld (xspeed),a       ; set horizontal speed.
       ld (yspeed),a       ; set vertical speed.
       ld a,127            ; half playfield width + half ball.
       ld (ballx),a        ; set ball x.
       ld a,92             ; half playfield height.
       ld (bally),a        ; set ball y.
       xor a               ; reset accumulator.
       ld (vdir),a         ; ball goes down.

; Reverse the horizontal direction of the ball.

       ld a,(hdir)         ; load horizontal direction into A.
       cp 0                ; is ball going left?
       jp z,+              ; yes? - fast forward.
       xor a               ; no? - make ball go left, by loading
       ld (hdir),a         ; 0 into horizontal direction.
       ret                 ; return.
+      inc a               ; A was 0, so now it is 1 (= right)!
       ld (hdir),a         ; load reversed direction into hdir.
       ret                 ; return.

; PREPARE VRAM.
; Set up vdp to recieve data at vram address in HL.

vrampr push af
       ld a,l
       out ($bf),a
       ld a,h
       or $40
       out ($bf),a
       pop af
       ret

; --------------------------------------------------------------
; WRITE TO VRAM
; Write BC amount of bytes from data source pointed to by HL.
; Tip: Use vrampr before calling.

vramwr ld a,(hl)
       out ($be),a
       inc hl
       dec bc
       ld a,c
       or b
       jp nz,vramwr
       ret

; --------------------------------------------------------------
; MEMORY FILL.
; HL = base address, BC = area size, A = fill byte.

mfill  ld (hl),a           ; load filler byte to base address.
       ld d,h              ; make DE = HL.
       ld e,l
       inc de              ; increment DE to HL + 1.
       dec bc              ; decrement counter.
       ld a,b              ; was BC = 0001 to begin with?
       or c
       ret z               ; yes - then just return.
       ldir                ; else - write filler byte BC times,
                           ; while incrementing DE and HL...
       ret

; --------------------------------------------------------------
; SET VDP REGISTER.
; Write to target register.
; A = byte to be loaded into vdp register.
; B = target register 0-10.

setreg out ($bf),a         ; output command word 1/2.
       ld a,$80
       or b
       out ($bf),a         ; output command word 2/2.
       ret

; --------------------------------------------------------------
; SWITCH CASE (SWITCH)
; Vector table based switch case.
; CAUTION: Do NEVER call this function. Jump to it, or the stack
; will go crazy on you!!
; A = case, DE = vector table.
switch sla a
       ld h,0
       ld l,a
       add hl,de
       ld a,(hl)
       inc hl
       ld h,(hl)
       ld l,a
       jp (hl)



; --------------------------------------------------------------
; DATA
; --------------------------------------------------------------
; Initial values for the 11 vdp registers.

regdat .db %00100110       ; reg. 0, display and interrupt mode.
                           ; bit 4 = line interrupt (disabled).
                           ; 5 = blank left column (enabled).
                           ; 6 = hori. scroll inhibit (disabled).
                           ; 7 = vert. scroll inhibit (disabled).

       .db %10100000       ; reg. 1, display and interrupt mode.
                           ; bit 0 = zoomed sprites (disabled).
                           ; 1 = 8 x 16 sprites (disabled).
                           ; 5 = frame interrupt (enabled).
                           ; 6 = display (blanked).

       .db $ff             ; reg. 2, name table address.
                           ; $ff = name table at $3800.

       .db $ff             ; reg. 3, n.a.
                           ; always set it to $ff.

       .db $ff             ; reg. 4, n.a.
                           ; always set it to $ff.

       .db $ff             ; reg. 5, sprite attribute table.
                           ; $ff = sprite attrib. table at $3F00.

       .db $ff             ; reg. 6, sprite tile address.
                           ; $ff = sprite tiles in bank 2.

       .db %11110011       ; reg. 7, border color.
                           ; set to color 3 in bank 2.

       .db $00             ; reg. 8, horizontal scroll value = 0.

       .db $00             ; reg. 9, vertical scroll value = 0.

       .db $ff             ; reg. 10, raster line interrupt.
                           ; turn off line int. requests.

; Vector tables.
       ;
       ; Table to switch playfield drawing.
vect0  .dw idlepf
       .dw stdpf
       .dw mmpf
       ;
       ; Table ..
vect1


; Paddle initialization data.
inipad .db 11 01 11 02 11 03
       .db 244 01 244 02 244 03

; Test data for name table buffer
ininam .db 22 00 23 00 01 00 02 00 01 000 00 00 00 00
       .db 24 00 25 00 01 00 02 00 01 000 00 00 00 00
       .db 26 00 27 00 01 00 02 00 01 000 00 00 00 00

; Graphics for the playfield.

pfpal  .include "Playfield_Palette.inc"
pftile .include "Playfield_Tiles.inc"
pfmap  .include "Playfield_Tilemap.inc"
dgtile  .include "DigitTiles.inc"

; Overlays.

over1  .include "Overlay_1_Tiles.inc"
over1m .include "Overlay_1_Tilemap.inc"

; Graphics for the sprites.

sprpal .include "Sprites_Palette.inc"
ballti .include "Balltile.inc"
padti .include "PaddleTiles.inc"


termin .db $d0


