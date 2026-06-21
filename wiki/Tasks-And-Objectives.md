_Associated Files: `MissionScripts\MissionFlowAndUi\createObjective.sqf`, `setObjectiveState.sqf`, `Waldo_fnc_CreateObjective`, `Waldo_fnc_SetObjectiveState`_

# Tasks / Objectives

A thin, JIP-safe wrapper over Arma's BIS task framework for mission makers who like to drive objectives from **SQF or triggers** rather than the Eden / Zeus task modules (those remain the GUI option). It creates assigned tasks, optionally drops a persistent map marker at the destination, and tidies the marker away when the task resolves.

Both helpers are **server-authoritative** — calling them on a client forwards to the server automatically, so joining players always see the correct task state.

As a bonus, every objective created or resolved through these helpers is recorded in the **After-Action Report** objective ledger, so the [ENDEX](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen) debrief can show an objective summary with no extra work.

## Creating an objective

```sqf
["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"]
    call Waldo_fnc_CreateObjective;
```

`Waldo_fnc_CreateObjective` parameters:

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Task ID | String | — (required) | Unique id, used to update the task later. |
| 1 | Owner | Side / Group / Object / Array | `west` | Who receives the task. |
| 2 | Title | String | `"New Task"` | Short task title (also used as the marker label). |
| 3 | Description | String | `""` | Longer task description. |
| 4 | Destination | Array / Object / String | `[]` | Map position or object for the task waypoint (`[]` = none). |
| 5 | State | String | `"ASSIGNED"` | Initial state: `CREATED`, `ASSIGNED`, `SUCCEEDED`, etc. |
| 6 | Create marker | Bool | `true` | Drop a persistent `mil_objective` map marker at the destination. |
| 7 | Task type | String | `""` | Task icon type (`""` = default icon). |

## Resolving an objective

```sqf
["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

`Waldo_fnc_SetObjectiveState` parameters:

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Task ID | String | — (required) | The id you passed to `Waldo_fnc_CreateObjective`. |
| 1 | State | String | `"SUCCEEDED"` | New state: `SUCCEEDED` / `FAILED` / `CANCELED` / `ASSIGNED` / `CREATED`. |

When the state becomes `SUCCEEDED`, `FAILED` or `CANCELED`, the helper-created map marker is removed automatically.

## Example

```sqf
// In a trigger / script — create the task when the mission starts:
["destroy_radar", east, "Destroy the Radar", "Knock out the coastal radar site.", getMarkerPos "radar1"]
    call Waldo_fnc_CreateObjective;

// Later, in the radar's "killed" event or another trigger:
["destroy_radar", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

## Notes

* The map marker is named `Waldo_obj_<taskId>` internally — it is created only if a destination position is given and **Create marker** is left on.
* These helpers are a convenience layer, not a replacement: for click-and-drag objectives use the Eden **Create Task** modules or the Zeus task tools.

## See also

* [ENDEX Script & Custom End Screen](https://github.com/AdamWaldie/WaldosMissionPack/wiki/ENDEX-Script-&-Custom-End-Screen) — the After-Action Report reads the objective ledger these helpers maintain
* [Mission UI Text Overlays](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-UI-Text-Overlays) — on-screen text to accompany objectives
