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

### Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Gunship_Support_Example_Minimal` registers a placed,
crewed VTOL with only `id` and `aircraft` set (every other key defaults —
no explicit turret profiles, WMP auto-discovers them). `_Full` shows every
option explicitly (callsign, side, home/orbit markers, altitude, radius,
service envelope, turret profiles) on the same crewed VTOL, orbiting a
movable marker.

## Lifecycle and runtime control

States: `INITIALISING`, `TRANSIT`, `ON_STATION`, `CONTROLLED`, `RTB`,
`SERVICING`, `UNAVAILABLE`, `DESTROYED`. At the combat orbit the controller
gets actions to designate another orbit, connect to a turret, release
control, or request service (a deliberate availability cycle, not an
instant refill — releases control, transits, locks tasking, waits
`serviceDuration`, applies configured fuel/ammo/damage, returns).

No controller (FAC/JTAC) is assigned by default — not even by the example compositions, since a
composition can't hardcode "whichever player joins". Beginner-friendly way to give it one from
mission start, from a placed unit's own Eden init field (no `isServer` wrapper needed, and it waits
bounded for the id to finish registering first since init fields have no guaranteed order against
each other):

```sqf
[this, "spectre_1"] call Waldo_fnc_GunshipAssignControllerOnStart;
```

Raw runtime calls (used by the ZEN modules, or for reassigning later):

```sqf
["spectre_1", "ASSIGN", [newController], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "SET_ORBIT", [getMarkerPos "target_area"], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "SET_ORBIT_PARAMS", [2000, 900], objNull] call Waldo_fnc_GunshipServerHandle;  // live radius/altitude, floored at 300m
["spectre_1", "SERVICE", [], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "RETURN", [], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", false] call Waldo_fnc_GunshipDestroy;   // final bool: delete only if WMP originally spawned it
[false] call Waldo_fnc_GunshipStop;                   // stop every system, preserving aircraft
```

The assigned controller also has a **Configure Orbit** self-interaction (ACE + vanilla fallback,
gated like Designate Orbit) that opens a small dialog (`Waldo_fnc_GunshipPromptOrbitConfig`)
pre-filled with the live radius/altitude and submits `SET_ORBIT_PARAMS` above — the only way to
change a *registered* gunship's radius/altitude without destroying and re-registering it. A **View
Off-Station Status** self-interaction (visible only while not `ON_STATION`/`CONTROLLED`) reveals a
panel for 10s explaining why the aircraft is currently away: resupply countdown, resupply-in-progress,
or "retasked to a new orbit" — it is never shown automatically. The aircraft marker uses its original
vanilla `"b_plane"` icon; the orbit centre gets a plain `"mil_circle"` dot plus a border-only ellipse
showing the current loiter radius. All gunship markers are visible only to players on the aircraft's
own side.

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
