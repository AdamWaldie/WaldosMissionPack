/*
 * Author: Waldo
 * Import unified buildings additive.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoCore_importUnifiedBuildingsAdditive;
 */

    params [["_payload", []]];

    if (isNil "Waldo_fnc_EcoCore_canRunAuthority" || {!([] call Waldo_fnc_EcoCore_canRunAuthority)}) exitWith {false};
    if (isNil "Waldo_fnc_EcoBuild_validateBuildImportPayload" || {isNil "Waldo_fnc_EcoBuild_normalizeBuildEntry"} || {isNil "Waldo_fnc_EcoBuild_setBuildCatalog"} || {isNil "Waldo_fnc_EcoBuild_getBuildCatalog"}) exitWith {false};
    if !([_payload] call Waldo_fnc_EcoBuild_validateBuildImportPayload) exitWith {false};

    private _incomingCatalog = [];

    {
        private _entry = [_x] call Waldo_fnc_EcoBuild_normalizeBuildEntry;
        if ((count _entry) <= 0) then {continue;};
        _entry set [7, false];
        _incomingCatalog pushBack _entry;
    } forEach (_payload param [2, []]);

    private _mergedCatalog = [call Waldo_fnc_EcoBuild_getBuildCatalog, _incomingCatalog] call Waldo_fnc_EcoCore_mergeNamedEntryCatalogs;
    [_mergedCatalog] call Waldo_fnc_EcoBuild_setBuildCatalog;
    true
