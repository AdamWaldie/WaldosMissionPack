# Object scaling and transforms

Server-validated runtime scaling for Simple Objects and attached objects,
plus helper transforms (reset, multiply, copy, bounded area scaling, full
pitch/bank/yaw, ATL/ASL/ASLW placement, scripted spawning, batch tagging).
"Call-driven" pattern — nothing scales until called or used via ZEN.

## Config (`MissionConfig\logisticsConfig.sqf`)

```sqf
["Waldo_ObjectScaling_Minimum", 0.1, false],           // server, positive multiplier
["Waldo_ObjectScaling_Maximum", 10, false],             // server, must be >= minimum
["Waldo_ObjectScaling_AllowClientRequests", false, false] // server: normally false, ZEN/server remains authority
```

## Scaling one object

```sqf
private _scaledStatue = [statue, 1.75, true] call Waldo_fnc_ObjectScale;
```

The third argument converts an empty grounded decorative target to a Simple
Object — conversion **removes simulation, damage, inventory, crew,
object-bound `addAction` entries and the original object reference**, so
always retain the returned object. Direction/orientation commands reset
scale and must run first; when the scale argument is negative WMP preserves
the object's current scale instead of letting Arma's direction commands
reset it to 1. Combined transforms apply position and orientation first,
then scale last.

## Batch scaling

Tag objects with `Waldo_ObjectScale`, then:

```sqf
[] call Waldo_fnc_ObjectScaleTagged;
```

## Zeus

**Scale Object** — place on a target, choose the scale, explicitly permit
decorative conversion.

## Gotchas

- Arma only supports uniform scaling (`setObjectScale` has no per-axis
  mode); visual and collision geometry may disagree on some assets — test
  unusual scales in-game.
- Merely disabling simulation on an ordinary object does **not** make
  scaling supported — it must actually be a Simple Object.
- Remote (non-server) requests are curator-only unless
  `Waldo_ObjectScaling_AllowClientRequests` is explicitly relaxed — normally
  leave it `false`.
- Related helpers (mass attach/detach) are covered in
  `misc-mission-maker-tools.md`, not here.
