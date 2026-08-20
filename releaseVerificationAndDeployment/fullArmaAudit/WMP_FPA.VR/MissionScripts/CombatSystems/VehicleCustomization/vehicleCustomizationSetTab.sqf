/*
 * Author: WaldoTheWarfighter
 * Switches the ZEN "Vehicle Customisation - Editor" dialog's visible tab (Turret / Pylon / Appearance
 * / Component) by toggling ctrlShow on each tab's own control group, matching
 * MissionScripts/EconomySystems/Build/setBuildConfigTab.sqf's tab-toggle pattern. The permanent
 * Pending Changes panel and its buttons are not part of any tab group and are always shown.
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
 * (the 4 tab buttons' ButtonClick handlers; initial dialog setup; and a one-time ~0.6s-delayed
 * re-assert that survives Waldo_fnc_EcoCore_fitPromptDisplay's own later, unrelated recoloring pass
 * over every button-type control in the display).
 */

params [["_disp", displayNull], ["_tab", "turret"]];
if (isNull _disp) exitWith {};

private _safeTab = toLower (str _tab);
if !(_safeTab in ["turret", "pylon", "appearance", "component"]) then {_safeTab = "turret";};

// Each tab's own control group is tagged on the display under WaldoVehCust_<Tab>TabControls -
// populated once by vehicleCustomizationPromptEditor.sqf when the controls are created.
{
    _x params ["_tabName", "_varName"];
    private _controls = _disp getVariable [_varName, []];
    private _show = _safeTab isEqualTo _tabName;
    {if (!isNull _x) then {_x ctrlShow _show; _x ctrlCommit 0;};} forEach _controls;
} forEach [
    ["turret", "WaldoVehCust_TurretTabControls"],
    ["pylon", "WaldoVehCust_PylonTabControls"],
    ["appearance", "WaldoVehCust_AppearanceTabControls"],
    ["component", "WaldoVehCust_ComponentTabControls"]
];

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
