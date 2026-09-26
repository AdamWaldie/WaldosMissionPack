# Tasks and Objectives

> **Use this page when:** you need server-authoritative, JIP-safe objective creation and resolution.

_Associated Files: `MissionScripts\MissionFlowAndUi\createObjective.sqf`, `setObjectiveState.sqf`, `Waldo_fnc_CreateObjective`, `Waldo_fnc_SetObjectiveState`_

These two calls let a script or trigger create and resolve an Arma task. Eden and Zeus task modules remain available if you prefer a visual setup. WMP also records these task changes for the After-Action Report.

Both helpers run on the server. Calls made on a client are forwarded there, and joining players receive the task state.

## Quick start: create your first task

Place a marker named `lz1` in Eden. In a server-side script or trigger activation field, use the call below. The marker gives the task a destination. The first string, `secure_lz`, is the stable ID used again when you finish the task.

## Call: create an objective

```sqf
["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"]
    call Waldo_fnc_CreateObjective;
```

`Waldo_fnc_CreateObjective` parameters:

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Task ID | String | Required | Unique ID, used to update the task later. |
| 1 | Owner | Side / Group / Object / Array | `west` | Who receives the task. |
| 2 | Title | String | `"New Task"` | Short task title (also used as the marker label). |
| 3 | Description | String | `""` | Longer task description. |
| 4 | Destination | Array / Object / String | `[]` | Position, object or marker name for the BIS task destination. Use `[]` for none. |
| 5 | State | String | `"ASSIGNED"` | Initial state: `CREATED`, `ASSIGNED`, `SUCCEEDED`, etc. |
| 6 | Create marker | Bool | `true` | Create a separate `mil_objective` map marker only when destination is a position array with at least two numbers. An object or marker-name destination still works for the BIS task, but this helper does not create an extra map marker for it. |
| 7 | Task type | String | `""` | Task icon type (`""` = default icon). |

**Return:** no value to use. An empty task ID is logged and creates no task. A client call forwards the request to the server, so it gives no immediate completion result. Reusing an ID updates its After-Action Report entry. Choose a new ID for each separate objective.

## Call: resolve an objective

```sqf
["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

`Waldo_fnc_SetObjectiveState` parameters:

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Task ID | String | Required | The ID you passed to `Waldo_fnc_CreateObjective`. |
| 1 | State | String | `"SUCCEEDED"` | New state: `SUCCEEDED` / `FAILED` / `CANCELED` / `ASSIGNED` / `CREATED`. |

When the state becomes `SUCCEEDED`, `FAILED` or `CANCELED`, the helper-created map marker is removed automatically.

**Return:** no value to use. An empty ID is logged. A client call sends the state change to the server. For a task created outside `Waldo_fnc_CreateObjective`, the After-Action Report uses the title “Mission objective”. Use the create call first to show the task's own title in the debrief.

## Complete example

```sqf
// In a trigger or script, create the task when the mission starts:
["destroy_radar", east, "Destroy the Radar", "Knock out the coastal radar site.", getMarkerPos "radar1"]
    call Waldo_fnc_CreateObjective;

// Later, in the radar's "killed" event or another trigger:
["destroy_radar", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

## During play and troubleshooting

The optional map marker is named `Waldo_obj_<taskId>` internally. If a task appears without that marker, check whether the destination passed to WMP was a position array. Passing an object or existing marker name creates the BIS task destination but not WMP's separate marker.

If a task is missing, check that the creation call ran and used a non-empty, stable ID. Resolve the ID used at creation. Changing the visible title does not identify another task. Server-owned task state reaches joining players.

## See also

* [ENDEX Script & Custom End Screen](ENDEX-Script-&-Custom-End-Screen): the After-Action Report reads the objective ledger these helpers maintain
* [Mission UI Text Overlays](Mission-UI-Text-Overlays): on-screen text to accompany objectives

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
