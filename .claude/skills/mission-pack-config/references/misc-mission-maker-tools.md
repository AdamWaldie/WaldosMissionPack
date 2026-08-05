# Misc mission-maker tools

Compact catch-all for smaller helper scripts that don't warrant their own
reference file. Each subsection is deliberately short — read the linked
wiki page for full detail if the user needs more than the key call/variable.

## AI Convoy System

Keeps an AI vehicle group in column formation, enforces spacing, forces
stalled vehicles back into formation; optional `pushThrough` stops AI
dismounting on contact.

```sqf
convoyScript = [convoyGroup, 30, 15, true] spawn Waldo_fnc_SimpleAiConvoy;
// [group, speed km/h (30), separation m (15), pushThrough (true)]
```

Must be called with `spawn` (loops continuously). Terminate at the final
waypoint's **On Activation**:
```sqf
terminate convoyScript;
{ (vehicle _x) limitSpeed 5000; (vehicle _x) setUnloadInCombat [true, false] } forEach (units convoyGroup);
convoyGroup enableAttack true;
```
Also reachable via Zeus **Spawn AI Convoy** (`Waldo_fnc_ZenConvoyModule`,
turns the nearest crewed land-vehicle group into a managed convoy). Wiki:
`AI-Convoy-System`.

## Map Location Tools

Two functions needing a placed Game Logic as position reference:
```sqf
[FobBartLogic, "FOB Bart", "NameVillage"] call Waldo_fnc_CreateMapLocationName;      // brand-new location
[AltisAirportLogic, "Al-Rayak Air Base", "NameLocal"] call Waldo_fnc_ReplaceMapLocationName; // renames nearest existing
```
Location type controls icon/behaviour (`NameCity`, `NameVillage`,
`NameLocal`, `Mount`, `Hill`, `Strategic`, `b_hq`/`o_hq`/`n_hq`, etc. — full
list commented in both `.sqf` files). Wiki: `Map-Location-Tools`.

## Vehicle Ambush & Camo

Lets a crew conceal a vehicle with deployable camo objects; crew may
dismount disguised as civilians until spotted/firing/moving >40m/damaged
breaks concealment (up to ~30s engine delay to revert side). Camo objects
stay until the vehicle moves or crew removes them. Requires ACE3.
```sqf
[this] call Waldo_fnc_VehicleCamoSetup;   // vehicle's init field
```
Setup: place vehicle + nearby Game Logic + camo objects, sync camo objects
to the Logic. Wiki: `Vehicle-Ambush-Script-And-Vehicle-Camo`.

## Teleportation & Move-Into-Cargo

```sqf
[this, "Teleport - Airfield", Airstrip] call Waldo_fnc_Teleport;        // [object, label, destination]
[this, aircraft, "ARGUS 1-4"] call Waldo_fnc_MoveInCargoPlane;          // board an already-airborne aircraft
```
Destination for Teleport can be a marker/object/location/group/task
variable name; Z is treated as ground level for markers/locations/tasks.
Wiki: `Teleportation-&-Move-Into-Cargo-Interactions`.

## Weapon Mounting With Custom Name

Attaches a separate turret object to a vehicle with "Get In [name]" /
"Return To Main Vehicle" actions, without it counting as a normal turret
seat.
```sqf
[mountedM2, truck1, "M2 Browning"] call Waldo_fnc_VehicleMountedWeapon;  // [turret, vehicle, custom name]
```
Wiki: `Weapon-Mounting-With-Custom-Name`.

## Construction Objects

Fakes ACE-timed "construction" of pre-placed hidden objects from one
interaction object (progress bar + sound); the interaction object can be
carried in ACE cargo and keeps its build ability after moving. Requires
ACE3.
```sqf
[this, true] call Waldo_fnc_ConstructionObjects;   // [interaction object, modern audio bool]
```
Setup: interaction object + nearby Game Logic + buildable objects synced to
the Logic. Wiki: `Construction-Objects`.

## Automatic ACE Fortify Setup

Converts objects synced to a Game Logic into a side's ACE Fortify budget +
build catalogue, pricing dynamically by volume/mass. Single-use — objects
and logic are destroyed after setup.
```sqf
[this, west, 6000] call Waldo_fnc_AutoFortifySetup;   // [game logic, side, starting budget]
[west, -250, false] call ace_fortify_fnc_updateBudget; // [side, change, display hint]
```
Zeus **Fortify Budget Manager** module (`Waldo_fnc_FortifyBudgetModule`)
adjusts budget live. Wiki: `Automatic-ACE-Fortify-Setup`.

## Radio Reports, Checklists, Support Calls & Documentation

In-game map-diary reference cards (SITREP, SPOTREP, 9-line CAS, call for
fire, LZ briefs, jumpmaster checklist, etc. — full list in
`wiki/Radio-Reports,-Checklists,-Support-Calls-And-Documentation.md`).
Loaded automatically via `call Waldo_fnc_AddDocs;` in `init.sqf`. Comment
out individual `Waldo_fnc_*` calls in
`MissionScripts\MissionInit\BriefingDocuments\AddDocs.sqf` to remove one
document; add a new `.sqf` there using the existing files as a template for
a custom one. Native rich text, not images — wraps/scales correctly.

## Team Colour Setup

Assigns ACE3 team colours from each player's Eden **Role Description** via
keyword match (case-insensitive, first match wins): Yellow (SL/PL/CO/etc.),
Red (ASL/Alpha), Blue (Bravo), Green (Medic/Charlie). Recommended role
description format: `[Team/Role] [Info]@[Callsign]`, e.g.
`Alpha Rifleman@Viking-1-1`. Runs automatically via
`call Waldo_fnc_SetTeamColour;` in `init.sqf`; comment out to disable.
Related parsers: `[player] call Waldo_fnc_GetPlayerGroup;` (callsign after
`@`), `call Waldo_fnc_GetPlayerRole;` (role before `@`). Wiki:
`Team-Colour-Setup`.
