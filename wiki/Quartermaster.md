# Quartermaster

> **Use this page when:** you want players to request mission-derived supply crates, spare parts, ACE rearm boxes or fuel from an object in your mission.

A Quartermaster is an object or NPC with issue actions. WMP reads the playable units' loadouts for the supply categories, so the contents follow the mission instead of a fixed template. Players use **ACE Interact > Quartermaster** when ACE is loaded. WMP provides ordinary Arma actions when ACE Interact is unavailable.

## Before you start

1. Keep `mission.sqm` unbinarized. WMP needs to read the playable units in that file.
2. Give playable units the equipment you want WMP to issue. Set their loadouts through ACE Arsenal before saving the mission.
3. Leave `Waldo_Quartermaster_Enable` on in `MissionConfig/logisticsConfig.sqf`. It is on by default.
4. Load ACE for ACE-specific issues such as wheels, tracks, fuel and rearm boxes.

WMP sets up the point on the server and installs actions on each player's machine, including players who join later. A Quartermaster creates no issues until a player requests one.

## Place a working Quartermaster

The quickest Eden setup is the **[WMP] Quartermaster (Minimal)** composition. Place it, start the mission and interact with its object. The **Full** composition includes a worked spawn-position example.

For your own object, put this in its Eden **Init** field:

```sqf
[this] call Waldo_fnc_SetupQuarterMaster;
```

Use `this` only in the object's own Init field. Do not add an `isServer` wrapper: the function handles server state and each player's local actions. If issued objects need a different spawn position, put this in the same field instead:

```sqf
[this, 180, 4] call Waldo_fnc_SetupQuarterMaster;
```

That places issues about four metres behind the point. Check the position in multiplayer so crates have room to spawn and players can reach them. A standalone point has an object-following 3D label. Set `Waldo_QM_Marker_Enable` to `false` in `MissionConfig/logisticsConfig.sqf` to hide only the label.

## Choose the issues

All ten normal issue types are on by default. Disable an unwanted `Waldo_QM_*_Enable` row in `MissionConfig/logisticsConfig.sqf`. The ZEN **Quartermaster - Set Up Object** module can narrow the choices at one point. It cannot re-enable a type disabled for the mission.

| Issue | What players receive | Main setting |
|---|---|---|
| Medical Box | ACE or vanilla medical supplies, depending on loaded addons | `Waldo_QM_Medical_Enable` |
| Heavy Supply Box | Weapons, ammunition and equipment from the mission's playable loadouts | `Waldo_QM_Supply_Enable` |
| Ammo Box | Ammunition from those loadouts | `Waldo_QM_Ammo_Enable` |
| ACE Wheel | Spare wheel | `Waldo_QM_Wheel_Enable` |
| ACE Track | Spare track | `Waldo_QM_Track_Enable` |
| Grenades Box | Eligible throwable magazines from the chosen side | `Waldo_QM_Grenades_Enable` |
| Explosives Box | Eligible mines and charges from the chosen side | `Waldo_QM_Explosives_Enable` |
| Rearm Box | Empty inventory box that supplies ACE rearming | `Waldo_QM_Rearm_Enable` |
| Fuel Barrel | ACE fuel source | `Waldo_QM_FuelBarrel_Enable` |
| Fuel Jerrycan | ACE fuel source | `Waldo_QM_FuelJerrycan_Enable` |

The two older vehicle/static rearm flags are compatibility settings. The player menu has one **Rearm Box** for both vehicles and static weapons. The issue takes five seconds and the progress bar names the requested object.

## Change crate models and quantities

Edit the existing rows in `MissionConfig/logisticsConfig.sqf`. Do not copy them into `initServer.sqf`.

| Setting | Default | Result |
|---|---|---|
| `Waldo_QM_Ammo_CrateClass` | `B_supplyCrate_F` | Model for the Ammo Box. |
| `Waldo_QM_Supply_CrateClass` | `B_supplyCrate_F` | Model for the Heavy Supply Box. |
| `Waldo_QM_Medical_CrateClass` | Empty | Uses WMP's ACE-aware medical crate choice. Set a valid class to override it. |
| `Waldo_QM_Grenades_CrateClass` | `Box_NATO_Ammo_F` | Model for the Grenades Box. |
| `Waldo_QM_Explosives_CrateClass` | `Box_NATO_AmmoOrd_F` | Model for the Explosives Box. |
| `Waldo_QM_Rearm_CrateClass` | `Box_NATO_AmmoVeh_F` | Model for the Rearm Box. |
| `Waldo_QM_Grenades_CountPerType` | `20` | Number of each eligible grenade magazine. |
| `Waldo_QM_Explosives_CountPerType` | `8` | Number of each eligible mine or charge. |
| `Waldo_QM_FuelBarrel_Litres` | `200` | Fuel in each barrel. |
| `Waldo_QM_FuelJerrycan_Litres` | `20` | Fuel in each jerrycan. |

Choose a crate class that exists in the mission's loaded addons. The `Logi_SupplyBoxClass` server row in the same file controls the general supply spawner. Change an issue-specific `Waldo_QM_*_CrateClass` row when only that Quartermaster issue needs a different model. WMP chooses `Logi_MedicalBoxClass` automatically unless you set an explicit medical override.

The Rearm Box has no ordinary inventory contents. In ACE **Limited Supply** mode, `Waldo_QM_Rearm_Supply` gives it 1200 points by default. Its status action shows remaining points and changes when the supply runs out. In ACE **Unlimited** mode, ACE ignores that value and the status action says the box is unlimited. The empty issue is unavailable in ACE **Specific Magazines** mode. Set the ACE rearm mode in your mission's addon settings.

WMP gives issued objects ACE Drag and Carry where appropriate and sets their ACE cargo size to one. [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling) explains how to inspect or change an individual object's settings.

## Script and ZEN controls

`[target, spawn bearing, spawn distance, deployment controlled] call Waldo_fnc_SetupQuarterMaster;`

| Position | Type | Default | Meaning |
|---|---|---|---|
| 0 | Object | Required | The object players use. |
| 1 | Number | `90` | Issue direction relative to the object: `0` front, `90` right, `180` rear, `270` left. |
| 2 | Number | `2` | Starting issue distance in metres. |
| 3 | Boolean | `false` | Reserve `true` for a system such as the MHQ that controls when issues are available. |

The call returns `true` when WMP accepts the object. Eden Init fields, compositions, the MHQ and ZEN use it. A repeat call updates the point without duplicating its actions. For an always-available standalone Quartermaster, leave the fourth argument out.

Place ZEN **Quartermaster - Set Up Object** directly on an existing object. The dialog sets issue direction, distance, deployment control and the types offered at that point. For mission-wide issue classes, quantities or availability, edit `MissionConfig/logisticsConfig.sqf` instead.

An MHQ can host the same issues while deployed. Follow the [Mobile Command Post setup](Mobile-Command-Post-With-Integrated-Logistics-System) for that case.

## If something does not appear

- **No interaction:** Check the feature flag, the object's Init call and whether the object exists when the mission starts. If the point is MHQ-controlled, deploy the MHQ first.
- **Empty or incomplete supply box:** Check playable unit loadouts, the requested side and the unbinarized `mission.sqm`.
- **An issue is missing:** Check its mission-wide enable flag, the point's ZEN selection and its ACE dependency.
- **A crate model is rejected:** Check the issue-specific classname against loaded `CfgVehicles` classes.
- **A rearm box does not issue:** Check ACE Rearm's supply mode. An empty box cannot serve Specific Magazines mode.

With `Waldo_SupplyTransfers_Enable` on, issued crates also get [Supply Transfers](Supply-Transfers) actions. Starter crates are excluded. [Physical Cargo](Physical-Cargo) handles visible mounting separately.

## See also

- [Logistics and loadout-derived crates](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System)
- [Supply Transfers](Supply-Transfers)
- [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
