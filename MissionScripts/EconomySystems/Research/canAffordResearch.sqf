/*
 * Author: WaldoTheWarfighter
 * Checks whether a side has enough of every resource charged by one technology row.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _entry <ANY> - entry
 *
 * Return Value:
 * <BOOL> true when every required resource balance is sufficient.
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_canAffordResearch;
 * Locality/Authority: Any machine can inspect published balances; the server repeats this
 * check before authoritative spending.
 * Repeat/JIP Behaviour: Pure read and repeat-safe; no JIP side effect.
 * Current Callers: Research status and server-side start validation.
 * Result: Returns false at the first short resource balance.
 */

        params ["_sideKey", "_entry"];

        private _canAfford = true;
        {
            if (([_sideKey, _x param [0, ""]] call Waldo_fnc_EcoResource_getSideResourceAmount) < (_x param [1, 0])) exitWith {
                _canAfford = false;
            };
        } forEach (_entry param [2, []]);

        _canAfford

