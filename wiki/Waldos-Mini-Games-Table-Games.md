_Associated Files: `init.sqf`, `MissionScripts\MiniGames\miniGamesInit.sqf`, `MissionScripts\MiniGames\engine\config.sqf`, `MissionScripts\MiniGames\engine\core.sqf`, `MissionScripts\MiniGames\engine\games\`, `Waldo_fnc_MiniGamesInit`_

# Waldos Mini Games — Table Games

Table games are the **multiplayer**, sit-down party games. Drop a supported table in the editor, and players standing near it get actions to take a seat, vote for a game and play together. Everything runs with the server as the authority and each player's screen as a thin client, and it is **JIP-safe** — players who join late get the system installed and can walk up and sit down.

This is the [Waldos Mini Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games) sub-page for the seated games. For solo challenges that gate an interaction, see [Interaction Challenges](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Interaction-Challenges).

## Setup

1. Make sure the engine is enabled in `init.sqf` (it is by default):

   ```sqf
   Waldo_MiniGames_Enable = true;
   if (Waldo_MiniGames_Enable) then {
       [] call Waldo_fnc_MiniGamesInit;
   };
   ```

2. Place a **supported table object** in Eden. Tables are detected automatically by class — no init-field code needed. Supported classes out of the box:

   | Class | Description |
   |---|---|
   | `Land_CampingTable_F` | Camping table (default) |
   | `Land_CampingTable_small_F` | Small camping table |
   | `Land_CampingTable_small_white_F` | Small white camping table |
   | `Land_TablePlastic_01_F` | Plastic table |

3. That's it. Walk a player up to the table and use the scroll-menu / ACE interaction to **Take a Seat**.

Up to **four** players can sit at a table. Once seated, players **vote** for a game from the lobby; when enough seated players are ready, the chosen game starts.

## The games

| Game | Players | Notes |
|---|---|---|
| **Battleship** | 2 | Private 10×10 fleets, placement previews & rotation, alternating shots, hits/sinks, safe spectators. |
| **Who's Who: Vehicles** | 2 | Guess-who with 48 vanilla vehicle previews and a hidden target; local red-X notes, alternating turns. |
| **Shotgun Roulette** | 2–4 | Hidden chamber, self-shots vs. targeting, six items, three lives each. |
| **Blackjack** | 1–4 | Automated dealer, even bets, Hit/Stand/Double, 3:2 blackjack, dealer stands on soft 17. |
| **Poker** | 2–4 | No-limit Texas Hold'em with blinds, side pots and all-ins; 100 starting chips. |
| **Chess** | 2 | Full rules: check, castling, en passant, promotion; marker-icon armies. |
| **Checkers** | 2 | Diagonals, captures, kings. |
| **Rock Paper Scissors** | 2–4 | Countdown, reveal, quick rounds. |
| **UNO** | 2–4 | Paged private hands, stacking, draw chains, "call UNO" callouts. |

Games that need more than the players currently seated stay locked in the vote list until enough people sit down.

## Using a table (player's view)

* **Take a Seat / Leave Seat** — sit down at (or stand up from) the table.
* **Open Lobby** — the shared screen: the seated players, the game vote list, table status and a details panel for the highlighted game.
* **Vote** for a game and mark yourself **ready**. When the seated players agree and are ready, the game launches for everyone at the table.
* **Spectate** — players near the table who aren't seated can watch an in-progress game safely.
* Press **Escape** to leave a game screen / lobby (you stay seated). Finishing or resetting a match returns the table to its lobby.

Seated players are made invulnerable and posed in a sitting animation while they play, and are restored when they get up.

## Tuning

Engine tuning constants live at the top of `MissionScripts\MiniGames\engine\config.sqf` as `Waldo_MG_CFG_*` values — seat offsets and count, action ranges, loop tick rates, and per-game settings (starting chips, blinds, shell counts, grid sizes, etc.). The supported table classes are `Waldo_MG_CFG_TABLE_CLASSES`; add a classname there to let players use a different object as a table. Most missions never need to touch these.

## Multiplayer / authority model

* `Waldo_fnc_MiniGamesInit` installs the engine on every machine and re-broadcasts it for JIP; a per-machine version guard makes repeat calls a no-op.
* The **server** is the single authority for all shared state (seats, votes, game state) and runs the background loops once for the mission; each **client** runs its own UI/discovery loop.
* No `description.ext` changes are required — every screen is built at runtime from vanilla controls.

## Attribution

This engine is ported from the community composition **"Party Games Scripted"** by **|LorÐ|™[Habilidade]Ðeus Ex**, rebranded into the pack's `Waldo_MG_` namespace with the original game logic preserved.

## See also

* [Waldos Mini Games (hub)](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games)
* [Interaction Challenges](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Interaction-Challenges)
