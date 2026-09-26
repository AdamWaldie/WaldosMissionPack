/*
 * Author: WaldoTheWarfighter
 * Store a normalized build catalog in this client's editor state.
 *
 * Locality / Authority: Local-only; this is not the authoritative catalog publisher.
 * Repeat/JIP: Replaces this machine's catalog each call and does not send
 * changes to other clients or replay state to JIP players.
 * Current Callers: EcoBuild_promptBuildConfig.
 *
 * Arguments:
 * 0: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * Nothing
 * Result: Makes normalized definitions available to the local prompt.
 *
 * Example:
 * [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalogLocal;
 */

        params [["_catalog", []]];
        missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog];

