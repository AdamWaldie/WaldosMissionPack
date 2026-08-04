# EMP burst

One-shot electromagnetic pulse — an area electronics kill, the offensive
counterpart to the (persistent) jammer. Server-authoritative; runs no
polling loops (fires once, reverts on a timer) so it's safe to leave
available in every mission.

```sqf
[getPosATL myObject, 200, 30] call Waldo_fnc_EMP;   // [position, radius(m), duration(s)]
[commandVehicle] call Waldo_fnc_EMPImmune;          // exempt a unit/vehicle (occupants inherit)
```

## Effects in radius (non-immune)

- Infantry lose NVGs and (TFAR) radio use for the duration.
- Vehicles have their engine cut (fuel drained, restored after).
- Every affected **player** gets a white-out flash.

Set `Waldo_EMP_NotifyAffectedPlayers = true` for an explicit local
disruption notice — defaults off. Applied per-entity on its owning machine
via `Waldo_fnc_EMPApply`.

## Zeus

**EMP Detonation** module (dialog: radius / duration). Parameters are
written to RPT, not chat.
