/*
 * Author: Waldo
 * Can afford build for side.
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
 * [_entry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide;
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};
        if (isNil "Waldo_fnc_EcoResource_getSideResourceAmount") exitWith {false};

        private _ok = true;
        {
            private _resourceName = _x param [0, ""];
            private _resourceValue = _x param [1, 0];
            if (([_sideKey, _resourceName] call Waldo_fnc_EcoResource_getSideResourceAmount) < _resourceValue) exitWith {
                _ok = false;
            };
        } forEach (_entry param [2, []]);

        _ok

