# Waldos Mini Games

> **Use this page when:** you are choosing between seated party games and field-equipment interaction procedures.

_Associated Files: `MissionScripts\MiniGames\miniGamesRegisterTable.sqf`, `MissionScripts\MiniGames\engine\`, `MissionScripts\InteractionsMinigames\`, `Waldo_fnc_MiniGamesRegisterTable`_


Waldos Mini Games is two complementary systems under one feature:

1. **[Table Games](Waldos-Mini-Games-Table-Games)** — a seated, **multiplayer** party-games engine. Place a table object in Eden and players get scroll-menu actions to sit down, vote for a game and play. Twelve games ship with the pack: Battleship, Who's Who: Vehicles, Shotgun Roulette, Blackjack, Texas Hold'em, Five-Card Draw, Liar's Dice, Chess, Checkers, Connect Four, Rock Paper Scissors and UNO. These are for downtime, staging areas, barracks, FOBs and "waiting for the op to start" moments.

2. **[Field Equipment Procedures](Waldos-Mini-Games-Interaction-Challenges)** — accessible **single-player** procedures that gate any object interaction. Each looks and behaves like distinct field equipment: EOD controller, diagnostic tablet, access terminal, lock cylinder, breaker cabinet, maintenance hatch, communications unit, hydraulic manifold, or secure console.

The fast path for mission makers is one Eden init line: `[this, "repair"] call Waldo_fnc_MiniGameInteractionSetup;`. Every procedure includes an integrated operating card, non-colour status cues, and a persistent **Field Procedure** reference.

> **Which do I want?** Multiplayer, social, sit-down-and-play → **Table Games**. A solo equipment operation that unlocks or triggers something → **Field Equipment Procedures**.

## Associated pages

* **[Table Games](Waldos-Mini-Games-Table-Games)** — placing tables, the twelve games, seats, voting, spectating, tuning.
* **[Field Equipment Procedures](Waldos-Mini-Games-Interaction-Challenges)** — equipment profiles, object/table setup, accessibility, and every built-in procedure.
* **[Bomb Defusal](Bomb-Defusal)** — apply any interaction procedure to a live or training explosive with an authoritative result and optional failure detonation.

## Enabling it

Seated tables activate individually from the table object's Eden init:

```sqf
[this] call Waldo_fnc_MiniGamesRegisterTable;
```

There is no automatic table discovery and no seated-game startup in `init.sqf`. `Waldo_MiniGames_Enable` remains the field-equipment challenge setting; changing it does not register seated tables. Field procedures still register on first use.

## Requirements

* **CBA_A3** — required (the whole pack depends on it).
* **ACE 3** — used for nested interaction menus on tables and field equipment. These discoverable surfaces also retain matching vanilla scroll-wheel actions; both routes call the same authoritative request handlers.
* No `description.ext` edits and no addon are needed — every screen is built at runtime from vanilla controls.

## See also

* [Feature Tutorials](Feature-Tutorials)
* [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
