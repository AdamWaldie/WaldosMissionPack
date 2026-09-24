# Aircraft boarding action

> **Use this page when:** adding a ground action that seats a player in a live aircraft's cargo compartment.

Name the aircraft in Eden. Put this in the boarding object's **Init** field, replacing `aircraft` with that name:

```sqf
[this, aircraft, "ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;
```

The arguments are `[boarding object, aircraft, action name]`. The name is optional and defaults to `"Aircraft"`. The boarding object shows a blue **Board ARGUS 1-4** scroll-wheel action while the aircraft is alive and has a free cargo seat.

The player goes into a cargo seat, including when the aircraft is already airborne. WMP checks the result and sends a notification. It does not place the player in a pilot, commander or turret seat. The action follows aircraft availability and replaces its previous version if setup runs again on the same object.

The call installs the action on each player's interface. Eden object Init fields run on clients. If you create the boarding object later by script, run this call for each interface client, including players who join later. WMP's [dynamic paradrop boarding point](Vehicle-Actions-&-Paradrop#dynamic-drop-zone-operations) handles that replay for its own objects.

## See also

- [Vehicle Actions and Paradrop](Vehicle-Actions-&-Paradrop)
- [Teleport Action](Teleport-Actions)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
