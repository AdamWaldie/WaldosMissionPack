/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe vanilla and optional IMS hooks for configurable tree felling and brush clearing.
 * Locality/authority: interface-local installation only; authoritative strikes remain server-side.
 * Repeat/JIP behaviour: waits asynchronously for the ordered runtime snapshot, installs once for
 * each player object and remains completely inert unless Waldo_TreeFelling_Enable is explicitly true.
 * Arguments: None.
 * Return Value: BOOL - true when installed or waiting for runtime state, otherwise false.
 * Current callers: initPlayerLocal and FeatureRuntimeApply.
 * Example: [] call Waldo_fnc_TreeFellingInit;
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", isServer]) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_TreeFellingInit};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_TreeFelling_Enable", false]) exitWith {false};
if (missionNamespace getVariable ["Waldo_TreeFelling_ClientStarted", false]) exitWith {true};

missionNamespace setVariable ["Waldo_TreeFelling_ClientStarted", true];
uiNamespace setVariable ["Waldo_TreeFelling_TargetCache", []];
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
    "[cursorObject, _this] call Waldo_fnc_TreeFellingCanTargetLocal",
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
