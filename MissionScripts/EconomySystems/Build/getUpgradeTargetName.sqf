/*
 * Author: Waldo
 * Get upgrade target name.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetName;
 */

        params [["_building", objNull]];

        if (isNull _building) exitWith {""};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {""};

        _entry param [18, ""]

