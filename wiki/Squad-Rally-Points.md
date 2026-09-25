# Squad Rally Points

> **Use this page when:** squad leaders need a temporary, group-owned respawn position.

Set `Waldo_Rally_Enable = true` in `MissionConfig\missionSystemsConfig.sqf`, or enable the feature during play with **Respawn - Squad Rally Control**. The current leader of a qualifying group receives controls to deploy or pack its rally. Ownership and cooldown stay with the group if its leader changes.

The server checks that the leader is alive, on foot, on dry and level ground, and outside the hostile exclusion radius. The group must also have enough living members. The server chooses a clear position and adds a group-scoped respawn point. Only current group members see the rally marker. Destroying, packing, or disabling the rally removes its object, respawn point, and marker. They also disappear when the rally expires.

## Settings

Edit the existing rows in `MissionConfig\missionSystemsConfig.sqf`:

| Setting | Type | Default | Purpose |
|---|---|---:|---|
| `Waldo_Rally_Enable` | Boolean | `false` | Enables squad-leader rally controls |
| `Waldo_Rally_ObjectClass` | String (`CfgVehicles` classname) | `"Land_SatelliteAntenna_01_F"` | Rally world object; class must exist in the loaded mod set |
| `Waldo_Rally_Duration` | Number (seconds) | `180` | Active lifetime; use a positive value |
| `Waldo_Rally_DeploymentTime` | Number (seconds) | `15` | Uninterrupted deployment time |
| `Waldo_Rally_Cooldown` | Number (seconds) | `300` | Group cooldown from deployment |
| `Waldo_Rally_EnemyExclusionRadius` | Number (metres) | `100` | Hostile exclusion radius |
| `Waldo_Rally_MinimumGroupMembers` | Number (whole players) | `2` | Living group members required, including the leader |
| `Waldo_Rally_PlacementDistance` | Number (metres) | `2` | Requested placement ahead of the leader |
| `Waldo_Rally_MaximumSlope` | Number (degrees) | `20` | Maximum terrain slope |
| `Waldo_Rally_RespawnClearance` | Number (metres) | `2.5` | Advanced empty radius around a candidate respawn position |
| `Waldo_Rally_RespawnSearchDistance` | Number (metres) | `15` | Advanced maximum radius searched for a clear respawn position |
| `Waldo_Rally_AllowRegroup` | Boolean | `false` | Allows direct movement to the rally |

This feature has no required object-init call. Enable it in the existing settings row, then test
with a playable squad leader and enough living group members. The server owns the active rally;
current and joining group members receive the actions and marker appropriate to their group.

Direct regroup is off by default. When enabled, only a living member of the owning group can request it. The server selects a clear destination beside the rally.

The server publishes runtime ZEN changes before client actions start. Joining players request the latest server state. Disabling the feature removes its actions and active rallies.

## If deployment is refused

Check that the requester leads the group, is alive and on foot, and has enough living group members. The server also checks dry, level ground, nearby hostiles and the group's cooldown. Move to a clear area or adjust the corresponding existing setting in `MissionConfig/missionSystemsConfig.sqf`.

## See also

- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
