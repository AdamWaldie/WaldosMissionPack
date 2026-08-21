/*
 * Author: WaldoTheWarfighter
 * Switches the ZEN "Vehicle Customisation - Editor" dialog's visible tab (Turret / Pylon / Appearance
 * / Component). Each tab's controls live inside its own RscControlsGroupNoScrollbars container (all
 * four sharing the exact same content rectangle), created once by
 * vehicleCustomizationPromptEditor.sqf and stored on the display under WaldoVehCust_<Tab>Group.
 *
 * Switching tabs MOVES each non-active group off-screen (ctrlSetPosition to a tiny rect well outside
 * the safe zone) rather than relying on ctrlShow. Two earlier versions of this function - one toggling
 * ~10-15 individual field controls per tab directly, then one toggling ctrlShow on these same four
 * groups - both survived static review but failed live in-engine testing: the clicked tab button's
 * highlight changed, but the displayed content never did, for either mechanism. Repositioning off-screen
 * doesn't depend on ctrlShow cascading correctly through anything - a control that isn't within the
 * safe zone simply isn't rendered, which is a much harder property to get subtly wrong than a visibility
 * flag. The active tab's group is always moved back to its real, on-screen rect. The permanent Pending
 * Changes panel and its buttons are not part of any tab group and are always shown.
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

// The real, on-screen rect every group was created at (vehicleCustomizationPromptEditor.sqf) - stored
// on the display so this function doesn't have to hardcode a second copy of those numbers.
private _onScreenRect = _disp getVariable ["WaldoVehCust_TabContentRect", [0.10, 0.16, 0.46, 0.62]];
// Comfortably outside the safe zone in every direction, tiny, so even if something ever rendered it
// anyway it would be imperceptible - the actual invisibility guarantee is being outside the safe zone.
private _offScreenRect = [-2, -2, 0.01, 0.01];

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
        _group ctrlSetPosition (if (_safeTab isEqualTo _tabName) then {_onScreenRect} else {_offScreenRect});
        _group ctrlCommit 0;
        // ctrlShow is kept as a harmless second signal alongside the position move - never relied on
        // alone here, since it's the exact mechanism that already failed twice.
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
