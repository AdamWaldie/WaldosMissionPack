_Associated Files: `MissionScripts\Logistics\Construction\ConstructionObjects.sqf`, `Waldo_fnc_ConstructionObjects`_

# Construction Objects

Fakes the **construction of defences, objects or scenery** from a single interaction object via an ACE timed action. Pre-place the objects you want "built" (hidden at mission start); when a player runs the build action on the interaction object, those objects appear with a construction sound and progress bar. It's a lightweight way to let players raise a sandbag wall, a checkpoint, an FOB, or any prop set on demand — without the full Eden/ACE base-building flow.

The interaction object can be **carried in ACE cargo** and keeps its build ability after being moved, so you can haul a "build kit" crate to where you need it.

## Requirements

* **ACE3** — the action uses the ACE interaction menu and progress bar. The function silently exits if ACE is not loaded.

## Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Target | Object | — | The object players interact with to build the synced objects. |
| 1 | Modern audio | Bool | `false` | `true` = modern construction sounds; `false` = older "wooden" construction sounds. |

## Setup in Eden

1. Place the **interaction object** (e.g. an ammo box) and give it a variable name.
2. Place a **Game Logic** as close as possible to it (near the Modules menu).
3. Place every object you want to appear when built, positioned where it should end up.
4. If a built object should rest on the ground, raise it ~1 ft to allow for any suspension/physics settling once the mission loads.
5. Select all the buildable objects, right-click → **Synchronise** them to the Game Logic.
6. In the interaction object's **init field**, call the function:

```sqf
[this, true] call Waldo_fnc_ConstructionObjects;   // modern construction audio
```

The synced objects start hidden and are revealed (with sound + progress bar) when a player completes the build action.

## Examples

```sqf
[this] call Waldo_fnc_ConstructionObjects;        // old wooden-sounding construction audio
[this, true] call Waldo_fnc_ConstructionObjects;  // modern construction audio
```

Below is an example of the construction script correctly set up. The ammo box is the object the player interacts with:
![Picture of the construction script in the editor](https://i.imgur.com/gYf9HQq.png)

## See also

* [Mobile Command Post](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mobile-Command-Post-With-Integrated-Logistics-System) — deploy/tear-down command post using the same synced-Logic pattern
* [Automatic Fortify Setup](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Automatic-ACE-Fortify-Setup) — full ACE Fortify base-building
* [Simple Mass Attach Items](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Simple-Mass-Attach-Items)
