/*
 * Author: WaldoTheWarfighter
 * Purpose: Fits structured text into its existing control rectangle.
 *
 * The template must contain one %1 placeholder for the selected text size. Build any other
 * dynamic values into the template before calling this helper. The helper returns the size
 * used and records it on the control for runtime inspection.
 *
 * Arguments:
 * Locality/Authority: Interface client only; changes one local control.
 * Repeat/JIP Behaviour: Repeat calls recompute the font size; no display is replayed to JIP clients.
 * Arguments: 0: control <CONTROL>, default controlNull; 1: structured-text template <STRING>
 * with a %1 size placeholder, default "<t size='%1'></t>"; 2: preferred size <NUMBER>, default 1;
 * 3: minimum size <NUMBER>, default 0.62.
 * Return Value: Selected size <NUMBER>, or the minimum for controlNull.
 * Current Callers: MiniGameChallengeUI and field-equipment challenge openers.
 * Example: [_label, "<t size='%1'>READY</t>", 1, 0.62]
 *          call Waldo_fnc_MiniGameEquipmentFitStructuredText;
 * Result: Text fits the existing control height without changing its rectangle.
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
