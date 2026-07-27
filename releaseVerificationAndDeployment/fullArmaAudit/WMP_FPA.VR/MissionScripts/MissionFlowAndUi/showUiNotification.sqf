/*
 * Author: WaldoTheWarfighter
 * Draws a reusable, accessible WMP notification card on the local client.
 * Transient cards queue FIFO per channel and stack safely across channels.
 * Persistent cards replace the current owner of their channel.
 * Duration 0 keeps the card visible until it is replaced or cleared.
 *
 * Arguments:
 * 0: Title <STRING>
 * 1: Message <STRING or TEXT>
 * 2: State <STRING> INFO | SUCCESS | WARNING | ERROR (default INFO)
 * 3: Duration <NUMBER> seconds, 0 = persistent (default 8)
 * 4: Placement <STRING> TOP | TOP_RIGHT | CENTER | BOTTOM_LEFT | BOTTOM_RIGHT
 * 5: Channel <STRING> replacement/ownership key (default MISSION)
 * 6: Source label <STRING> (default WALDOS MISSION PACK)
 * 7: Policy <STRING> AUTO | FIFO | REPLACE (default AUTO)
 * 8: Priority <NUMBER> mission metadata for arbitration/reporting (default 0)
 * 9: Allow permitted local placement override <BOOL> (default false)
 *
 * Return: STRING token, or empty string if queued while no gameplay display exists.
 *
 * Example:
 * ["SUPPLY DELIVERED", "The forward crate is ready.", "SUCCESS", 8, "TOP", "LOGISTICS"]
 *     call Waldo_fnc_ShowUiNotification;
 */
if (!hasInterface) exitWith {""};

params [
    ["_title", "NOTICE", [""]],
    ["_message", ""],
    ["_state", "INFO", [""]],
    ["_duration", 8, [0]],
    ["_placement", "TOP", [""]],
    ["_channel", "MISSION", [""]],
    ["_source", "WALDOS MISSION PACK", [""]],
    ["_policy", "AUTO", [""]],
    ["_priority", 0, [0]],
    ["_allowLocalOverride", false, [true]],
    ["_fromQueue", false, [true]]
];

private _display = findDisplay 46;
if (isNull _display) exitWith {
    _this spawn {
        private _deadline = diag_tickTime + 20;
        waitUntil {uiSleep 0.1; !isNull (findDisplay 46) || {diag_tickTime >= _deadline}};
        if (!isNull (findDisplay 46)) then {_this call Waldo_fnc_ShowUiNotification;};
    };
    ""
};

_state = toUpper _state;
_channel = toUpper _channel;
_placement = [_channel, _placement, _allowLocalOverride] call Waldo_fnc_ResolveUiPanelPlacement;
_policy = toUpper _policy;
if (_policy isEqualTo "AUTO") then {_policy = if (_duration <= 0) then {"REPLACE"} else {"FIFO"};};
if !(_policy in ["FIFO", "REPLACE"]) then {_policy = "FIFO";};
private _semantic = switch (_state) do {
    case "SUCCESS": {["#6CE5A8", "[OK]"]};
    case "WARNING": {["#FFD166", "[!]"]};
    case "ERROR": {["#FF6161", "[X]"]};
    default {["#79C7FF", "[i]"]};
};
_semantic params ["_colour", "_symbol"];

private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _existingIndex = _registry findIf {(_x param [0, ""]) isEqualTo _channel};
if (_policy isEqualTo "FIFO" && {!_fromQueue} && {_existingIndex >= 0 || {({(_x param [3, ""]) isEqualTo _placement} count _registry) >= 3}}) exitWith {
    private _request = [_title, _message, _state, _duration, _placement, _channel, _source, _policy, _priority, _allowLocalOverride, false];
    private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
    private _identity = format ["%1|%2|%3|%4", _channel, _title, _message, _state];
    private _duplicate = _queue findIf {
        format ["%1|%2|%3|%4", toUpper (_x param [5, "MISSION"]), _x param [0, ""], _x param [1, ""], toUpper (_x param [2, "INFO"])] isEqualTo _identity
    };
    if (_duplicate < 0) then {_queue pushBack _request;};
    uiNamespace setVariable ["Waldo_UiPanelQueue", _queue];
    "QUEUED"
};
if (_existingIndex >= 0) then {
    private _old = _registry deleteAt _existingIndex;
    {if (!isNull _x) then {ctrlDelete _x;};} forEach (_old param [1, []]);
};

private _frame = _display ctrlCreate ["RscText", -1];
private _accent = _display ctrlCreate ["RscText", -1];
private _content = _display ctrlCreate ["RscStructuredText", -1];
_frame ctrlSetBackgroundColor [0.012, 0.020, 0.028, 0.94];
_accent ctrlSetBackgroundColor (switch (_state) do {
    case "SUCCESS": {[0.18, 0.66, 0.45, 1]};
    case "WARNING": {[0.88, 0.60, 0.12, 1]};
    case "ERROR": {[0.78, 0.15, 0.20, 1]};
    default {[0.10, 0.38, 0.66, 1]};
});
_content ctrlSetBackgroundColor [0, 0, 0, 0];

private _messageText = if ((typeName _message) isEqualTo "TEXT") then {str _message} else {_message};
_content ctrlSetStructuredText parseText format [
    "<t align='left' color='#9FB3C8' size='0.72'>%1</t><br/>" +
    "<t align='left' color='%2' size='1.12' shadow='1'>%3 %4</t><br/>" +
    "<t align='left' color='#FFFFFF' size='0.88'>%5</t>",
    toUpper _source,
    _colour,
    _symbol,
    _title,
    _messageText
];

private _visibleW = safeZoneW;
private _visibleH = safeZoneH;
private _panelW = switch (_placement) do {
    case "BOTTOM_RIGHT": {_visibleW * 0.235};
    case "TOP_RIGHT": {_visibleW * 0.28};
    case "BOTTOM_LEFT": {_visibleW * 0.34};
    case "CENTER": {_visibleW * 0.44};
    default {_visibleW * 0.48};
};
private _padX = _visibleW * 0.010;
private _padY = _visibleH * 0.008;
private _maximumContentH = _visibleH * 0.22;
_content ctrlSetPosition [0, 0, _panelW - (2 * _padX), _maximumContentH];
_content ctrlCommit 0;
private _contentH = (((ctrlTextHeight _content) + (_visibleH * 0.006)) max (_visibleH * 0.07)) min _maximumContentH;
private _panelH = _contentH + (2 * _padY);
private _accentH = (_visibleH * 0.004) max 0.002;
{_x ctrlShow true;} forEach [_frame, _accent, _content];

private _token = format ["%1_%2", diag_tickTime, random 1e9];
private _controls = [_frame, _accent, _content];
_registry pushBack [_channel, _controls, _token, _placement, _panelW, _panelH, _padX, _padY, _accentH, _contentH, _priority, diag_tickTime];
uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
[] call Waldo_fnc_ReflowUiPanels;

if (_duration > 0) then {
    [_channel, _token, _duration] spawn {
        params ["_channel", "_token", "_duration"];
        uiSleep (_duration max 1);
        private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
        private _index = _registry findIf {
            (_x param [0, ""]) isEqualTo _channel && {(_x param [2, ""]) isEqualTo _token}
        };
        if (_index >= 0) then {
            private _entry = _registry deleteAt _index;
            {if (!isNull _x) then {ctrlDelete _x;};} forEach (_entry param [1, []]);
            uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
            [] call Waldo_fnc_ReflowUiPanels;
            [] call Waldo_fnc_DrainUiNotificationQueue;
        };
    };
};

_token
