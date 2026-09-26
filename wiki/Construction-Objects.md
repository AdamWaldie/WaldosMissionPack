# Construction Objects

> **Use this page when:** you need synchronized construction objects, parameters, and Eden setup examples.

_Associated Files: `MissionScripts\Logistics\Construction\ConstructionObjects.sqf`, `Waldo_fnc_ConstructionObjects`_


Construction Objects gives one Eden object ACE actions to reveal or hide a set of synchronized props. Players see a progress bar and hear the selected construction sound. Put the props where they should appear before the mission starts.

The script attaches the synchronized props and their Game Logic to the interaction object. They keep their authored offset if that object moves. ACE cargo eligibility is a separate setting on the interaction object. This function does not make it loadable.

## Requirements

* **ACE3** supplies the interaction menu and progress bar. The function exits without installing actions if ACE is absent.

## Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Target | Object | Required | Existing object that players interact with. |
| 1 | Modern audio | Boolean | `false` | `true` selects modern construction audio. `false` selects the older wooden sound. |

`Waldo_fnc_ConstructionObjects` has no documented return value. Eden Init runs on the server and each interface client. The server prepares the hidden objects and public status; each client installs its local ACE actions. The function has no duplicate-action guard, so do not call it repeatedly on the same object. Eden Init covers joining players. Runtime-created interaction objects need their setup sent to joining clients.

## Setup in Eden

1. Place the **interaction object** (e.g. an ammo box) and give it a variable name.
2. Place a **Game Logic** near it (near the Modules menu). This script chooses the nearest Logic, so keep unrelated Logics farther away.
3. Place every object you want to appear when built, positioned where it should end up.
4. Position the props for the interaction object's expected location. If it is a vehicle, leave room for suspension movement and check the placement in play.
5. Select all the buildable objects, right-click → **Synchronise** them to the Game Logic.
6. In the interaction object's **init field**, call the function:

```sqf
[this, true] call Waldo_fnc_ConstructionObjects;   // modern construction audio
```

The synchronized objects start hidden. The **Perform Construction Work** action reveals them after a ten-second progress bar. **Tear Down Construction** hides them again with the same progress duration.

## Examples

```sqf
[this] call Waldo_fnc_ConstructionObjects;        // old wooden-sounding construction audio
[this, true] call Waldo_fnc_ConstructionObjects;  // modern construction audio
```

The ammo box is the object players interact with. The Game Logic holds the synchronized build objects. To make the box ACE-loadable, set its handling through [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling).

## If nothing appears after building

Check that ACE is loaded and the interaction object's Init call runs. Make sure the intended Game Logic is nearest and the build objects are synchronized to it. The script attaches those objects to the interaction object, so moving the latter moves their eventual build position too.

## See also

* [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System): deploy and tear down a command post using a synchronized Logic
* [Automatic Fortify Setup](Automatic-ACE-Fortify-Setup): add objects to an ACE Fortify build catalogue
* [Simple Mass Attach Items](Simple-Mass-Attach-Items)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
