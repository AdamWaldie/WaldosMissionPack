/*
 * Author: Waldo
 * Can player manage building.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_building, _unit] call Waldo_fnc_EcoBuild_canPlayerManageBuilding;
 */

        params [["_building", objNull], ["_unit", objNull]];

        if (isNull _building || isNull _unit) exitWith {false};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {false};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_unit] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {false};

        private _ownerSide = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        private _playerSide = [side group _unit] call Waldo_fnc_EcoResource_getSideKeyFromSide;

        (_ownerSide in ["WEST", "EAST", "GUER"]) && {_playerSide isEqualTo _ownerSide}

