# Squad Rally Points

> **Use this page when:** squad leaders need a temporary, group-owned respawn position.

Set `Waldo_Rally_Enable = true` in `MissionConfig\missionSystemsConfig.sqf`, or enable the feature during play with **Respawn - Squad Rally Control**. The current leader of a qualifying group receives controls to deploy or pack its rally. Ownership and cooldown stay with the group if its leader changes.

The server checks that the leader is alive, on foot, on dry and level ground, and outside the hostile exclusion radius. The group must also have enough living members. The server chooses a clear position and adds a group-scoped respawn point. Only current group members see the rally marker. Destroying, packing, or disabling the rally removes its object, respawn point, and marker. They also disappear when the rally expires.

## Settings

Edit the existing rows in `MissionConfig\missionSystemsConfig.sqf`:

| Setting | Default | Purpose |
|---|---:|---|
| `Waldo_Rally_Enable` | `false` | Enables squad-leader rally controls |
| `Waldo_Rally_ObjectClass` | `Land_SatelliteAntenna_01_F` | Rally world object |
| `Waldo_Rally_Duration` | `180` | Active seconds |
| `Waldo_Rally_DeploymentTime` | `15` | Uninterrupted deployment time |
| `Waldo_Rally_Cooldown` | `300` | Group cooldown from deployment |
| `Waldo_Rally_EnemyExclusionRadius` | `100` | Hostile exclusion radius in metres |
| `Waldo_Rally_MinimumGroupMembers` | `2` | Living group members required |
| `Waldo_Rally_PlacementDistance` | `2` | Placement distance ahead of the leader |
| `Waldo_Rally_MaximumSlope` | `20` | Maximum surface angle in degrees |
| `Waldo_Rally_AllowRegroup` | `false` | Allows direct movement to the rally |

Direct regroup is off by default. When enabled, only a living member of the owning group can request it. The server selects a clear destination beside the rally.

The server publishes runtime ZEN changes before client actions start. Joining players request the latest server state. Disabling the feature removes its actions and active rallies.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
