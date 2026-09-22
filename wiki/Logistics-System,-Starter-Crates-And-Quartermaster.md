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
| **Heavy Supply Box** | All weapons, ammo, attachments, equipment from mission loadouts (full side complement) | |
| **Ammo Box** | Ammo only (0.75× scale supply, no weapons or equipment) | |
| **ACE Wheel** | `ACE_Wheel` - spare vehicle wheel | |
| **ACE Track** | `ACE_Track` - spare vehicle track | |
| **Grenades Box** | Eligible throwable magazines from this side's playable loadouts | Opt in with `Waldo_QM_Grenades_Enable` |
| **Explosives Box** | Eligible mines and charges from this side's playable loadouts | Opt in with `Waldo_QM_Explosives_Enable` |
| **Rearm Box** | Finite ACE rearm source for vehicles and static weapons | Opt in with `Waldo_QM_Rearm_Enable` |
| **Fuel Barrel** | ACE fuel source with a configured litre limit | Opt in with `Waldo_QM_FuelBarrel_Enable` |
| **Fuel Jerrycan** | ACE jerrycan with a configured litre limit | Opt in with `Waldo_QM_FuelJerrycan_Enable` |

The five additional issues are off by default. `Waldo_Quartermaster_Enable` remains on for the established issues. Set the flags and quantities in `MissionConfig/logisticsConfig.sqf`. Rearm and refuel use ACE's own source functions and capacity rules. Older `Waldo_QM_VehicleRearm_Enable` and `Waldo_QM_StaticRearm_Enable` settings are accepted as aliases for the one Rearm Box action; they no longer create duplicate options. ACE interaction groups infantry supplies, vehicle support and fuel separately. Progress text uses the selected issue name, and spawned objects receive an ACE cargo name suffix identifying the issue. Grenades use the side's small ammo box, explosives an ordnance box and rearm a vehicle-ammo box; each receives an ACE size suited to the issue.

Each established issue now also has its own availability flag: `Waldo_QM_Medical_Enable`, `Waldo_QM_Ammo_Enable`, `Waldo_QM_Supply_Enable`, `Waldo_QM_Track_Enable` and `Waldo_QM_Wheel_Enable` all default to `true`. New issue flags default to `false`. The rearm box's four ordinary inventory categories are cleared after spawning; its finite ammo is supplied by ACE, not loose magazines inside the crate. A blue **ACE Rearm Source** object action identifies the otherwise empty box and explains its use. Its source capacity depends on the enabled rearm setting (default 1200 for general/vehicle rearm, 250 for static-only legacy configuration).

For crate merging, selective transfers, empty removal and per-crate ACE loading control, enable [Supply Transfers](Supply-Transfers). Physical mounting remains a [separate feature](Physical-Cargo).

For the five established issues, the Quartermaster prevents duplicates within 5 m of its spawn point. The new opt-in issues currently rely on clear-space placement and do not use that legacy duplicate check.

## Changing the boxes the Quartermaster spawns

Set crate classes in `MissionConfig/logisticsConfig.sqf`. The current defaults are `B_supplyCrate_F` for ammo and heavy supply, `Box_NATO_Ammo_F` for grenades, `Box_NATO_AmmoOrd_F` for explosives, and `Box_NATO_AmmoVeh_F` for rearm. Configure them independently with `Waldo_QM_Ammo_CrateClass`, `Waldo_QM_Supply_CrateClass`, `Waldo_QM_Grenades_CrateClass`, `Waldo_QM_Explosives_CrateClass` and `Waldo_QM_Rearm_CrateClass`. The legacy vehicle/static rearm class keys are also present for direct scripted issue calls; the player-facing quartermaster presents one Rearm Box action. `Waldo_QM_Medical_CrateClass` defaults to an empty string, meaning the ACE-aware `Logi_MedicalBoxClass` default is retained. Unavailable configured classes are rejected rather than silently spawning a different object.

The older mission-level class controls remain available for general spawners:

![Picture displaying the appropriate place in initServer.sqf to change the boxes](https://i.imgur.com/0CdEY8U.png)

- **`Logi_SupplyBoxClass`** - the class of box spawned for supply and ammo requests.
- **`Logi_MedicalBoxClass`** - the class of box spawned for medical requests.

```sqf
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

ZEN **Quartermaster - Set Up Object** configures the object directly under the module. Its labelled controls set spawn bearing (0–359° relative to the object), spawn distance (2–12 m), whether another system controls deployment, and which of the ten issue types this particular point offers. An ordinary laptop should leave **Deployment controlled** unchecked; otherwise its retrieval actions wait for an MHQ-style controller. The issue checkboxes are per-point filters: a globally disabled issue cannot be enabled in ZEN. Existing ZEN settings are prefilled on repeat use, and the server applies the validated settings before refreshing client actions. Place no module on empty ground. For a mission-wide class, quantity or availability change, edit `MissionConfig/logisticsConfig.sqf` instead. For example, enable `Waldo_QM_Rearm_Enable` globally and select **ACE rearm box** in ZEN to offer it on one point; `Waldo_QM_Rearm_CrateClass` and `Waldo_QM_Rearm_Supply` set its class and finite ACE capacity.

When `Waldo_SupplyTransfers_Enable` is on, WMP-issued quartermaster crates receive the [crate logistics actions](Supply-Transfers) automatically. Starter crates are excluded. ZEN **Supply Transfers - Register or Inspect** can add a mission-placed box or cargo-capable vehicle independently; on a vehicle it adds a receive-supplies menu, not a second quartermaster.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
