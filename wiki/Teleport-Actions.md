# Teleport action

> **Use this page when:** adding a single scroll-wheel action that moves the player to a destination.

Put a destination marker or object in Eden. Name it, then put this in the interaction object's **Init** field:

```sqf
[this, "Teleport to base", "respawn_west"] call Waldo_fnc_Teleport;
```

The marker named `respawn_west` must exist in the mission. The call also accepts an object, map location, group or task as its destination.

The arguments are `[interaction object, action label, destination]`. If you omit the label, the action reads **Teleport**. If you omit the destination, it uses the interaction object itself.

The helper adds a green vanilla scroll-wheel action. It moves the player about three metres east and north of the destination and shows the built-in “A few minutes later...” fade. It does not search for clear ground. Test the arrival point, especially inside buildings or near obstacles.

For several named destinations with per-object save, heal or spectator actions, use [Base Services](Base-Services). That system checks for a safe arrival position and lets you set a transition per destination.

## See also

- [Base Services](Base-Services)
- [Map Location Tools](Map-Location-Tools)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
