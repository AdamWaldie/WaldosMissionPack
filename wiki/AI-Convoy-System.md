# AI Convoy System

> **Use this page when:** you need WMP to control an AI vehicle convoy in a mission without Waldos AI Tweaks (WAIT).

WMP keeps a selected AI land-vehicle group in column formation, caps its speed, requests vehicle spacing and nudges stalled followers back toward the leader every five seconds. Optional push-through mode prevents the group unloading on contact.

When WAIT is loaded, WMP does not register its convoy Zeus module and the script API exits before changing the group. WAIT can then provide its own convoy controller. The check also runs inside an active WMP worker.

## Setup

Create an AI land-vehicle group with a route. The driver of each vehicle must belong to the group.

## Script call

Give the AI vehicle group a route and call the controller once on the server:

```sqf
if (isServer) then {
    convoyScript = [convoyGroup, 30, 15, true] call Waldo_fnc_SimpleAiConvoy;
};
```

| Argument | Type | Default | Meaning |
| --- | --- | --- | --- |
| Group | GROUP | Required | AI drivers and vehicles to control. |
| Speed | NUMBER | `30` | Lead-vehicle speed cap, 5–120 km/h. |
| Separation | NUMBER | `15` | Requested spacing, 5–100 m. |
| Push through | BOOL | `true` | Prevent attack orders and unloading on contact. |

The call returns the controller's Script handle. A second call for the same group terminates its previous worker. The controller pins crew against automatic headless reassignment and runs only while the group is local to the server. Joining players do not start another worker.

At the final waypoint, stop the controller and restore any AI settings your mission needs:

```sqf
if (isServer) then {
    terminate (convoyGroup getVariable ["Waldo_Convoy_Worker", scriptNull]);
    convoyGroup enableAttack true;
    {vehicle _x limitSpeed 5000; vehicle _x setUnloadInCombat [true, false]} forEach units convoyGroup;
};
```

## Zeus control

Place **WMP AI & Combat → AI Convoy - Control** directly on a crewed AI land vehicle. The dialog provides labelled speed, separation and push-through choices. An empty-ground placement is rejected. The server checks the curator and settings before starting the worker. The module is hidden when WAIT is loaded.

## Limitations and troubleshooting

The group needs living AI drivers in simulation-enabled land vehicles and a valid route. WMP does not create a route. If another system takes group locality away despite the headless pin, WMP's worker exits. Restore mission-specific attack, speed and unloading settings when the route ends.

## See also

- [Transport Services](Transport-Services)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
