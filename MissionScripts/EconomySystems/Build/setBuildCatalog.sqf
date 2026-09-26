/*
 * Author: WaldoTheWarfighter
 * Normalizes and publishes the authoritative Construction catalog.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalog;
 * Locality/Authority: Economy authority only; clients consume the public catalog.
 * Repeat/JIP Behaviour: Repeated calls replace definitions; JIP receives latest rows.
 * Current Callers: Construction ZEN configuration and exported mission setup calls.
 * Result: Validated build rows become available to Construction actions.
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog, true];

