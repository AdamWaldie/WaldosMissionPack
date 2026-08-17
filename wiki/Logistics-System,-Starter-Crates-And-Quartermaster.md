# Logistics, Starter Crates, and Quartermaster

> **Use this page when:** you need mission-derived supply crates, limited arsenals, or quartermaster logistics.

_Associated Files: `MissionScripts\Logistics\Crates`_

WMP's logistics system builds itself from your mission's own playable loadouts, rather than a
hand-authored equipment list you have to keep in sync. It recursively scans every playable unit
(including those inside Eden organiser folders, nested folders included) and builds a unique list
of gear per side. That list then powers everything below: supply crates, medical crates, starter
crates, limited arsenals, the Mobile Command Post, and the Logistics Quartermaster.

The initial scrape call lives in `initServer.sqf`:

![Loadout scrape call in initServer.sqf](https://i.imgur.com/zgkHsqA.png)

## The two rules

For the logistics system to work at all:

1. The mission must **not** be binarized (Eden → Properties → uncheck **Binarize the Scenario File**).
2. Player loadouts must be customised through ACE Arsenal, not left as default unit kits - a default
   kit produces empty or incomplete crates.

## What it provides

* Automated supply, medical, and starter crates built from player loadouts.
* A Logistics Quartermaster NPC/object players can request supplies, medical supplies, and vehicle
  spare parts from.
* A limited ACE Arsenal restricted to whatever the mission actually loads out.
* Mobile Command Post / MHQ integration, so the MHQ can double as a Quartermaster.

## Starter crates

Turns an object's inventory into a starter kit: players can save their respawn loadout there and,
if enabled, use a limited or unrestricted arsenal.

```sqf
[this, true, west, false] spawn Waldo_fnc_DoStarterCrate;
```

| # | Parameter | Type | Meaning |
|---|---|---|---|
| 0 | `_target` | OBJECT | The object to turn into a starter crate. |
| 1 | `_arsenal` | BOOL | Whether to add an ACE/vanilla arsenal. |
| 2 | `_crateSide` | SIDE (default `west`) | Which side's equipment pool the crate/arsenal draws from. |
| 3 | `_unrestrictedArsenal` | BOOL (default `false`) | `true` = full ACE Arsenal; `false` = limited to the mission's own loadout pool. |

Sets up: a linked ACE/vanilla action for saving the respawn loadout, a limited ACE Arsenal
(restricted to `mission.sqm`'s gear), and full supplies (medical and standard, also
`mission.sqm`-bound).

## Supply crate

Populates a crate with weapons, ammo, and equipment drawn from the mission's own loadouts.

```sqf
[this, 1, west, false, false] spawn Waldo_fnc_SupplyCratePopulate;
```

| # | Parameter | Type | Meaning |
|---|---|---|---|
| 0 | `_crate` | OBJECT | The crate to populate. |
| 1 | `_scalar` | NUMBER (default `1`) | Multiplier for the medical supply complement. |
| 2 | `_crateSupplySide` | SIDE (default `west`) | Which side's loadouts to draw from. |
| 3 | `_weaponsAttachmentsUniforms` | BOOL (default `false`) | Add weapons, attachments, equipment and clothing. |
| 4 | `_includeLaunchersAndLauncherAmmo` | BOOL (default `false`) | Add launchers and their ammo. |

## Medical crate

Populates an advanced medical crate, with the option to also act as a field hospital.

```sqf
[this, true, 1] call Waldo_fnc_MedicalCratePopulate;
```

| # | Parameter | Type | Meaning |
|---|---|---|---|
| 0 | `_crate` | OBJECT | The crate to populate. |
| 1 | `_isFacility` | BOOL (default `true`) | Grants the locational medical-skill boost when ACE Medical is loaded - installs a small "Field Hospital Info" interaction on the crate so players can see it grants the boost without opening its inventory. |
| 2 | `_scale` | NUMBER (default `1`) | Multiplier for the medical supply complement. |

## Limited arsenal

Creates an ACE Arsenal on an object, restricted to equipment drawn from the mission's own loadouts.

```sqf
[this, west, false] spawn Waldo_fnc_CreateLimitedArsenal;
```

| # | Parameter | Type | Meaning |
|---|---|---|---|
| 0 | `_target` | OBJECT | The object to turn into a limited arsenal. |
| 1 | `_crateSupplySide` | SIDE (default `west`) | Which side's loadouts to draw from. |
| 2 | `_preExisting` | BOOL (default `false`) | `true` if an ACE Arsenal already exists on this object. |

## Logistics Quartermaster

The Quartermaster is an object or NPC where players request supply boxes and vehicle spare parts.
Use the **Logistics Spawner Example** composition for a ready-made point, or paste one of the calls
below into an object's Eden **Init** field. A standalone Quartermaster becomes available
immediately; its server state and each player's local interaction are installed automatically, so
do not wrap the call in `isServer`.

Every point also has a WMP-blue **Logistics Quartermaster** informational action. With ACE loaded,
actual crate retrieval is under **ACE Interact > Logistics Quartermaster**. Without ACE, the
retrieval choices appear directly in Arma's action menu.

### Reading the call

`[target, spawn bearing, spawn distance, deployment controlled] call Waldo_fnc_SetupQuarterMaster;`

| Position | Beginner meaning | Default |
|---|---|---|
| `target` | Object players interact with. In its own Init field, use `this`. | Required |
| `spawn bearing` | Direction relative to the object: `0` front, `90` right, `180` rear, `270` left. | `90` |
| `spawn distance` | Starting distance from the object in metres. | `2` |
| `deployment controlled` | Leave `false` for a normal always-available point. WMP's MHQ passes `true` internally because deploying the command post controls access. | `false` |

The simplest standalone setup is:

```sqf
[this] call Waldo_fnc_SetupQuarterMaster;
```

This example places requested crates four metres behind the interaction point:

```sqf
[this, 180, 4] call Waldo_fnc_SetupQuarterMaster;
```

The fourth argument exists for systems that own deployment state. Normal mission makers should not
set it to `true`: doing so deliberately hides retrieval actions until another server-owned system
activates the Quartermaster.

## What the Quartermaster spawns

| ACE Interaction | Contents | Notes |
|---|---|---|
| **Medical Box** | ACE medical supplies (if ACE Medical loaded), or vanilla medical supplies | Marked as ACE field hospital; draggable/carryable |
| **Supply Box** | All weapons, ammo, attachments, equipment from mission loadouts (full side complement) | |
| **Ammo Box** | Ammo only (0.75× scale supply, no weapons or equipment) | |
| **ACE Wheel** | `ACE_Wheel` - spare vehicle wheel | |
| **ACE Track** | `ACE_Track` - spare vehicle track | |

The Quartermaster prevents duplicates: if a box of the same type already exists within 5 m of the
spawn point, a new one is not spawned, and the QM says so.

## Changing the boxes the Quartermaster spawns

Set the classnames in `initServer.sqf`:

![Picture displaying the appropriate place in initServer.sqf to change the boxes](https://i.imgur.com/0CdEY8U.png)

- **`Logi_SupplyBoxClass`** - the class of box spawned for supply and ammo requests.
- **`Logi_MedicalBoxClass`** - the class of box spawned for medical requests.

```sqf
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
