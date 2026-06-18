/*
 * Author: Waldo
 * Get research entry by name.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _researchName <ANY> - research name
 * 1: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_researchName, _catalog] call Waldo_fnc_EcoResearch_getResearchEntryByName;
 */

        params ["_researchName", ["_catalog", []]];

        private _safeName = [_researchName] call Waldo_fnc_EcoCore_trimString;
        if (_safeName isEqualTo "") exitWith {[]};

        if ((count _catalog) <= 0) then {
            _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        };

        private _index = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower _safeName)};
        if (_index < 0) exitWith {[]};
        +(_catalog select _index)

