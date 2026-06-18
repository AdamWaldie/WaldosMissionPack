/*
 * Author: Waldo
 * Get player upgrade status.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _targetEntry <ARRAY> - target entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_building, _targetEntry] call Waldo_fnc_EcoBuild_getPlayerUpgradeStatus;
 */

        params [["_building", objNull], ["_targetEntry", []]];

        if (isNull _building || {(count _targetEntry) <= 0}) exitWith {"invalid"};
        if (_building getVariable ["WaldoEcoBuild_IsUpgrading", false]) exitWith {"upgrading"};

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        if ([_targetEntry, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError) exitWith {"invalid"};

        private _sideKey = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        if !(_sideKey in ["WEST", "EAST", "GUER"]) exitWith {"invalid"};

        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([player] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {"command"};
        if !([_targetEntry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide) exitWith {"requirements"};
        if !([_targetEntry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide) exitWith {"cost"};

        "upgrade"

