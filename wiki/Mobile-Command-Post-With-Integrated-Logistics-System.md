# Mobile Command Post

> **Use this page when:** you need to configure, deploy, tear down, or troubleshoot an MHQ with logistics.

_Associated Files: `MissionScripts\Logistics\MHQ\MHQSetup.sqf`, `Waldo_fnc_MHQSetup`_

A Mobile Headquarters (MHQ) turns a vehicle or static object into a deployable field respawn point,
optionally paired with the [logistics quartermaster system](Logistics-System,-Starter-Crates-And-Quartermaster).
Players deploy it on request wherever they are, and undeploy it again to pack up and move on.

## Setup in Eden

1. Place the vehicle or object that should become the deployable respawn, and give it a variable
   name. This is the MHQ.
2. Place a **Game Logic** as close as possible to the MHQ (same editor category as Modules).
3. Place any objects that should appear when the MHQ deploys - tents, crates, whatever the field
   setup should look like. Leave roughly 3 m clear to the left of the primary object so players have
   room to actually respawn there.
4. If the MHQ is a vehicle and any deployable objects should end up resting on the ground, raise
   them about a foot in Eden. This accounts for the vehicle's suspension settling once the mission
   loads.
5. Select every deployable object, right-click, and synchronize them all to the Game Logic.
6. In the MHQ's **Initialization** field:
   ```sqf
   [this] call Waldo_fnc_MHQSetup;
   ```
7. (Optional) The script defines an array of random Command Post names. Add your own, trim it down,
   or leave it as shipped - it's a plain array of strings passed to `selectRandom`.

## What it does

- Works with any vehicle or static object. A vehicle keeps its synced objects attached while it
  moves; a static object's deployment stays put.
- Generates a randomized Command Post name and map marker on deployment.
- Sets the respawn side to whichever side deployed it.
- Optionally deploys logistics supplies alongside the MHQ when the
  [logistics system](Logistics-System,-Starter-Crates-And-Quartermaster) is enabled.

## Parameters

| # | Name | Type | Meaning |
|---|---|---|---|
| 0 | `_target` | OBJECT | The vehicle or object to use as the MHQ. |
| 1 | `_constructionAudio` | BOOL (default `false`) | `true` plays modern construction sounds on deploy/undeploy; `false` plays the older wooden-construction sounds. |
| 2 | `_logistics` | BOOL (default `false`) | `true` enables the logistics quartermaster spawner alongside this MHQ. |
| 3 | `_logisticsDirection` | NUMBER (default `180`) | Bearing of the logistics spawner relative to the vehicle's own heading, not compass north - `0` front, `90` right, `180` rear, `270` left. Only matters when `_logistics` is `true`. |
| 4 | `_logisticsDistance` | NUMBER (default `4`) | Distance in metres from the vehicle to the logistics spawner. Only matters when `_logistics` is `true`. |

```sqf
// Default - no modern audio, no logistics:
[this] call Waldo_fnc_MHQSetup;

// Modern construction audio:
[this, true] call Waldo_fnc_MHQSetup;

// Logistics enabled, spawner 4 m behind the vehicle:
[this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
```

Below is a properly set-up MHQ using a Halftrack as the interaction object:

![MHQ example](https://i.imgur.com/Rz9KwXL.png)

## Changing the crates the quartermaster spawns

Set the classnames in `initServer.sqf`:

![Picture displaying the appropriate place in initServer.sqf to change the boxes](https://i.imgur.com/0CdEY8U.png)

- **`Logi_SupplyBoxClass`** - the crate spawned for ammo/resupply.
- **`Logi_MedicalBoxClass`** - the crate spawned for medical supplies.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
