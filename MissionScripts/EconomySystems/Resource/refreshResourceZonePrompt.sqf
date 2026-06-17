/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - refreshResourceZonePrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_refreshResourceZonePrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp"];

    if (isNull _disp) exitWith {};

    private _owners = ["NONE", "WEST", "EAST", "GUER"];
    private _ownerIndex = _disp getVariable ["WaldoEcoResource_ZoneOwnerIndex", 0];
    if (_ownerIndex < 0) then {_ownerIndex = (count _owners) - 1;};
    if (_ownerIndex >= count _owners) then {_ownerIndex = 0;};
    _disp setVariable ["WaldoEcoResource_ZoneOwnerIndex", _ownerIndex];

    private _ownerCtrl = _disp getVariable ["WaldoEcoResource_ZoneOwnerValue", controlNull];
    if (!isNull _ownerCtrl) then {
        _ownerCtrl ctrlSetText ([_owners select _ownerIndex] call Waldo_fnc_EcoResource_getZoneOwnerLabel);
        _ownerCtrl ctrlCommit 0;
    };
