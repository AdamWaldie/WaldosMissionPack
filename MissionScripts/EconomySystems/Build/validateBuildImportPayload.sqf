/*
 * Author: WaldoTheWarfighter
 * Check the outer shape and version of a saved build catalog payload.
 *
 * Locality / Authority: Pure helper; import callers must still use Economy authority for
 * mutations and normalize each entry after this shape check.
 * Repeat/JIP: Read-only and repeat-safe; no state is published here.
 * Current Callers: EcoBuild_importBuildConfiguration,
 * EcoCore_buildUnifiedSaveExportPayload and EcoCore_importUnifiedBuildingsAdditive.
 *
 * Arguments:
 * 0: _payload <ARRAY> - decoded V1, V2 or V3 build export record (required)
 *
 * Return Value:
 * BOOL - true when version, include-built flag and catalog list have the
 * expected outer types.
 * Result: This is a shape check, not proof that each definition is valid.
 *
 * Example:
 * [_payload] call Waldo_fnc_EcoBuild_validateBuildImportPayload;
 */

        params ["_payload"];

        if !(_payload isEqualType []) exitWith {false};
        if ((count _payload) < 3) exitWith {false};
        if !((_payload param [0, ""]) in ["WaldoEcoBuild_BUILD_V1", "WaldoEcoBuild_BUILD_V2", "WaldoEcoBuild_BUILD_V3"]) exitWith {false};
        if !((_payload param [1, false]) isEqualType true) exitWith {false};
        if !((_payload param [2, []]) isEqualType []) exitWith {false};

        true

