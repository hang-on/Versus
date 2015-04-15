# Versus

##Introduction
Versus is a Pong clone for the Sega Master System. It is designed to run on an
NTSC system (60 hz). It is pretty straight forward to navigate and play. The
players take up the roles of Nya and Ken, two Pong-playing, competing siblings.
The first player to score 9 points wins the match. That's it! Even though Pong
is best played against a real human, this game can also cater to an intense
one-player Pong showdown, thanks to the built-in, always Pong-ready AI.

Versus is built with tools and knowledge from the SMS-Power! community. Thanks
to Maxim for BMP2Tile, Bock for Meka, Calindro for Emulicious, and sverx for
PSGLib and vgm2psg! At the time of writing the SMS-Power 18th anniversary compo
is finishing, and it has been very inspiring to be a part of it. Greetings to
my fellow contestants.

The rest of this document does mainly provide some development notes on
aspects of the game.

##Terminology
- Nya: Nya is a warm-blooded girl that loves to play Pong but hates to loose.
  She is player 1's avatar.
- Ken: Ken is Nya's brother, and he is more of a sensitive dreamer, who likes
  Pong for its intricate connections to Zen philosophy. He is player 2's avatar.
  In a one-player game, the computer controls Ken.
- Match: Nya and Ken battle it out. Then first to score 9 points wins the
  match.  When a match ends, the game displays the Pre-match menu and waits for
  user input.
- Session: A session consists of multiple matches. A session starts when the
  game changes from title screen to the first Pre-match menu, and it is
  terminated once you go back to the title screen.
- Pre-match menu: A menu that appears on top of the playfield before each
  match. Its purpose is twofold:
    1. Let the player choose between starting the match, or ending the session
    by going back to the title screen.
    2. Show Nya's and Ken's reactions to the outcome of the last match. If
    this is the first match of the session, then Nya and Ken are shown in a
    ready-for-action pose.
- Main loop: The game is built around a main loop. Except for game states that
  require heavy duty vram tasks, the duration of the main loop is one frame,
  starting from the vertical blanking phase.
- Object: The main loop parses a list of game objects, i.e. the ball, paddles,
  score, etc. Objects are the main building blocks of the game. An object can
  read other object's registers, but can only write to it own registers. All
  objects can set the flags in the Hub_Status register, and this way they can
  communicate with each other. Two special objects exist:
    1. The Hub is the last object to be parsed during each game loop cycle.
    Its main purpose is to control the Hub_GameState variable. The HUb is the
    only object with write acces to the game state variable.
    2. The Loader is called by the frame interupt handler. Depending on the
    game state, the loader loads buffered data into vram, i.e. the sprite
    attribute table, the name table.

##Hub_GameState
The overall state of the game is controlled by the 1 byte variable
Hub_GameState. This variable is altered by the Hub object, and it is read by
each of the game objects during the main loop. A game object has a script for
each game state. This way each object adjusts its behavior depending on the
game state.

The numbering is not chronological. Instead the numbers reflect where in the
development process the corresponding states where implemented.

| Value | Comment                                                              |
| :---: | :------------------------------------------------------------------- |
| 0     | Initialize match                                                     |
| 1     | Run match                                                            |
| 2     | Run pre-match menu                                                   |
| 3     | Initialize pre-match menu                                            |
| 4     | Initialize session                                                   |
| 5     | Prepare titlescreen                                                  |
| 6     | Run titlescreen                                                      |

Typical flow (The value of Hub_GameState):
(Power on) > 5 > 6 > 4 > 3 > 2 > 0 > 1 > 3 ....

##The main loop
```asm
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

```


##Hub_Status
This is 8 flags that can be set by any game object. Unlike Hub_GameState,
which game objects can read, but only Hub can write to.

| Bit   | Comment                                                              |
| :---: | :------------------------------------------------------------------- |
| 0     | Player 1 is scoring                                                  |
| 1     | Player 2 is scoring                                                  |
| 2     | Match is over (one player has 9 points)                              |
| 3     | Ken is controlled by the AI                                          |


##Known issues
Versus is tested on Meka, Emulicious and real hardware (60 hz modded SMSII w.
an Everdrive). It should run without problems, except for the sound effects,
which are are a little out of sync on my Meka setup.
