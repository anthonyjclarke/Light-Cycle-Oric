# Light Cycle – Player's Guide

Everything here is read from the Oric code (`oric/game.s`); it has not yet been checked by playing the original in an
emulator. The C64 version will follow these rules (see [porting.md](porting.md)).

---

## Menus

After loading, the title screen explains the keys. The game then asks, in order:

1. **Volume.** A rainbow bar with a `~` marker: cursor up and down move it while a test tone plays; RETURN accepts.
   Volume 0 silences the game (`VolumeScreen`).
2. **Number of players.** `1` puts the computer in charge of player 2; `2` gives player 2 to a second person
   (`AskPlayers`).
3. **Speed.** `1` (fast) to `9` (slow): it sets the per-frame delay (`AskSpeed`, `FrameDelay`).

---

## Controls

| Control | Oric P1 | Oric P2     | C64 P1 | C64 P2      |
|:--------|:--------|:------------|:-------|:------------|
| Up      | `2`     | `]`         | `2`    | `@`         |
| Down    | `A`     | Right SHIFT | `A`    | Right SHIFT |
| Left    | `W`     | `;`         | `W`    | `:`         |
| Right   | `E`     | `'`         | `E`    | `;`         |
| Boost   | `R`     | `L`         | `R`    | `L`         |

The C64 keys keep the Oric layout's shape; the C64 has no `]` or `'`. Joystick port 2 also drives player 1, and port 1
player 2, with fire as boost (`ReadKeysP1`, `ReadKeysP2` in `c64/src/input.s`).

---

## Rules

Each player rides a light cycle that leaves a permanent trail. Touching any lit pixel crashes. Player 1 starts at x=25
heading right, player 2 at x=215 heading left, both at random heights (`RandomStarts`).

The arena is a one-pixel frame (x 6–239, y 0–199) with eight random-length diagonal walls aimed at the centre
(`DrawObstacles`), on a random paper colour: red, blue, magenta or black (`SetPaperColour`). Every 255 frames
`BonusBlocks` tries a random empty 6×6 spot and animates a block there; the last frame stays as a new obstacle, so the
arena slowly fills.

Normal speed moves a cycle one pixel every second frame; boost moves it every frame. Player 2's trail is dotted (plotted
on alternate steps), so the two trails can be told apart in monochrome.

---

## Scoring and Winning

`TIME` counts up every 8 frames at speeds 1–3 and every 4 frames at speeds 4–9 (`TickTime`). When a player crashes, the
other scores `TIME + 200` and `TIME` restarts (`AwardP1`, `AwardP2`). Each player has 5 lives. When either has none
left, the higher score wins (`DecideWinner`): the winner's name flashes and their score goes to the hi-score table of
eight, **LIGHT CYCLE HEROES**. If the computer wins, it types its own name. SPACE plays again; `V` returns to the volume
screen (`PlayAgain`).

---

## The Computer

`ComputerAI` looks 3 pixels ahead, 3 pixels wide. When the way is blocked it turns toward player 1 on the other axis;
`AIAvoid` reverses that turn if it is blocked too. `AIBoost` boosts whenever the computer is 30 or more pixels from
player 1 on either axis, so it closes distance fast and slows down near you.
