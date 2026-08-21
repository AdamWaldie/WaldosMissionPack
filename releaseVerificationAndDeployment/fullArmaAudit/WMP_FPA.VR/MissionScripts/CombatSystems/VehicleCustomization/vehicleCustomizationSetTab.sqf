/*
 * Author: WaldoTheWarfighter
 * Switches the ZEN "Vehicle Customisation - Editor" dialog's visible tab (Turret / Pylon / Appearance
 * / Component). Each tab's controls live inside its own RscControlsGroupNoScrollbars container (all
 * four sharing the exact same content rectangle), created once by
 * vehicleCustomizationPromptEditor.sqf and stored on the display under WaldoVehCust_<Tab>Group -
 * switching tabs is exactly four ctrlShow calls, one per group. This mirrors the group-container
 * pattern already proven elsewhere in this codebase -
 * MissionScripts/InteractionsMinigames/Core/challengeUi.sqf's own "content group" idiom.
 *
 * This replaces an earlier version that toggled ~10-15 individual field controls per tab directly via
 * a flat forEach/ctrlShow loop; that mechanism survived static review twice but still failed live
 * in-engine testing (a tab button's highlight changed on click, but the displayed content never did).
 * Collapsing to one ctrlShow per tab removes that entire class of per-control state drift. The
 * permanent Pending Changes panel and its buttons are not part of any tab group and are always shown.
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

private _safeTab = toLower (str _tab);
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
        _group ctrlCommit 0;
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
