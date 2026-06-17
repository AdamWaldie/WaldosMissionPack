/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - getSideActiveResearch
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_getSideActiveResearch via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey"];

        private _varName = [_sideKey] call Waldo_fnc_EcoResearch_getResearchActiveVar;
        if (_varName isEqualTo "") exitWith {[]};
        +(missionNamespace getVariable [_varName, []])

