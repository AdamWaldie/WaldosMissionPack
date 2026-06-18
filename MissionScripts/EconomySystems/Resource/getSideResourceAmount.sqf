/*
 * Author: Waldo
 * Get side resource amount.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _resourceType <ANY> - resource type
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _resourceType] call Waldo_fnc_EcoResource_getSideResourceAmount;
 */

    params ["_sideKey", "_resourceType"];

    private _varName = [_sideKey] call Waldo_fnc_EcoResource_getSideStorageVar;
    if (_varName isEqualTo "") exitWith {0};

    private _rows = missionNamespace getVariable [_varName, []];
    private _index = _rows findIf {
        ((_x param [0, ""]) isEqualTo _resourceType)
    };

    if (_index < 0) exitWith {0};
    (_rows select _index) param [1, 0]
