# Automatic ACE Fortify Setup

> **Use this page when:** you want synchronized editor objects converted into an ACE Fortify budget and build catalogue.

_Associated Files: `MissionScripts\Logistics\Fortify\AutoFortify.sqf`, `Waldo_fnc_AutoFortifySetup`_

ACE3's **Fortify** module lets players spend a budget to build defensive structures with a fortify
tool, but it needs a build catalogue and a starting budget before anyone can use it. This function
builds that catalogue for you: sync any objects and static weapons to a Game Logic in Eden, call
one function, and every synced object becomes buildable in that side's Fortify menu, priced
automatically from its size and weight.

## Setup

1. Give the intended players a fortify tool.
2. Place a **Game Logic** in Eden (same category as Modules).
3. Sync every object or static weapon that should be buildable to that Game Logic. Vehicles other
   than static weapons are not supported - syncing one produces unreliable results.
4. In the Game Logic's **Initialization** field, call the function (see below).
5. Repeat steps 2-4 for each additional side that should have its own fortify catalogue.

```sqf
[this, west, 6000] call Waldo_fnc_AutoFortifySetup;
```

Each setup is single-use: the synced objects and the Game Logic are consumed (deleted) once the
catalogue is built, so re-running the same Game Logic's init does nothing on a second pass.

## Parameters

| # | Name | Type | Meaning |
|---|---|---|---|
| 0 | `_target` | OBJECT | The Game Logic carrying the synced objects. |
| 1 | `_side` | SIDE | Which side's Fortify menu receives the catalogue: `west`, `east`, `independent`, or `civilian`. |
| 2 | `_budget` | NUMBER | That side's starting Fortify budget. |

## Changing a side's budget later

Add or remove budget mid-mission with ACE's own function directly - WMP does not wrap this one:

```sqf
[west, -250, false] call ace_fortify_fnc_updateBudget;
// [side, change, display hint]
```

A curator can do the same thing from Zeus without scripting - see the **Fortify Budget Manager**
module on the [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules) page.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
