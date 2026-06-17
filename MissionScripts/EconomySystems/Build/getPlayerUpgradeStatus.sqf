/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getPlayerUpgradeStatus
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getPlayerUpgradeStatus via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

