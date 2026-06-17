/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - purgeSideResourceValues
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_purgeSideResourceValues via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    {
        private _varName = [_x] call Waldo_fnc_EcoResource_getSideStorageVar;
        if (_varName isEqualTo "") then {continue;};
        missionNamespace setVariable [_varName, [[], _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows, true];
    } forEach ["WEST", "EAST", "GUER", "CIV"];
