# Introduction
Versus is a Pong clone for the Sega Master System.

# Terminology
- **Nya**: Nya is a warm-blooded girl that loves to play Pong but hates to loose. She is player 1's avatar.
- **Ken**: Ken is Nya's brother, and he is more of a sensitive dreamer, who likes Pong for its intricate connections to Zen philosophy. He is player 2's avatar. In a one-player game, the computer controls Ken.
- **Match**: Nya and Ken battle it out. Then first to score 9 points wins the match. When a match ends, the game displays the Pre-match menu and waits for user input.
- **Session**: A session consists of multiple matches. A session starts when the game changes from title screen to the first Pre-match menu, and it is terminated once you go back to the title screen.
- **Pre-Match Menu**: A menu that appears on top of the playfield before each match. Its purpose is twofold:
  1. Let the player choose between starting the match, or ending the session by going back to the title screen. 
  2. Show Nya's and Ken's reactions to the outcome of the last match. If this is the first match of the session, then Nya and Ken are shown in a ready-for-action pose.

#Hub_GameState  
The overall state of the game is controlled by the 1 byte variable Hub_GameState. This variable is altered by the Hub object, and it is read by each of the game objects during the main loop. A game object has a script for each game state. This way each object adjusts its behavior depending on the game state.

| Value | Comment                                               |
| :---: | :---------------------------------------------------- |
| 0     | Initialize match                                      |
| 1     | Run match                                             |
| 2     | Run pre-match menu                                    |
| 3     | Initialize pre-match menu                             |
| 4     | Initialize session                                    |

Typical flow (The value of Hub_GameState):
4 > 3 > 2 > 0 > 1 > 3 ....

#Hub_Status  
This is 8 flags that can be set by any game object. Unlike Hub_GameState, which game objects can read, but only Hub can write to.

| Bit   | Comment                                               |
| :---: | :---------------------------------------------------- |
| 0     | Player 1 is scoring                                   |
| 1     | Player 2 is scoring                                   |
| 2     | Match is over (one player has 9 points)               |
