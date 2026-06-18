/*
 * Author: Waldo
 * Can afford research.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _entry <ANY> - entry
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_canAffordResearch;
 */

        params ["_sideKey", "_entry"];

        private _canAfford = true;
        {
            if (([_sideKey, _x param [0, ""]] call Waldo_fnc_EcoResource_getSideResourceAmount) < (_x param [1, 0])) exitWith {
                _canAfford = false;
            };
        } forEach (_entry param [2, []]);

        _canAfford

