# Transport Services (helicopter + ground)

Reusable server-reserved AI transport pools — players request pickup/
destination from a registered vehicle's crew via ACE Self Interact, the
server reserves and dispatches it. Helicopters and ground vehicles are
separate typed pools; a request can never cross-reserve.

## Config (`MissionConfig\logisticsConfig.sqf`)

```sqf
["Waldo_TransportServices_Enable", true, true],     // server: enables the inert framework; vehicles still need registration
["Waldo_Transport_TravelTimeout", 900, false],       // max seconds for one pickup/destination/RTB leg
["Waldo_Transport_DefaultBoardingSeconds", 300, false],
["Waldo_Transport_DefaultDestinationDwell", 45, false],
["Waldo_HeliTransport_DefaultAltitude", 50, false],
["Waldo_HeliTransport_DefaultLzSearchRadius", 250, false],
["Waldo_HeliTransport_DefaultLzClearanceScale", 2.0, false], // multiplier on real helicopter model bounding box
["Waldo_HeliTransport_DefaultSeparation", 60, false],
["Waldo_GroundTransport_DefaultRoadSearchRadius", 200, false],
["Waldo_GroundTransport_DefaultSeparation", 18, false],
["Waldo_GroundTransport_DefaultSpeedLimit", 60, false],
["Waldo_Transport_DefaultPathRetrySeconds", 25, false],
["Waldo_Transport_DefaultPathRetryLimit", 3, false]
```

Enabling the framework spawns nothing by itself — a vehicle must still be
registered ("enable + register" pattern).

## Registering a vehicle (Eden init field or `initServer.sqf`)

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One"] call Waldo_fnc_TransportRegister;
[this, "GROUND", "GROUND_1", "Ground One"] call Waldo_fnc_TransportRegister;
```

Forwards to server authority automatically — no `if (isServer)` wrapper
needed. The vehicle needs a living AI driver and simulation enabled; its
current position/direction becomes its base. Optional fifth-argument
HashMap overrides per-service options (`leadersOnly`, `showMarker`,
`cruiseAltitude`, `boardingSeconds`, `destinationDwell`,
`landingSearchRadius`, `roadSearchRadius`, `groundSpeedLimit`,
`pathRetrySeconds`, `pathRetryLimit`, `repairAtBase`, `refuelAtBase`,
`forceDisembark`, `failSafeReset`, `invulnerable`, `useImprovedLanding`,
`keepEngineOnAway`) — see `wiki/Transport-Services.md` for the full table
if a specific option needs tuning.

## Player usage

**ACE Self Interact > WMP Transport > Helicopter/Ground Transport > Request
/ Move Pickup**, click the map, board, then **Select Destination**. **Select
/ Manage Transport** lists every service by name with move/destination/
retry/RTB controls. **Request All Available** dispatches every eligible
vehicle of that type around one clicked centre. **Return All Controlled to
Base** returns everything reserved by or carrying the player. A stuck
transport publishes **STUCK** rather than silently dropping the
reservation — retry via the same menu or send it to RTB.

## Zeus

**WMP Transport > Transport Service - Register** (on an existing AI-crewed
vehicle; dialog picks type, display name, timing/recovery in plain
language) and **Transport Service - Return to Base**.

## Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Transport_Services_Example_Minimal` is a pre-crewed
helicopter and ground vehicle each registered with only the required
arguments (`createVehicleCrew this; [this, "HELICOPTER"/"GROUND"] call
Waldo_fnc_TransportRegister;`). `_Full` shows the same pair with LZ
clearance, improved-landing and other options set explicitly, including
`keepEngineOnAway`.

## Gotchas

- Registrations survive WMP vehicle-recovery reconstruction via the
  built-in `Waldo_TransportService_Registration` recovery variable — no
  extra work needed if the mission also uses `vehicle-recovery-rallies.md`.
- Improved AI Helicopter Landing (see `ai-rebalance.md`) takes over the
  final approach automatically unless `useImprovedLanding` is set `false`
  on that registration.
- Optional `invulnerable` only protects the vehicle and its original AI
  service crew — never passenger players.
- Registration locks the driver seat to players and blocks the captured AI
  crew from dismounting (`allowGetOut false`), so a driver taking fire or
  reacting to nearby infantry can't strand the vehicle by bailing out.
- `Waldo_Transport_MaxEffectiveDamage` (`MissionConfig\logisticsConfig.sqf`,
  default `0.8`) writes a still-"alive" but too-heavily-damaged transport
  off the service pool the same as an outright loss, and warns every
  player on that service's `allowedSides` — unlike an obvious loss, a
  damaged vehicle quietly dropping out of availability needs telling.
- `keepEngineOnAway` (helicopters only, default `true`) re-asserts
  `engineOn true` right after touchdown at a pickup/destination stop away
  from base, overriding vanilla `TR UNLOAD`'s engine idle-down. RTB
  shutdown is unaffected either way — set `false` to restore the old
  idle-down-away-from-base behaviour.
