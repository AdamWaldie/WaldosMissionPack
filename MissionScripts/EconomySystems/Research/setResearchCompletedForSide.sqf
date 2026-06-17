/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - setResearchCompletedForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_setResearchCompletedForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey", "_researchName", ["_completed", true]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _rows = [_sideKey] call Waldo_fnc_EcoResearch_getSideResearched;
        private _name = [_researchName] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {};

        private _index = _rows findIf {(toLower _x) isEqualTo (toLower _name)};
        if (_completed) then {
            if (_index < 0) then {
                _rows pushBack _name;
            };
        } else {
            if (_index >= 0) then {
                _rows deleteAt _index;
            };
        };

        [_sideKey, _rows] call Waldo_fnc_EcoResearch_setSideResearched;

