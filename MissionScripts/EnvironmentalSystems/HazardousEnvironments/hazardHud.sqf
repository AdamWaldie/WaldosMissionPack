/*
 * Author: WaldoTheWarfighter, Val
 * Draws one continuously updated hazardous-environment status panel. It does not use notification
 * cards or their queue. The panel owns the lower-left specialist region while the electronic-
 * warfare panel owns lower-right, and both register with the global WMP UI reservation service so
 * ordinary notifications reflow around whichever panels are currently visible. ACE interaction
 * suppression is inherited automatically from that shared service.
 * Locality and authority: Interface-client only. It creates and updates controls on display 46
 * for the executing player and never changes server hazard state.
 *
 * Arguments:
 * 0: status lines <ARRAY<STRING>> - current visible hazard labels/exposure values; [] hides panel.
 *
 * Return Value: <BOOL> - true after the panel was updated or hidden.
 *
 * Example:
 * [["Toxic Leak: 1.14"]] call Waldo_fnc_HazardHud;
 * Result: Shows or updates one lower-left hazard panel; an empty array hides and releases it.
 * Current callers: Waldo_fnc_HazardTick and Waldo_fnc_HazardStop.
 */
if (!hasInterface) exitWith {false};
params [["_statusLines", [], [[]]]];

private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _frame = _display displayCtrl 5349;
private _content = _display displayCtrl 5350;
if (_statusLines isEqualTo []) exitWith {
    if (!isNull _content) then {_content ctrlShow false;};
    if (!isNull _frame) then {_frame ctrlShow false;};
    ["HAZARDOUS_ENVIRONMENT_STATUS"] call Waldo_fnc_UnregisterUiReservationLocal;
    true
};

private _theme = [] call Waldo_fnc_UiTheme;
if (isNull _frame) then {_frame = _display ctrlCreate ["RscText", 5349];};
if (isNull _content) then {_content = _display ctrlCreate ["RscStructuredText", 5350];};
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.015, 0.025, 0.035, 0.92]]);
_content ctrlSetBackgroundColor [0, 0, 0, 0];

private _lines = _statusLines apply {
    format ["<t align='left' font='%1' color='%2' size='0.90'>  %3</t>",
        _theme getOrDefault ["font", "RobotoCondensed"],
        _theme getOrDefault ["textHex", "#FFFFFF"],
        _x]
};
_content ctrlSetStructuredText parseText format [
    "<t align='left' font='%1' color='%2' size='0.72'>  ENVIRONMENTAL HAZARD</t><br/>" +
    "<t align='left' font='%3' color='%4' size='1.10' shadow='1'>  EXPOSURE DETECTED</t><br/>%5",
    _theme getOrDefault ["font", "RobotoCondensed"],
    _theme getOrDefault ["mutedHex", "#9FB3C8"],
    _theme getOrDefault ["fontBold", "RobotoCondensedBold"],
    _theme getOrDefault ["warningHex", "#F4C542"],
    _lines joinString "<br/>"
];

private _visibleW = safeZoneW max 0.2;
private _visibleH = safeZoneH max 0.2;
private _panelW = _visibleW * 0.235;
private _padX = _visibleW * 0.008;
private _padY = _visibleH * 0.007;
private _panelX = safeZoneX + (_visibleW * 0.012);
_content ctrlSetPosition [_panelX + _padX, safeZoneY, _panelW - (2 * _padX), _visibleH * 0.14];
_content ctrlCommit 0;
private _contentH = ((ctrlTextHeight _content) max (_visibleH * 0.072)) min (_visibleH * 0.14);
private _panelH = _contentH + (2 * _padY);
private _panelY = safeZoneY + safeZoneH - (_visibleH * 0.19) - _panelH;
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_content ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_content ctrlCommit 0;
["HAZARDOUS_ENVIRONMENT_STATUS", [_frame, _content], ["BOTTOM_LEFT"], true] call Waldo_fnc_RegisterUiReservationLocal;
true
