# Field Resupply

> **Use this page when:** a squad should carry a limited number of mission-loadout-derived resupply crates and refill that allowance at a hub.

Field Resupply gives a designated carrier a crate allowance. The carrier deploys a real supply crate. Players take its contents through ordinary inventory or ACE interactions. A hub refills the allowance. It does not invent ammunition outside the loadouts of playable units on the servicing side.

## Before you start

Field Resupply is enabled in the shipped `MissionConfig/logisticsConfig.sqf`, but does nothing until you place a hub and assign a carrier. ACE provides the preferred interactions. The `[WMP]Field_Resupply_Hub_Example` composition contains both parts if you want an Eden example.

## Set up a hub and carrier

1. Place an ammo point or other hub object in Eden. Put this in its **Init** field:

   ```sqf
   [this, west, -1] call Waldo_fnc_FieldResupplyRegisterHub;
   ```

2. Place a playable unit in its normal side and group. Give it a backpack. Put this in the unit's **Init** field:

   ```sqf
   [this, 3, 3] call Waldo_fnc_FieldResupplyAssignCarrier;
   ```

3. In the mission, use **Check Resupply Crates** at the hub, then **Deploy Field Resupply** while on foot. Open the deployed crate through inventory or ACE. Zeus can also register a hub or assign a carrier through the Field Resupply modules.

The public calls route authoritative changes to the server. WMP installs client interactions for current players and joiners. Each hub's side controls which loadout pool supplies its crates. `"ALL"` accepts every side.

## Calls and settings

`Waldo_fnc_FieldResupplyRegisterHub` takes `[hub object, serviced side, stock]`. Stock `-1` is unlimited; a non-negative number is finite. `Waldo_fnc_FieldResupplyAssignCarrier` takes `[unit, starting crates, maximum crates]`. Use `[_carrier, _amount, _expandCapacity] call Waldo_fnc_FieldResupplyGrantCrates` to grant more. The final argument defaults to `false`, which keeps the carrier's current capacity limit; `true` expands it. The server validates requests and informs the affected player.

Edit these existing rows in `MissionConfig/logisticsConfig.sqf` before mission start:

| Setting | Shipped value | What it changes |
|---|---|---|
| `Waldo_FieldResupply_Enable` | `true` | Allows hubs and carrier actions; set `false` to disable the feature. |
| `Waldo_FieldResupply_CrateClass` | `Box_NATO_Ammo_F` | Class of deployed crate. Use a valid inventory container. |
| `Waldo_FieldResupply_DefaultCarrierCapacity` | `2` | Maximum when assignment omits a capacity. |
| `Waldo_FieldResupply_CrateSizeScalar` | `1` | Multiplier for generated contents. |
| `Waldo_FieldResupply_IncludeWeaponsAttachments` | `false` | Add weapons, attachments and clothing as well as ammunition. |
| `Waldo_FieldResupply_IncludeLaunchers` | `false` | Include launchers and their ammunition. |
| `Waldo_FieldResupply_RetainOnRespawn` | `true` | Keep carrier status and allowance after respawn. |

## Salvage and troubleshooting

An unused crate can be salvaged back into the carrier's allowance. WMP compares its actual inventory with the snapshot taken when it was deployed. A crate that has been used or filled with other items cannot be salvaged. If deployment reports no supplies, check that the hub services the intended side and that the mission has playable-unit loadouts for it. If the action is missing, check the enable flag, backpack, carrier assignment and whether the player is on foot.

## See also

- [Logistics and loadout-derived crates](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Supply Transfers](Supply-Transfers)
- [Optional Feature Extensions](Optional-Feature-Extensions) for additional stock and lifecycle detail

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
