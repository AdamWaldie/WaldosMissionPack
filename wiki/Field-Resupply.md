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

`Waldo_fnc_FieldResupplyRegisterHub` registers or updates a refill point:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing world object players will use as the hub. |
| 1 | Side or string | `"ALL"` | A side such as `west`, or `"ALL"` for every side. |
| 2 | Number | `-1` | Number of crates available. `-1` means unlimited; zero means empty. WMP rounds finite values to whole crates. |

It returns `true` when the server accepts the registration. An Eden Init field also runs on clients; those duplicate calls do no work. The server publishes the hub state and client action for players who join later.

`Waldo_fnc_FieldResupplyAssignCarrier` gives a unit an allowance:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Infantry unit (`CAManBase`) that will deploy crates. |
| 1 | Number | `1` | Starting crates, rounded to a whole number and capped by the maximum. |
| 2 | Number | `2` | Maximum crates the unit may hold. |

It returns `true` when the server accepts the assignment. If `Waldo_FieldResupply_RetainOnRespawn` is on, WMP transfers the allowance to the replacement unit and reinstalls its action.

To grant more during play, call `[carrier, 2, false] call Waldo_fnc_FieldResupplyGrantCrates` from a server script:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Living, assigned infantry carrier. |
| 1 | Number | `1` | Number of crates to add, rounded to a whole number. |
| 2 | Boolean | `false` | Set `true` to raise the carrier's capacity enough to fit the whole grant. |

The server returns the number actually granted, which may be lower when capacity is full. A client call forwards the request and returns `-1` before the server processes it. The server validates each grant and informs the affected player.

Edit these existing rows in `MissionConfig/logisticsConfig.sqf` before mission start:

| Setting | Type | Shipped value | What it changes |
|---|---|---|---|
| `Waldo_FieldResupply_Enable` | Boolean | `true` | Allows hubs and carrier actions; set `false` to disable the feature. |
| `Waldo_FieldResupply_CrateClass` | CfgVehicles classname string | `"Box_NATO_Ammo_F"` | Class of deployed crate. Use a valid inventory container. |
| `Waldo_FieldResupply_DefaultCarrierCapacity` | Number, crates | `2` | Maximum when assignment omits a capacity. |
| `Waldo_FieldResupply_CrateSizeScalar` | Number, multiplier | `1` | Multiplier for generated contents. |
| `Waldo_FieldResupply_IncludeWeaponsAttachments` | Boolean | `false` | Add weapons, attachments and clothing as well as ammunition. |
| `Waldo_FieldResupply_IncludeLaunchers` | Boolean | `false` | Include launchers and their ammunition. |
| `Waldo_FieldResupply_RetainOnRespawn` | Boolean | `true` | Keep carrier status and allowance after respawn. |

## Salvage and troubleshooting

An unused crate can be salvaged back into the carrier's allowance. WMP compares its actual inventory with the snapshot taken when it was deployed. A crate that has been used or filled with other items cannot be salvaged. If deployment reports no supplies, check that the hub services the intended side and that the mission has playable-unit loadouts for it. If the action is missing, check the enable flag, backpack, carrier assignment and whether the player is on foot.

## See also

- [Logistics and loadout-derived crates](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Supply Transfers](Supply-Transfers)
- [Optional Feature Extensions](Optional-Feature-Extensions) for additional stock and lifecycle detail

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
