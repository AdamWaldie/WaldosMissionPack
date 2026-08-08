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

## Eden composition (beginner drop-in)

For a beginner who'd rather place a working example than build steps 1-4 by
hand, `WMP_Compositions/[WMP]MHQ_BASIC_EXAMPLE_Minimal` is a single truck
already wired with the plain `[this] call Waldo_fnc_MHQSetup;` call — drop
it in and it works. `[WMP]MHQ_BASIC_EXAMPLE_Full` is the complete synced
Logic/tent/crate layout with every `Waldo_fnc_MHQSetup` option shown
explicitly, for learning what each one does once the Minimal version is
understood. Placing a composition is still an Eden Editor action —
instruction mode, per SKILL.md Step 1.
