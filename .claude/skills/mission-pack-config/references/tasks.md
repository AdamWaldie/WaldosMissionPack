# Tasks / objectives helper

A thin, JIP-safe wrapper over the BIS task framework for mission makers
driving objectives from SQF/triggers rather than Eden's task module or the
Zeus task module (both remain valid GUI alternatives — mention this isn't
the only way to make tasks if the user seems to want the simpler Eden route
instead). Server-authoritative — calling from a client forwards automatically.

```sqf
// Create an assigned task with a persistent map marker at the destination:
["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"]
    call Waldo_fnc_CreateObjective;

// Later, resolve it (also removes the helper-created marker):
["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

Params for `Waldo_fnc_CreateObjective`:
`[taskId, owner, title, description, destination, state, createMarker, taskType]`
(only the first five are required).

This feeds the AAR's objective summary automatically (see `endex-aar.md`) —
no separate wiring needed once objectives are created/resolved through
these two functions.

For exact optional-param behaviour, check the script headers in
`MissionScripts/MissionFlowAndUi/createObjective.sqf` and
`setObjectiveState.sqf` if available in the project — those headers are the
authoritative param list.
