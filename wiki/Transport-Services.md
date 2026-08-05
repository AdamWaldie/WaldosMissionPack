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

Helicopters use a WMP improved-AI-landing-compatible landing waypoint and stop at pickup/destination rather than immediately taking off again. Ground taxis resolve requested points to nearby roads. Return is physical by default. `failSafeReset` may reposition only an empty service that failed to return before the configured deadline; it never teleports players.

## ZEN and lifecycle

Use **WMP Logistics > Transport Service - Register** on an existing AI-crewed vehicle. The dialog selects the service type independently, provides plain-language timing and recovery settings, and rejects a type/vehicle mismatch. **Transport Service - Return to Base** cancels a selected registered service.

Registrations survive WMP vehicle-recovery reconstruction through the built-in `Waldo_TransportService_Registration` recovery variable. Deleted/dead services are removed from the server registry and their markers. Player actions are reinstalled after respawn and JIP availability is published by type.

Global defaults live in `MissionConfig\logisticsConfig.sqf`. `Waldo_TransportServices_Enable` enables the inert framework; no vehicles exist until they are registered.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
