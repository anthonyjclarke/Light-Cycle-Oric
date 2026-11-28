# Light Cycle – Player's Guide

I've read these rules from the Oric code (`oric/game.s`). I've run the original in Auric, but I haven't checked the
rules against it one by one. The C64 version follows the same rules, apart from the differences listed in
[porting.md](porting.md).

---

## Menus

After loading, the title screen explains the keys. The game then asks, in order:

1. **Volume.** A rainbow bar with a `~` marker: cursor up and down move it while a test tone plays, and RETURN accepts.
   Volume 0 silences the game (`VolumeScreen`).
2. **Number of players.** `1` puts the computer in charge of player 2; `2` gives player 2 to a second person
   (`AskPlayers`).
3. **Speed.** `1` (fast) to `9` (slow), which sets the per-frame delay (`AskSpeed`, `FrameDelay`).

On the C64 the game opens with a picture based on the original cassette inlay, then the instructions, then a demo of
the computer playing itself. From any of them, `1`, SPACE or fire starts a one-player game and `2` a two-player one.

Until the menus are ported (Phase 4), the volume is fixed at 10 and the speed at 5, and RUN/STOP ends a game. The
scores, lives and `TIME` sit in a panel on each side of the arena, laid out like the Oric's status rows, with player 1
on the left and player 2 on the right. When a player runs out of lives the winner's name flashes and the game goes back
to the intro (the hi-score table arrives in Phase 4).

---

## Controls

| Control | Oric P1 | Oric P2     | C64 P1 | C64 P2      |
|:--------|:--------|:------------|:-------|:------------|
| Up      | `2`     | `]`         | `2`    | `@`         |
| Down    | `A`     | Right SHIFT | `A`    | Right SHIFT |
| Left    | `W`     | `;`         | `W`    | `:`         |
| Right   | `E`     | `'`         | `E`    | `;`         |
| Boost   | `R`     | `L`         | `R`    | `L`         |

The C64 has no `]` or `'`, so the C64 keys keep the shape of the Oric layout. Joystick port 2 also drives player 1 and
port 1 drives player 2, with fire as boost (`ReadKeysP1`, `ReadKeysP2` in `c64/src/input.s`).

---

## Rules

Each player rides a light cycle that leaves a permanent trail, and touching any lit pixel is a crash. Player 1 starts
at x=25 heading right and player 2 at x=215 heading left, both at random heights (`RandomStarts`).

The arena is a one-pixel frame (x 6–239, y 0–199) with a V-shaped wedge of random size at the middle of each wall,
pointing inward (`DrawObstacles`). The paper colour is random: red, blue, magenta or black (`SetPaperColour`). Every
255 frames `BonusBlocks` tries a random empty 6×6 spot and animates a block there. The last frame stays as a new
obstacle, so the arena slowly fills.

At normal speed a cycle moves one pixel every second frame; boost moves it every frame. Player 2's trail is dotted
(plotted on alternate steps), so you can tell the two trails apart on a monochrome screen.

---

## Scoring and Winning

`TIME` counts up every 8 frames at speeds 1–3 and every 4 frames at speeds 4–9 (`TickTime`). When a player crashes, the
other scores `TIME + 200` and `TIME` restarts (`AwardP1`, `AwardP2`). Each player has 5 lives.

When either player has none left, the higher score wins (`DecideWinner`). The winner's name flashes and their score
goes into the hi-score table of eight, **LIGHT CYCLE HEROES**. If the computer wins, it types in its own name. SPACE
plays again, and `V` goes back to the volume screen (`PlayAgain`).

---

## The Computer

`ComputerAI` looks 3 pixels ahead, across a width of 3 pixels. When the way is blocked it turns toward player 1 on the
other axis, and `AIAvoid` reverses that turn if it's blocked too. `AIBoost` boosts whenever the computer is 30 or more
pixels from player 1 on either axis, so it closes the distance fast and slows down once it's near player 1.
