/*
 * Author: WaldoTheWarfighter
 * Publishes one side's active Research project row.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - WEST/EAST/GUER/CIV side key
 * 1: _row <ARRAY> - row (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _row] call Waldo_fnc_EcoResearch_setSideActiveResearch;
 * Locality/Authority: Economy authority; this function publishes the supplied row.
 * Repeat/JIP Behaviour: Replaces the side's current row; public state reaches JIP clients.
 * Current Callers: Research start, progress and completion paths.
 * Result: Side queries read the new active project, or [] when cleared.
 */

        params ["_sideKey", ["_row", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_varName isEqualTo "") exitWith {};

        missionNamespace setVariable [_varName, _row, true];

