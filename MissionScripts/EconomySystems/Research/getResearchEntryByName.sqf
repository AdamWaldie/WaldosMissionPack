/*
 * Author: WaldoTheWarfighter
 * Finds one technology row by name, ignoring letter case and surrounding whitespace.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _researchName <STRING> - technology name
 * 1: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * <ARRAY> matching technology row, or [] when absent.
 *
 * Example:
 * [_researchName, _catalog] call Waldo_fnc_EcoResearch_getResearchEntryByName;
 * Locality/Authority: Any machine; reads the supplied or published catalog.
 * Repeat/JIP Behaviour: Pure lookup; JIP uses its current published catalog.
 * Current Callers: Research start, requirement and authoring helpers.
 * Result: Returns a copy of the matching row, not the stored array itself.
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

