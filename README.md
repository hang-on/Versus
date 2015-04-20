# Versus

##Introduction
Versus is a Pong clone for the Sega Master System. It is designed to run on an
NTSC system (60 hz). It is pretty straight forward to navigate and play. The
players take up the roles of Nya and Ken, two Pong-playing, competing siblings.
The first player to score 9 points wins the match. That's it! Even though Pong
is best played against a real human, this game can also cater to an intense
one-player Pong showdown, thanks to the built-in, always Pong-ready AI.

Depending on where it hits the paddle, the ball is deflected either upwards, 
downwards or straight horizontally. Every time the ball is deflected by a 
paddle, its speed increases for a still longer time period. After a little 
while, the ball swirls fast between the two players. Every time the ball is 
served from the center line, its speed is reset.

Versus is built with tools and knowledge from the SMS-Power! community. Thanks
to Maxim (BMP2Tile), Bock (Meka), Calindro (Emulicious), and sverx (PSGLib and 
vgm2psg)!

At the time of writing, the SMS-Power 18th anniversary compo is finishing, and 
it has been very inspiring to be a part of it. Greetings to my fellow 
contestants!

The title screen smash hit was composed on Delek's Deflemask tracker, with
arpeggio inspiration from jrlepage, and drum/bass inspiration from TmEE's
compo entry this year.

The visual style of the in-game assets is inspired by [the Pong tutorial at
Rembound](http://rembound.com/articles/the-pong-tutorial).

A Pong-clone is not breaking new ground on the SMS homebrew scene. Greetings 
to Homsar47 and haroldoop who have also experimented with this classic game.

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
    2. Show Nya's and Ken's reactions to the outcome of the last match.
- Main loop: The game is built around a main loop. Except for game states that
  require heavy duty vram tasks, the duration of the main loop is one frame,
  starting from the vertical blanking phase.
- Object: The main loop parses a list of game objects, i.e. the ball, paddles,
  score, etc. Objects are the main building blocks of the game. An object can
  read other objects' registers, but can only write to its own registers. All
  objects can set the flags in the Hub_Status register, and this way they can
  communicate with each other. Two special objects exist:
    1. The Hub is the last object to be parsed during each game loop cycle.
    Its main purpose is to control the Hub_GameState variable. The Hub is the
    only object with write acces to the game state variable.
    2. The Loader is the first object in the main loop. Depending on the
    game state, the loader loads buffered data into vram, i.e. the sprite
    attribute table, the name table. The loader takes care of all the vram
    updating.

##Hub_GameState
The overall state of the game is controlled by the 1 byte variable
Hub_GameState. This variable is altered by the Hub object, and it is read by
each of the game objects during the main loop. A game object has a script for
each game state. This way each object adjusts its behavior depending on the
game state.

The numbering is not chronological. Instead the numbers reflect where in the
development process the corresponding states were implemented.

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

##The Main Loop
Versus' structure is actually inspired by studies of disassembled Atari 2600
games. Every object is called once every cycle of the loop. This has really 
improved my workflow as the game started to grow. For example: I came to a 
point where I needed a menu, and I just created a menu object and squeezed it
into the loop. This structure allows me to 'hack in' new elements and features
as I go along, without the code turning spaghetti on me!
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
Every object follows the same structure. At first it executes instructions
that should be carried out, regardless of game state. Then comes a vector
table that functions like a switch/case control structure, allowing the object
to behave differently depending on the value of Hub_GameState. Remember,
objects can only read, not write, to the Hub_GameState. This turns the Hub
object (which controls the game state) into a kind of master/synchronization
device.

##Hub_Status
This is 8 flags that can be set by any game object. Unlike Hub_GameState,
which game objects can read, but only Hub can write to.

| Bit   | Comment                                                             |
| :---: | :------------------------------------------------------------------ |
| 0     | Player 1 is scoring                                                 |
| 1     | Player 2 is scoring                                                 |
| 2     | Match is over (one player has 9 points)                             |
| 3     | Ken is controlled by the AI                                         |
| 4     | Secret easy mode enabled (one player game only)                     |
| 5     | Ball collided with paddle (set/reset by ball obj)                   |
| 6     | Unused                                                              |
| 7     | Unused                                                              |

If you think the AI is a little too tough, you can activate the secret easy
mode by holding down left on player 1's joystick, while you select "play"
from the pre-match menu. For the rest of the match, the AI will be a little
slower. The secret easy mode is adressing concerns made by younger members of
the playtesting team :)

##Known issues
Versus is tested on Meka, Emulicious and real hardware (60 hz modded SMSII w.
an Everdrive). It should run without problems, except for the sound effects,
which are are a little out of sync on my Meka setup.
