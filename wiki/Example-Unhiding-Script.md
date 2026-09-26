# Example Unhiding Script

> **Use this page when:** you want a starting pattern for revealing a pre-placed enemy group during a mission.

This file is a template with mission-specific group names already in it. It reveals the named groups' units and vehicles and enables their simulation. It does not discover your groups, schedule an ambush or handle late joining players for you.

## Quick setup for your own mission

1. Place and name the groups you intend to reveal. Hide them and disable their simulation with a separate setup that runs before players can see them.
2. Open `MissionScripts\MissionMakerResourceScripts\ExampleUnhidingScript.sqf`. Replace every shipped `Attack1...` group name with a group variable from your mission. Remove any unused blocks.
3. Call the edited file from a server-owned trigger's **On Activation** field:

```sqf
[] execVM "MissionScripts\MissionMakerResourceScripts\ExampleUnhidingScript.sqf";
```

Do not run the shipped file unchanged. Its group names refer to its original example mission, so they may be undefined in yours.

## Script call and group contract

| Input | Type | Default | Effect |
| --- | --- | --- | --- |
| Arguments | None | None | Group variable names are edited in the file, not passed as call arguments. |
| Group reference | Group variable | Shipped `Attack1...` examples | `units` supplies the members to reveal. |
| Execution | `execVM` call | Manual trigger | Returns an Arma Script handle immediately. The script itself has no useful result. |

For each listed group, the script uses `hideObjectGlobal false` and `enableSimulationGlobal true` on its members and their current vehicles. Those commands change shared world state. Run the trigger once on the server. Repeating it is unnecessary, and this template has no explicit JIP replay or cleanup path.

## If nothing appears

Check each group variable name in the edited file. Confirm the trigger executed on the server and that the units still exist. The script cannot reveal a group it cannot resolve.

## See also

- [Tasks and Objectives](Tasks-And-Objectives)
- [Mission-Maker Resource Scripts](Mission-Maker-Resource-Scripts)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
