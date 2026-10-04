/*
 * Author: WaldoTheWarfighter
 * Checks whether a friendly building has an upgrade target visible to a unit.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * <BOOL> true when a valid friendly upgrade target exists.
 *
 * Example:
 * [_building, _unit] call Waldo_fnc_EcoBuild_canPlayerViewUpgrade;
 * Locality/Authority: Any machine; read-only building/side visibility check.
 * Repeat/JIP Behaviour: Repeat-safe read of public ownership/definition.
 * Current Callers: EcoBuild_startBuildingUpgrade server-side eligibility gate.
 * Result: Hides upgrade controls on enemy or terminal-tier buildings.
 */

        params [["_building", objNull], ["_unit", objNull]];

        if (isNull _building || isNull _unit) exitWith {false};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {false};
        if (_building getVariable ["WaldoEcoBuild_IsUpgrading", false]) exitWith {false};

        private _ownerSide = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        private _playerSide = [side group _unit] call Waldo_fnc_EcoResource_getSideKeyFromSide;
        private _targetName = [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetName;

        (_ownerSide in ["WEST", "EAST", "GUER"])
        && {_playerSide isEqualTo _ownerSide}
        && {_targetName isNotEqualTo ""}

