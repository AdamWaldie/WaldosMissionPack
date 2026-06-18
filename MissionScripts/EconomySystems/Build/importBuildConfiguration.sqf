/*
 * Author: Waldo
 * Import build configuration.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _payload <ANY> - payload
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoBuild_importBuildConfiguration;
 */

        params ["_payload"];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if !([_payload] call Waldo_fnc_EcoBuild_validateBuildImportPayload) exitWith {};

        private _catalog = [];

        {
            private _entry = [_x] call Waldo_fnc_EcoBuild_normalizeBuildEntry;
            if ((count _entry) <= 0) then {continue;};
            _entry set [7, false];
            _catalog pushBack _entry;
        } forEach (_payload param [2, []]);

        [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalog;

