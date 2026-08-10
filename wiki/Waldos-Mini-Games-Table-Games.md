# Waldos Mini Games: Table Games

> **Use this page when:** you need to configure or play the twelve seated multiplayer table games.

_Associated Files: `init.sqf`, `MissionScripts\MiniGames\miniGamesInit.sqf`, `MissionScripts\MiniGames\engine\config.sqf`, `MissionScripts\MiniGames\engine\core.sqf`, `MissionScripts\MiniGames\engine\games\`, `Waldo_fnc_MiniGamesInit`_

## Waldos Mini Games — Table Games

Table games are the **multiplayer**, sit-down party games. Drop a supported table in the editor, and players standing near it get actions to take a seat, vote for a game and play together. Everything runs with the server as the authority and each player's screen as a thin client, and it is **JIP-safe** — players who join late get the system installed and can walk up and sit down.

This is the [Waldos Mini Games](Waldos-Mini-Games) sub-page for the seated games. For solo challenges that gate an interaction, see [Interaction Challenges](Waldos-Mini-Games-Interaction-Challenges).

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
   | `Land_WoodenTable_large_F` | Large wooden table |
   | `Land_WoodenTable_small_F` | Small wooden table |

3. That's it. Walk a player up to the table and use either the scroll-menu or the nested ACE **Party Table** interaction to **Sit at Table**. Both routes submit the same server-validated request.

Up to **four** players can sit at a table. Once seated, players **vote** for a game from the lobby; when enough seated players are ready, the chosen game starts.

## The games

| Game | Players | Notes |
|---|---|---|
| **Battleship** | 2 | Private 10×10 fleets, placement previews & rotation, alternating shots, hits/sinks, safe spectators. |
| **Who's Who: Vehicles** | 2 | Guess-who with 48 vanilla vehicle previews and a hidden target; local red-X notes, alternating turns. |
| **Shotgun Roulette** | 2–4 | Hidden chamber, self-shots vs. targeting, six items, three lives each. |
| **Blackjack** | 1–4 | Automated dealer, even bets, Hit/Stand/Double, 3:2 blackjack, dealer stands on soft 17. |
| **Texas Hold'em** | 2–4 | No-limit betting with blinds, side pots and all-ins; 100 starting chips. |
| **Five-Card Draw** | 2–4 | One-chip ante, two betting rounds, exchange zero to three cards, side pots and all-ins. |
| **Liar's Dice** | 2–4 | Five private dice, wild ones, ordered bids, challenge reveals and elimination. |
| **Chess** | 2 | Full rules: check, castling, en passant, promotion; marker-icon armies. |
| **Checkers** | 2 | Diagonals, captures, kings. |
| **Connect Four** | 2 | 7×6 board, mouse or keys 1–7, Blue O / Amber X identities, first to two board wins. |
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

## Five-Card Draw

Each funded player antes one chip and receives five private cards. A no-limit betting round is followed by the draw: select up to three cards and press **DRAW**, or select none and press **STAND PAT**. A second betting round leads to showdown. The screen always identifies the dealer, acting player, pot, call amount, minimum raise, stack, contribution, folded/all-in state and last action.

Controls:

* Click cards to mark or unmark them for exchange. A selected card receives a contrasting outline/background, so selection does not rely on colour.
* **Fold**, **Check**, **Call**, **All In**, or enter a legal **Raise To** amount during betting.
* At hand end, every remaining seated player readies the next hand. When only one funded player remains, the same ready flow resets all stacks for a rematch.

The dealer rotates between funded players. A player who can pay only part of the ante remains eligible as an all-in contributor. Main and side pots are built from total contributions, ties split each pot, and odd chips are assigned deterministically.

## Liar's Dice

Every player begins with five private dice. The acting player bids a quantity and a face from 2 through 6. A legal raise either increases the quantity, or keeps the quantity and increases the face. The next player raises or presses **CHALLENGE THE BID**. Ones count as wild for every bid.

After a challenge, all dice are displayed for 2.5 seconds with both numerals and pip patterns. If matching dice plus wild ones meet the bid, the challenger loses a die; otherwise the bidder loses one. The loser opens the next round, zero-die players are eliminated, and the final player wins. There is no exact-bid action or palifico rule.

Spectators can see bids, turn order, die counts and challenge reveals, but never private dice under the cups.

## Connect Four

Two players alternate on a 7-column by 6-row board. Click a column header or press number keys **1–7**. Blue always uses the text symbol **O** and Amber always uses **X**, so colour is supplementary. Full columns are visibly disabled. Horizontal, vertical and both diagonal four-piece lines are detected by the server.

The match is first to two board wins. Drawn boards replay without a point, and both players must ready the next board or full rematch. Spectators remain read-only.

## Texas Hold'em interface

Hold'em rules and betting behaviour are unchanged. Its revised screen groups dealer/small-blind/big-blind markers, acting-player emphasis, stacks and contributions, community cards, main/side-pot breakdown, call and minimum raise values, hand descriptions, last-action explanations and next-hand readiness. Illegal actions are disabled and their tooltips explain why. Cards always include rank and suit letters; suit colour is only an additional cue.

## State privacy, spectators and departures

All action requests carry a unique token plus the table game ID and current hand/round epoch. The server rejects duplicates, stale epochs, malformed values and out-of-turn actions before changing state. Shared table variables contain only public snapshots. Draw Poker hands, Hold'em hands and Liar's Dice rolls are stored server-side and copied only to an owner-targeted player variable. Spectators never receive those private payloads.

Late joiners install the same runtime through the JIP entry and may spectate the current public snapshot. Seating remains locked to the table roster during a game. If a player departs one of the three new fixed-roster games, the server safely clears that match and returns the remaining seats to the lobby so no stale roster can block play. Table deletion and reset clear private payloads and game state.

## New-game tuning constants

| Constant | Default | Purpose |
|---|---:|---|
| `Waldo_MG_CFG_DRAWPOKER_STARTING_CHIPS` | 100 | Initial and rematch stack. |
| `Waldo_MG_CFG_DRAWPOKER_ANTE` | 1 | Compulsory contribution per hand. |
| `Waldo_MG_CFG_DRAWPOKER_MAX_DISCARDS` | 3 | Maximum cards exchanged. |
| `Waldo_MG_CFG_DRAWPOKER_UI_TICK` | 0.15 | Local display refresh interval. |
| `Waldo_MG_CFG_LIARSDICE_STARTING_DICE` | 5 | Dice per player at match start. |
| `Waldo_MG_CFG_LIARSDICE_REVEAL_SECONDS` | 2.5 | Public challenge reveal duration. |
| `Waldo_MG_CFG_LIARSDICE_UI_TICK` | 0.15 | Local display refresh interval. |
| `Waldo_MG_CFG_CONNECTFOUR_COLUMNS` | 7 | Board width. |
| `Waldo_MG_CFG_CONNECTFOUR_ROWS` | 6 | Board height. |
| `Waldo_MG_CFG_CONNECTFOUR_WINS_REQUIRED` | 2 | Boards needed to win the match. |
| `Waldo_MG_CFG_CONNECTFOUR_UI_TICK` | 0.10 | Local display refresh interval. |

Screenshots are intentionally not embedded until the final in-engine capture pass; the interfaces are procedural runtime controls rather than static texture mock-ups.

## Tuning

Engine tuning constants live at the top of `MissionScripts\MiniGames\engine\config.sqf` as `Waldo_MG_CFG_*` values — seat offsets and count, action ranges, loop tick rates, and per-game settings (starting chips, blinds, shell counts, grid sizes, etc.). The supported table classes are `Waldo_MG_CFG_TABLE_CLASSES`; add a classname there to let players use a different object as a table. Most missions never need to touch these.

## Multiplayer / authority model

* `Waldo_fnc_MiniGamesInit` installs the engine on every machine and re-broadcasts it for JIP; a per-machine version guard makes repeat calls a no-op.
* The **server** is the single authority for all shared state (seats, votes, game state) and runs the background loops once for the mission; each **client** runs its own UI/discovery loop.
* No `description.ext` changes are required — every screen is built at runtime from vanilla controls.

## See also

* [Waldos Mini Games (hub)](Waldos-Mini-Games)
* [Interaction Challenges](Waldos-Mini-Games-Interaction-Challenges)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
