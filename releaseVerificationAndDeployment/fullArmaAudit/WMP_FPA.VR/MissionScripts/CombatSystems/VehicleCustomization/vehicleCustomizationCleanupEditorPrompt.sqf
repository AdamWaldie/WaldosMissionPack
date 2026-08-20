/*
 * Author: WaldoTheWarfighter
 * Tears down the ZEN "Vehicle Customisation - Editor" dialog - the only thing that ever closes it.
 * Clears the display-local pending/vehicle/candidate state, then hands off to
 * Waldo_fnc_EcoCore_closePromptDisplayIfDedicated (the display created by
 * Waldo_fnc_EcoCore_createZeusPromptDisplay is always its own dedicated child display, so this simply
 * closes it, destroying every control on it in one call - no per-control cleanup needed).
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_VehCust_cleanupEditorPrompt;
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (the Ok/Close button).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {};

_disp setVariable ["WaldoVehCust_PendingRows", nil];
_disp setVariable ["WaldoVehCust_Vehicle", nil];
_disp setVariable ["WaldoVehCust_ComponentCandidates", nil];
_disp setVariable ["WaldoVehCust_TurretTabControls", nil];
_disp setVariable ["WaldoVehCust_PylonTabControls", nil];
_disp setVariable ["WaldoVehCust_AppearanceTabControls", nil];
_disp setVariable ["WaldoVehCust_ComponentTabControls", nil];

[_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;
