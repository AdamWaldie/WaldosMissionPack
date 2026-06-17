/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - canAffordBuildForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_canAffordBuildForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

