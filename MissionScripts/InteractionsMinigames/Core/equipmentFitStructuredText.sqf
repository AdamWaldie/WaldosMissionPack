/*
 * Fits structured text into its existing control rectangle.
 *
 * The template must contain one %1 placeholder for the selected text size. Build any other
 * dynamic values into the template before calling this helper. The helper returns the size
 * used and records it on the control for runtime inspection.
 *
 * Arguments:
 * 0: control
 * 1: structured-text template
 * 2: preferred size (default 1)
 * 3: minimum size (default 0.62)
 */
disableSerialization;
params [
    ["_control", controlNull, [controlNull]],
    ["_template", "<t size='%1'></t>", [""]],
    ["_preferred", 1, [0]],
    ["_minimum", 0.62, [0]]
];
if (isNull _control) exitWith {_minimum};
private _size = _preferred max _minimum;
private _bounds = ctrlPosition _control;
// The template contract deliberately reserves %1 for the selected size, so
// format is sufficient and avoids depending on a BIS helper that is not
// guaranteed to be compiled when a mission opens this display.
_control ctrlSetStructuredText parseText (format [_template, _size]);
_control ctrlCommit 0;
while {
    _size > _minimum
    && {ctrlTextHeight _control > ((_bounds select 3) * 0.94)}
} do {
    _size = (_size - 0.04) max _minimum;
    _control ctrlSetStructuredText parseText (format [_template, _size]);
    _control ctrlCommit 0;
};
_control setVariable ["Waldo_MG_UI_StructuredTextSize", _size];
_size
