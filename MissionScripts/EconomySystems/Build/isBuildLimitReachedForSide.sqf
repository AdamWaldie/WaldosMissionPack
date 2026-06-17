/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - isBuildLimitReachedForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_isBuildLimitReachedForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _buildLimit = 0 max (floor (_entry param [19, 0]));
        if (_buildLimit <= 0) exitWith {false};

        private _buildName = _entry param [0, ""];
        ([_sideKey, _buildName] call Waldo_fnc_EcoBuild_getBuildCountForSide) >= _buildLimit

