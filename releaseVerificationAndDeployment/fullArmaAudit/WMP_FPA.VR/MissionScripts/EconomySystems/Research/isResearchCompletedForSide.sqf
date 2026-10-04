/*
 * Author: WaldoTheWarfighter
 * Checks whether a technology is completed for a side or globally pre-researched in the catalog.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _researchName <ANY> - research name
 *
 * Return Value:
 * <BOOL> true when completed, false otherwise.
 *
 * Example:
 * [_sideKey, _researchName] call Waldo_fnc_EcoResearch_isResearchCompletedForSide;
 * Locality/Authority: Any machine; reads published catalog and side completion state.
 * Repeat/JIP Behaviour: Repeat-safe query; JIP clients receive the current source state.
 * Current Callers: Research requirements, status and completion checks.
 * Result: Returns true for catalog-global or side-specific completion.
 */

        params ["_sideKey", "_researchName"];

        private _name = [_researchName] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {false};

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        private _index = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower _name)};
        if (_index >= 0 && {(_catalog select _index) param [7, false]}) exitWith {true};

        (([_sideKey] call Waldo_fnc_EcoResearch_getSideResearched) findIf {(toLower _x) isEqualTo (toLower _name)}) >= 0

