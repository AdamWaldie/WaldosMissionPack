/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - isResearchCompletedForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_isResearchCompletedForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey", "_researchName"];

        private _name = [_researchName] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {false};

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        private _index = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower _name)};
        if (_index >= 0 && {(_catalog select _index) param [7, false]}) exitWith {true};

        (([_sideKey] call Waldo_fnc_EcoResearch_getSideResearched) findIf {(toLower _x) isEqualTo (toLower _name)}) >= 0

