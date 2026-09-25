# Aircraft boarding action

> **Use this page when:** adding a ground action that seats a player in a live aircraft's cargo compartment.

Name the aircraft in Eden. Put this in the boarding object's **Init** field, replacing `aircraft` with that name:

```sqf
[this, aircraft, "ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;
```

`Waldo_fnc_MoveInCargoPlane` accepts:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing stand, sign or other boarding object that players use. |
| 1 | Object | Required | Existing aircraft. Give it an Eden variable name; do not pass its classname or a marker. |
| 2 | String | `"Aircraft"` | Short name used in **Board <name>**. |

The boarding object shows a blue **Board ARGUS 1-4** scroll-wheel action while the aircraft is alive and has a free cargo seat. The client call returns its local action ID, or `-1` when no action could be installed. This ID is useful only on that interface, not as a global mission identifier.

The player goes into a cargo seat, including when the aircraft is already airborne. WMP checks the result and sends a notification. It does not place the player in a pilot, commander or turret seat. The action follows aircraft availability and replaces its previous version if setup runs again on the same object.

The call installs the action on each player's interface. Eden object Init fields run on clients. If you create the boarding object later by script, run this call for each interface client, including players who join later. WMP's [dynamic paradrop boarding point](Paradrop#dynamic-drop-zone-operations) handles that replay for its own objects.

## If boarding does not appear

Check that the aircraft variable name resolves to a live object and that it has a free cargo seat. This helper does not place players in pilot or turret seats. For a boarding object created during play, confirm that joining clients also receive its setup call.

## See also

- [Paradrop](Paradrop)
- [Teleport Action](Teleport-Actions)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
