/*
 * Author: WaldoTheWarfighter
 * Normalizes and publishes the completed technology names for one side.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - WEST/EAST/GUER/CIV side key
 * 1: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_sideKey, _rows] call Waldo_fnc_EcoResearch_setSideResearched;
 * Locality/Authority: Economy authority; this function publishes the normalized list.
 * Repeat/JIP Behaviour: Replaces side completion state and broadcasts it for JIP clients.
 * Current Callers: Research completion, authoring and import paths.
 * Result: Duplicate or blank names are excluded from the stored side list.
 */

        params ["_sideKey", ["_rows", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchStateVar;
        if (_varName isEqualTo "") exitWith {};

        private _clean = [];
        {
            private _name = [_x] call Waldo_fnc_EcoCore_trimString;
            if (_name isEqualTo "") then {continue;};
            if ((_clean findIf {(toLower _x) isEqualTo (toLower _name)}) >= 0) then {continue;};
            _clean pushBack _name;
        } forEach _rows;

        missionNamespace setVariable [_varName, _clean, true];

