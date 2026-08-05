# Helicopter and Ground Transport Services

> **Use this page when:** you want reusable AI-crewed air or ground transports that players can call during a mission.

WMP Transport Services manages helicopters and ground vehicles in separate typed pools. A helicopter request can never reserve a ground vehicle, and two requests cannot reserve the same vehicle. The server owns registration, access rules, reservations, request IDs, requester identity, state and JIP-visible vehicle status. The machine currently owning the AI group performs movement, so server, headless-client and client-local AI are supported. Optional invulnerability covers only the vehicle and its original AI service crew; it is off by default and never protects passenger players.

## Beginner setup

Place an AI-crewed helicopter or land vehicle with simulation enabled. Put this in its Eden init field:

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One"] call Waldo_fnc_TransportRegister;
```

For a ground transport:

```sqf
[this, "GROUND", "GROUND_1", "Ground One"] call Waldo_fnc_TransportRegister;
```

The call forwards to server authority itself, so no `if (isServer)` wrapper is required. The vehicle must have a living AI driver. Its current position and direction become its base.

The optional fifth argument is a readable HashMap. Omit it for the safe defaults:

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One", createHashMapFromArray [
    ["leadersOnly", true],
    ["showMarker", true],
    ["cruiseAltitude", 90],
    ["boardingSeconds", 240],
    ["destinationDwell", 60],
    ["landingSearchRadius", 75],
    ["roadSearchRadius", 200],
    ["groundSpeedLimit", 60],
    ["pathRetrySeconds", 25],
    ["pathRetryLimit", 3],
    ["repairAtBase", false],
    ["refuelAtBase", true],
    ["forceDisembark", false],
    ["failSafeReset", false]
]] call Waldo_fnc_TransportRegister;
```

Each registered vehicle has a WMP-blue informational action naming it as a **Helicopter Transport** or **Ground Transport**. The vehicle's ACE category and vanilla controls always include its configured name and affect that exact vehicle.

To travel:

1. Open **ACE Self Interact > WMP Transport**.
2. Choose **Helicopter Transport** or **Ground Transport**, then **Request / Move Pickup** and click the desired point on the map.
3. Wait for the named service and board it.
4. While aboard, return to the same self-interaction menu and choose **Select Destination**.
5. Click the destination on the map and disembark after arrival. **Return This Transport to Base** cancels that named transport's current journey.

### Multiple transports and changing a request

- The normal request path manages one active helicopter and one active ground transport per player.
- The first menu level is deliberately short and scalable: **Helicopter Transport** and **Ground Transport**. Air and ground controls do not compete for the same radial-menu space.
- **Request / Move Pickup** requests the first service, or retargets that player's single inbound/boarding service of the same type.
- **Select / Manage Transport** opens one live alphabetical list. Available services can be requested directly; active services reserved by or carrying the player expose move, destination, retry and RTB controls. Zeus can manage every active service. This replaces the old separate “Request Another” and “Manage Active Services” entries.
- **Request All Available** dispatches every eligible available transport of that type around one clicked centre. WMP uses enlarged, separate search slots instead of sending the fleet to one coordinate, then shows one combined result card instead of one card per vehicle.
- **Return All Controlled to Base** returns every active same-type transport reserved by you or carrying you. Zeus may return every active transport of that type. “Available” vehicles are already at base and are therefore not included in RTB.
- Repeating **Request Pickup** while that player's same-type transport is inbound or boarding moves the existing transport's pickup point. It never silently reserves a second vehicle.
- Retargeting publishes a new request token before redispatch. Superseded AI-owner loops stop before they can land, stop or report against the old point.
- The same named controls also exist directly on each transport. Being inside or near another transport no longer changes which object the action addresses.
- The original requester may move pickup or order RTB while outside the vehicle. A passenger may select destination or order RTB for the transport they occupy. Zeus may manage any registered transport.
- Once a transport is travelling to a destination, disembarking or returning, a repeated pickup is refused with the existing transport's name and state. Return it to base or let its lifecycle complete before requesting another of that type.

### If a transport becomes stuck

The ground controller watches progress and reselects its existing route up to `pathRetryLimit` times. If the vehicle still cannot progress, or either transport type exceeds its journey deadline, the server publishes **STUCK** rather than silently losing the reservation. The requester and player passengers receive the transport name and failed phase. Clear the obstruction, then use **Select / Manage Transport > [name] > Retry Current Route**, use the same control directly on the vehicle, or order that exact transport to RTB. Emergency teleport remains off unless `failSafeReset` was explicitly enabled.

When ACE Interact is unavailable, WMP-blue scroll-wheel pickup actions preserve the essential request path. If ACE is installed but still initialising, WMP waits for it instead of leaving duplicate scroll-wheel actions beside the ACE category.

## What the system does after each click

The client only opens the map and sends the chosen point. The server then selects and atomically reserves the nearest eligible service from the requested typed pool. It resolves a reachable service point, records a unique request number and tells the machine currently owning that AI group to move. That owner can be the server, a headless client or another client; if locality changes mid-journey, dispatch transfers to the new owner without allowing an old arrival report to complete the newer task.

Helicopters receive a real departure `MOVE` waypoint followed by Arma's supported `SCRIPTED` landing waypoint using `A3\functions_f\waypoints\fn_wpLand.sqf`. When improved landing is enabled, its local tracker recognises that landing script and takes over the approach. If it cannot acquire, Arma's landing script and the invisible-helipad `landAt` fallback continue the same landing order. WMP never uses the invalid `LAND` waypoint type.

At pickup the vehicle stops and enters **BOARDING**. It does not know a destination yet. After a passenger uses **Select Destination**, the service explicitly releases the pickup stop order and begins a new **TO_DESTINATION** movement. At destination it enters **DISEMBARKING**, waits for passengers to leave or for the configured dwell timer, then physically returns to its recorded base. Emergency teleport is disabled by default; an empty service that fails physical RTB may reset only when the mission maker explicitly enables `failSafeReset`.

### Ground transport movement

- The selected point is moved to the nearest connected road inside `roadSearchRadius` when one exists. Open terrain remains usable when no road is found.
- Ground transports use one waypoint path, SAFE driving and the `groundSpeedLimit` cap. WMP does not add a competing direct-drive order.
- When both the transport and resolved destination are on roads, the driver is told to follow roads. Off-road endpoints retain normal terrain pathfinding.
- Every new phase clears old waypoints, releases persistent `doStop` state and creates one exact waypoint.
- If the transport makes no useful progress for `pathRetrySeconds`, WMP reselects the existing waypoint up to `pathRetryLimit` times. This can recover a stale AI order without overriding the route planner, but it cannot make an unsuitable vehicle cross impassable terrain or repair a broken road network.
- Stops are resolved to clear vehicle positions and kept at least `minimumSeparation` metres from other active ground-service targets. The default is 18 metres. Arma still owns route planning, so two vehicles can meet on a narrow road; WMP prevents intentional shared endpoints rather than pretending it can guarantee traffic separation everywhere.

### Helicopter movement

- A clicked point is accepted only when a safe landing point can be found inside `landingSearchRadius`, which defaults to 75 metres. The notification reports adjustments greater than 10 metres and the destination marker shows the actual service point.
- WMP creates an invisible helipad at that exact resolved point and uses `landAt` for the touchdown.
- Air Transport uses the normal improved-helicopter-landing path by default. It first creates a 75 m departure MOVE waypoint so Arma cannot complete the landing task while the helicopter is still parked, then creates the supported LAND waypoint. The same global, locality-aware tracker used by every other AI helicopter acquires that second waypoint at the standard speed-aware distance. Transport only monitors touchdown and request state. The invisible-helipad `landAt` controller remains a fallback when the normal controller does not acquire or aborts.
- The service uses an exact MOVE waypoint followed by the dedicated landing order. It does not use `TR UNLOAD`, whose dedicated-server behaviour is unsuitable for an AI-crewed aircraft carrying only player passengers.
- Active helicopter LZs are kept at least `minimumSeparation` metres apart; the default is 60 metres. Bulk pickup lays out a deterministic grid of separated landing slots around the clicked centre.

These choices follow Bohemia's documented behaviour: [`doStop` must be released with `doFollow`](https://community.bohemia.net/wiki/doFollow), a zero-radius [`addWaypoint`](https://community.bohemia.net/wiki/addWaypoint) can still be shifted while radius `-1` is exact, and [`landAt`](https://community.bohemia.net/wiki/landAt) targets a specific helipad.

## Per-service options

| Option | Beginner meaning |
|---|---|
| `landingSearchRadius` | Maximum metres a helicopter LZ may move away from the clicked point. |
| `roadSearchRadius` | Maximum metres searched for a road around a ground-transport click. |
| `minimumSeparation` | Minimum metres between active destinations and bulk service slots. Defaults to 60 for helicopters and 18 for ground vehicles. Prepared bases may be closer; registration rejects only physically overlapping vehicle footprints. |
| `groundSpeedLimit` | Maximum ground-transport speed in km/h. |
| `pathRetrySeconds` | Seconds without progress before the driver receives the same order again. |
| `pathRetryLimit` | Maximum retries during one pickup, destination or RTB journey. |
| `useImprovedLanding` | Default `true`: use WMP's vector approach and flare. Set `false` only to force the simpler invisible-helipad `landAt` fallback. |
| `invulnerable` | Default `false`: when enabled, protects the transport and its original AI service crew across locality changes. Passenger players remain vulnerable. |
| `failSafeReset` | Default `false`; opt-in emergency teleport after an empty physical RTB fails. |

## ZEN and lifecycle

Use **WMP Transport > Transport Service - Register** on an existing AI-crewed vehicle. The dialog selects the service type independently, provides a player-facing display name and plain-language timing/recovery settings, and rejects a type/vehicle mismatch. Internal service IDs are always generated automatically and are never exposed to Zeus. A successful registration publishes the pool availability, installs player controls, creates the optional marker and renames the AI crew group to the display name. A rejected registration sends Zeus the exact reason. **Transport Service - Return to Base** immediately cancels a selected registered service without an extra confirmation dialog.

Registrations survive WMP vehicle-recovery reconstruction through the built-in `Waldo_TransportService_Registration` recovery variable. Deleted/dead services are removed from the server registry and their markers. Player actions are reinstalled after respawn and JIP availability is published by type.

RTB always targets the service's exact registered base position. The generic safe-position search is
used for player-selected stops, not for returning a service to its own prepared parking point.

Global defaults live in `MissionConfig\logisticsConfig.sqf`. `Waldo_TransportServices_Enable` enables the inert framework; no vehicles exist until they are registered.

All Transport feedback uses the master WMP notification system. Each named vehicle owns an independent replacement channel, so simultaneous services use global stacking and overflow while repeated state from one vehicle coalesces. Theme, colour-vision presentation, queue limits and ACE-interaction suppression are inherited automatically.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
