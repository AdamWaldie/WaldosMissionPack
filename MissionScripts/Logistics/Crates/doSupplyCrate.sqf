/*
 * Author: WaldoTheWarfighter
 * Purpose: Populates a container with mission-loadout-derived ammunition, equipment and basic medical supplies.
 * Locality / Authority: Server mutates global cargo; caller owns the decision to register crate-handling actions.
 * Repeat / JIP: Clears and repopulates on repeat; global inventory changes replicate to JIP.
 * Arguments: crate <OBJECT>, scale <NUMBER> (1), side <SIDE> (west),
 *   include equipment <BOOL> (false), include launchers <BOOL> (false).
 * Return Value: No supported return value; use the crate's resulting inventory.
 * Current callers: starter crates, quartermaster, ZEN crate and field resupply.
 * Example: [myCrate, 1, west, false, false] call Waldo_fnc_SupplyCratePopulate;
 * Result: The crate receives dynamic mission-derived ammunition and selected equipment.
 */

params ["_crate", ["_scalar",1],["_crateSupplySide",west],["_weaponsAttachmentsUniforms",false],["_includeLaunchersAndLauncherAmmo",false]];
if (!isServer) exitWith {};

clearweaponcargoGlobal _crate;
clearmagazinecargoGlobal _crate;
clearitemcargoGlobal _crate;
clearbackpackcargoGlobal _crate;

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };

//Get the loadout pool for the requested side (defaults to west)
private _loadoutArray = [_crateSupplySide] call Waldo_fnc_GetSideLoadoutArray;

_loadoutArray params["_mainWeapons","_mainAmmo","_launchers","_launcherAmmo","_pGear","_pItems","_pBackpack","_weapAttach"];
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

// Add launchers if requested
if (_includeLaunchersAndLauncherAmmo == true) then {
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
};

//If the calling method wants everything, not just weapons and Ammo, provide it!
if (_weaponsAttachmentsUniforms == true) then {
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
    _crate addItemCargoGlobal ["ACE_suture",(50)];
};

if !(_crate getVariable ["Waldo_Logistics_StarterCrate", false]) then {
    // A spawned child of a remote-executed request keeps isRemoteExecuted, which the server-only
    // cargo/registration guards reject. Finish from CBA's server-local next frame instead.
    // Same ACE handling as a quartermaster crate (drag/carry regardless of weight, one cargo slot).
    [{
        [_this select 0, 1] call Waldo_fnc_LogisticsApplyAceHandling;
        _this spawn Waldo_fnc_LogisticsRegisterSpawned;
    }, [_crate, "SUPPLY"]] call CBA_fnc_execNextFrame;
};
