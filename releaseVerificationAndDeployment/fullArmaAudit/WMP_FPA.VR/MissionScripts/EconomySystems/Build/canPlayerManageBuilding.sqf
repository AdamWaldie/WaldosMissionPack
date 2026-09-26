/*
 * Author: WaldoTheWarfighter
 * Checks whether a unit may manage an operational building owned by its side.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * <BOOL> true when unit, side and building state permit management.
 *
 * Example:
 * [_building, _unit] call Waldo_fnc_EcoBuild_canPlayerManageBuilding;
 * Locality/Authority: Client visibility check and server request gate read the same public owner state.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP receives current building ownership.
 * Current Callers: Building management action and server-side manage validation.
 * Result: Opposing sides and units without command authority cannot manage it.
 */

        params [["_building", objNull], ["_unit", objNull]];

        if (isNull _building || isNull _unit) exitWith {false};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {false};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([_unit] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {false};

        private _ownerSide = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        private _playerSide = [side group _unit] call Waldo_fnc_EcoResource_getSideKeyFromSide;

        (_ownerSide in ["WEST", "EAST", "GUER"]) && {_playerSide isEqualTo _ownerSide}

