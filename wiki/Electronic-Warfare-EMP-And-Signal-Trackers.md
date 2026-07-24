_Associated Files: `MissionScripts\MissionInit\ElectronicWarfare\emp.sqf`, `empApply.sqf`, `empImmune.sqf`, `tracker.sqf`, `trackerRemove.sqf`, `trackerRender.sqf`, `trackerAttach.sqf`, `MissionScripts\ZenModules\Zen_empModule.sqf`, `Zen_trackerModule.sqf`, `Waldo_fnc_EMP`, `Waldo_fnc_EMPImmune`, `Waldo_fnc_Tracker`, `Waldo_fnc_TrackerAttach`_

# Electronic Warfare — EMP & Signal Trackers

Two self-contained electronic-warfare tools that sit alongside [Radio Jamming](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Radio-Jamming): a one-shot **EMP burst** and C-Track style **signal trackers**. Both are scriptable and available as Zeus modules, and neither runs any background loop until you actually use it.

---

# EMP Burst

An electromagnetic pulse fries electronics in a radius for a while — the offensive, one-shot counterpart to a jammer (which is a persistent field). It fires once and reverts on a timer, so it costs nothing to leave available.

## What it hits

Inside the radius, anything **not** made immune:

* **Infantry** lose their night-vision goggles (fried — removed from inventory) and, under TFAR, can't use their radio for the duration.
* **Vehicles** have their engine cut (fuel drained and restored afterwards — aircraft will drop!).
* **Players** in range get a **white-out flash** and a clear *"EMP DETONATION — electronics down"* message, so it reads as a deliberate EW event rather than a bug.

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

**Modules → Waldos Mission Modules → EMP Detonation** — a dialog for **radius** and **duration**, detonated at the module's position.

---

# Signal Trackers (C-Track)

Plant a tracker on a unit or vehicle and a chosen side follows it **live on the map** — electronic reconnaissance without keeping eyes on the target. The marker is drawn only on the tracking side's clients, so it stays hidden from the side being tracked.

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

**Modules → Waldos Mission Modules → Plant Signal Tracker** — a dialog to pick which side sees it; it tags the nearest unit or vehicle to the module.

## Notes

* Markers update every couple of seconds and follow the target's position and facing.
* Only planted trackers cost anything — there is no per-frame work and no cost when none are placed.

## See also

* [Radio Jamming (ACRE2 / TFAR)](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Radio-Jamming) — the persistent-field side of the EW suite, including UAV jamming
* [Waldos Mission Pack Zeus Modules](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mission-Pack-Zeus-Modules)
* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference)
