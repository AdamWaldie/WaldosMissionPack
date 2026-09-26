# Vehicle Exit Actions

> **Use this page when:** passengers need a left/right exit choice from a helicopter.

WMP adds **Get out Left Side** and **Get out Right Side** to cargo-seat passengers. The action moves the passenger to the chosen side. It does not set up a paradrop or change ACE Cargo settings.

## Quick setup: supported aircraft

These helicopter families receive the actions when the mission starts or Zeus spawns one:

| Base class | Vehicle family |
|---|---|
| `Heli_Transport_01_base_F` | Vanilla transport helicopter with this base class |
| `rhs_uh1h_base` | RHS UH-1H |
| `RHS_UH1_Base` | RHS UH-1Y/N |
| `RHS_Mi24_base` | RHS Mi-24 |

The Mi-24 also receives a static-line jump action. [Paradrop](Paradrop) covers that separate feature.

## Call: add the actions to another vehicle

Put this line in the vehicle's Eden Init field:

```sqf
[this] call Waldo_fnc_AddExitActions;
```

Pass `false` as the second argument if you want plain action labels instead of coloured left/right labels:

```sqf
[this, false] call Waldo_fnc_AddExitActions;
```

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing helicopter or other vehicle whose cargo passengers need an exit choice. |
| 1 | Boolean | `true` | `true` colours the left/right labels; `false` uses plain text. |

The function returns no useful value. It records setup on the object so a repeated call does not add duplicate actions. Put it in the vehicle's Eden Init field for placed vehicles. A vehicle created during play needs the same client-facing action setup for players who join later.

The setup call does nothing if the actions are already present. Test the chosen class in play: the action only appears to a passenger in a cargo seat.

## If an exit choice is absent

Check that the target is a supported vehicle and the player is in the passenger role for which the action is installed. The custom call adds exits to another vehicle but does not create a safe door on a model that lacks usable geometry. Test both sides of each modded aircraft before release.

## See also

- [Aircraft Boarding Action](Aircraft-Boarding-Actions)
- [Emergency Dismount](Optional-Feature-Systems#emergency-dismount)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
