/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getPlayerBuildStatus
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getPlayerBuildStatus via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"], ["_entry", []]];

        if ((count _entry) <= 0) exitWith {"invalid"};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([player] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {"command"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide) exitWith {"unavailable"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide) exitWith {"requirements"};
        if ([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildLimitReachedForSide) exitWith {"limit"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide) exitWith {"cost"};
        "build"

