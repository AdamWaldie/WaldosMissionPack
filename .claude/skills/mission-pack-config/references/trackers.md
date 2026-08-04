# Signal trackers (C-Track)

Plant a tracker on a unit or vehicle and a chosen side follows it live on
the map — electronic recon. Server-authoritative registry
(`Waldo_Tracker_Registry`, JIP-safe) with a light server prune loop that
drops trackers whose target dies. Markers render **locally** on each
tracking client (`Waldo_fnc_TrackerRender`), so they stay invisible to the
tracked side.

```sqf
[enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;   // [target, trackingSide, label]
[cursorTarget] call Waldo_fnc_TrackerAttach;                // plant on what you're looking at, tracked by your own side
[enemyTruck] call Waldo_fnc_TrackerRemove;                  // remove
```

## Player / Zeus access

Players get an ACE **Plant Signal Tracker** action on units and vehicles.
Zeus gets a **Plant Signal Tracker** module (attaches to the nearest unit,
tracked by a chosen side).
