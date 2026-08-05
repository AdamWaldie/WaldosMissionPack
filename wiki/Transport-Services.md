# Helicopter Transport and Ground Taxi Services

> **Use this page when:** you want reusable AI-crewed pickup and taxi vehicles that players can call during a mission.

WMP Transport Services manages helicopters and ground taxis in separate typed pools. A helicopter request can never reserve a ground vehicle, and two requests cannot reserve the same vehicle. The server owns registration, access rules, reservations, request IDs, state and JIP-visible vehicle status. The machine currently owning the AI group performs movement, so server, headless-client and client-local AI are supported.

## Beginner setup

Place an AI-crewed helicopter or land vehicle with simulation enabled. Put this in its Eden init field:

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One"] call Waldo_fnc_TransportRegister;
```

For a ground taxi:

```sqf
[this, "GROUND", "TAXI_1", "Taxi One"] call Waldo_fnc_TransportRegister;
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
    ["failSafeReset", true]
]] call Waldo_fnc_TransportRegister;
```

Each registered vehicle has a WMP-blue informational addAction naming it as a **Helicopter Transport Service** or **Ground Taxi Service**. Use that action if you encounter a vehicle and are unsure what it does.

To travel:

1. Open **ACE Self Interact > WMP Interface > Transport Services**.
2. Choose **Request Helicopter Pickup** or **Request Ground Taxi** and click the desired pickup point on the map.
3. Wait for the named service and board it.
4. While aboard, return to the same self-interaction menu and choose **Select Destination**.
5. Click the destination on the map and disembark after arrival. **Return Service to Base** cancels the current journey.

When ACE Interact is unavailable, WMP-blue scroll-wheel pickup actions preserve the essential request path.

## What the system does after each click

The client only opens the map and sends the chosen point. The server then selects and atomically reserves the nearest eligible service from the requested typed pool. It resolves a reachable service point, records a unique request number and tells the machine currently owning that AI group to move. That owner can be the server, a headless client or another client; if locality changes mid-journey, dispatch transfers to the new owner without allowing an old arrival report to complete the newer task.

At pickup the vehicle stops and enters **BOARDING**. It does not know a destination yet. After a passenger uses **Select Destination**, the service explicitly releases the pickup stop order and begins a new **TO_DESTINATION** movement. At destination it enters **DISEMBARKING**, waits for passengers to leave or for the configured dwell timer, then physically returns to its recorded base. Only an empty service that fails its RTB deadline may use `failSafeReset`.

### Ground taxi movement

- The selected point is moved to the nearest connected road inside `roadSearchRadius` when one exists. Open terrain remains usable when no road is found.
- Ground taxis default to NORMAL waypoint speed plus the `groundSpeedLimit` cap rather than full-speed AI driving.
- Every new phase clears old waypoints, releases persistent `doStop` state, creates an exact waypoint and issues a fresh driver movement order.
- If the taxi makes no useful progress for `pathRetrySeconds`, WMP reissues that movement order up to `pathRetryLimit` times. This can recover a stale AI order, but it cannot make an unsuitable vehicle cross impassable terrain or repair a broken road network.

### Helicopter movement

- A clicked point is accepted only when a safe landing point can be found inside `landingSearchRadius`, which defaults to 75 metres. The notification reports adjustments greater than 10 metres and the destination marker shows the actual service point.
- WMP creates an invisible helipad at that exact resolved point and uses `landAt` for the touchdown.
- Registered service helicopters are excluded from the global improved-helicopter-landing controller by default. The transport system owns takeoff, landing, waiting and RTB, preventing two flight controllers from fighting over one aircraft. Advanced registrations may set `useImprovedLanding` true, but this is deliberately not the default.
- The service uses an exact MOVE waypoint followed by the dedicated landing order. It does not use `TR UNLOAD`, whose dedicated-server behaviour is unsuitable for an AI-crewed aircraft carrying only player passengers.

These choices follow Bohemia's documented behaviour: [`doStop` must be released with `doFollow`](https://community.bohemia.net/wiki/doFollow), a zero-radius [`addWaypoint`](https://community.bohemia.net/wiki/addWaypoint) can still be shifted while radius `-1` is exact, and [`landAt`](https://community.bohemia.net/wiki/landAt) targets a specific helipad.

## Per-service options

| Option | Beginner meaning |
|---|---|
| `landingSearchRadius` | Maximum metres a helicopter LZ may move away from the clicked point. |
| `roadSearchRadius` | Maximum metres searched for a road around a ground-taxi click. |
| `groundSpeedLimit` | Maximum ground-taxi speed in km/h. |
| `pathRetrySeconds` | Seconds without progress before the driver receives the same order again. |
| `pathRetryLimit` | Maximum retries during one pickup, destination or RTB journey. |
| `useImprovedLanding` | Advanced compatibility switch; false gives the transport service exclusive landing control. |

## ZEN and lifecycle

Use **WMP Logistics > Transport Service - Register** on an existing AI-crewed vehicle. The dialog selects the service type independently, provides plain-language timing and recovery settings, and rejects a type/vehicle mismatch. **Transport Service - Return to Base** cancels a selected registered service.

Registrations survive WMP vehicle-recovery reconstruction through the built-in `Waldo_TransportService_Registration` recovery variable. Deleted/dead services are removed from the server registry and their markers. Player actions are reinstalled after respawn and JIP availability is published by type.

Global defaults live in `MissionConfig\logisticsConfig.sqf`. `Waldo_TransportServices_Enable` enables the inert framework; no vehicles exist until they are registered.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
