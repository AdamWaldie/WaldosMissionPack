# Paradrop (HALO / static-line)

Most "Plane"-class assets get HALO/static-line jump actions automatically —
no per-vehicle config needed in the common case.

## Config (`initServer.sqf`)

```sqf
missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180, true];  // metres
missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350, true];
missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310, true];     // km/h
missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE", "rhs_d6_Parachute", true];
missionNamespace setVariable ["WALDO_PARA_HALOALTITUDE", 1000, true];
missionNamespace setVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute", true];
```

- Static-line jumps only activate within the altitude/speed window above —
  if a user reports "no jump option," check the aircraft's actual altitude
  and speed against these thresholds first.
- `WALDO_STATIC_STATICCHUTE` / `WALDO_PARA_HALOCHUTE` are parachute
  classnames — swap for a mod's chute (e.g. an RHS one) if the mission uses
  one instead of vanilla.

## Custom / non-auto-detecting aircraft

If a vehicle doesn't get the jump action automatically (custom mod aircraft
sometimes don't), add to its **Eden Editor init field**:

```sqf
[this] call Waldo_fnc_VehicleJumpSetup;
```

This is a script call, not a `mission.sqm` edit — safe to give the user as a
paste-into-init-field snippet even though it's placed via Eden.
