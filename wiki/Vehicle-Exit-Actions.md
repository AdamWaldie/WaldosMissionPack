# Vehicle Exit Actions

> **Use this page when:** passengers need a left/right exit choice from a helicopter.

WMP adds **Get out Left Side** and **Get out Right Side** to cargo-seat passengers. The action moves the passenger to the chosen side. It does not set up a paradrop or change ACE Cargo settings.

## Automatic setup

These helicopter families receive the actions when the mission starts or Zeus spawns one:

| Base class | Vehicle family |
|---|---|
| `Heli_Transport_01_base_F` | Vanilla CH-47 |
| `rhs_uh1h_base` | RHS UH-1H |
| `RHS_UH1_Base` | RHS UH-1Y/N |
| `RHS_Mi24_base` | RHS Mi-24 |

The Mi-24 also receives a static-line jump action. [Paradrop](Paradrop) covers that separate feature.

## Add the actions to another vehicle

Put this line in the vehicle's Eden Init field:

```sqf
[this] call Waldo_fnc_AddExitActions;
```

Pass `false` as the second argument if you want plain action labels instead of coloured left/right labels:

```sqf
[this, false] call Waldo_fnc_AddExitActions;
```

The setup call does nothing if the actions are already present. Test the chosen class in play: the action only appears to a passenger in a cargo seat.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
