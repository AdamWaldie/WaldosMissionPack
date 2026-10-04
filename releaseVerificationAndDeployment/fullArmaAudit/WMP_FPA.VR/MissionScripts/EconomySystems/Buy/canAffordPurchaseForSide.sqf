/*
 * Author: WaldoTheWarfighter
 * Checks whether a side has enough of every resource charged by an asset row.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true when all required resource balances are sufficient.
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuy_canAffordPurchaseForSide;
 * Locality/Authority: Any machine can read published balances; server repeats the check
 * before debiting resources.
 * Repeat/JIP Behaviour: Pure read; no JIP side effect.
 * Current Callers: Purchase status and server purchase validation.
 * Result: Returns false at the first resource shortfall.
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

