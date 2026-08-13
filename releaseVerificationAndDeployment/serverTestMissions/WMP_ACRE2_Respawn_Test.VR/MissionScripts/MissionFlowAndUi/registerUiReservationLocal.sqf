/*
 * Author: WaldoTheWarfighter
 * Registers or updates one specialist HUD reservation with the shared WMP UI flow manager.
 * Notification stacking and overflow consume only this generic registry; they do not know which
 * feature owns a control. Registration is local, repeat-safe and compatible with ACE suppression.
 *
 * Arguments:
 * 0: reservation key <STRING>
 * 1: controls <ARRAY<CONTROL>>
 * 2: affected placements <ARRAY<STRING>> - TOP, TOP_RIGHT, CENTER, BOTTOM_LEFT, BOTTOM_CENTER or BOTTOM_RIGHT
 * 3: active <BOOL> (default true)
 * 4: reflow now <BOOL> (default true)
 *
 * Return Value: BOOL - true when the reservation was stored.
 *
 * Example: ["EW_STATUS", [_frame, _content], ["BOTTOM_RIGHT"], true] call Waldo_fnc_RegisterUiReservationLocal;
 * Current callers: SafeStart, electronic-warfare and hazardous-environment specialist HUD renderers;
 * available to plugins.
 */
if (!hasInterface) exitWith {false};
params [
    ["_key", "", [""]],
    ["_controls", [], [[]]],
    ["_placements", [], [[]]],
    ["_active", true, [true]],
    ["_reflow", true, [true]]
];
_key = toUpperANSI _key;
if (_key isEqualTo "") exitWith {false};
private _valid = ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
_placements = _placements apply {toUpperANSI _x};
_placements = _placements arrayIntersect _valid;
_controls = _controls select {!isNull _x};

private _registry = +(uiNamespace getVariable ["Waldo_UI_ReservationRegistry", []]);
private _index = _registry findIf {(_x param [0, ""]) isEqualTo _key};
private _entry = [_key, _controls, _placements, _active];
if (_index < 0) then {_registry pushBack _entry} else {_registry set [_index, _entry]};
uiNamespace setVariable ["Waldo_UI_ReservationRegistry", _registry];

private _visible = _active && {!(uiNamespace getVariable ["Waldo_UI_PanelsSuppressed", false])};
{_x ctrlShow _visible} forEach _controls;
if (_reflow) then {[0] call Waldo_fnc_ReflowUiPanels};
true
