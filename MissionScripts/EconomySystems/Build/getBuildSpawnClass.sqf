/*
 * Author: Waldo
 * Get build spawn class.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_getBuildSpawnClass;
 */

        params [["_entry", []]];

        private _className = _entry param [8, ""];
        if (_className isNotEqualTo "" && {isClass (configFile >> "CfgVehicles" >> _className)}) exitWith {_className};

        [] call Waldo_fnc_EcoBuild_getFallbackBuildAnchorClass

