# AI Convoy System

> **Use this page when:** you need to create, tune, monitor, or stop a scripted AI vehicle convoy.

_Associated Files: MissionScripts\AiScripting\simpleAiConvoy.sqf_

This helper runs a five-second control loop for one AI vehicle group. It puts the group in column formation, sets speed and spacing, and tells a stalled follower to follow the leader again. The optional push-through mode stops the group unloading on contact.

## Features

- Maintains column formation with configurable vehicle spacing
- Caps convoy speed so all vehicles move together
- Checks stalled followers every 5 seconds and orders them back into formation
- Optional `pushThrough` mode stops the group unloading on contact

## Setup

Run this once on the server. Give `convoyGroup` an Eden variable name, and create a route for the group. In a trigger or waypoint **On Activation** field, guard the call so each machine does not start its own control loop. Store the script handle for cleanup at the end of the route.

```sqf
if (isServer) then {
    convoyScript = [convoyGroup] spawn Waldo_fnc_SimpleAiConvoy;
};

// Server script with explicit values
convoyScript = [convoyGroup, 30, 15, true] spawn Waldo_fnc_SimpleAiConvoy;
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `convoyGroup` | Group | Required | The AI vehicle group to run as a convoy. |
| `convoySpeed` | Number | `30` | Leader speed cap in km/h; follower cap is 15% higher. |
| `convoySeparation` | Number | `15` | Target spacing between vehicles in metres. |
| `pushThrough` | Boolean | `true` | Disables group attack orders and unloading in combat while the worker runs. |

`spawn` returns a Script handle. The helper does not register a persistent WMP service or replay a worker for joining players. It pins crew groups against automatic headless reassignment, but the control loop still needs to run on the server while it owns the group.

## Ending the Script

In the group's **final waypoint On Activation** field, terminate the same handle and restore the AI settings that push-through mode changed:

```sqf
if (isServer) then {
    terminate convoyScript;
    { (vehicle _x) limitSpeed 5000; (vehicle _x) setUnloadInCombat [true, false] } forEach (units convoyGroup);
    convoyGroup enableAttack true;
};
```

## Multiple Convoys

If you need more than one convoy running simultaneously, use a different handle name for each:

```sqf
convoyScript_1 = [PatrolGroup1, 30, 15, true]  spawn Waldo_fnc_SimpleAiConvoy;
convoyScript_2 = [PatrolGroup2, 25, 20, false] spawn Waldo_fnc_SimpleAiConvoy;
```

Terminate each handle independently at their respective final waypoints.

## Notes

- Use `spawn` because the loop sleeps. A direct `call` in unscheduled code cannot run it correctly.
- The helper has no duplicate guard. Start one worker per group and terminate it when the route ends.
- The cleanup example uses `limitSpeed 5000` and `[true, false]` for unloading. If your mission had different values before convoy setup, restore those values instead.

## If the convoy stops or splits

Check that the group has a living AI driver in a simulation-enabled land vehicle and that its route remains valid. The push-through-contact choice changes whether the group stops to fight. Tune speed and separation for the road and vehicle mix before blaming the server or adding another movement loop.

## See also

- [Transport Services](Transport-Services)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
