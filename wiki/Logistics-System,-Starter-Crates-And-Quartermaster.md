# Logistics, Starter Crates, and Quartermaster

> **Use this page when:** setting up mission-derived supply crates, an arsenal or a Quartermaster.

WMP scans your mission's playable units, including units in nested Eden folders, and builds an equipment pool for each side. Supply crates, medical crates, starter crates, limited arsenals, the Mobile Command Post and the Quartermaster use that pool.

The pack already starts the scan from `initServer.sqf`. You do not need to add another scan call:

![Loadout scrape call in initServer.sqf](https://i.imgur.com/zgkHsqA.png)

## Before you place a supply point

1. Turn off **Binarize the Scenario File** in Eden Properties. WMP needs the readable `mission.sqm`.
2. Customise player loadouts through ACE Arsenal. Default unit kits produce empty or incomplete crates.

## What it provides

* Automated supply, medical, and starter crates built from player loadouts.
* A Quartermaster NPC/object players can request supplies, medical supplies, and vehicle
  spare parts from.
* A limited ACE Arsenal restricted to the mission's playable loadouts.
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
Starter crates stay in place: WMP disables ACE Drag, Carry and loading into ACE Cargo on them.

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
All ten issue types are on by default.

Place **[WMP] Quartermaster (Minimal)** from Eden's WMP
Logistics category for a ready-to-use point. The **Full** version shows how to change where boxes
spawn. Their source folders retain the older `Logistics_Spawner` names for compatibility.

To turn an object you placed into a Quartermaster, put this in its Eden **Init** field:

```sqf
[this] call Waldo_fnc_SetupQuarterMaster;
```

WMP installs the server state and each player's interaction. Do not wrap this call in `isServer`.

Every point also has a WMP-blue **Quartermaster** informational action. With ACE loaded,
actual crate retrieval is under **ACE Interact > Quartermaster**. Without ACE, the
retrieval choices appear directly in Arma's action menu.

Standalone points show a 3D **Quartermaster** label on the object. Set
`Waldo_QM_Marker_Enable` to `false` in `MissionConfig/logisticsConfig.sqf` to hide that label.
This does not disable the point or its ACE actions. The label follows a moved object.

### Reading the call

`[target, spawn bearing, spawn distance, deployment controlled] call Waldo_fnc_SetupQuarterMaster;`

| Position | Beginner meaning | Default |
|---|---|---|
| `target` | Object players interact with. In its own Init field, use `this`. | Required |
| `spawn bearing` | Direction relative to the object: `0` front, `90` right, `180` rear, `270` left. | `90` |
| `spawn distance` | Starting distance from the object in metres. | `2` |
| `deployment controlled` | Leave `false` for a normal always-available point. WMP's MHQ passes `true` internally because deploying the command post controls access. | `false` |

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
| **Grenades Box** | Eligible throwable magazines from this side's playable loadouts | On by default; `Waldo_QM_Grenades_Enable` |
| **Explosives Box** | Eligible mines and charges from this side's playable loadouts | On by default; `Waldo_QM_Explosives_Enable` |
| **Rearm Box** | Empty inventory box that acts as an ACE rearm source | On by default; `Waldo_QM_Rearm_Enable` |
| **Fuel Barrel** | ACE fuel source with a configured litre limit | On by default; `Waldo_QM_FuelBarrel_Enable` |
| **Fuel Jerrycan** | ACE jerrycan with a configured litre limit | On by default; `Waldo_QM_FuelJerrycan_Enable` |

All ten Quartermaster issue types are on by default in a new mission. Turn off unwanted types in
`MissionConfig/logisticsConfig.sqf`. That file also sets quantities. Existing missions with their
own copied config retain their chosen values. ACE supplies the rearm and refuel mechanics.

The older vehicle and static rearm flags both feed the single Rearm Box option. ACE groups the
actions under infantry supplies, vehicle support and fuel.

The progress bar lasts five seconds and names the requested issue. The spawned object's ACE cargo
name carries the same label. Grenades use a small ammo box, explosives an ordnance box, and rearm a
vehicle-ammo box.

Players can drag or carry Quartermaster issues regardless of ACE's weight limit. Each takes one
ACE cargo slot when loaded into a vehicle. WMP ZEN-spawned crates use the same handling defaults.

Each issue has an availability flag. WMP clears ordinary inventory from the Rearm Box. The box
has a status action outside ACE. In ACE's Limited
Supply mode, it shows the remaining points and changes to **Rearm supply exhausted** at zero.
`Waldo_QM_Rearm_Supply` gives each box 1200 points by default. The older static-only issue uses
250 points by default.

ACE's Unlimited mode makes the Rearm Box unlimited and its status action says so. WMP leaves the
mission's ACE Rearm mode unchanged.

ACE's Specific Magazines mode needs stocked magazine classes. The empty Quartermaster issue is
unavailable in that mode. Set the ACE Rearm supply mode in your mission's addon settings before
using the issue.

For crate merging, selective transfers, empty removal and per-crate ACE loading control, enable [Supply Transfers](Supply-Transfers). Physical mounting remains a [separate feature](Physical-Cargo).

For the five established issues, the Quartermaster prevents duplicates within 5 m of its spawn point. The five additional issues rely on clear-space placement and do not use that legacy duplicate check.

## Changing the boxes the Quartermaster spawns

Set crate classes in `MissionConfig/logisticsConfig.sqf`. Ammo and heavy supply default to `B_supplyCrate_F`. Grenades use `Box_NATO_Ammo_F`, explosives use `Box_NATO_AmmoOrd_F`, and rearm uses `Box_NATO_AmmoVeh_F`.

Choose classes through `Waldo_QM_Ammo_CrateClass`, `Waldo_QM_Supply_CrateClass`, `Waldo_QM_Grenades_CrateClass`, `Waldo_QM_Explosives_CrateClass` and `Waldo_QM_Rearm_CrateClass`. The legacy vehicle and static rearm class keys remain for direct scripted calls. The player-facing quartermaster has one Rearm Box action. An empty `Waldo_QM_Medical_CrateClass` retains the ACE-aware `Logi_MedicalBoxClass` default. WMP rejects unavailable classes.

The older mission-level class controls remain available for general spawners:

![Picture displaying the appropriate place in initServer.sqf to change the boxes](https://i.imgur.com/0CdEY8U.png)

- **`Logi_SupplyBoxClass`** - the class of box spawned for supply and ammo requests.
- **`Logi_MedicalBoxClass`** - the class of box spawned for medical requests.

```sqf
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

Place ZEN **Quartermaster - Set Up Object** directly on the intended object. The dialog sets spawn bearing (0-359 degrees relative to the object), distance (2-12 m), deployment gating and the issues offered there. Leave **Deployment controlled** unchecked for a standalone laptop. An MHQ-style controller must activate a gated point. ZEN remembers settings when you edit the same point again. A global issue flag still wins over a checked ZEN box.

For mission-wide class, quantity or availability changes, edit `MissionConfig/logisticsConfig.sqf`.
Select **ACE rearm box** in ZEN to offer it at a point. `Waldo_QM_Rearm_CrateClass` and
`Waldo_QM_Rearm_Supply` set its class and capacity.

With `Waldo_SupplyTransfers_Enable` on, WMP-issued quartermaster crates receive [crate logistics actions](Supply-Transfers). Starter crates do not. ZEN **Supply Transfers - Register or Inspect** can register a mission-placed box or cargo-capable vehicle. Registered vehicles get the same source, selective transfer and merge workflow as crates.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
