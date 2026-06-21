_Associated Files: `MissionScripts\Logistics\VehicleCamoScript\vehicleCamo.sqf`, `Waldo_fnc_VehicleCamoSetup` (script by Val & Waldo)_

# Vehicle Ambush / Vehicle Camo

Lets a crew **conceal a vehicle for an ambush** by deploying a set of "camo" objects (foliage, netting, scenery) over it on demand, via an ACE action. While concealed, the crew may dismount and move a short distance around the vehicle disguised as civilians — until something blows the ambush.

## How the concealment breaks

The player is automatically returned to their own side (with a potential engine-imposed delay of up to ~30 seconds) if they:

* Are **spotted** by the enemy
* **Fire the vehicle's weapons**
* Move **more than 40 m** from the vehicle
* Take **damage** (player or vehicle)

The camo objects themselves **remain in place** until the vehicle moves, or the crew removes them with the provided ACE action — so breaking concealment doesn't instantly un-hide the vehicle.

## Requirements

* **ACE3** — the deploy/remove actions use the ACE interaction menu. The function silently exits if ACE is not loaded.
* Designed for **vehicles**.

## Parameters

| # | Parameter | Type | Purpose |
|---|---|---|---|
| 0 | Target | Object | The vehicle (or object) the camo is deployed from. |

## Setup in Eden

1. Place the **vehicle** and give it a variable name.
2. Place a **Game Logic** as close as possible to it (near the Modules menu).
3. Place every object you want to appear when the camo is deployed.
4. If a camo object should rest on the ground, raise it ~1 ft to allow for the vehicle's suspension settling once the mission loads.
5. Select all the camo objects, right-click → **Synchronise** them to the Game Logic.
6. In the vehicle's **init field**, call the function:

```sqf
[this] call Waldo_fnc_VehicleCamoSetup;
```

The synced objects start hidden and are revealed (and attached) when the crew deploys the camo via the ACE action.

Below is an example of a camo system set up in the Eden editor — the tank is the interaction object:
![Camo script example in the editor](https://i.imgur.com/dlyoKsk.png)

## See also

* [Simple Mass Attach Items](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Simple-Mass-Attach-Items) — attach static objects to a vehicle permanently
* [Construction Objects](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Construction-Objects)
* [Waldos AI Tweak](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-AI-Tweak) — tune how easily AI spot your ambush
