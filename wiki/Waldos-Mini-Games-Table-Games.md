# Waldos Mini Games: Table Games

> **Use this page when:** you need to configure or play the twelve seated multiplayer table games.

_Associated Files: `MissionScripts\MiniGames\miniGamesRegisterTable.sqf`, `MissionScripts\MiniGames\miniGamesUnregisterTable.sqf`, `MissionScripts\MiniGames\miniGamesEnsureRuntime.sqf`, `MissionScripts\MiniGames\engine\`, `Waldo_fnc_MiniGamesRegisterTable`_

## Waldos Mini Games — Table Games

Table games are the **multiplayer**, sit-down party games. A table becomes active only when its Eden init explicitly registers it. Everything runs with the server as authority and each player's screen as a thin client. Missions with no registered tables do not compile or run the seated-game engine.

This is the [Waldos Mini Games](Waldos-Mini-Games) sub-page for the seated games. For solo challenges that gate an interaction, see [Interaction Challenges](Waldos-Mini-Games-Interaction-Challenges).

## Setup

1. Place the **`[WMP] Party Table Example`** composition, or put this in a table object's init:

   ```sqf
   [this] call Waldo_fnc_MiniGamesRegisterTable;
   ```

2. Any valid object can be the table; object class is not used for discovery. The default setup enables all twelve games and uses four seats. To customise it:

   ```sqf
   [
       this,
       createHashMapFromArray [
           ["displayName", "Recreation Table"],
           ["games", ["chess", "checkers", "uno"]],
           ["seatOffsets", [[0,-1.05,0],[0,1.05,0],[-1.35,0,0],[1.35,0,0]]],
           ["seatExitOffsets", [[0,-1.85,0],[0,1.85,0],[-2.05,0,0],[2.05,0,0]]],
           ["seatDirections", [0,180,90,270]],
           ["actionRange", 4.5]
       ]
   ] call Waldo_fnc_MiniGamesRegisterTable;
   ```

   An empty `games` array means all twelve games. Unknown keys or games, malformed geometry, invalid objects, and seat arrays other than exactly four entries are rejected with an RPT diagnostic. Equivalent registration is repeat-safe.

3. Keep the four seat and exit lanes clear. Walk a player up to the table and use either the scroll-menu or nested ACE **Party Table** interaction to **Sit at Table**.

To remove a live table, use `[this] call Waldo_fnc_MiniGamesUnregisterTable;`. Object deletion performs the same cleanup automatically.

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

Late joiners receive registered-table metadata and request the current permitted snapshot when they interact or resume a seat. No executable script is sent through JIP. Seating remains locked to the table roster during a game. If a player departs one of the fixed-roster games, the server safely clears that match and returns the remaining seats to the lobby. Table deletion and reset clear private payloads and game state.

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

Per-game rules constants live in `MissionScripts\MiniGames\engine\config.sqf` as `Waldo_MG_CFG_*` values. Table display name, available games, seat/exit geometry, directions and action range belong in the table registration options. There is no supported-class list or automatic world discovery.

## Multiplayer / authority model

* `Waldo_fnc_MiniGamesRegisterTable` is the sole activation path. The first registration lazily loads server rules, interface UI, or the small headless-client locality role as appropriate.
* The **server** validates direct, tokenised requests and drains a per-table queue only while work exists. Idle tables have no authority poller or recurring discovery.
* Movement, animation, invulnerability, camera and presentation execute on the player owner. Table-local commands execute where the table is local, including after headless-client or curator locality changes.
* No `description.ext` changes are required — every screen is built at runtime from vanilla controls.

## See also

* [Waldos Mini Games (hub)](Waldos-Mini-Games)
* [Interaction Challenges](Waldos-Mini-Games-Interaction-Challenges)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
