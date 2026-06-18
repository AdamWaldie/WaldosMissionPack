/*
 * Author: Waldo
 * Set build catalog.
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
 */

        params [["_catalog", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog, true];

