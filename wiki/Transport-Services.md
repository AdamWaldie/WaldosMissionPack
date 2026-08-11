# Helicopter, Ground and Boat Transport Services

> **Use this page when:** you want reusable AI-crewed air, ground or water transports that players can call during a mission.

WMP Transport Services manages helicopters, ground vehicles and boats in separate typed pools. A helicopter request can never reserve a ground vehicle or a boat, and two requests cannot reserve the same vehicle. The server owns registration, access rules, reservations, request IDs, requester identity, state and JIP-visible vehicle status. The machine currently owning the AI group performs movement, so server, headless-client and client-local AI are supported. Optional invulnerability covers only the vehicle and its original AI service crew; it is off by default and never protects passenger players.

## Beginner setup

Place a helicopter or land vehicle with simulation enabled, then place a correctly sided AI driver
inside it in Eden. Put this in the vehicle's init field:

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One"] call Waldo_fnc_TransportRegister;
```

For a ground transport:

```sqf
[this, "GROUND", "GROUND_1", "Ground One"] call Waldo_fnc_TransportRegister;
```

For a boat transport:

```sqf
[this, "BOAT", "BOAT_1", "Boat One"] call Waldo_fnc_TransportRegister;
```

`WMP_Compositions/[WMP]Transport_Services_Example_Minimal` and `_Full` are drop-in Eden examples with
all three types (helicopter, ground, boat) pre-placed and pre-crewed - the fastest way to see a
working registration before writing your own. Move the boat object onto/adjacent to water yourself
after placing the composition.

No `if (isServer)` wrapper and no `createVehicleCrew this` line are required. Eden runs an object init
on every machine, but WMP deliberately lets only the authoritative server register the service.
Registration never creates or replaces crew: this avoids duplicate and `sideUnknown` AI on dedicated
servers and keeps the vehicle's allegiance visible in Eden. Its current position and direction become
its base. An empty vehicle is rejected with a clear error; add its AI driver and register it again.

The optional fifth argument is a readable HashMap. Omit it for the safe defaults:

```sqf
[this, "HELICOPTER", "RAVEN_1", "Raven One", createHashMapFromArray [
    ["leadersOnly", true],
    ["showMarker", true],
    ["cruiseAltitude", 90],
    ["boardingSeconds", 240],
    ["destinationDwell", 60],
    ["landingSearchRadius", 500],
    ["roadSearchRadius", 200],
    ["groundSpeedLimit", 60],
    ["waterSearchRadius", 300],
    ["boatSpeedLimit", 45],
    ["pathRetrySeconds", 25],
    ["pathRetryLimit", 3],
    ["avoidRoadObstacles", true],
    ["repairAtBase", false],
    ["refuelAtBase", true],
    ["forceDisembark", false],
    ["failSafeReset", false]
]] call Waldo_fnc_TransportRegister;
```

Each registered vehicle has a WMP-blue informational action naming it as a **Helicopter Transport**, **Ground Transport** or **Boat Transport** and reporting its current state - installed as a vanilla `addAction` alongside ACE, not only as a fallback when ACE is absent, so it's reachable without opening ACE Self Interact first. The vehicle's ACE category and vanilla controls always include its configured name and affect that exact vehicle; the four operational controls (move pickup, select destination, RTB, retry) remain ACE-priority with a vanilla fallback only when ACE genuinely isn't available.

The optional service marker (`showMarker`) shows `<display name> - <state>` (for example `Raven One - Available`, `Raven One - To Pickup`, `Raven One - RTB`) and is kept in sync with the service's live position, facing and state every server tick - not just its display name at registration time. Set `showMarker` to `false` for a map-clutter-free operation instead.

To travel:

1. Open **ACE Self Interact > WMP Transport**.
2. Choose **Helicopter Transport**, **Ground Transport** or **Boat Transport**, then **Request / Move Pickup** and click the desired point on the map.
3. Wait for the named service and board it.
4. While aboard, return to the same self-interaction menu and choose **Select Destination**.
5. Click the destination on the map and disembark after arrival. **Return This Transport to Base** cancels that named transport's current journey.

Every registered transport also exposes **Send to Destination** and **Return This Transport to
Base** directly on the vehicle through ACE interaction. These two controls are available to every
player currently inside that exact transport, regardless of who requested it or which seat they
occupy. The map click and RTB order still use the normal server-authoritative request path, and the
server rejects a forged request unless the player is actually part of the vehicle crew. An occupant
can select a destination immediately after boarding a registered transport at its base; a prior pickup
request is not required. RTB remains available to occupants unless that exact transport is already
returning to base.

### Multiple transports and changing a request

- The normal request path manages one active helicopter, one active ground transport and one active boat per player.
- The first menu level is deliberately short and scalable: **Helicopter Transport**, **Ground Transport**, **Boat Transport** and **All Transports**. Per-type and fleet-wide controls do not compete for the same radial-menu space.
- **Request / Move Pickup** requests the first service, or retargets that player's single inbound/boarding service of the same type.
- **Select / Manage Transport** opens one live alphabetical list. Available services can be requested directly; active services reserved by or carrying the player expose move, destination, retry and RTB controls. Issuing an instruction does not remove this control surface: the named row remains available to its requester until the transport finishes RTB and becomes available again. WMP matches both the live player object and UID so hosted play, respawn/JIP object replacement and dedicated-server use remain reliable. Zeus can manage every active service. This replaces the old separate “Request Another” and “Manage Active Services” entries.
- **All Transports** groups every action that affects the whole fleet rather than one named vehicle: **Request All Available Helicopters/Ground Vehicles/Boats** dispatches every eligible available transport of that type around one clicked centre (WMP uses enlarged, separate search slots instead of sending the fleet to one coordinate, then shows one combined result card instead of one card per vehicle), and **Return All Helicopters/Ground Vehicles/Boats to Base** returns every active same-type transport reserved by you or carrying you (Zeus may return every active transport of that type; “Available” vehicles are already at base and are therefore not included).
- Repeating **Request Pickup** while that player's same-type transport is inbound or boarding moves the existing transport's pickup point. It never silently reserves a second vehicle.
- **Select Destination** works the same way once a destination is already set: choosing it again while the transport is already travelling to that destination (`TO_DESTINATION`) retargets it, the same as retargeting a pickup - it does not require returning to `BOARDING` first.
- Retargeting publishes a new request token before redispatch. Superseded AI-owner loops stop before they can land, stop or report against the old point.
- The same named controls also exist directly on each transport. Being inside or near another transport no longer changes which object the action addresses.
- The original requester may move pickup or order RTB while outside the vehicle. A passenger may select destination or order RTB for the transport they occupy. Zeus may manage any registered transport.
- Once a transport is travelling to a destination, disembarking or returning, a repeated pickup is refused with the existing transport's name and state. Return it to base or let its lifecycle complete before requesting another of that type.

### If a transport becomes stuck

The ground and boat controller watches progress and reselects its existing route up to `pathRetryLimit` times. If the vehicle still cannot progress, or any transport type exceeds its journey deadline, the server publishes **STUCK** rather than silently losing the reservation. The requester and player passengers receive the transport name and failed phase. Clear the obstruction, then use **Select / Manage Transport > [name] > Retry Current Route**, use the same control directly on the vehicle, or order that exact transport to RTB. Emergency teleport remains off unless `failSafeReset` was explicitly enabled.

When ACE Interact is unavailable, WMP-blue scroll-wheel pickup actions preserve the essential request path. If ACE is installed but still initialising, WMP waits for it instead of leaving duplicate scroll-wheel actions beside the ACE category.

## What the system does after each click

The client only opens the map and sends the chosen point. The server then selects and atomically reserves the nearest eligible service from the requested typed pool. It resolves a reachable service point, records a unique request number and tells the machine currently owning that AI group to move. That owner can be the server, a headless client or another client; if locality changes mid-journey, dispatch transfers to the new owner without allowing an old arrival report to complete the newer task.

Helicopter pickup and empty RTB retain the proven `TR UNLOAD` approach. A passenger destination instead uses an ordinary `MOVE` route which WMP recognises as a landing route only while that registered transport's authoritative state is **TO_DESTINATION**. This avoids `TR UNLOAD` ordering cargo out independently of WMP's `forceDisembark` setting. It also avoids leaving Arma's scripted LAND task alive after WMP replaces the completed route with RTB, which could leave an accepted RTB request unable to move the aircraft. Both routes use the vehicle command `land "LAND"` inside 300 metres and a physical-touchdown check. WMP adds a required takeoff gate because the original distance-only test ordered an aircraft to land immediately when an LZ was selected within 300 metres of its base. Improved landing may take ownership of the final approach after physical takeoff; while it is active, Transport Services withholds the fallback LAND command.

At pickup the vehicle stops and enters **BOARDING**. It does not know a destination yet. After a passenger uses **Select Destination**, the service releases the stop order and begins a new **TO_DESTINATION** movement. At destination it enters **DISEMBARKING** and remains under the normal `LAND` command. WMP reads every occupied driver, commander, turret, FFV and cargo role through [`fullCrew`](https://community.bohemia.net/wiki/fullCrew); AI service crew may remain, but automatic RTB is forbidden while any human occupies any seat. This is intentionally stricter than reacting to the [`GetOut`](https://community.bohemia.net/wiki/Arma_3%3A_Event_Handlers) event, which reports one exit but does not prove that every player has finished leaving or that the aircraft has settled.

An empty cabin alone is not enough. WMP also requires continuous ground contact and low total velocity, following the same contact-plus-speed principle shown in Bohemia's safely-parked [`isTouchingGround`](https://community.bohemia.net/wiki/isTouchingGround) example. By default the aircraft must remain settled for three seconds and human-empty for two seconds. A player who starts disembarking just before touchdown therefore cannot cause an immediate RTB order during the landing bounce. `destinationDwell` no longer permits departure with occupants: when `forceDisembark` is enabled it only determines when WMP requests `moveOut`, after which WMP continues waiting until `fullCrew` is genuinely human-empty. With `forceDisembark` disabled, the service waits indefinitely for players to leave. The final automatic RTB request uses a dedicated server-authority wrapper that validates the completed request, calls the ordinary RTB path and records whether dispatch was accepted. A newer destination or manual RTB order invalidates the older wait.

### Ground transport movement

- The selected point is moved to the nearest connected road inside `roadSearchRadius` when one exists. Open terrain remains usable when no road is found.
- Ground transports use one waypoint path, SAFE driving and the `groundSpeedLimit` cap. WMP does not add a competing direct-drive order.
- When both the transport and resolved destination are on roads, the driver is told to follow roads. Off-road endpoints retain normal terrain pathfinding.
- Every new phase clears old waypoints, releases persistent `doStop` state and creates one exact waypoint.
- If the transport makes no useful progress for `pathRetrySeconds`, WMP reselects the existing waypoint up to `pathRetryLimit` times. This can recover a stale AI order without overriding the route planner, but it cannot make an unsuitable vehicle cross impassable terrain or repair a broken road network.
- The first reselect also drops the road-follow order (`avoidRoadObstacles`, default `true`) if it was active. A driver forced to follow a road cannot manoeuvre around a parked vehicle, wreck or roadblock sitting on that exact segment - releasing the road pin hands the stall back to the AI's own off-road pathfinding, which is where its real obstacle and vehicle avoidance lives. Set `avoidRoadObstacles` to `false` to keep retrying the identical road-locked path instead.
- Stops are resolved to clear vehicle positions and kept at least `minimumSeparation` metres from other active ground-service targets. The default is 18 metres. Arma still owns route planning, so two vehicles can meet on a narrow road; WMP prevents intentional shared endpoints rather than pretending it can guarantee traffic separation everywhere.

### Boat movement

- Boat transports share the same waypoint-based movement worker as ground transports (one waypoint path, progress-based stall detection reissuing up to `pathRetryLimit` times), but skip the road-follow logic entirely - there is no water equivalent of a road network to pin to or drop.
- The selected point must resolve to open water. WMP requires the clicked position - and a small ring of points around it, at least `minimumSeparation` metres out - to all read `surfaceIsWater` before accepting it; a single water sample right at the shoreline edge is exactly the case that beaches a boat on arrival. Only a genuinely unsafe click starts a deterministic nearest-first search inside `waterSearchRadius` (default 300 metres).
- **This is a documented limitation, not full navigable-water routing.** WMP cannot detect an island, headland or other landmass sitting directly between the boat's current position and the resolved point - it only validates that the resolved point itself sits in clear water. A route that must pass close around land may still run the boat aground mid-journey; place boat services and destinations with a clear line of open water in mind.
- A landlocked click (no open water found within `waterSearchRadius`) is rejected outright with a clear reason - WMP never silently substitutes a different, unrelated location.
- Boat transports use the `boatSpeedLimit` cap (default 45 km/h) instead of `groundSpeedLimit`, and are kept at least `minimumSeparation` metres apart (default 25 for boats, vs. 18 for ground and 60 for helicopters).

### Helicopter movement

- WMP first validates the exact clicked point and keeps it unchanged when it is flat, on land, separated from another active LZ and clear for the aircraft. Only a genuinely unsafe click starts a deterministic nearest-first search inside `landingSearchRadius`, which defaults to 500 metres. WMP reads the aircraft's real model bounding box and expands both its width and length by `landingClearanceScale` (default 1.5). Arma's terrain check accepts a circle, so WMP uses the longer expanded half-axis rather than the box diagonal; this covers the scaled airframe axes without adding up to 41% of empty-corner overclearance. People standing at a requested pickup do not invalidate it, while another parked vehicle does. The notification reports adjustments greater than 10 metres and the destination marker shows the actual service point.
- WMP creates an invisible helipad at that exact resolved point. Pickup uses `TR UNLOAD`; destination uses a transport-state-qualified `MOVE` route; both retain the `land "LAND"` fallback and WMP's global locality-aware improved-landing controller.
- Registered air transports reacquire the improved controller immediately after physical takeoff, before the original 300 m LAND fallback can intervene. The controller now supplies a minimum approach-entry speed instead of inheriting an almost stationary lift-off speed, preventing the former slow Little Bird approach without delaying transport takeover.
- Active helicopter LZs are kept at least `minimumSeparation` metres apart; the default is 60 metres. Bulk pickup lays out a deterministic grid of separated landing slots around the clicked centre.

These choices follow Bohemia's documented behaviour: [`doStop` must be released with `doFollow`](https://community.bohemia.net/wiki/doFollow), a zero-radius [`addWaypoint`](https://community.bohemia.net/wiki/addWaypoint) can still be shifted while radius `-1` is exact, and [`landAt`](https://community.bohemia.net/wiki/landAt) targets a specific helipad.

## Per-service options

| Option | Beginner meaning |
|---|---|
| `landingSearchRadius` | Maximum metres a helicopter LZ may move away from the clicked point. Default `500`. |
| `landingClearanceScale` | Multiplies the helicopter's real model width and length for LZ clearance. Default `1.5`; values below `1` are rejected. |
| `roadSearchRadius` | Maximum metres searched for a road around a ground-transport click. |
| `waterSearchRadius` | Maximum metres a boat service point may move away from the clicked position while searching for open water. Default `300`. |
| `minimumSeparation` | Minimum metres between active destinations and bulk service slots. Defaults to 60 for helicopters, 18 for ground vehicles and 25 for boats. Prepared bases may be closer; registration rejects only physically overlapping vehicle footprints. |
| `groundSpeedLimit` | Maximum ground-transport speed in km/h. |
| `boatSpeedLimit` | Maximum boat-transport speed in km/h. Default `45`. |
| `pathRetrySeconds` | Seconds without progress before the driver receives the same order again (ground and boat). |
| `pathRetryLimit` | Maximum retries during one pickup, destination or RTB journey (ground and boat). |
| `avoidRoadObstacles` | Ground only, default `true`: the first stalled retry drops the road-follow order so off-road pathfinding can route around whatever blocked the road. Set `false` to keep retrying the same road-locked path instead. |
| `useImprovedLanding` | Default `true`: apply WMP's vector-guided final approach to pickup `TR UNLOAD` and the destination's transport-qualified `MOVE` route. Set `false` to use the direct `land "LAND"` fallback only. |
| `destinationDwell` | Seconds before the optional forced-exit request. Default `45`. It never authorizes RTB while a human remains aboard. |
| `forceDisembark` | Default `false`: nobody is ejected and the transport waits for every player to leave. When true, WMP requests `moveOut` after `destinationDwell`, but RTB still waits for every human-occupied `fullCrew` row to clear. |
| `Waldo_Transport_DestinationSettleSeconds` | Advanced global safety setting. Continuous grounded/slow time required before automatic RTB; default `3` seconds. |
| `Waldo_Transport_DestinationEmptyConfirmSeconds` | Advanced global safety setting. Continuous human-empty confirmation required before automatic RTB; default `2` seconds. |
| `Waldo_Transport_DestinationSettleSpeedKph` | Advanced global safety setting. Maximum total speed still considered settled; default `5 km/h`. |

| `invulnerable` | Default `false`: when enabled, protects the transport and its original AI service crew across locality changes. Passenger players remain vulnerable. |
| `failSafeReset` | Default `false`; opt-in emergency teleport after an empty physical RTB fails. |

## ZEN and lifecycle

Use **WMP Transport > Transport Service - Register** on an existing AI-crewed vehicle. The dialog selects the service type independently, provides a player-facing display name and plain-language timing/recovery settings, and rejects a type/vehicle mismatch. Internal service IDs are always generated automatically and are never exposed to Zeus. A successful registration publishes the pool availability, installs player controls, creates the optional marker and renames the AI crew group to the display name—even when the registration originated from a remote curator and the AI group is owned by another machine. A rejected registration sends Zeus the exact reason. **Transport Service - Return to Base** immediately cancels a selected registered service without an extra confirmation dialog.

Registrations survive WMP vehicle-recovery reconstruction through the built-in `Waldo_TransportService_Registration` recovery variable. Deleted/dead services are removed from the server registry and their markers. Player actions are reinstalled after respawn and JIP availability is published by type.

Registration locks the driver seat to players and disables fleeing/panic on the captured AI service crew (`allowFleeing 0`) — a driver who bails out under fire otherwise stranded the vehicle the same way a dead driver would, just without the monitor's driver-death check ever catching it. A passenger who boards later as cargo is unaffected. A registered vehicle that becomes too heavily damaged to remain effective — `Waldo_Transport_MaxEffectiveDamage` in `MissionConfig\logisticsConfig.sqf`, default `0.8` — is written off the service pool the same way an outright loss is, and (unlike a self-evident loss) every player on the service's `allowedSides` gets a warning card naming it, since a vehicle quietly vanishing from availability otherwise has no explanation.

RTB always targets the service's exact registered base position. The generic safe-position search is
used for player-selected stops, not for returning a service to its own prepared parking point.

Global defaults live in `MissionConfig\logisticsConfig.sqf`. `Waldo_TransportServices_Enable` enables the inert framework; no vehicles exist until they are registered.

All Transport feedback uses the master WMP notification system. Each named vehicle owns an independent replacement channel, so simultaneous services use global stacking and overflow while repeated state from one vehicle coalesces. Theme, colour-vision presentation, queue limits and ACE-interaction suppression are inherited automatically.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
