/*
 * Author: Waldo
 * Is build available for side.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide;
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _availability = [(_entry param [20, ["ALL"]])] call Waldo_fnc_EcoBuild_normalizeBuildAvailability;
        if ((_availability find "ALL") >= 0) exitWith {true};

        _sideKey in _availability

