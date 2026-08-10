# Transport Services (helicopter + ground + boat)

Reusable server-reserved AI transport pools — players request pickup/
destination from a registered vehicle's crew via ACE Self Interact, the
server reserves and dispatches it. Helicopters, ground vehicles and boats
are separate typed pools; a request can never cross-reserve.

## Config (`MissionConfig\logisticsConfig.sqf`)

```sqf
["Waldo_TransportServices_Enable", true, true],     // server: enables the inert framework; vehicles still need registration
["Waldo_Transport_TravelTimeout", 900, false],       // max seconds for one pickup/destination/RTB leg
["Waldo_Transport_DefaultBoardingSeconds", 300, false],
["Waldo_Transport_DefaultDestinationDwell", 45, false],
["Waldo_HeliTransport_DefaultAltitude", 50, false],
["Waldo_HeliTransport_DefaultLzSearchRadius", 500, false],
["Waldo_HeliTransport_DefaultLzClearanceScale", 1.5, false], // multiplier on real helicopter model bounding box
["Waldo_HeliTransport_DefaultSeparation", 60, false],
["Waldo_GroundTransport_DefaultRoadSearchRadius", 200, false],
["Waldo_GroundTransport_DefaultSeparation", 18, false],
["Waldo_GroundTransport_DefaultSpeedLimit", 60, false],
["Waldo_BoatTransport_DefaultWaterSearchRadius", 300, false],
["Waldo_BoatTransport_DefaultSeparation", 25, false],
["Waldo_BoatTransport_DefaultSpeedLimit", 45, false],
["Waldo_Transport_DefaultPathRetrySeconds", 25, false],
["Waldo_Transport_DefaultPathRetryLimit", 3, false]
```

Enabling the framework spawns nothing by itself — a vehicle must still be
registered ("enable + register" pattern).

## Registering a vehicle (Eden init field or `initServer.sqf`)

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One"] call Waldo_fnc_TransportRegister;
[this, "GROUND", "GROUND_1", "Ground One"] call Waldo_fnc_TransportRegister;
[this, "BOAT", "BOAT_1", "Boat One"] call Waldo_fnc_TransportRegister;
```

Forwards to server authority automatically — no `if (isServer)` wrapper
needed. The vehicle needs a living AI driver and simulation enabled; its
current position/direction becomes its base. Optional fifth-argument
HashMap overrides per-service options (`leadersOnly`, `showMarker`,
`cruiseAltitude`, `boardingSeconds`, `destinationDwell`,
`landingSearchRadius`, `roadSearchRadius`, `groundSpeedLimit`,
`waterSearchRadius`, `boatSpeedLimit`, `pathRetrySeconds`, `pathRetryLimit`,
`avoidRoadObstacles`, `repairAtBase`, `refuelAtBase`, `forceDisembark`,
`failSafeReset`, `invulnerable`, `useImprovedLanding`) — see
`wiki/Transport-Services.md` for the full table if a specific option needs
tuning. Ground and boat services stall-detect and reissue the same order up
to `pathRetryLimit` times; ground additionally drops its road-follow order
(`avoidRoadObstacles`, default `true`) on the first retry so off-road
pathfinding can route the AI driver around a parked vehicle or wreck
blocking that road segment. Boats have no road equivalent to drop.

Boat destination/pickup points must resolve to open water — the clicked
position (and a small ring of points around it, so the boat doesn't beach
right at the shoreline) must all read `surfaceIsWater`, searched outward up
to `waterSearchRadius`. A landlocked click is rejected with a clear reason.
This is a documented limitation, not full navigable-water routing: it
cannot detect an island or headland sitting between the boat and the
resolved point.

## Player usage

**ACE Self Interact > WMP Transport > Helicopter/Ground/Boat Transport >
Request / Move Pickup**, click the map, board, then **Select Destination**.
**Select / Manage Transport** lists every service by name with move/
destination/retry/RTB controls. **Request All Available** dispatches every
eligible vehicle of that type around one clicked centre. **Return All
Controlled to Base** returns everything reserved by or carrying the player.
A stuck transport publishes **STUCK** rather than silently dropping the
reservation — retry via the same menu or send it to RTB.

External vehicle interaction (approaching the vehicle from outside) is
identification/status only — it names the vehicle and reports its current
state. The operational controls (move pickup, select destination, RTB,
retry) live in that exact vehicle's **own ACE self-interaction tree** —
any player physically occupying it can reach them there, independent of
who originally requested it or which seat they're in. An occupant can
select a destination immediately after boarding at base without a prior
pickup request. Outside the vehicle, only the original requester may move
pickup or order RTB; a passenger inside may select destination or order
RTB for the transport they occupy; Zeus may manage any registered
transport. The server validates control against exact current crew
membership (object + UID) — a request from someone not actually aboard is
rejected, so this can't be spoofed by proximity alone.

## Zeus

**WMP Transport > Transport Service - Register** (on an existing AI-crewed
vehicle; dialog picks type — helicopter, ground or boat — display name,
timing/recovery in plain language) and **Transport Service - Return to
Base**.

## Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Transport_Services_Example_Minimal` is a pre-crewed
helicopter and ground vehicle each registered with only the required
arguments (`createVehicleCrew this; [this, "HELICOPTER"/"GROUND"] call
Waldo_fnc_TransportRegister;`). `_Full` shows the same pair with LZ
clearance, improved-landing and other options set explicitly. Neither
composition currently ships a boat example; register one directly with the
`"BOAT"` type shown above.

## Gotchas

- At destination the transport waits (up to `destinationDwell`, default
  `45`s) for every player passenger to physically leave before ordering
  RTB — it never forces anyone out by default. Only with `forceDisembark`
  explicitly enabled does WMP request `moveOut` at the timeout, giving a
  short exit-animation grace before RTB. A newer destination/RTB order
  always invalidates a stale wait.
- Registrations survive WMP vehicle-recovery reconstruction via the
  built-in `Waldo_TransportService_Registration` recovery variable — no
  extra work needed if the mission also uses `vehicle-recovery-rallies.md`.
- Improved AI Helicopter Landing (see `ai-rebalance.md`) takes over the
  final approach automatically unless `useImprovedLanding` is set `false`
  on that registration. Ground and boat transports are unaffected.
- Optional `invulnerable` only protects the vehicle and its original AI
  service crew — never passenger players.
- Registration locks the driver seat to players and disables fleeing/panic
  on the captured AI crew (`allowFleeing 0`), so a driver taking fire
  can't strand the vehicle by bailing out.
- `Waldo_Transport_MaxEffectiveDamage` (`MissionConfig\logisticsConfig.sqf`,
  default `0.8`) writes a still-"alive" but too-heavily-damaged transport
  off the service pool the same as an outright loss, and warns every
  player on that service's `allowedSides` — unlike an obvious loss, a
  damaged vehicle quietly dropping out of availability needs telling.
- A boat requires `isKindOf "Ship"` at registration; a route that must pass
  close around land can still run the boat aground mid-journey even though
  its endpoint validated as open water — this is a real, documented
  limitation of the water-position search, not full pathfinding.
