/*
 * Author: Waldo
 * Cycle resource zone owner.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 * 1: _delta <SCALAR> - delta (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoResource_cycleResourceZoneOwner;
 */

    params ["_disp", ["_delta", 0]];

    if (isNull _disp) exitWith {};
    _disp setVariable ["WaldoEcoResource_ZoneOwnerIndex", (_disp getVariable ["WaldoEcoResource_ZoneOwnerIndex", 0]) + _delta];
    [_disp] call Waldo_fnc_EcoResource_refreshResourceZonePrompt;
