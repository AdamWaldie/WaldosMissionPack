/*
 * Author: WaldoTheWarfighter
 * Checks whether one side has every resource charged by a build entry.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true when all resource balances cover the costs.
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide;
 * Locality/Authority: Any machine may inspect published balances; server checks again before debit.
 * Repeat/JIP Behaviour: Pure read; no JIP side effect.
 * Current Callers: Construction status, upgrade status and authoritative job start.
 * Result: Returns false at the first short resource balance.
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

