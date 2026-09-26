# Logistics and loadout-derived crates

> **Use this page when:** you want WMP to build starter, supply or medical crates from the equipment in your mission's playable units.

WMP reads playable unit loadouts from `mission.sqm` and builds a pool for each side. Supply crates, medical crates, starter crates, limited arsenals, the [Quartermaster](Quartermaster) and the [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System) use that pool. WMP starts the scan during mission setup; you do not need to add a scan call.

## Before you place a crate

1. In Eden, turn off **Binarize the Scenario File**. WMP needs a readable `mission.sqm`.
2. Give playable units the gear you want the crates to offer. Use ACE Arsenal to save custom loadouts before you save the mission.
3. Keep the pack's shipped init files. [Quickstart](Quickstart-Guide) covers installation and the first multiplayer preview.

If a box comes out empty, check those three steps before changing script arguments. A side's box only uses that side's loadout pool.

## Starter crate

A starter crate lets players save a respawn loadout and, when selected, use a limited or unrestricted arsenal. Place a suitable inventory object and put this in its Eden **Init** field:

```sqf
[this, true, west, false] spawn Waldo_fnc_DoStarterCrate;
```

| Position | Type | Default | Meaning |
|---|---|---|---|
| 0 | Object | Required | The starter crate. |
| 1 | Boolean | `false` | Add an arsenal when `true`. |
| 2 | Side | `west` | Which side's loadout pool it uses. |
| 3 | Boolean | `false` | Give the full ACE Arsenal when `true`; otherwise limit it to mission gear. |

The function sets up the crate's contents and player actions. Starter crates stay in place: WMP disables ACE Drag, Carry and loading into ACE Cargo. The Init call is an asynchronous `spawn`, so it does not return a useful crate result to the Init field.

## Supply crate

Put this in a placed crate's Eden **Init** field to stock it from the west-side loadout pool:

```sqf
[this, 1, west, false, false] spawn Waldo_fnc_SupplyCratePopulate;
```

| Position | Type | Default | Meaning |
|---|---|---|---|
| 0 | Object | Required | The crate to stock. |
| 1 | Number | `1` | Multiplier for its medical supply complement. |
| 2 | Side | `west` | Side whose loadouts supply the contents. |
| 3 | Boolean | `false` | Also include weapons, attachments, equipment and clothing. |
| 4 | Boolean | `false` | Also include launchers and launcher ammunition. |

WMP gives ordinary supplied crates ACE Drag and Carry and an ACE cargo size of one. If [Supply Transfers](Supply-Transfers) is enabled, it also registers them for crate logistics. This is an asynchronous setup call; use a mission preview to inspect its contents.

## Medical crate

Put this in a placed crate's Eden **Init** field:

```sqf
[this, true, 1] call Waldo_fnc_MedicalCratePopulate;
```

| Position | Type | Default | Meaning |
|---|---|---|
| 0 | Object | Required | The crate to stock. |
| 1 | Boolean | `true` | Mark it as an ACE medical facility when ACE Medical is loaded. |
| 2 | Number | `1` | Multiplier for the medical supply complement. |

The facility option adds a **Field Hospital Info** action so players can see the medical benefit. WMP uses vanilla medical supplies when ACE Medical is unavailable. Keep a reference to the Eden object; this call does not return a stable crate handle.

## Limited arsenal

Put this in a placed object's Eden **Init** field to offer the west-side mission gear through ACE Arsenal:

```sqf
[this, west, false] spawn Waldo_fnc_CreateLimitedArsenal;
```

| Position | Type | Default | Meaning |
|---|---|---|---|
| 0 | Object | Required | Object that hosts the arsenal. |
| 1 | Side | `west` | Side whose mission loadout pool supplies available gear. |
| 2 | Boolean | `false` | Set `true` if this object already has an ACE Arsenal. |

The Init call starts the setup asynchronously. Inspect the arsenal in a multiplayer preview before handing the mission to players.

## Settings: crate models and other issue points

The general supply spawner uses `Logi_SupplyBoxClass` from the **server** rows in `MissionConfig/logisticsConfig.sqf`. It defaults to `B_supplyCrate_F`. WMP chooses the medical class automatically: `ACE_medicalSupplyCrate_advanced` with ACE Medical, or `C_IDAP_supplyCrate_F` without it. Leave that conditional default alone unless your mission needs a tested override.

The [Quartermaster](Quartermaster) has separate `Waldo_QM_*_CrateClass` rows for each issue type. Change those rows in `MissionConfig/logisticsConfig.sqf` when you want a different issue model. The [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System) can offer Quartermaster issues when deployed.

ZEN supply and medical crate modules use WMP's crate contents and ACE handling. Their controls are listed under [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules). Mission-placed crates need one of the Init calls above.

## If a crate does not work

- **Empty contents:** Check unbinarized `mission.sqm`, playable loadouts and the selected side.
- **No arsenal action:** Check the second starter-crate argument or the limited-arsenal call, then check that ACE Arsenal is loaded.
- **No Carry or Drag:** Starter crates intentionally have neither. For other crates, check the ACE object settings with [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling).
- **Wrong box model:** Check the issue-specific Quartermaster setting first, or `Logi_SupplyBoxClass` for a general supply crate.

## See also

- [Quartermaster](Quartermaster)
- [Supply Transfers](Supply-Transfers)
- [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling)
- [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
