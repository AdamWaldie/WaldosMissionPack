/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - beginResourceCratePlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_beginResourceCratePlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _disp) exitWith {};

    if (_disp getVariable ["WaldoEcoResource_PlacementPending", false]) exitWith {};

    [_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    [_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;

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
            [_pos] call Waldo_fnc_EcoResource_promptResourceCrateValue;
        }
    ] call Waldo_fnc_EcoCore_beginZeusPlacementSession;
