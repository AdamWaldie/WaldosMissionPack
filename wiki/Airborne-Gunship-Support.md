# Airborne Gunship Support

> **Use this page when:** you need to configure, operate, or extend a player-controlled airborne gunship.

_Associated Files: `MissionConfig\airOperationsConfig.sqf`,
`MissionScripts\CombatSystems\AirborneGunship\`, `initServer.sqf`, and the public
`Waldo_fnc_Gunship*` functions._

Airborne Gunship Support manages any number of named, crewed aircraft through a server-owned lifecycle. It can register an existing aircraft or spawn a configured class, assign a player controller, move between combat and service orbits, provide validated remote turret control, and return automatically when fuel, damage or ammunition limits are reached.

Operational side and physical airframe are independent. Side controls crew allegiance, controller
access, marker friendliness and targeting; the airframe dropdown can use any compatible configured
aircraft regardless of its original faction.

Service is a deliberate availability cycle rather than an instant refill. A request releases weapon
control, sends the aircraft to its home/service orbit, locks tasking during transit and service,
waits the configured duration, applies the configured fuel, ammunition and repair fractions, then
returns to the previous combat orbit. During RTB/service the assigned controller sees only a status
interaction, including approximate remaining service time.

The feature is disabled by default. Calling `Waldo_fnc_GunshipRegister` or using the registration Zeus module explicitly enables it.

## Three ways to get one flying

1. **No scripting:** place a crewed aircraft in Eden, then in a running mission use the **Gunship - Register or Spawn** Zeus module on it (see Focused Zeus modules below).
2. **Drop-in example:** place the `[WMP]Gunship_Support_Example_Minimal` composition from `WMP_Compositions/` — an armed Blackfish with its complete four-person BLUFOR editor crew (pilot, copilot and two weapon operators), already registered with the minimum required keys.
3. **Smallest working script call**, in the placed-and-crewed aircraft's own init field:
   ```sqf
   [createHashMapFromArray [["id", "spectre_1"], ["aircraft", this]]] call Waldo_fnc_GunshipRegister;
   ```
   Every other key below (callsign, side, home/orbit markers, altitude, radius, service envelope, turret profiles) has a working default — add only the ones a mission actually needs to change.

## Controller assignment (FAC / JTAC)

Nothing is assigned as controller by the Minimal example. The Full teaching composition includes a
separate, correctly grouped BLUFOR team leader and assigns that unit as its example controller at
mission start; replace it with the intended playable FAC/JTAC or use Zeus during play. Until a
controller exists:

- Every player on a friendly side can still see a **Status** interaction (aircraft callsign,
  current state, and who — if anyone — is the assigned controller), so the aircraft is never
  invisible or silently broken.
- Designating an orbit, requesting service, releasing control and — the one players hit most —
  taking control of a turret all stay locked to that one player, so nobody else's menu shows those
  actions at all. This is deliberate access control (the equivalent of a FAC/JTAC role), not a bug;
  if "take control" seems to do nothing, check Status first — it names the missing step.

Assign a controller one of four ways:
1. **Zeus (recommended for a live session):** curator runs **Gunship - Assign Controller**, which
   assigns the nearest player.
2. **Eden, from a placed unit's own init field (recommended for "always has a controller from
   mission start"):**
   ```sqf
   [this, "spectre_1"] call Waldo_fnc_GunshipAssignControllerOnStart;
   ```
   The beginner-friendly one-liner - place a unit near the gunship (a stand-in for a real FAC/JTAC
   role), give it this init call with the gunship's `id`, done. Object init fields have no
   guaranteed order against each other, so this waits (bounded, default 60s) for that id to finish
   registering before assigning it - safe regardless of whether the controller unit's or the
   aircraft's init field happens to run first. See it in place in the Gunship Support Example (Full)
   composition.
3. **Script/init, by object:** `["controller", gunshipController]` in the config passed to
   `Waldo_fnc_GunshipRegister` (see the full example below) - use this when the controller unit is
   guaranteed to already exist (e.g. created earlier in the same script) before registration runs.
4. **Script/init, by UID (survives that player's respawn):** `["controllerUID", "<steam64id>"]`.

Re-running `["spectre_1", "ASSIGN", [newController], objNull] call Waldo_fnc_GunshipServerHandle;`
reassigns control at any time (also releasing the previous controller's turret access).

## Scripted setup (every option)

Run registration from `initServer.sqf` after the aircraft and player slots exist:

```sqf
private _config = createHashMapFromArray [
    ["id", "spectre_1"],
    ["callsign", "SPECTRE 1"],
    ["aircraft", gunshipAircraft],
    ["controller", gunshipController],
    ["side", west],
    ["home", getMarkerPos "gunship_service_orbit"],
    ["orbit", "gunship_initial_orbit"],
    ["altitude", 700],
    ["radius", 1500],
    ["direction", "CIRCLE_L"],
    ["serviceDuration", 900],
    ["minimumFuel", 0.25],
    ["maximumDamage", 0.65],
    ["maximumServiceCycles", -1],
    ["maximumRangeFromHome", 30000],
    ["turretProfiles", [
        ["Primary Gun", [0]],
        ["Heavy Gun", [2]]
    ]]
];
[_config] call Waldo_fnc_GunshipRegister;
```

Passing the initial `orbit` as a marker-name string is recommended. WMP reads the marker position
and, after successful registration, deletes the Eden placeholder so the live callsign-labelled WMP
orbit marker replaces it. Passing `getMarkerPos` still supplies a valid position, but discards the
marker name, so WMP cannot know which placeholder should be removed.

On a dedicated server, briefing clients can recreate their local `mission.sqm` marker after the
server has consumed it. WMP therefore also sends a persistent interface-local hide instruction for
that exact source-marker name through the briefing transition. It does not hide the new operational
orbit marker.

Omit `aircraft` and provide `aircraftClass` plus `spawnPosition` to create the asset. Alternatively provide `aircraftClasses`, `faction`, or use the mission's `Waldo_Gunship_SideAircraftPools` and `Waldo_Gunship_FactionAircraftPools`. Invalid or non-aircraft classes are rejected before spawning.

An existing Eden aircraft must already contain its intended crew. Registration does not silently
fill an existing aircraft because doing so can duplicate placed crew and briefly create incorrectly
sided AI on multiplayer machines. Runtime crew creation is used only when the script or ZEN module
actually spawns a new aircraft. For the vanilla armed Blackfish, the editor example contains four
crew linked to the pilot, copilot, left-gunner and right-gunner stations.

If `turretProfiles` is empty, the feature discovers currently crewed gunner turret paths. Explicit profiles are recommended for mod aircraft because turret layouts vary significantly.

## Lifecycle

The state machine uses `INITIALISING`, `TRANSIT`, `ON_STATION`, `CONTROLLED`, `RTB`, `SERVICING`, `UNAVAILABLE` and `DESTROYED`.

When it reaches the configured orbit, the assigned controller receives actions to designate another orbit, connect to a configured turret, release control or request service. At the home orbit it waits for `serviceDuration`, applies the configured fuel/ammunition/damage service levels on the aircraft's owning machine, then returns to the last combat orbit.

Set `maximumServiceCycles` to a non-negative number for finite support. A negative value is unlimited. The controller can be retained across respawn by UID. Server checks ensure remote requests come from the assigned player or an active curator.

## Runtime operations

Trusted server scripts can call:

```sqf
["spectre_1", "ASSIGN", [newController], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "SET_ORBIT", [getMarkerPos "target_area"], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "SERVICE", [], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", "RETURN", [], objNull] call Waldo_fnc_GunshipServerHandle;
["spectre_1", false] call Waldo_fnc_GunshipDestroy;
// Stop every system while preserving registered and spawned aircraft:
[false] call Waldo_fnc_GunshipStop;
```

The final destroy argument deletes the aircraft only when the feature originally spawned it. Registered editor aircraft are preserved.

## Focused Zeus modules

- **Gunship - Register or Spawn** offers allegiance and aircraft in one dialog; changing allegiance immediately refreshes friendly-name choices from compatible, turret-equipped side/faction aircraft pools. It generates the internal system key; Zeus never has to type a config classname or registry ID.
- **Gunship - Assign Controller** assigns the nearest player to a named system.
- **Gunship - Set Orbit** moves a named system to the module position.
- **Gunship - Operational Control** returns it on station, sends it for service, releases remote control or removes it.

Assignment, orbit and operational dialogs show callsigns and current state while retaining internal IDs only as hidden values. These are operational controls, not a general live-feature manager.

## Extension callbacks

Server-only configuration callbacks include `onStateChanged`, `onArrive`, `onDepart`, `onService`, `onDestroyed` and `onControllerChanged`. They receive the system ID and current server state, allowing mission-specific tasks, radio traffic, resource costs or objectives without changing the feature files.

## Engine boundaries

- Remote control depends on the target aircraft's actual turret paths and crew. Profiles require multiplayer testing for each supported aircraft mod.
- AI LOITER waypoints are advisory; aircraft handling, terrain and mods can prevent a perfectly stable circle.
- A human remote gunner is not silently constrained to a firing polygon. Mission callbacks can warn or release the operator, but projectile deletion would be intrusive and inconsistent.
- Service is an abstract orbit cycle rather than physical landing and taxiing. This avoids relying on aircraft-specific runway behaviour.
- Aircraft state is not automatically recreated through persistence. Missions may persist their own allocation state through the callbacks.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
