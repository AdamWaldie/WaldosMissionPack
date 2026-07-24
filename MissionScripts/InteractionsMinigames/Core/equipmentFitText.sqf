/*
 * Fits text inside its existing control height. Returns the selected font height.
 * Structured text is laid out by its own size attributes and is only validated.
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
while {_height > _minimum && {ctrlTextHeight _control > ((_bounds select 3) * 0.96)}} do {
    _height = (_height - 0.001) max _minimum;
    _control ctrlSetFontHeight _height;
    _control ctrlCommit 0;
};
_control setVariable ["Waldo_MG_UI_FontHeight", _height];
_height
