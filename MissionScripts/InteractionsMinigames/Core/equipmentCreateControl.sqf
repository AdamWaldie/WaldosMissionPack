/*
 * Creates a control inside the equipment work-area group.
 * Arguments: [display, className, gridRect, semanticLabel]
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
