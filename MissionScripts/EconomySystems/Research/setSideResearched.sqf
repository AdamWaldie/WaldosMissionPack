/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - setSideResearched
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_setSideResearched via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

