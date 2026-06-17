/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getUpgradeTargetName
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getUpgradeTargetName via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_building", objNull]];

        if (isNull _building) exitWith {""};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {""};

        _entry param [18, ""]

