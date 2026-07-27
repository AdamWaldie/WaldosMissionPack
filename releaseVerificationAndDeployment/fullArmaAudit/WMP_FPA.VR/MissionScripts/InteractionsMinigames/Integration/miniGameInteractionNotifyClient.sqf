/* Shows interaction acquisition/result feedback without occupying Arma's shared hint channel. */
if (!hasInterface) exitWith {false};
params [["_message", "EQUIPMENT UNAVAILABLE", [""]], ["_severity", "WARN", [""]], ["_duration", 4, [0]]];
private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _equipmentDisplay = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
if (!isNull _equipmentDisplay && {(toUpper _severity) in ["OK", "ERROR"]}) exitWith {
    // Terminal procedure feedback already occupies the equipment's fixed status
    // region. Do not render a second result at a different screen position.
    true
};
private _frame = _display displayCtrl 5319;
private _control = _display displayCtrl 5320;
if (isNull _frame) then {
    _frame = _display ctrlCreate ["RscText", 5319];
    _frame ctrlSetBackgroundColor [0.025, 0.035, 0.032, 0.95];
    _frame ctrlCommit 0;
};
if (isNull _control) then {
    _control = _display ctrlCreate ["RscStructuredText", 5320];
    _control ctrlCommit 0;
};
private _colour = switch (toUpper _severity) do {
    case "OK": {"#73E2A7"};
    case "ERROR": {"#FF7188"};
    default {"#F2BE55"};
};
private _token = format ["%1_%2", diag_tickTime, random 1e9];
uiNamespace setVariable ["Waldo_MG_InteractionNoticeToken", _token];
private _visibleX = safeZoneX;
private _visibleY = safeZoneY;
private _visibleW = safeZoneW;
private _visibleH = safeZoneH;
private _panelW = _visibleW * 0.52;
private _panelX = _visibleX + ((_visibleW - _panelW) / 2);
private _panelY = _visibleY + (_visibleH * 0.78);
private _padX = _visibleW * 0.012;
private _padY = _visibleH * 0.008;
private _noticeTemplate = "<t align='center' size='%1' color='" + _colour + "'>" + _message + "</t>";
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _visibleH * 0.12];
_control ctrlCommit 0;
[_control, _noticeTemplate, 1.05, 0.62] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
private _contentH = ((ctrlTextHeight _control) max (_visibleH * 0.045)) min (_visibleH * 0.12);
private _panelH = _contentH + (2 * _padY);
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_control ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_control ctrlCommit 0;
_frame ctrlShow true;
_control ctrlShow true;
[_frame, _control, _token, _duration max 1] spawn {
    params ["_frame", "_control", "_token", "_duration"];
    uiSleep _duration;
    if ((uiNamespace getVariable ["Waldo_MG_InteractionNoticeToken", ""]) isEqualTo _token) then {
        if (!isNull _control) then {_control ctrlShow false;};
        if (!isNull _frame) then {_frame ctrlShow false;};
        uiNamespace setVariable ["Waldo_MG_InteractionNoticeToken", nil];
    };
};
true
