/*
 * Author: Waldo
 * Get upgrade target entry.
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
 * [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetEntry;
 */

        params [["_building", objNull]];

        private _targetName = [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetName;
        if (_targetName isEqualTo "") exitWith {[]};

        [_targetName] call Waldo_fnc_EcoBuild_getBuildDefinition

