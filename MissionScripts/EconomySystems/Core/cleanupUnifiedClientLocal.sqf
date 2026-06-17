/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - cleanupUnifiedClientLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_cleanupUnifiedClientLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    [] call Waldo_fnc_EcoCore_removeUnifiedPlayerActionsLocal;
    [] call Waldo_fnc_EcoCore_removeUnifiedZeusMenusFromDisplay;

    if (!isNil "Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal") then {
        [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;
    };

    private _zeusDisplay = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (!isNull _zeusDisplay) then {
        [_zeusDisplay] call Waldo_fnc_EcoCore_cleanupUnifiedSaveContext;
    };

    {
        private _display = uiNamespace getVariable [_x, displayNull];
        if (!isNull _display) then {
            _display closeDisplay 1;
            uiNamespace setVariable [_x, displayNull];
        };
    } forEach [
        "WaldoEcoResearch_PlayerResearchDisplay",
        "WaldoEcoResearch_PubResourceDisplay",
        "WaldoEcoBuild_PubConstructionDisplay",
        "WaldoEcoBuild_PubUpgradeDisplay",
        "WaldoEcoBuy_PubPurchaseDisplay"
    ];

    WaldoEcoResource_ZeusHookStarted = nil;
    WaldoEcoResearch_ZeusHookStarted = nil;
    WaldoEcoBuild_ZeusHookStarted = nil;
    WaldoEcoBuy_ZeusHookStarted = nil;
    WaldoEcoCore_SaveZeusHookStarted = nil;
    WaldoEcoCore_LocalWorldActionLoopStarted = nil;
    WaldoEcoCommand_LocalIdentityLoopStarted = nil;
