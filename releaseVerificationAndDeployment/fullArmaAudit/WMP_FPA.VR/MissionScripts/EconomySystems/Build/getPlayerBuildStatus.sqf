/*
 * Author: WaldoTheWarfighter
 * Classifies whether the local player can begin one Construction entry.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * <STRING> status code; "build" when all gates pass.
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoBuild_getPlayerBuildStatus;
 * Locality/Authority: Interface/authority read of published Economy state; server checks again
 * before committing the construction request.
 * Repeat/JIP Behaviour: Repeat-safe status read; JIP receives current registries.
 * Current Callers: Construction catalog action availability and feedback.
 * Result: Returns the first block, such as requirements, limit or cost.
 */

        params [["_sideKey", "NONE"], ["_entry", []]];

        if ((count _entry) <= 0) exitWith {"invalid"};
        if (([_entry] call Waldo_fnc_EcoBuild_getBuildSpawnClass) isEqualTo "") exitWith {"invalid"};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([player] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {"command"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildAvailableForSide) exitWith {"unavailable"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide) exitWith {"requirements"};
        if ([_entry, _sideKey] call Waldo_fnc_EcoBuild_isBuildLimitReachedForSide) exitWith {"limit"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuild_canAffordBuildForSide) exitWith {"cost"};
        "build"

