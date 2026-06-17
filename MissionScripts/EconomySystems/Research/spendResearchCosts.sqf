/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - spendResearchCosts
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_spendResearchCosts via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

