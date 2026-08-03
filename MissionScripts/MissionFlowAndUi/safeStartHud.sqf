/*
 * Author: WaldoTheWarfighter
 * Draws Safestart status in a dedicated main-display control. Keeping the
 * persistent countdown out of Arma's global hint channel allows other systems
 * to present important transient messages at the same time.
 *
 * Arguments: 0: enabled <BOOL>; 1: structured content <STRING>.
 * Return Value: BOOL - true when the local HUD was updated or hidden.
 *
 * Example: [true, "Weapons safe"] call Waldo_fnc_SafeStartHud;
 * Current caller: the local SafeStart state service.
 */
if (!hasInterface) exitWith {false};
params [['_enabled', true, [true]], ['_content', '', ['']]];

// Protection begins immediately, but the title sequence owns the screen during startup.
// The service loop calls this function once per second, so the current state appears as soon
// as the real pack init has finished without replaying stale startup notices.
if !(missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]) exitWith {false};

private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;
private _frame = _display displayCtrl 5299;
private _control = _display displayCtrl 5300;
private _legacyNotice = _display displayCtrl 5301;
if !(isNull _legacyNotice) then {_legacyNotice ctrlShow false;};
if (isNull _frame) then {
    _frame = _display ctrlCreate ['RscText', 5299];
    _frame ctrlCommit 0;
};
_frame ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.015, 0.07, 0.12, 0.92]]);
if (isNull _control) then {
    _control = _display ctrlCreate ['RscStructuredText', 5300];
    _control ctrlSetBackgroundColor [0, 0, 0, 0];
    _control ctrlCommit 0;
};

// A transition notice temporarily owns the same control. The persistent loop must not erase
// it or hide it while the transition is still being read.
if ((uiNamespace getVariable ["Waldo_SafeStart_NoticeToken", ""]) != "") exitWith {true};

if (!_enabled) exitWith {
    _control ctrlShow false;
    _frame ctrlShow false;
    ["SAFESTART_STATUS", [_frame, _control], ["TOP", "TOP_RIGHT"], false] call Waldo_fnc_RegisterUiReservationLocal;
    true
};

_control ctrlSetStructuredText parseText _content;
private _panelW = safeZoneW * 0.48;
private _padX = _panelW * 0.035;
private _padY = safeZoneH * 0.012;
private _panelX = safeZoneX + ((safeZoneW - _panelW) / 2);
private _panelY = safeZoneY + (safeZoneH * 0.045);
private _maximumContentH = safeZoneH * 0.32;
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _maximumContentH];
_control ctrlCommit 0;
private _contentH = (((ctrlTextHeight _control) + (safeZoneH * 0.008)) max (safeZoneH * 0.10)) min _maximumContentH;
private _panelH = _contentH + (2 * _padY);
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_control ctrlCommit 0;
["SAFESTART_STATUS", [_frame, _control], ["TOP", "TOP_RIGHT"], true] call Waldo_fnc_RegisterUiReservationLocal;
true
