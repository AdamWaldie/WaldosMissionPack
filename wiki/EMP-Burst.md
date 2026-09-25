# EMP Burst

> **Use this page when:** a mission needs a one-shot electrical disruption at a chosen point.

An EMP affects units and vehicles inside a radius for a set duration. It runs no background loop while unused. Unlike [Radio Jamming](Radio-Jamming), this is a single event rather than a persistent field.

## Detonate an EMP

In Zeus, place **EMP - Detonate at Cursor** under **WMP Electronic Warfare**. Choose a radius and duration in the dialog. The burst occurs at the module position. For a scripted mission, call:

```sqf
[getPosATL myObject, 200, 30] call Waldo_fnc_EMP;
```

Arguments are `[position, radius in metres, duration in seconds]`. Radius defaults to `150` and duration to `30` if omitted. Place a marker or object at the intended centre before using the scripted call.

## Effects and immunity

Unprotected infantry lose their night-vision goggles. With TFAR, they cannot use their radios for the duration. Vehicles temporarily lose engine power until WMP restores their fuel state. Aircraft can lose lift, so choose the radius carefully. Players in range see a white flash.

An additional disruption notice is off by default. Advanced missions can enable that local notice in `initPlayerLocal.sqf` with `missionNamespace setVariable ["Waldo_EMP_NotifyAffectedPlayers", true];`. There is no shipped `MissionConfig` row for it.

To protect a specific vehicle or unit, put this in its Eden **Init** field:

```sqf
[this] call Waldo_fnc_EMPImmune;
```

Occupants of an immune vehicle are protected. The flag reaches joining players. You can also pass `[object, true]` to set immunity explicitly.

## If the effect differs from the plan

Check the radius, duration and immunity of each target. Test aircraft separately before using an EMP near players in flight. The Zeus module logs its parameters in the server RPT for diagnosis. It does not announce them in chat.

## See also

- [Signal Trackers](Signal-Trackers)
- [Radio Jamming](Radio-Jamming)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
