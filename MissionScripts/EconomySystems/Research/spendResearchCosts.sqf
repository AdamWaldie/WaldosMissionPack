/*
 * Author: Waldo
 * Spend research costs.
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
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_spendResearchCosts;
 */

        params ["_sideKey", "_entry"];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {false};
        if !([_sideKey, _entry] call Waldo_fnc_EcoResearch_canAffordResearch) exitWith {false};

        {
            private _resourceName = _x param [0, ""];
            private _cost = _x param [1, 0];
            private _current = [_sideKey, _resourceName] call Waldo_fnc_EcoResource_getSideResourceAmount;
            [_sideKey, _resourceName, (_current - _cost), "Research"] call Waldo_fnc_EcoResource_setSideResourceAmount;
        } forEach (_entry param [2, []]);

        true

