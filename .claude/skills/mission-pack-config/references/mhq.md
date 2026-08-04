# MHQ / Mobile Command Post

Setup is mostly Eden Editor work — **instruction mode** for steps 1-4.

1. Place a vehicle (or static object) with a variable name, e.g. `MHQ_1`.
2. Place a Game Logic near it.
3. Place the tent/crate objects to be deployed and **sync each one to the
   Logic** (not the vehicle) — this is the step users most often get wrong
   (syncing to the vehicle instead of the Logic silently breaks deployment).
4. Raise ground-placed objects ~1ft if using a vehicle, to account for
   suspension settling.
5. In the vehicle's init field (this part is a script call, safe to hand
   over as a paste-in snippet):

```sqf
[this] call Waldo_fnc_MHQSetup;
// or with options:
[this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
// params: [vehicle, modernAudio, enableLogistics, logiBearing, logiDistance]
```

Players get ACE3 "Deploy/Tear Down Command Post" actions. Deployed state
creates a named respawn point and map marker automatically.
