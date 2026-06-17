/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - setSideActiveResearch
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_setSideActiveResearch via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey", ["_row", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_varName isEqualTo "") exitWith {};

        missionNamespace setVariable [_varName, _row, true];

