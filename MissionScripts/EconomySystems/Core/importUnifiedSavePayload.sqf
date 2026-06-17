/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - importUnifiedSavePayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_importUnifiedSavePayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
