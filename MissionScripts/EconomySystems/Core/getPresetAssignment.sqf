/*
 * Author: Waldo
 * Get preset assignment.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignment;
 */

    params [["_sideKey", ""]];

    private _varName = [_sideKey] call Waldo_fnc_EcoCore_getPresetAssignmentVar;
    if (_varName isEqualTo "") exitWith {[]};
    +(missionNamespace getVariable [_varName, []])
