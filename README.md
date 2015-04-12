# Versus_X

GameState:

| Value | Comment                                               |
| :---: | :---------------------------------------------------- |
| 0     | Initialize match                                      |
| 1     | Run match                                             |
| 2     | Run pre-match menu                                    |
| 3     | Initialize pre-match menu                             |
| 4     | Initialize session                                    |

Typical flow:
4 > 3 > 2 > 0 > 1 > 3 ....


Hub_Status:

| Bit   | Comment                                               |
| :---: | :---------------------------------------------------- |
| 0     | Player 1 is scoring                                   |
| 1     | Player 2 is scoring                                   |
| 2     | Match is over (one player has 9 points)               |
