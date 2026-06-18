/*
 * Author: Waldo
 * Set preset assignment.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "")
 * 1: _complexityKey <STRING> - complexity key (optional, default: "")
 * 2: _catalogKey <STRING> - catalog key (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _complexityKey, _catalogKey] call Waldo_fnc_EcoCore_setPresetAssignment;
 */

    params [
        ["_sideKey", ""],
        ["_complexityKey", ""],
        ["_catalogKey", ""]
    ];

    private _varName = [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
    if (_varName isEqualTo "") exitWith {};

    missionNamespace setVariable [_varName, [_complexityKey, _catalogKey], true];
