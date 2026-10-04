/*
 * Author: WaldoTheWarfighter
 * Purpose: Fits plain text inside an existing control rectangle.
 * Locality/Authority: Interface client only; changes one local control.
 * Repeat/JIP Behaviour: Repeat calls recompute the font height; no JIP UI replay.
 * Arguments: 0: control <CONTROL>, default controlNull; 1: preferred height <NUMBER>,
 * default 0.035; 2: minimum height <NUMBER>, default 0.014.
 * Return Value: Selected font height <NUMBER>, or minimum for controlNull.
 * Current Callers: MiniGameChallengeUI and field-equipment challenge openers.
 * Example: [_title, 0.035, 0.014] call Waldo_fnc_MiniGameEquipmentFitText;
 * Result: Shrinks the font until it fits, retaining the control's rectangle.
 */
disableSerialization;
params [
    ["_control", controlNull, [controlNull]],
    ["_preferred", 0.035, [0]],
    ["_minimum", 0.014, [0]]
];
if (isNull _control) exitWith {_minimum};
private _height = _preferred;
_control ctrlSetFontHeight _height;
_control ctrlCommit 0;
private _bounds = ctrlPosition _control;
while {
    _height > _minimum
    && {
        ctrlTextHeight _control > ((_bounds select 3) * 0.94)
        || {ctrlTextWidth _control > ((_bounds select 2) * 0.94)}
    }
} do {
    _height = (_height - 0.001) max _minimum;
    _control ctrlSetFontHeight _height;
    _control ctrlCommit 0;
};
_control setVariable ["Waldo_MG_UI_FontHeight", _height];
_height
