_Associated Files: `MissionScripts\MissionFlowAndUi\ENDEX.sqf`, `aarTrack.sqf`, `aarWound.sqf`, `Waldo_fnc_ENDEX`, `Waldo_fnc_AARTrack`_

# ENDEX
The ENDEX script performs the following actions:
* Places all player weapons on Safe and prevents Players and player vehicles from firing.
* Makes all Hostile AI Passive
* Fully Heals all Players & Makes them invincible
* Creates a popup informing players that the mission is over and to congregate together for debriefing.
* If a player tries to fire their weapon or use grenades, it is deleted and a popup tells them to cease firing.
* Shows an **After-Action Report** in the ENDEX popup when mission tracking is running (see below).

You can call ENDEX by executing this line of code locally - such as a trigger:

`[] spawn Waldo_fnc_ENDEX;`

Alternatively, you could remotely execute it via a script:

`remoteExec ["Waldo_fnc_ENDEX",0,true];`

An example of it in use can be seen below:
![Zeus Endex execution example](https://i.imgur.com/PBpewY8.png)

# After-Action Report (AAR)
The ENDEX popup also shows an **After-Action Report** summarising how the mission went. You do not need to configure anything — tracking starts automatically from `initServer.sqf` via `[] call Waldo_fnc_AARTrack`, which registers a single lightweight `EntityKilled` mission event handler (negligible overhead, no per-frame loops). If tracking never ran, ENDEX simply omits the AAR block.

The report includes (each line is omitted when its tally is empty):

| Line | Source |
|---|---|
| **Duration** | Time since mission start. |
| **KIA** per side | Infantry killed, tallied by the dead unit's side. |
| **Player losses** | Human players killed. |
| **Vehicles lost** per side | Vehicles destroyed, tallied by the vehicle's side. |
| **WIA** per side | Unique wounded — **requires ACE medical** (counts each unit's first unconsciousness once). |
| **Friendly fire** | Kills where the shooter and victim share a side. |
| **Objective summary** | Tasks created/resolved with [Waldo_fnc_CreateObjective / SetObjectiveState](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Tasks-And-Objectives). |
| **Top fraggers** | Leaderboard of enemy kills scored by human players. |

WIA tracking relies on an `ace_unconscious` listener registered in `init.sqf`; if ACE medical is not loaded, the WIA line is simply absent. The objective summary populates automatically when you drive objectives through the [Tasks / Objectives](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Tasks-And-Objectives) helpers.

# Custom End Screen
At the base of the description.ext provided, you can find a custom end card section.

You can customise this section to display a custom end screen Title, Subtitle and description - similar to that in Zeus, but with greater control.

![Picture of the description.ext showing the custom end screen](https://i.imgur.com/XuVkkmF.png)

You can then end the mission with this custom end screen by executing the following script:

`["end1"] remoteExec ["BIS_fnc_endMission",0,true];`

Below is an example of the custom mission end screen:
![Mission End Screen Example](https://i.imgur.com/xmK9I1e.png)

## Zeus Usage
You may also use the provided Zeus Enhanced modules in the pack to perform both of these actions. 

[Waldos Mission Pack Zeus Modules](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mission-Pack-Zeus-Modules) are covered separately.