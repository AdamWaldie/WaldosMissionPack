/*
 * Author: WaldoTheWarfighter
 * Reads the active Research row for one side.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - WEST/EAST/GUER/CIV side key
 *
 * Return Value:
 * <ARRAY> active research row, or [] when none/invalid side.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResearch_getSideActiveResearch;
 * Locality/Authority: Any machine; reads public side state.
 * Repeat/JIP Behaviour: Repeat-safe read of the latest published active row.
 * Current Callers: Research status, progress, start and timer helpers.
 * Result: Returns a copy of that side's active row.
 */

        params ["_sideKey"];

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_varName isEqualTo "") exitWith {[]};
        +(missionNamespace getVariable [_varName, []])

