_Associated Files: MissionScripts\AiScripting\simpleAiConvoy.sqf_

A convoy script for AI vehicle groups, expanded and enhanced from Tova's original. It keeps vehicles in column formation, enforces convoy spacing, and forces stalled vehicles to follow the convoy leader. Optionally prevents AI from dismounting on contact, keeping the convoy moving through enemy fire.

## Features

- Maintains column formation with configurable vehicle spacing
- Caps convoy speed so all vehicles move together
- Detects stalled vehicles every 5 seconds and orders them back into formation
- Optional `pushThrough` mode prevents AI from halting and dismounting on contact — units return fire while continuing to move

## Setup

Call the function from a trigger, script, or a waypoint **On Activation** field. Store the return handle so you can terminate the script at the end of the route.

```sqf
// Basic call — 30 km/h, 15 m spacing, pushThrough enabled
convoyScript = [convoyGroup] spawn Waldo_fnc_SimpleAiConvoy;

// Full parameters
convoyScript = [convoyGroup, convoySpeed, convoySeparation, pushThrough] spawn Waldo_fnc_SimpleAiConvoy;
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `convoyGroup` | GROUP | — | The group to run as a convoy (required) |
| `convoySpeed` | NUMBER | 30 | Maximum convoy speed in km/h |
| `convoySeparation` | NUMBER | 15 | Target separation between vehicles in metres |
| `pushThrough` | BOOL | true | When true, AI push through contact without dismounting |

## Ending the Script

In the group's **final waypoint On Activation** field, paste the following to terminate the convoy script and restore normal AI behaviour:

```sqf
terminate convoyScript;
{ (vehicle _x) limitSpeed 5000; (vehicle _x) setUnloadInCombat [true, false] } forEach (units convoyGroup);
convoyGroup enableAttack true;
```

## Multiple Convoys

If you need more than one convoy running simultaneously, use a different handle name for each:

```sqf
convoyScript_1 = [PatrolGroup1, 30, 15, true]  spawn Waldo_fnc_SimpleAiConvoy;
convoyScript_2 = [PatrolGroup2, 25, 20, false] spawn Waldo_fnc_SimpleAiConvoy;
```

Terminate each handle independently at their respective final waypoints.

## Notes

- Must be called with `spawn` — the script loops continuously and will block execution if called with `call`
- `pushThrough` disables `enableAttack` on the group and prevents unloading in combat; always restore this via the termination block above
- Works with any mix of vehicle types in the group
- The script handles one group per call — for multiple convoys, call it once per group
