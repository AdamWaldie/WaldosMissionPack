/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - canAffordResearch
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_canAffordResearch via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_sideKey", "_entry"];

        private _canAfford = true;
        {
            if (([_sideKey, _x param [0, ""]] call Waldo_fnc_EcoResource_getSideResourceAmount) < (_x param [1, 0])) exitWith {
                _canAfford = false;
            };
        } forEach (_entry param [2, []]);

        _canAfford

