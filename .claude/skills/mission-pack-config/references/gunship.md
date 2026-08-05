# Airborne Gunship Support

Named, server-owned lifecycle for a crewed aircraft: register an existing
aircraft or spawn a configured class, assign a player controller, move
between combat/service orbits, provide validated remote turret control,
auto-return on fuel/damage/ammo limits. Disabled until
`Waldo_fnc_GunshipRegister` (or its ZEN module) is actually used —
`Waldo_Gunship_Enable` only *permits* registration, it spawns nothing.

## Config (`MissionConfig\airOperationsConfig.sqf` — shared)

```sqf
["Waldo_Gunship_Enable", true],                 // permits registration/ZEN creation only
["Waldo_Gunship_DefaultAltitude", 700], ["Waldo_Gunship_MaximumAltitude", 5000],
["Waldo_Gunship_DefaultRadius", 1500], ["Waldo_Gunship_MaximumRadius", 10000],
["Waldo_Gunship_DefaultServiceDuration", 900],
["Waldo_Gunship_MonitorInterval", 2],           // ADVANCED
["Waldo_Gunship_MinimumFuel", 0.25], ["Waldo_Gunship_MaximumDamage", 0.65],
["Waldo_Gunship_ServiceFuelFraction", 1], ["Waldo_Gunship_ServiceAmmoFraction", 1], ["Waldo_Gunship_ServiceDamage", 0],
["Waldo_Gunship_MaximumServiceCycles", -1],     // -1 unlimited
["Waldo_Gunship_ReturnWhenOutOfAmmo", true],
["Waldo_Gunship_SideAircraftPools", createHashMapFromArray [["WEST", ["B_T_VTOL_01_armed_F"]], ["EAST", []], ["INDEPENDENT", []], ["CIVILIAN", []]]],
["Waldo_Gunship_FactionAircraftPools", createHashMap]  // optional, narrower than side pool; leave empty normally
```

## Scripted setup (`initServer.sqf`, after the aircraft/player slots exist)

```sqf
private _config = createHashMapFromArray [
    ["id", "spectre_1"], ["callsign", "SPECTRE 1"],
    ["aircraft", gunshipAircraft], ["controller", gunshipController],
    ["side", west], ["home", getMarkerPos "gunship_service_orbit"], ["orbit", getMarkerPos "gunship_initial_orbit"],
    ["altitude", 700], ["radius", 1500], ["direction", "CIRCLE_L"],
    ["serviceDuration", 900], ["minimumFuel", 0.25], ["maximumDamage", 0.65], ["maximumServiceCycles", -1],
    ["turretProfiles", [["Primary Gun", [0]], ["Heavy Gun", [2]]]]
];
[_config] call Waldo_fnc_GunshipRegister;
```

Omit `aircraft` and give `aircraftClass` + `spawnPosition` to spawn one
instead of registering an existing aircraft; or use `aircraftClasses`/
`faction`/the side-faction pools above. If `turretProfiles` is empty, WMP
discovers currently crewed gunner turret paths — explicit profiles are
recommended for mod aircraft since turret layouts vary.

## Lifecycle and runtime control

States: `INITIALISING`, `TRANSIT`, `ON_STATION`, `CONTROLLED`, `RTB`,
`SERVICING`, `UNAVAILABLE`, `DESTROYED`. At the combat orbit the controller
gets actions to designate another orbit, connect to a turret, release
control, or request service (a deliberate availability cycle, not an
instant refill — releases control, transits, locks tasking, waits
`serviceDuration`, applies configured fuel/ammo/damage, returns).

```sqf
["spectre_1", "ASSIGN", [newController], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "SET_ORBIT", [getMarkerPos "target_area"], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "SERVICE", [], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "RETURN", [], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", false] call Waldo_fnc_GunshipDestroy;   // final bool: delete only if WMP originally spawned it
[false] call Waldo_fnc_GunshipStop;                   // stop every system, preserving aircraft
```

## Zeus

**Gunship - Register or Spawn** (allegiance + aircraft in one dialog, from
compatible turret-equipped pools), **Gunship - Assign Controller** (nearest
player), **Gunship - Set Orbit** (module position), **Gunship - Operational
Control** (station/service/release/remove).

## Extension callbacks (server-only, config-time)

`onStateChanged`, `onArrive`, `onDepart`, `onService`, `onDestroyed`,
`onControllerChanged` — receive the system ID and current server state.

## Gotchas

- Operational side and physical airframe are independent — side controls
  crew allegiance/access/targeting, airframe can be any compatible class.
- Remote control depends on the aircraft's actual turret paths/crew; test
  each supported mod airframe.
- Service is an abstract orbit cycle, not physical landing/taxiing.
- Aircraft state is not automatically persisted — persist allocation state
  through the callbacks if needed alongside `persistence.md`.
