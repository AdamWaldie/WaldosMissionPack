_Associated Files: `MissionScripts\MiniGames\Interactions\`, `Waldo_fnc_MiniGameInteraction`, `Waldo_fnc_BombDefuseSetup`, `Waldo_fnc_MiniGameChallenge`, `Waldo_fnc_MiniGameRegisterChallenge`_

# Waldos Mini Games — Interaction Challenges

Interaction challenges are short, **single-player** mini games that resolve to **pass or fail**. On their own they are little skill/puzzle games; their real power is a **generic hook** that lets you gate *any* object interaction behind one. "Cut the right wire to defuse the bomb", "beat minesweeper to hack the laptop", "pick the lock to open the cache", "splice the junction box to restore power" — all the same system, just different callbacks.

This is the [Waldos Mini Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games) sub-page for solo challenges. For seated multiplayer games, see [Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games).

These challenges **register themselves the first time they are used**, so they work even if the table-games engine is disabled (`Waldo_MiniGames_Enable = false`).

## Quick start — bomb defusal

Put this in a bomb object's Eden **Initialization** field:

```sqf
[this] call Waldo_fnc_BombDefuseSetup;
```

Players get a **Defuse Bomb** interaction. Using it opens the wire-cut challenge: cut the correct wire to disarm it; a wrong wire, the timer running out, or aborting **detonates** it. Options let you tune the difficulty and the blast:

```sqf
[this, [
    ["title", "Defuse IED"],
    ["wireCount", 6],          // 3..6 wires
    ["timeLimit", 15],         // seconds (0 = no clock)
    ["detonateOnFailure", true],
    ["explosive", "IEDLandBig_Remote_Ammo"],
    ["oneShot", true]          // one attempt: defuse or boom
]] call Waldo_fnc_BombDefuseSetup;
```

On success the device sets `Waldo_MG_BombDefused` (and any `defusedVariable` you name) to `true` — handy for triggers and tasks.

## The generic hook — `Waldo_fnc_MiniGameInteraction`

`Waldo_fnc_BombDefuseSetup` is just a convenience wrapper over the generic hook. Use the hook directly to gate **anything**. Call it from the object's Eden **Initialization** field (so it runs on every machine):

```sqf
[
    this,                    // the object
    "minesweeper",           // which challenge (see the table below)
    [4, 6],                  // challenge config (challenge-specific)
    {                        // onSuccess — runs on the SERVER, gets [_object, _actor, true]
        params ["_obj", "_actor"];
        _obj setVariable ["laptopHacked", true, true];
        ["intel_task", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
    },
    {                        // onFailure — runs on the SERVER, gets [_object, _actor, false]
        params ["_obj", "_actor"];
        [format ["%1 tripped the lockout.", name _actor]] remoteExec ["systemChat", 0];
    },
    [                        // options
        ["title", "Hack Laptop"],
        ["oneShot", false]   // allow repeated attempts
    ]
] call Waldo_fnc_MiniGameInteraction;
```

**Callbacks run on the server**, so they can safely change mission state (delete/damage objects, complete tasks, spawn things, set broadcast variables). The challenge itself plays on the actor's screen and reports the result back to the server automatically.

### Options

| Key | Default | Purpose |
|---|---|---|
| `title` | `"Attempt"` | Action text. |
| `icon` | `""` | ACE action icon path. |
| `condition` | `{true}` | Extra show condition; receives `_object` as `_this`, returns a Boolean. |
| `oneShot` | `true` | Consume (hide) the action after one attempt. |
| `distance` | `4` | Radius in metres for the vanilla addAction fallback (ACE handles its own range). |

## Standalone — `Waldo_fnc_MiniGameChallenge`

You don't need an object. Run a challenge for any reason (a task step, a trigger, a Zeus prompt) and branch on the result:

```sqf
["keypad", [4, 6], { hint "Safe open."; }, { hint "Locked out."; }] call Waldo_fnc_MiniGameChallenge;
```

Parameters: `[_challengeId, _config, _onSuccess, _onFailure, _actor, _context]`. The callbacks run locally on `_actor` (default `player`) and receive `[_actor, _challengeId, _context]`.

## Built-in challenges

All five follow the same `_config` idea: an array of optional settings. Every challenge fails on **timeout** (if a clock is set) and on **Escape**.

| Id | Name | Skill | `_config` (all optional) |
|---|---|---|---|
| `wirecut` | Wire-Cut Defusal | Deduction | `[wireCount(3–6, 5), timeLimit(20), title]` |
| `minesweeper` | Minesweeper | Spatial logic | `[size(4–8, 5), mineCount(5), timeLimit(0), title]` |
| `keypad` | Keypad Code-Crack | Code-breaking | `[digits(3–6, 4), maxGuesses(6), timeLimit(0), title]` |
| `lockpick` | Lockpick | Timing | `[pins(1–6, 3), period(1.4s), zoneWidth(0.16), timeLimit(0), title]` |
| `circuit` | Circuit Wiring | Matching | `[pairs(3–6, 4), maxMistakes(3), timeLimit(0), title]` |

* **Wire-Cut** — a printed clue names exactly one correct wire (by colour or position). Cut it.
* **Minesweeper** — classic: reveal every safe cell; numbers count adjacent mines and empty cells flood-open. Hit a mine and it's over.
* **Keypad** — Mastermind-style. Guess the code; after each guess you're told how many digits are *correct* (right slot) and *misplaced* (right digit, wrong slot).
* **Lockpick** — a marker sweeps a bar; press **SET PIN** (or **Space**) while it's in the green zone. Each pin re-randomises the zone and speeds up.
* **Circuit** — connect each left terminal to its matching-colour terminal on the scrambled right column without too many wrong splices.

### Thematic pairings

| Object / idea | Good challenge |
|---|---|
| Bomb / IED defusal | `wirecut` (via `Waldo_fnc_BombDefuseSetup`) |
| Hacking a laptop / terminal | `minesweeper`, `keypad` |
| Safe, keypad door, arming panel | `keypad` |
| Padlock, cache, locked vehicle | `lockpick` |
| Repair panel, junction box, comms splice | `circuit` |

## Registering your own challenge

A challenge is CODE following the contract `[_config, _resolve]`: present something to the local player, then call `[_success]` on `_resolve` exactly once. Register it and it becomes usable by id everywhere:

```sqf
["mychallenge", { params ["_config", "_resolve"]; /* ... */ [true] call _resolve; }, "My Challenge"]
    call Waldo_fnc_MiniGameRegisterChallenge;
```

## See also

* [Waldos Mini Games (hub)](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games)
* [Table Games](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games-Table-Games)
* [Tasks / Objectives](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Tasks-And-Objectives) — pair challenge outcomes with tasks
