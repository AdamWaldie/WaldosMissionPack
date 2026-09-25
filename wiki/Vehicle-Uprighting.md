# Set Vehicle Upright

> **Use this page when:** players need to right a tipped land vehicle.

WMP adds **Set Vehicle Upright** to land vehicles automatically. No Eden Init line, ZEN module, or feature flag is required. This is a local action on the vehicle, separate from [Emergency Dismount](Optional-Feature-Systems#emergency-dismount). Emergency Dismount moves occupants out. This action rights the vehicle when a player chooses it.

## Use it in play

1. Get out of the vehicle and stand within six metres of it.
2. Wait until it is stationary. The action appears when Arma reports speed below 3 km/h and the vehicle tilts far enough to need righting.
3. Choose **Set Vehicle Upright** from the vehicle's action menu.

The server checks the player's request and sends the operation to the machine that owns the vehicle. WMP stops the vehicle, aligns it with the local terrain, and places it above the ground using its model bounds. Keep vehicle simulation enabled. Check the surroundings before use, especially on a slope or beside other vehicles. Arma reports a signed speed, so the action can appear while a vehicle reverses. Stop it before selecting the action.

This action does not repair damage or replace the [Vehicle Recovery](Vehicle-Recovery) workshop system.

Mission scripts can request the same operation on the server after checking their own trigger:

```sqf
[_vehicle] call Waldo_fnc_VehicleUpright; // Run in a server script.
```

| Position | Type | Default | What to supply |
|---:|---|---|---|
| 0 `vehicle` | Object | `objNull` (rejected) | Existing land vehicle to right. |
| 1 `actor` | Player Object | `objNull` | Player who requested the action; required for remote player requests. Server-owned scripts can omit it. |

The server validates a remote player's identity and distance, then forwards the operation to the
vehicle owner when needed. The owner aligns the vehicle and returns `true`; an invalid request or
vehicle returns `false`. A server `true` after forwarding means the owner request was sent, not
that the new orientation has already been observed. The automatic action is installed locally on
clients, including joining players. Do not call the local action setup function yourself.

## If the action is missing

Check that the target is a land vehicle, the player is on foot and within six metres, and the vehicle has stopped and tilted enough to qualify. This action does not appear on a normally upright vehicle. A blocked landing spot or nearby vehicle can still make the result unsafe; clear the area before using it.

## See also

- [Emergency Dismount](Optional-Feature-Systems#emergency-dismount)
- [Vehicle Recovery](Vehicle-Recovery)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
