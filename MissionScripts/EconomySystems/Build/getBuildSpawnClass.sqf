/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getBuildSpawnClass
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getBuildSpawnClass via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []]];

        private _className = _entry param [8, ""];
        if (_className isNotEqualTo "" && {isClass (configFile >> "CfgVehicles" >> _className)}) exitWith {_className};

        [] call Waldo_fnc_EcoBuild_getFallbackBuildAnchorClass

