/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - isBuildAvailableForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_isBuildAvailableForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _availability = [(_entry param [20, ["ALL"]])] call Waldo_fnc_EcoBuild_normalizeBuildAvailability;
        if ((_availability find "ALL") >= 0) exitWith {true};

        _sideKey in _availability

