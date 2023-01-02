/*
This function populates an supply crate, with basic medical supplied (quickclot & splints) based on players magazines & weaponry in the mission.sqm

Params:
_crate - object to populate (Passed from module where thee classname of the box is defined)
_size - scalar value to multiply medical supplycompliment
_crateSupplyside - (STRING) the side that the crate will populate equipment from. Options: west,east,independent,civilian
_fullCompliment - boolean (true/false) variable to dennote whether everything is to be added, or just that related to weapons & ammo

Where the call is as follows:

[_crate, _size, _crateSupplyside, _fullCompliment] spawn Waldo_fnc_SupplyCratePopulate;

e.g.

[this, 1, west, false] spawn Waldo_fnc_SupplyCratePopulate;

Called via Zen Module as defined in Zen_medicalCrateModule.sqf

*/

params ["_crate", ["_scalar",1],["_crateSupplySide",west],["_fullCompliment",false]];

clearweaponcargoGlobal _crate;
clearmagazinecargoGlobal _crate;
clearitemcargoGlobal _crate;
clearbackpackcargoGlobal _crate;

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };

//default setup
private _loadoutArray = missionNamespace getVariable "Logi_MissionSQMArray_West";
//get all loadout data by default
if (_crateSupplySide == EAST) then {
    _loadoutArray = missionNamespace getVariable "Logi_MissionSQMArray_East";
};
if (_crateSupplySide == INDEPENDENT) then {
    _loadoutArray = missionNamespace getVariable "Logi_MissionSQMArray_Ind";
};
if (_crateSupplySide == CIVILIAN) then {
    _loadoutArray = missionNamespace getVariable "Logi_MissionSQMArray_Civ";
};


_loadoutArray params["_mainWeapons","_mainAmmo","_launchers","_launcherAmmo","_pGear","_pItems","_pBackpack","_weapAttach"];

/*
private _loadoutArray = missionNamespace getVariable "Logi_MissionSQMArray";
_loadoutArray params["_mainWeapons","_mainAmmo","_launchers","_launcherAmmo","_pGear","_pItems","_pBackpack","_weapAttach"];
*/
private _MedicalItems = ["Medikit","FirstAidKit","ACE_fieldDressing","ACE_packingBandage","ACE_elasticBandage","ACE_tourniquet","ACE_splint","ACE_morphine","ACE_adenosine","ACE_epinephrine","ACE_plasmaIV","ACE_plasmaIV_500","ACE_plasmaIV_250","ACE_salineIV","ACE_salineIV_500","ACE_salineIV_250","ACE_bloodIV","ACE_bloodIV_500","ACE_bloodIV_250","ACE_quikclot","ACE_personalAidKit","ACE_surgicalKit"];

// Remove ACE Medical Items if applicable
_pItems = _pItems - _MedicalItems;

//Add All to crate with Varying Quantities

{
    if (!(_x == "EMPTY")) then {
        if (_x call BIS_fnc_isThrowable) then {
            _crate addMagazineCargoGlobal [_x,(([15,30] call BIS_fnc_randomInt)*_scalar)];
        } else {
            _crate addMagazineCargoGlobal [_x,(([30,50] call BIS_fnc_randomInt)*_scalar)];
        };
    };
} forEach _mainAmmo;

{
    if (!(_x == "EMPTY")) then {
        _crate addWeaponCargoGlobal [_x,(([8,12] call BIS_fnc_randomInt)*_scalar)];
    };
} forEach _launchers;

{
    if (!(_x == "EMPTY")) then {
        _crate addMagazineCargoGlobal [_x,(([8,12] call BIS_fnc_randomInt)*_scalar)];
    };
} forEach _launcherAmmo;

//If the calling method wants everything, not just weapons and Ammo, provide it!
if (_fullCompliment == true) then {
    {
       if (!(_x == "EMPTY")) then {
            _crate addWeaponCargoGlobal [_x,(([1,3] call BIS_fnc_randomInt)*_scalar)];
       };
    } forEach _mainWeapons;
    {
        if (!(_x == "EMPTY")) then {
            _crate addItemCargoGlobal [_x,(([2,4] call BIS_fnc_randomInt)*_scalar)];
        };
    } forEach _weapAttach;
    {
        if (!(_x == "EMPTY")) then {
            _crate addItemCargoGlobal [_x,(([1,3] call BIS_fnc_randomInt)*_scalar)];
        };
    } forEach _pGear; 

    {
        if (!(_x == "EMPTY")) then {
            _crate addItemCargoGlobal [_x,(([4,8] call BIS_fnc_randomInt)*_scalar)];
        };
    } forEach _pItems;

    {
        if (!(_x == "EMPTY")) then {
            _crate addBackpackCargoGlobal [_x,[2,4] call BIS_fnc_randomInt];
        };
    } forEach _pBackpack;
};

//If Ace medical enabled, add the most basic of medical supplies to tide people in a pinch
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    _crate addItemCargoGlobal ["ACE_quikclot", (40)];
    _crate addItemCargoGlobal ["ACE_tourniquet", (20)];
};

[_crate, 1] call ace_cargo_fnc_setSize;
[_crate, true] call ace_dragging_fnc_setDraggable;
[_crate, true] call ace_dragging_fnc_setCarryable;