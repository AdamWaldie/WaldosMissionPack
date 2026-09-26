# Vehicle Ambush and Camo

> **Use this page when:** you need a concealed vehicle that reveals itself when its ambush conditions are met.

_Associated Files: `MissionScripts\Logistics\VehicleCamoScript\vehicleCamo.sqf`, `Waldo_fnc_VehicleCamoSetup`_

The vehicle gets ACE actions to show and hide synchronized camo objects. Deploying also moves the activating player's current group into a civilian group. This legacy script changes group membership and removes several event-handler types during reveal, so check its interaction with the rest of your mission.

## Set it up in Eden

1. Place the vehicle and give it an Eden variable name.
2. Place one Game Logic near it. The script uses the nearest Logic, so keep unrelated Logics farther away.
3. Place the camo objects where they should appear. Synchronize each one to the Game Logic.
4. Put this call in the vehicle's **Init** field:

```sqf
[this] call Waldo_fnc_VehicleCamoSetup;
```

The server attaches and hides the synchronized props at startup. Players need ACE3 for the actions and progress bars. The vehicle must have more than five nearby trees or bushes within 20 m before the deploy action appears. It must also be on the ground, moving below 2 km/h, with the player within 7 m.

## Parameters and result

| Position | Type | Default | What to supply |
| --- | --- | --- | --- |
| 0 | Object | Required | Existing vehicle carrying the nearest Game Logic's synchronized camo objects. |

The setup call has no documented return value. Eden Init runs on server and clients. The server prepares the props and publishes the initial deployed state. Each interface installs ACE actions.

There is no duplicate-action guard, so call it once per object. Eden Init runs for joining clients. A vehicle created during play needs its own client/JIP setup.

## During play

**Deploy Vehicle Camouflage** takes ten seconds. It reveals the props and shifts the activating player's group to civilian. The script then checks for a group member more than 40 m from the vehicle and for an enemy unit within 150 m of it. It does not query Arma's `knowsAbout` value. Vehicle fire or a vehicle/player hit also attempts to return the group to its original side. Arma may delay the visible side change.

**Remove Vehicle Camouflage** also takes ten seconds and hides the props. Starting the engine hides them as well. Fire, damage or enemy proximity can end the side disguise while leaving the props visible until removal or engine start.

## If concealment does not deploy

Check that ACE3 is loaded, the Init call runs, and the nearest Game Logic has the intended synchronized objects. At the deploy point, the script requires more than five nearby trees or bushes. The action also requires a stationary grounded vehicle and a player within 7 m.

This legacy script removes all **GetIn**, **GetOut**, **Hit**, **Fired** and **Engine** event handlers on some reveal or removal paths. It can disrupt other features using those handlers. It also does not track a worker ID for the recurring concealment check. Test repeated deployment, group-side restoration and interaction with other vehicle scripts in a disposable mission before using it in live play.

## See also

* [Simple Mass Attach Items](Simple-Mass-Attach-Items): attach static objects to a vehicle manually
* [Construction Objects](Construction-Objects)
* [Waldos AI Tweak](Waldos-AI-Tweak): configure AI skill settings

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
