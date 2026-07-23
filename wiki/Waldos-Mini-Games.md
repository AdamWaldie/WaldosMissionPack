_Associated Files: `init.sqf`, `MissionScripts\MiniGames\miniGamesInit.sqf`, `MissionScripts\MiniGames\engine\`, `MissionScripts\MiniGames\Interactions\`, `Waldo_fnc_MiniGamesInit`_

# Waldos Mini Games

Waldos Mini Games is two complementary systems under one feature:

1. **[Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games)** — a seated, **multiplayer** party-games engine. Place a table object in Eden and players get scroll-menu actions to sit down, vote for a game and play. Nine games ship with the pack: Battleship, Who's Who: Vehicles, Shotgun Roulette, Blackjack, Poker (no-limit Hold'em), Chess, Checkers, Rock Paper Scissors and UNO. These are for downtime, staging areas, barracks, FOBs and "waiting for the op to start" moments.

2. **[Interaction Challenges](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Interaction-Challenges)** — short, **single-player** mini games that resolve to pass/fail and can gate **any** object interaction through a generic hook. Five ship with the pack: wire-cut defusal, minesweeper, keypad code-crack, lockpick and circuit wiring. Use them to build bomb defusal, hacking a laptop, picking a lock, splicing a junction box, arming a device — anything where "succeed at a little game to make something happen" fits.

> **Which do I want?** Multiplayer, social, sit-down-and-play → **Table Games**. A solo skill/puzzle check that unlocks or triggers something → **Interaction Challenges**.

## Associated pages

* **[Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games)** — placing tables, the nine games, seats, voting, spectating, tuning.
* **[Interaction Challenges](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Interaction-Challenges)** — the generic interaction hook, bomb defusal, and every built-in challenge with its options.

## Enabling it

The table-games engine is installed from `init.sqf`:

```sqf
Waldo_MiniGames_Enable = true;
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};
```

* Leave it `true` (the default) to use the seated table games.
* The **interaction challenges register themselves on first use**, so bomb defusal and the other challenges work **even if this flag is `false`** — you only need the flag on for the seated table games.

## Requirements

* **CBA_A3** — required (the whole pack depends on it).
* **ACE 3** — used for the interaction menu on tables and on gated objects. Without ACE, gated interactions fall back to a vanilla scroll-wheel action; the table games use a vanilla action to sit.
* No `description.ext` edits and no addon are needed — every screen is built at runtime from vanilla controls.

## Attribution

The seated table-games engine is ported from the community composition **"Party Games Scripted"** by **|LorÐ|™[Habilidade]Ðeus Ex**, rebranded into the pack's `Waldo_MG_` namespace with the game logic preserved. The interaction-challenge framework (the generic hook, bomb defusal and the five built-in challenges) is original to WMP.

## See also

* [Feature Tutorials](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Feature-Tutorials)
* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference)
