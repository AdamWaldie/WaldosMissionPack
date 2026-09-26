/*
 * Author: WaldoTheWarfighter
 * Purpose: Creates and records a control inside the equipment work-area group.
 * Locality/Authority: Interface client only; no server state changes.
 * Repeat/JIP Behaviour: One control per call, scoped to the supplied display. A new client
 * creates controls only when it opens its own challenge.
 * Arguments: 0: display <DISPLAY>, default displayNull; 1: control class <STRING>, default "RscText";
 * 2: rectangle <ARRAY [x,y,w,h]> in the 40 x 25 grid, default [0,0,1,1];
 * 3: semantic label <STRING>, default "".
 * Return Value: <CONTROL> new control, or controlNull if no work-area group exists.
 * Current Callers: MiniGameChallengeUI and field-equipment challenge openers.
 * Example: [_display, "RscText", [1, 2, 8, 1], "status label"]
 *          call Waldo_fnc_MiniGameEquipmentCreateControl;
 * Result: The control is positioned and recorded for validation/cleanup.
 */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_className", "RscText", [""]],
    ["_rect", [0, 0, 1, 1], [[]]],
    ["_semanticLabel", "", [""]]
];
if (isNull _display) exitWith {controlNull};
private _group = _display getVariable ["Waldo_MG_UI_ContentGroup", controlNull];
if (isNull _group) exitWith {controlNull};
private _control = _display ctrlCreate [_className, -1, _group];
_control ctrlSetPosition ([_display, _rect] call Waldo_fnc_MiniGameEquipmentRect);
_control ctrlCommit 0;
if (ctrlType _control in [0, 1, 11, 12, 16, 41]) then {
    private _height = (ctrlPosition _control) select 3;
    private _largeText = ((_display getVariable ["Waldo_IMG_Profile", createHashMap]) getOrDefault ["accessibility", createHashMap]) getOrDefault ["largeText", false];
    private _fontHeight = ((_height * (if (_largeText) then {0.84} else {0.74})) min 0.038) max 0.018;
    _control ctrlSetFontHeight _fontHeight;
    _control ctrlCommit 0;
};
_control setVariable ["Waldo_MG_UI_GridRect", +_rect];
_control setVariable ["Waldo_MG_UI_SemanticLabel", _semanticLabel];
private _controls = _display getVariable ["Waldo_MG_UI_EquipmentControls", []];
_controls pushBack _control;
_display setVariable ["Waldo_MG_UI_EquipmentControls", _controls];
_control
