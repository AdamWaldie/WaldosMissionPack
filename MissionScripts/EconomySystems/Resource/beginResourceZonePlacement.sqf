/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - beginResourceZonePlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_beginResourceZonePlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _disp) exitWith {};

    [_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    [_disp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
    [_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;

    _disp setVariable ["WaldoEcoResource_PlacementMode", "ZONE"];

    [
        _disp,
        "WaldoEcoResource_PlacementPending",
        "WaldoEcoResource_PlacementEH",
        "WaldoEcoResource_PlacementKeyEH",
        {
            [] call Waldo_fnc_EcoResource_getResourceCratePlacementPos
        },
        {
            params ["_display", "_pos"];
            [_pos] call Waldo_fnc_EcoResource_promptResourceZone;
        }
    ] call Waldo_fnc_EcoCore_beginZeusPlacementSession;
