/*
 * Author: WaldoTheWarfighter
 * Closes Economy client UI, removes local actions/hooks and stops local lifecycle services.
 *
 * Locality/authority: interface client only; does not mutate server Economy state. Repeat/JIP
 * behaviour: repeat-safe and invalidates scheduled local action repair before a later re-enable.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Current callers: server-broadcast unified cleanup during purge/re-enable workflows.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_cleanupUnifiedClientLocal;
 */

    if (!hasInterface) exitWith {};

    [] call Waldo_fnc_EcoCore_stopLocalWorldActionService;
    [] call Waldo_fnc_EcoCommand_stopLocalGroundCommandIdentityService;

    [] call Waldo_fnc_EcoCore_removeUnifiedPlayerActionsLocal;

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
