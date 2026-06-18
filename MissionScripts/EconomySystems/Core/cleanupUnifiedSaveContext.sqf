/*
 * Author: Waldo
 * Cleanup unified save context.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSaveContext;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    private _activePrompt = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _activePrompt && {!(_activePrompt isEqualTo _disp)}) then {
        [_activePrompt] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
    };

    if (!isNil "Waldo_fnc_EcoResource_cleanupResourceCratePrompt") then {[_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;};
    if (!isNil "Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt") then {[_disp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;};
    if (!isNil "Waldo_fnc_EcoResource_cleanupResourceConfigPrompt") then {[_disp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;};
    if (!isNil "Waldo_fnc_EcoResource_cleanupResourceZonePrompt") then {[_disp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;};
    if (!isNil "Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt") then {[_disp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;};
    if (!isNil "Waldo_fnc_EcoResource_stopResourceCratePlacement") then {[_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;};

    if (!isNil "Waldo_fnc_EcoResearch_cleanupResearchConfigPrompt") then {[_disp] call Waldo_fnc_EcoResearch_cleanupResearchConfigPrompt;};
    if (!isNil "Waldo_fnc_EcoResearch_stopResearchCenterPlacement") then {[_disp] call Waldo_fnc_EcoResearch_stopResearchCenterPlacement;};

    if (!isNil "Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt") then {[_disp] call Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt;};
    if (!isNil "Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt") then {[_disp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;};
    if (!isNil "Waldo_fnc_EcoBuild_stopConstructionPlacement") then {[_disp] call Waldo_fnc_EcoBuild_stopConstructionPlacement;};

    if (!isNil "Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt") then {[_disp] call Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt;};
    if (!isNil "Waldo_fnc_EcoBuy_cleanupDropPointPrompt") then {[_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;};
    if (!isNil "Waldo_fnc_EcoBuy_stopDropPointPlacement") then {[_disp] call Waldo_fnc_EcoBuy_stopDropPointPlacement;};

    [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSavePrompt;
    [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPresetPrompt;
    [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPurgePrompt;
