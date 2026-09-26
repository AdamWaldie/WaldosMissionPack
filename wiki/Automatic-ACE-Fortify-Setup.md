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

| # | Name | Type | Default | Meaning |
|---|---|---|---|---|
| 0 | `_target` | Object | Required | The Game Logic carrying the synced objects. |
| 1 | `_side` | Side | `west` | The side whose Fortify menu receives the catalogue. |
| 2 | `_budget` | Number | `1000` | Starting budget passed to ACE Fortify. |

Call this on the server or in the Game Logic's Eden Init field. Non-server copies exit. The function has no useful return value. It deletes the synced source objects and the Game Logic after registering their classes, so the same setup cannot be rerun. WMP does not replay this registration to joining clients itself. Check ACE Fortify in a late-join test for your mod set.

## Changing a side's budget later

Add or remove budget mid-mission with ACE's own function directly - WMP does not wrap this one:

```sqf
[west, -250, false] call ace_fortify_fnc_updateBudget;
// [side, change, display hint]
```

A curator can do the same thing from Zeus without scripting - see the **Fortify Budget Manager**
module on the [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules) page.

## If fortify objects are missing

Check that ACE Fortify is loaded, the chosen side has a catalogue and budget, and every configured object classname exists in the loaded mods. A live Zeus budget change does not create missing class definitions. Start with one vanilla object to separate a setup error from a mod dependency.

## See also

- [Construction Objects](Construction-Objects)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
