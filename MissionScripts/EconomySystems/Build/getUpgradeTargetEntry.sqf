/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getUpgradeTargetEntry
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getUpgradeTargetEntry via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_building", objNull]];

        private _targetName = [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetName;
        if (_targetName isEqualTo "") exitWith {[]};

        [_targetName] call Waldo_fnc_EcoBuild_getBuildDefinition

