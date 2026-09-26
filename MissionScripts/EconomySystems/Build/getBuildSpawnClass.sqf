/*
 * Author: WaldoTheWarfighter
 * Validates and returns the CfgVehicles class used by a build entry.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * <STRING> valid vehicle/building class, or "" for missing/unknown class.
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_getBuildSpawnClass;
 * Locality/Authority: Any machine; reads local config data only.
 * Repeat/JIP Behaviour: Pure validation; no JIP state.
 * Current Callers: Construction catalog validation and spawn selection.
 * Result: Unsafe or absent classnames do not reach the spawn call.
 */

        params [["_entry", []]];

        private _className = _entry param [8, ""];
        if (_className isEqualTo "") exitWith {""};
        if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {""};
        _className

