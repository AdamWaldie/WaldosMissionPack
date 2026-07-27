_Associated Files: `init.sqf`, `MissionScripts\MiniGames\miniGamesInit.sqf`, `MissionScripts\MiniGames\engine\`, `MissionScripts\InteractionsMinigames\`, `Waldo_fnc_MiniGamesInit`_

# Waldos Mini Games

Waldos Mini Games is two complementary systems under one feature:

1. **[Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games)** — a seated, **multiplayer** party-games engine. Place a table object in Eden and players get scroll-menu actions to sit down, vote for a game and play. Twelve games ship with the pack: Battleship, Who's Who: Vehicles, Shotgun Roulette, Blackjack, Texas Hold'em, Five-Card Draw, Liar's Dice, Chess, Checkers, Connect Four, Rock Paper Scissors and UNO. These are for downtime, staging areas, barracks, FOBs and "waiting for the op to start" moments.

2. **[Field Equipment Procedures](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Interaction-Challenges)** — accessible **single-player** procedures that gate any object interaction. Each looks and behaves like distinct field equipment: EOD controller, diagnostic tablet, access terminal, lock cylinder, breaker cabinet, maintenance hatch, communications unit, hydraulic manifold, or secure console.

The fast path for mission makers is one Eden init line: `[this, "repair"] call Waldo_fnc_MiniGameInteractionSetup;`. Every procedure includes an integrated operating card, non-colour status cues, and a persistent **Field Procedure** reference.

> **Which do I want?** Multiplayer, social, sit-down-and-play → **Table Games**. A solo equipment operation that unlocks or triggers something → **Field Equipment Procedures**.

## Associated pages

* **[Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games)** — placing tables, the twelve games, seats, voting, spectating, tuning.
* **[Field Equipment Procedures](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Interaction-Challenges)** — equipment profiles, object/table setup, bomb defusal, accessibility, and every built-in procedure.

## Enabling it

The table-games engine is installed from `init.sqf`:

```sqf
Waldo_MiniGames_Enable = true;
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};
```

* Leave it `true` (the default) to use the seated table games.
* Field equipment procedures register on first use, so they work even when this flag is `false`; the flag only controls seated table games.

## Requirements

* **CBA_A3** — required (the whole pack depends on it).
* **ACE 3** — used for nested interaction menus on tables and field equipment. These discoverable surfaces also retain matching vanilla scroll-wheel actions; both routes call the same authoritative request handlers.
* No `description.ext` edits and no addon are needed — every screen is built at runtime from vanilla controls.

## Attribution

The seated table-games engine is ported from the community composition **"Party Games Scripted"** by **|LorÐ|™[Habilidade]Ðeus Ex**, rebranded into the pack's `Waldo_MG_` namespace with the game logic preserved. The field-equipment interaction framework is original to WMP.

## See also

* [Feature Tutorials](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Feature-Tutorials)
* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference)
