# Electronic Warfare: EMP and Signal Trackers

> **Use this page when:** you need one-shot EMP effects or side-private signal trackers through scripts or Zeus.

_Associated Files: `MissionScripts\MissionInit\ElectronicWarfare\emp.sqf`, `empApply.sqf`, `empImmune.sqf`, `tracker.sqf`, `trackerRemove.sqf`, `trackerRender.sqf`, `trackerAttach.sqf`, `MissionScripts\ZenModules\Zen_empModule.sqf`, `Zen_trackerModule.sqf`, `Waldo_fnc_EMP`, `Waldo_fnc_EMPImmune`, `Waldo_fnc_Tracker`, `Waldo_fnc_TrackerAttach`_


Two self-contained electronic-warfare tools that sit alongside [Radio Jamming](Radio-Jamming): a one-shot **EMP burst** and C-Track style **signal trackers**. Both are scriptable and available as Zeus modules, and neither runs any background loop until you actually use it.

---

## EMP Burst

An electromagnetic pulse disables electronics inside a radius for a set duration. It is the one-shot counterpart to a persistent jammer and runs no background loop while unused.

## What it hits

Inside the radius, anything **not** made immune:

* **Infantry** lose their night-vision goggles. The goggles are removed from inventory. Under TFAR, radio use is blocked for the duration.
* **Vehicles** lose engine power until their fuel state is restored. Aircraft can lose lift.
* **Players** in range get a **white-out flash**. The additional disruption notice is off by default; set `Waldo_EMP_NotifyAffectedPlayers = true` to enable it.

## Scripting

```sqf
[getPosATL myObject, 200, 30] call Waldo_fnc_EMP;   // [position, radius (m), duration (s)]
```

Defaults: radius `150`, duration `30`.

## Immunity

Protect command vehicles, mission-critical assets or a friendly element:

```sqf
[this] call Waldo_fnc_EMPImmune;              // in a vehicle's or unit's init field
[commandVehicle, true] call Waldo_fnc_EMPImmune;
```

Occupants of an immune vehicle are protected automatically. The flag is broadcast, so it holds for JIP players.

## Zeus

**Modules > WMP Combat Systems > EW: Detonate EMP at Cursor** opens a dialog for **radius** and **duration**, then detonates at the module position.

The module writes its parameters to the RPT for diagnostics and does not announce them in chat.

---

## Signal Trackers (C-Track)

Plant a tracker on a unit or vehicle to show its live position to a chosen side. Only clients on that side draw the marker, so the target does not receive it.

## Planting one

**As a player:** walk up to any unit or vehicle and use the ACE interaction **Plant Signal Tracker**. Your side then sees it on the map.

**From script or a trigger:**

```sqf
[enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;   // [target, trackingSide, label]
[cursorTarget] call Waldo_fnc_TrackerAttach;                // tag what you're looking at, for your side
```

`trackingSide` accepts a side (`west`/`east`/…), a string (`"WEST"`/`"BLUFOR"`, `"EAST"`/`"OPFOR"`, `"IND"`/`"INDFOR"`, `"CIV"`/`"CIVILIAN"`) or `"ALL"`.

## Removing one

```sqf
[enemyTruck] call Waldo_fnc_TrackerRemove;   // by object
[2] call Waldo_fnc_TrackerRemove;            // by tracker id (returned by Waldo_fnc_Tracker)
```

A tracker also drops itself automatically when its target is killed or deleted.

## Zeus

**Modules > WMP Combat Systems > Tracker: Attach to Selected Object** opens a dialog for the tracking side, marker label and initial active state, then tags the nearest unit or vehicle to the module through `Waldo_fnc_Tracker`.

## Notes

* Markers update every couple of seconds and follow the target's position and facing.
* The tracker renderer starts only when a tracker exists. An empty registry has no per-frame work.

## See also

* [Radio Jamming (ACRE2 / TFAR)](Radio-Jamming): persistent radio and UAV interference fields
* [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
* [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
