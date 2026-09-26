# EMP Burst

> **Use this page when:** a mission needs a one-shot electrical disruption at a chosen point.

An EMP affects units and vehicles inside a radius for a set duration. It runs no background loop while unused. Unlike [Radio Jamming](Radio-Jamming), this is a single event rather than a persistent field.

## Quick setup: detonate an EMP

In Zeus, place **EMP - Detonate at Cursor** under **WMP Electronic Warfare**. Choose a radius and duration in the dialog. The burst occurs at the module position. For a scripted mission, call:

```sqf
[getPosATL myObject, 200, 30] call Waldo_fnc_EMP;
```

`Waldo_fnc_EMP` takes a world position, not a marker name or an object. Resolve a marker with `getMarkerPos "markerName"`, or an object with `getPosATL objectName`.

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Position array `[x, y, z]` | `[0, 0, 0]` | Centre of the burst. Supply it explicitly so the effect does not occur at the map origin. |
| 1 | Number | `150` | Radius in metres. |
| 2 | Number | `30` | Disruption duration in seconds. |

The call runs on the server, forwards a client call there, and returns no useful value. It affects entities inside the radius once, then restores temporary effects after the duration. It creates no persistent zone for late joiners.

## Settings, effects and immunity

Unprotected infantry lose their night-vision goggles. With TFAR, they cannot use their radios for the duration. Vehicles temporarily lose engine power until WMP restores their fuel state. Aircraft can lose lift, so choose the radius carefully. Players in range see a white flash.

An additional disruption notice is off by default. Advanced missions can enable that local notice in `initPlayerLocal.sqf` with `missionNamespace setVariable ["Waldo_EMP_NotifyAffectedPlayers", true];`. There is no shipped `MissionConfig` row for it.

To protect a specific vehicle or unit, put this in its Eden **Init** field:

```sqf
[this] call Waldo_fnc_EMPImmune;
```

Occupants of an immune vehicle are protected. The flag reaches joining players. You can also pass `[object, true]` to set immunity explicitly.

`Waldo_fnc_EMPImmune` takes `[unit or vehicle <OBJECT>, immune <BOOLEAN, default true>]`. Pass `false` as the second value to remove immunity. It returns no useful value. WMP publishes the flag so the server and joining clients see the same choice.

## If the effect differs from the plan

Check the radius, duration and immunity of each target. Test aircraft separately before using an EMP near players in flight. The Zeus module logs its parameters in the server RPT for diagnosis. It does not announce them in chat.

## See also

- [Signal Trackers](Signal-Trackers)
- [Radio Jamming](Radio-Jamming)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
