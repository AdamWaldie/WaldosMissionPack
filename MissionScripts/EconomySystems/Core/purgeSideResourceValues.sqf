/*
 * Author: Waldo
 * Purge side resource values.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeSideResourceValues;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _types = call Waldo_fnc_EcoResource_getResourceTypes;
    {
        private _varName = [_x] call Waldo_fnc_EcoResource_getSideStorageVar;
        if (_varName isEqualTo "") then {continue;};
        missionNamespace setVariable [_varName, [[], _types] call Waldo_fnc_EcoResource_normalizeSideResourceRows, true];
    } forEach ["WEST", "EAST", "GUER", "CIV"];
