/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - canPlayerViewUpgrade
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_canPlayerViewUpgrade via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

