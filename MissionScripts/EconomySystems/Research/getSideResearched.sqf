/*
 * Author: WaldoTheWarfighter
 * Reads the completed technology names for one side.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - WEST/EAST/GUER/CIV side key
 *
 * Return Value:
 * <ARRAY of STRING> completed technology names, or [] for an invalid side.
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResearch_getSideResearched;
 * Locality/Authority: Any machine; reads public side state.
 * Repeat/JIP Behaviour: Repeat-safe read of the latest published completed list.
 * Current Callers: Research requirement, completion and export helpers.
 * Result: Returns a copy of that side's completed names.
 */

        params ["_sideKey"];

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchStateVar;
        if (_varName isEqualTo "") exitWith {[]};
        +(missionNamespace getVariable [_varName, []])

