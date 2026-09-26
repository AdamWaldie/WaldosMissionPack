/*
 * Author: WaldoTheWarfighter
 * Replace the authoritative build catalog with a validated saved preset.
 *
 * Locality / Authority: Economy authority only; the catalog setter publishes new state.
 * Repeat/JIP: Re-import replaces definitions, not world buildings; the
 * published catalog is available to joining clients.
 * Current Callers: EcoCore_importUnifiedSavePayload.
 *
 * Arguments:
 * 0: _payload <ARRAY> - decoded BUILD_V3 export record (required)
 *
 * Return Value:
 * Nothing
 * Result: Invalid payloads leave the catalog unchanged; valid definitions
 * are normalized with their runtime built flag cleared.
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

