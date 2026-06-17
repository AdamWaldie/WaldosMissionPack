/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - buildUnifiedSaveExportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_buildUnifiedSaveExportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_includeResources", true],
        ["_includeResearch", true],
        ["_includeBuildings", true],
        ["_includeBuy", true]
    ];

    private _payloads = [];

    if (_includeResources && {!isNil "Waldo_fnc_EcoResource_buildExportPayload"}) then {
        private _payload = parseSimpleArray ([false] call Waldo_fnc_EcoResource_buildExportPayload);
        if (!isNil "Waldo_fnc_EcoResource_validateImportPayload" && {[_payload] call Waldo_fnc_EcoResource_validateImportPayload}) then {
            _payloads pushBack _payload;
        };
    };

    if (_includeResearch && {!isNil "Waldo_fnc_EcoResearch_buildResearchExportPayload"}) then {
        private _payload = parseSimpleArray ([false] call Waldo_fnc_EcoResearch_buildResearchExportPayload);
        if (!isNil "Waldo_fnc_EcoResearch_validateResearchImportPayload" && {[_payload] call Waldo_fnc_EcoResearch_validateResearchImportPayload}) then {
            _payloads pushBack _payload;
        };
    };

    if (_includeBuildings && {!isNil "Waldo_fnc_EcoBuild_buildBuildExportPayload"}) then {
        private _payload = parseSimpleArray ([false] call Waldo_fnc_EcoBuild_buildBuildExportPayload);
        if (!isNil "Waldo_fnc_EcoBuild_validateBuildImportPayload" && {[_payload] call Waldo_fnc_EcoBuild_validateBuildImportPayload}) then {
            _payloads pushBack _payload;
        };
    };

    if (_includeBuy && {!isNil "Waldo_fnc_EcoBuy_buildPurchaseExportPayload"}) then {
        private _payload = parseSimpleArray (call Waldo_fnc_EcoBuy_buildPurchaseExportPayload);
        if (!isNil "Waldo_fnc_EcoBuy_validatePurchaseImportPayload" && {[_payload] call Waldo_fnc_EcoBuy_validatePurchaseImportPayload}) then {
            _payloads pushBack _payload;
        };
    };

    str ["WaldoEcoCore_SAVE_V1", _payloads]
