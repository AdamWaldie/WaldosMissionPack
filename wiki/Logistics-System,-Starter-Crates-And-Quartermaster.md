_Associated Files: MissionScripts\Logistics\Crates_

The logistics system in WaldosMissionPack is more automated than most of the comparable script packs.

The mission pack scrapes through player loadouts to construct a unique list of gear per side, which can then be used to resupply players in the field via the ZEN modules, or used as part of the Quartermaster, Logistics crates, MHQ or Starter Crates.

The initial call for this scrape can be found in the initServer.sqf file pictured below:
![Loadout scrape call in initServer.sqf](https://i.imgur.com/zgkHsqA.png)


# The Three Rules
The following three rules must be adhered to for the logistics system to function:
1. The Mission Must **NOT** be binaried.
2. Player load-outs must be customised via an arsenal and cannot be default unit kits.
3. Player units must not be placed in an organiser folder in the editor; they must remain under the BLUFOR, OPFOR, INDEPENDENT and CIVILIAN side folders.

Failure to follow these rules will lead to unexpected results.

# Logistics Features
* Automated Supply, Medical and Starter Crates based on Player Loadouts.
* Logistics Quartermaster to spawn Supplies, Medical Supplies, ACE Tracks, and ACE Wheels.
* Limited ACE Arsenal based on Player Loadouts.
* Mobile Command Post / MHQ integration so that the Mobile Command Post / MHQ can act as a Logistics Quartermaster.



# Logistics Crates

## Starter Crates

This transforms an object's inventory to house supplies, allowing players to save their respawn loadout or use a limited/unlimited arsenal if enabled.

Simply paste and edit the example below into an object's init to turn it into a starter crate.

Does the following:
* Adds addaction to allow for the saving of loadout
* Adds limited Ace Arsenal (Mission.sqm bound)
* Adds supplies (Mission.sqm bound)


Parameters:
* _target - the object variable name you want this to apply to
* _arsenal - boolean as tto whether you want an ACE/Vanilla arsenal or not
* _crateSide - the side that the crate will populate equipment from. Options: West,East,Independent,Civilian
* _unrestrictedArsenal - boolean as to whether you want the arsenal to be unrestricted or not.


To call

`[_target,_arsenal,_crateSide,_unrestrictedArsenal] spawn Waldo_fnc_DoStarterCrate;`

e.g.

`[this,true,west,false] spawn Waldo_fnc_DoStarterCrate;`

## Supply Crate
This function populates a supply crate, with basic medical supplied (quickclot & splints) based on players' inventory & weaponry in the mission.sqm

Simply paste and edit the example below into an object's init to turn it into a supplycrate.

Params:
* _crate - object to populate (Passed from module where thee classname of the box is defined)
* _size - scalar value to multiply medical supplycompliment
* _crateSupplyside - (STRING) the side that the crate will populate equipment from. Options: west,east,independent,civilian
* _weaponsAttachmentsUniforms - boolean (true/false) variable to dennote whether weapons, weapon attachments, equipment and clothing should be added.
* _includeLaunchersAndLauncherAmmo - boolean (true/false) variable to dennote whether launchers and their ammo should be added.

Where the call is as follows:

`[_crate, _size, _crateSupplyside, _fullCompliment, _includeLaunchersAndLauncherAmmo ] spawn Waldo_fnc_SupplyCratePopulate;`

e.g.

`[this, 1, west, false, true] spawn Waldo_fnc_SupplyCratePopulate;`

## Medical Crate
This function populates an advanced medical crate, with the option to enable the box as a field hospital if desired.

Simply paste and edit the example below into an object's init to turn it into a medical crate.

Params:
* _crate - object to populate
* _isFacility - tickbox option to enable locational boost to medical skill
* _scale - scalar value to multiply medical supply complement

Where the call is as follows:

`[_crate, _fieldHopsital, _size] call Waldo_fnc_MedicalCratePopulate;`

e.g.

`[this, true, 1] call Waldo_fnc_MedicalCratePopulate;`


# Limited Arsenal
Function to create an ace limited arsenal on the object, limited to the equipment retrieved from the mission.sqm

Simply paste and edit the example below into an object's init to turn it into a limited arsenal.

Parameters:
* _target - the object variable name you want this to apply to
* _crateSupplyside - the side that the crate will populate equipment from. Options: West,East,Independent,Civilian
* _preExisting - user-defined boolean for specifying whether an ace arsenal already exists on the object.

`[_target,_crateSupplyside,_preExisting] spawn Waldo_fnc_CreateLimitedArsenal;`

e.g.

`[this, west, false] spawn Waldo_fnc_CreateLimitedArsenal;`



# Logistics Quartermaster
This is used to set up the logistics spawning system via the "Quartermaster". The Quartermaster is an object or NPC which acts as the spawner for supply boxes & equipment.

Simply paste and edit the example below into an object's init to turn it into a quartermaster.

Params:
* _target - The quartermaster from which you can select these actions
* _offsetDegrees - determines the bearing around the vehicle the spawner will be. Based on vehicle heading, not compass. E.g 0 = Front, 90 = Right, 180 = Rear, 270 = Left.
* _offsetDistance - determines how far away from the vehicle the logistics spawner will be.

Exemplar:

`[this] call Waldo_fnc_SetupQuarterMaster; `

Example which spawns logistics crates behind the interaction point, 4 meters away.

`[this,180,4] call Waldo_fnc_SetupQuarterMaster; `


## What the Quartermaster Spawns

| ACE Interaction | Contents | Notes |
|---|---|---|
| **Medical Box** | ACE medical supplies (if ACE Medical loaded), or vanilla medical supplies | Marked as ACE field hospital; draggable/carryable |
| **Supply Box** | All weapons, ammo, attachments, equipment from mission loadouts (full side complement) | |
| **Ammo Box** | Ammo only (0.75× scale supply, no weapons or equipment) | |
| **ACE Wheel** | `ACE_Wheel` — spare vehicle wheel | |
| **ACE Track** | `ACE_Track` — spare vehicle track | |

The Quartermaster prevents duplicates: if a box of the same type already exists within 5 m of the spawn point, a new one will not be spawned and the QM will say so.

## Changing the Boxes The Quartermaster Spawns
You can edit the class of crate spawned for both medical and supply boxes in `initServer.sqf`:
![Picture displaying the appropriate place in Initserver.sqf to change the boxes](https://i.imgur.com/0CdEY8U.png)

**Logi_SupplyBoxClass** is the class of box spawned for supply and ammo requests.

**Logi_MedicalBoxClass** is the class of box spawned for medical requests.

```sqf
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```