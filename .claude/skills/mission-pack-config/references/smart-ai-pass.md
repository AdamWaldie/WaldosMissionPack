# Smart AI Pass

Optional behaviour improvements for non-player AI squads. Off by default. All settings are in
`MissionConfig\aiConfig.sqf` (`shared` scope). Edit that file; do not add a call to `init.sqf`
(it already starts the pass on the server, which replays it to headless clients).

```sqf
["Waldo_AIPass_Enable", true],                            // master switch (default false)
["Waldo_AIPass_IncludedSides", ["WEST", "EAST", "GUER"]], // sides the pass may command
["Waldo_AIPass_LambsMode", "SPLIT"],                      // SPLIT or WMP; only matters with LAMBS Danger
```

**Zeus always has priority.** Selecting a squad, giving it waypoints or a target, moving or
remote-controlling its soldiers, or ZEN AI actions pause the pass for that squad
(`Waldo_AIPass_ZeusHoldSeconds`, default 120; Zeus waypoints hold it until finished). No setting is
needed; do not tell users to disable the pass for Zeus-run missions.

**Behaviour profiles** follow the AI Rebalance profile name (MILITIA/LINE/VETERAN/ELITE) and never
change skills. Override per faction with `Waldo_AIPass_FactionProfiles` (a map of faction classname
to profile), or per group with `(group this) setVariable ["Waldo_AIPass_Profile", "ELITE", true];`.
The numbers are in `Waldo_AIPass_ProfileBehaviour` (ADVANCED).

## Behaviour switches (each `Waldo_AIPass_<Name>_Enable`)

| Switch | Default | Notes |
|---|---|---|
| `Regroup` | true | survivors of a destroyed squad join a nearby squad |
| `Contact` | true | state ladder CALM/CONTACT/SECURITY/SEARCH/REGROUP/RETREAT; every combat behaviour needs it |
| `PostContact` | true | hold, two-man search, regroup |
| `Investigate` | true | two riflemen (whole squad beyond 150 m) check known but unseen enemies |
| `Assault` | true | flank ends with grenade and rush |
| `Advance` | true | fire team bounds towards the squad's waypoint in long firefights |
| `CoordinatedAssault` | true | reinforcing squads assault from both sides |
| `Stance` | true | stance matches the cover in front |
| `AmmoShare` | true | magazines passed to squad-mates who are out |
| `VehicleGunnery` | true | gunners hit AT soldiers first; armour keeps distance from AT |
| `ArtillerySmoke` | true | smoke screen for retreats (needs `Artillery`) |
| `AircraftBreak` | false | gunships/fighters jink from missiles; test first |
| `Flank` | true | base of fire + flanking element in covered bounds |
| `StreetCrossing` | true | flanks smoke and cross roads in one bound |
| `FireControl` | true | close threats, fire distribution, disciplined suppression |
| `Morale` | true | broken squads retreat under smoke |
| `Surrender` | false | last isolated survivors surrender (ACE Captives) |
| `GrenadeEvasion` | false | needs in-engine testing first |
| `AntiArmour` | true | best AT gunner, backblast check |
| `Vehicles` | true | dismount under fire; damaged vehicles smoke and withdraw |
| `ContactReports` | true | radio (jammable) or voice sharing |
| `Reinforce` | true | idle squads move up behind a squad in contact (never garrisons, defence lines, aircrews, gun or artillery crews) |
| `Artillery` | false | fire missions on well-located enemies only |
| `CounterBattery` | false | `Waldo_AIPass_CounterBattery_Mode` "KNOWN" or "RADAR" |
| `Airborne` | false | paradropped reinforcements; `Waldo_AIPass_Airborne_Auto` for automatic calls |
| `AircraftFlares` | false | WMP gunships and Dynamic AA fighters |

Tuning rows (`_Flank_*`, `_Morale_*`, `_Artillery_*`, `_Airborne_*`, `_Tick*`, ranges) are ADVANCED;
leave them unless the user asks. Airborne aircraft and jumper classes are per-side hashmaps
(`Waldo_AIPass_Airborne_AircraftClasses`, `_JumperClasses`); set them to the mission's factions when
mods are used.

## Orders (call where the group is local or on the server; need the pass running)

```sqf
[group this, getPosATL this, 40] call Waldo_fnc_AIPassGarrison;          // garrison buildings within 40 m
[group this, getMarkerPos "ridge", 45, 80] call Waldo_fnc_AIPassDefend;  // defence line facing 045, 80 m wide
[_group] call Waldo_fnc_AIPassDefendRelease;
[_group] call Waldo_fnc_AIPassGarrisonRelease;
[group this, nearestBuilding this] call Waldo_fnc_AIPassClearBuilding;   // clear one building
[thisTrigger, east] call Waldo_fnc_AIPassAirborneRequest;                // trigger On Activation, server only
[this, west] call Waldo_fnc_AIPassRegisterRadar;                         // counter-battery RADAR mode
```

`Waldo_AIPass_Garrison_DynamicAO = true` gives Dynamic AO garrisons the WMP garrison handling. With
LAMBS Waypoints loaded in SPLIT mode, garrison and clear orders are handed to LAMBS.

## Exclusions

Automatic: groups with a living player; Gunship; Transport Services crews while their transport is in
service (taken over once it is written off and they are on foot); Paradrop aircraft, and AI jumpers
until landed (then taken over); Dynamic AA, AI Convoy, dialogue speakers, drones. Dynamic
AO groups are included on purpose. Manual: `this setVariable ["Waldo_AIPass_Exclude", true, true];`
on a unit or `group this`. `Waldo_AI_Exclude` excludes from every WMP AI change.

## Runtime and diagnostics

Zeus: **WMP AI & Combat > AI Control** (every switch) and **AI Orders** (garrison, defend, release,
clear, airborne at the module position, keep for Zeus, return to pass). Diagnostics rows `ai/smart-ai-pass`, `-regroup`, `-groups`,
`-drills`, `-zeus`, `-support`, `-lambs`. RPT tag `[WMP AI PASS]`; `Waldo_AIPass_Debug` adds detail.

Wiki: `Smart-AI-Pass`.
