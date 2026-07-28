/*
 * Author: Waldo
 * Installs repeat-safe vanilla and optional IMS hooks for configurable tree felling and brush clearing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when installed
 *
 * Example:
 * [] call Waldo_fnc_TreeFellingInit;
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {waitUntil {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}; [] call Waldo_fnc_TreeFellingInit};
    true
};
if !(missionNamespace getVariable ["Waldo_TreeFelling_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_TreeFelling_ClientStarted", false]) exitWith {true};

missionNamespace setVariable ["Waldo_TreeFelling_ClientStarted", true];
private _actionId = player addAction [
    "Fell Tree / Clear Brush",
    {
        [player, currentWeapon player, cursorObject] call Waldo_fnc_TreeFellingSwing;
    },
    [],
    1.5,
    false,
    true,
    "",
    "_this == player && {vehicle player == player} && {player distance cursorObject <= (missionNamespace getVariable ['Waldo_TreeFelling_Range', 3])} && {toLowerANSI ((getModelInfo cursorObject) select 1) find 'tree' >= 0 || {typeOf cursorObject in (missionNamespace getVariable ['Waldo_TreeFelling_AllowedClasses', []])} || {(missionNamespace getVariable ['Waldo_TreeFelling_ClearBushes', false]) && {toLowerANSI ((getModelInfo cursorObject) select 1) find 'bush' >= 0}}}",
    4
];
player setVariable ["Waldo_TreeFelling_ActionId", _actionId];

private _previous = player getVariable ["IMS_EventHandler_Swing", {}];
player setVariable ["Waldo_TreeFelling_PreviousIMSHandler", _previous];
player setVariable ["IMS_EventHandler_Swing", {
    params ["_unit", "_weapon"];
    private _prior = player getVariable ["Waldo_TreeFelling_PreviousIMSHandler", {}];
    if (_prior isEqualType {}) then {_this call _prior};
    [_unit, _weapon, cursorObject] call Waldo_fnc_TreeFellingSwing;
}];
true
