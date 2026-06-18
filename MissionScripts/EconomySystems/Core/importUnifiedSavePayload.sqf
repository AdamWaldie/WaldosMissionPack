/*
 * Author: Waldo
 * Import unified save payload.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 * 1: _callerName <STRING> - caller name (optional, default: "Zeus")
 * 2: _additive <BOOL> - additive (optional, default: false)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_payload, _callerName, _additive] call Waldo_fnc_EcoCore_importUnifiedSavePayload;
 */

    params [
        ["_payload", []],
        ["_callerName", "Zeus"],
        ["_additive", false]
    ];

    private _payloads = [_payload] call Waldo_fnc_EcoCore_collectKnownModuleImportPayloads;
    if ((count _payloads) <= 0) exitWith {false};

    {
        if ((_x param [0, ""]) in ["WaldoEcoResource_CONFIG_V1", "WaldoEcoResource_CONFIG_V2", "WaldoEcoResource_CONFIG_V3"]) then {
            if (_additive) then {
                [_x, _callerName] call Waldo_fnc_EcoCore_importUnifiedResourcesAdditive;
            } else {
                [_x, _callerName] call Waldo_fnc_EcoResource_importResourceConfiguration;
            };
        };
    } forEach _payloads;

    {
        if ((_x param [0, ""]) isEqualTo "WaldoEcoResearch_RESEARCH_V1") then {
            if (_additive) then {
                [_x] call Waldo_fnc_EcoCore_importUnifiedResearchAdditive;
            } else {
                [_x] call Waldo_fnc_EcoResearch_importResearchConfiguration;
            };
        };
    } forEach _payloads;

    {
        if ((_x param [0, ""]) in ["WaldoEcoBuild_BUILD_V1", "WaldoEcoBuild_BUILD_V2", "WaldoEcoBuild_BUILD_V3"]) then {
            if (_additive) then {
                [_x] call Waldo_fnc_EcoCore_importUnifiedBuildingsAdditive;
            } else {
                [_x] call Waldo_fnc_EcoBuild_importBuildConfiguration;
            };
        };
    } forEach _payloads;

    {
        if ((_x param [0, ""]) isEqualTo "WaldoEcoBuy_PURCHASE_V1") then {
            if (_additive) then {
                [_x] call Waldo_fnc_EcoCore_importUnifiedPurchasesAdditive;
            } else {
                [_x] call Waldo_fnc_EcoBuy_importPurchaseConfiguration;
            };
        };
    } forEach _payloads;

    true
