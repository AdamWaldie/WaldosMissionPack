# Teleport action

> **Use this page when:** adding a single scroll-wheel action that moves the player to a destination.

This helper gives one Eden object a simple teleport action. The destination can be a named map marker or a live world reference. It uses a fixed arrival offset, so check the landing space before players use it.

## Set up a teleport action

Put a destination marker or object in Eden. Name it, then put this in the interaction object's **Init** field:

```sqf
[this, "Teleport to base", "respawn_west"] call Waldo_fnc_Teleport;
```

The marker named `respawn_west` must exist in the mission. The call also accepts an object, map location, group or task as its destination.

## Call and parameters

`Waldo_fnc_Teleport` accepts:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing object that receives the scroll-wheel action. |
| 1 | String | `"Teleport"` | Label players see. |
| 2 | Object, marker-name string, Location, Group or Task | Interaction object | Destination that exists when the player selects the action. Use a quoted marker name such as `"respawn_west"`, not the marker's visible text. |

The function returns the local `addAction` ID. An Init field runs on every machine, so each player's interface gets its own action. Repeating the call installs another action. This helper does not remove an earlier one. If you create the interaction object during play, set up its action on each interface client, including joining players.

The helper adds a green vanilla scroll-wheel action. It moves the player about three metres east and north of the destination and shows the built-in “A few minutes later...” fade. It does not search for clear ground. Test the arrival point, especially inside buildings or near obstacles.

## If the action or arrival is wrong

Check the destination's Eden variable name or marker name and confirm it exists when the action runs. The basic helper uses a fixed offset, so move the destination or use [Base Services](Base-Services) if that offset lands inside scenery. Base Services searches for a clear arrival point and offers destination-specific transitions.

For several named destinations with per-object save, heal or spectator actions, use [Base Services](Base-Services). That system checks for a safe arrival position and lets you set a transition per destination.

## See also

- [Base Services](Base-Services)
- [Map Location Tools](Map-Location-Tools)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
