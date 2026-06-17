/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - getResearchEntryByName
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_getResearchEntryByName via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

