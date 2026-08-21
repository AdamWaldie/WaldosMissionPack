/*
 * Author: WaldoTheWarfighter
 * Switches the ZEN "Vehicle Customisation - Editor" dialog's visible tab (Turret / Pylon / Appearance
 * / Component). Each tab's controls live inside its own RscControlsGroupNoScrollbars container (all
 * four sharing the exact same fitted rectangle), created once by
 * vehicleCustomizationPromptEditor.sqf and stored on the display under WaldoVehCust_<Tab>Group.
 * Switching tabs changes the four groups' visibility only. Their positions belong to the shared prompt
 * fitter and are never rewritten here; moving hidden groups off-screen before fitting polluted the
 * fitter's bounds, while restoring a hard-coded pre-fit rectangle afterward undid the fitted layout.
 * The permanent Pending Changes panel and its buttons are not part of a tab group and remain visible.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 * 1: Tab <STRING> - "turret", "pylon", "appearance", or "component" (optional, default: "turret")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, "pylon"] call Waldo_fnc_VehCust_setTab;
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (the 4 tab buttons' ButtonClick handlers, and the initial dialog setup).
 */

params [["_disp", displayNull], ["_tab", "turret"]];
if (isNull _disp) exitWith {};

// _tab is already a STRING. `str _tab` adds literal quote characters, fails the allow-list below and
// silently forces every requested tab back to Turret.
private _safeTab = toLowerANSI _tab;
if !(_safeTab in ["turret", "pylon", "appearance", "component"]) then {_safeTab = "turret";};

private _tabGroups = [
    ["turret", "WaldoVehCust_TurretGroup"],
    ["pylon", "WaldoVehCust_PylonGroup"],
    ["appearance", "WaldoVehCust_AppearanceGroup"],
    ["component", "WaldoVehCust_ComponentGroup"]
];
{
    _x params ["_tabName", "_varName"];
    private _group = _disp getVariable [_varName, controlNull];
    if (!isNull _group) then {
        _group ctrlShow (_safeTab isEqualTo _tabName);
    };
} forEach _tabGroups;

private _tabButtons = [
    ["turret", "WaldoVehCust_TabTurretBtn"],
    ["pylon", "WaldoVehCust_TabPylonBtn"],
    ["appearance", "WaldoVehCust_TabAppearanceBtn"],
    ["component", "WaldoVehCust_TabComponentBtn"]
];
{
    _x params ["_tabName", "_varName"];
    private _btn = _disp getVariable [_varName, controlNull];
    if (!isNull _btn) then {
        _btn ctrlSetBackgroundColor ([[0, 0, 0, 0.70], [0.18, 0.18, 0.18, 0.95]] select (_safeTab isEqualTo _tabName));
        _btn ctrlCommit 0;
    };
} forEach _tabButtons;

_disp setVariable ["WaldoVehCust_CurrentTab", _safeTab];
