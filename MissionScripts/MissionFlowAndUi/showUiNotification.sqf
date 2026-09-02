/*
 * Author: WaldoTheWarfighter
 * Draws a reusable, accessible WMP notification card on the local client.
 * Transient cards stack across channels and may spill into other screen regions.
 * Pending state is bounded, expires, and coalesces by channel to prevent notification after-play.
 * Persistent cards replace the current owner of their channel.
 * Duration 0 keeps the card visible until it is replaced or cleared. For timed cards, the supplied
 * duration is the maximum: WMP shortens concise messages toward the configured readable minimum and
 * progressively grants longer text more reading time, without ever extending a caller's old timing.
 *
 * Arguments:
 * 0: Title <STRING>
 * 1: Message <STRING or TEXT>
 * 2: State <STRING> INFO | SUCCESS | WARNING | ERROR (default INFO)
 * 3: Maximum duration <NUMBER> seconds, 0 = persistent (default 8)
 * 4: Placement <STRING> TOP | TOP_RIGHT | CENTER | BOTTOM_LEFT | BOTTOM_CENTER | BOTTOM_RIGHT
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
 * Current callers: all WMP feature notification adapters and direct mission-maker scripts.
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

private _messageText = if ((typeName _message) isEqualTo "TEXT") then {str _message} else {_message};
if (_duration > 0 && {!_fromQueue}) then {
    private _maximumDuration = _duration max 1;
    private _minimumDuration = ((missionNamespace getVariable ["Waldo_UiNotification_MinimumDuration", 3]) max 1) min _maximumDuration;
    private _charactersPerSecond = ((missionNamespace getVariable ["Waldo_UiNotification_CharactersPerSecond", 18]) max 5) min 60;
    private _characterCount = count toArray format ["%1 %2", _title, _messageText];
    _duration = (_minimumDuration + (_characterCount / _charactersPerSecond)) min _maximumDuration;
};

private _display = findDisplay 46;
if (isNull _display) exitWith {
    private _ttl = ((missionNamespace getVariable ["Waldo_UiNotification_QueueLifetime", 15]) max 2) min 120;
    private _startupPriority = _priority max (switch (toUpper _state) do {case "ERROR": {3}; case "WARNING": {2}; case "SUCCESS": {1}; default {0}});
    private _pending = +(uiNamespace getVariable ["Waldo_UiNotification_DisplayWaitQueue", []]);
    _pending = _pending select {(_x param [1, 0]) > diag_tickTime};
    private _startupChannel = toUpper _channel;
    private _sameChannel = _pending findIf {toUpper (((_x param [0, []]) param [5, "MISSION"])) isEqualTo _startupChannel};
    private _entry = [+_this, diag_tickTime + _ttl, _startupPriority];
    if (_sameChannel >= 0) then {
        if (_startupPriority >= ((_pending select _sameChannel) param [2, 0])) then {_pending set [_sameChannel, _entry]};
    } else {
        private _maximumQueued = ((missionNamespace getVariable ["Waldo_UiNotification_MaximumQueued", 12]) max 1) min 50;
        if (count _pending < _maximumQueued) then {_pending pushBack _entry};
    };
    uiNamespace setVariable ["Waldo_UiNotification_DisplayWaitQueue", _pending];
    if !(uiNamespace getVariable ["Waldo_UiNotification_DisplayWaitRunning", false]) then {
        uiNamespace setVariable ["Waldo_UiNotification_DisplayWaitRunning", true];
        [] spawn {
            private _deadline = diag_tickTime + 20;
            waitUntil {uiSleep 0.1; !isNull (findDisplay 46) || {diag_tickTime >= _deadline}};
            private _requests = +(uiNamespace getVariable ["Waldo_UiNotification_DisplayWaitQueue", []]);
            uiNamespace setVariable ["Waldo_UiNotification_DisplayWaitQueue", []];
            uiNamespace setVariable ["Waldo_UiNotification_DisplayWaitRunning", false];
            if (!isNull (findDisplay 46)) then {
                {if ((_x param [1, 0]) > diag_tickTime) then {(_x select 0) call Waldo_fnc_ShowUiNotification}} forEach _requests;
            };
        };
    };
    "QUEUED"
};

_state = toUpper _state;
_channel = toUpper _channel;
_placement = if (_fromQueue) then {toUpper _placement} else {[_channel, _placement, _allowLocalOverride] call Waldo_fnc_ResolveUiPanelPlacement};
_policy = toUpper _policy;
if (_policy isEqualTo "AUTO") then {_policy = if (_duration <= 0) then {"REPLACE"} else {"FIFO"};};
if !(_policy in ["FIFO", "REPLACE"]) then {_policy = "FIFO";};
private _theme = [] call Waldo_fnc_UiNotificationTheme;
// The shared renderer builds different silhouettes without texture files or theme-owned drawing
// code, while every theme retains one consistent, resolution-aware content footprint.
private _resolution = getResolution;
private _screenHeight = (_resolution param [1, 1080]) max 480;
// Arma's safe-zone coordinates handle UI scaling, while this final bounded factor protects short
// displays where a three-card stack otherwise consumes most of the available vertical space.
private _resolutionScale = linearConversion [720, 1080, _screenHeight, 0.88, 1, true];
private _notificationScaleId = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationScaleLocal", profileNamespace getVariable ["Waldo_UI_NotificationScale", "MEDIUM"]]);
private _personalScale = switch (_notificationScaleId) do {case "SMALL": {0.82}; case "LARGE": {1.18}; default {1};};
private _sizeScale = 0.68 * _resolutionScale * _personalScale;
private _panelScale = 0.76 * _resolutionScale * _personalScale;
// Full themes share one medium footprint. Per-theme width multipliers compounded with font and
// chrome reductions and made nominally equivalent cards visibly inconsistent. Theme identity now
// comes from construction, material, typography and alignment rather than overall size.
private _widthScale = 1;
private _semantic = switch (_state) do {
    case "SUCCESS": {[_theme getOrDefault ["successHex", "#6CE5A8"], _theme getOrDefault ["successSymbol", "[OK]"], _theme getOrDefault ["success", [0.18, 0.66, 0.45, 1]]]};
    case "WARNING": {[_theme getOrDefault ["warningHex", "#FFD166"], _theme getOrDefault ["warningSymbol", "[!]"], _theme getOrDefault ["warning", [0.88, 0.60, 0.12, 1]]]};
    case "ERROR": {[_theme getOrDefault ["dangerHex", "#FF6161"], _theme getOrDefault ["dangerSymbol", "[X]"], _theme getOrDefault ["danger", [0.78, 0.15, 0.20, 1]]]};
    default {[_theme getOrDefault ["accentHex", "#79C7FF"], _theme getOrDefault ["infoSymbol", "[i]"], _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]};
};
_semantic params ["_colour", "_symbol", "_accentColour"];

private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _existingIndex = _registry findIf {(_x param [0, ""]) isEqualTo _channel};
private _uiSuppressed = uiNamespace getVariable ["Waldo_UI_PanelsSuppressed", false];
private _maximumPerPlacement = ((missionNamespace getVariable ["Waldo_UiNotification_MaximumPerPlacement", 3]) max 1) min 6;
private _placementCandidates = [_placement];
if (missionNamespace getVariable ["Waldo_UiNotification_AllowPlacementOverflow", true]) then {
    {
        private _candidate = toUpper _x;
        if (_candidate in ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]) then {
            _placementCandidates pushBackUnique _candidate;
        };
    } forEach (missionNamespace getVariable ["Waldo_UiNotification_OverflowPlacements", ["BOTTOM_RIGHT", "BOTTOM_LEFT", "CENTER"]]);
};
if (_existingIndex < 0) then {
    private _freePlacement = _placementCandidates findIf {
        private _candidate = _x;
        ({(_x param [3, ""]) isEqualTo _candidate} count _registry) < _maximumPerPlacement
    };
    if (_freePlacement >= 0) then {_placement = _placementCandidates select _freePlacement};
};
private _allPlacementsFull = _placementCandidates findIf {
    private _candidate = _x;
    ({(_x param [3, ""]) isEqualTo _candidate} count _registry) < _maximumPerPlacement
} < 0;
if (
    !_fromQueue
    && {
        _uiSuppressed
        || {_policy isEqualTo "FIFO" && {_existingIndex >= 0 || {_allPlacementsFull}}}
    }
) exitWith {
    private _ttl = ((missionNamespace getVariable ["Waldo_UiNotification_QueueLifetime", 15]) max 2) min 120;
    private _queuePriority = _priority max (switch (_state) do {case "ERROR": {3}; case "WARNING": {2}; case "SUCCESS": {1}; default {0}});
    private _request = [_title, _message, _state, _duration, _placement, _channel, _source, _policy, _queuePriority, _allowLocalOverride, false, diag_tickTime, diag_tickTime + _ttl];
    private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
    _queue = _queue select {(_x param [12, 1e11]) > diag_tickTime};
    private _sameChannel = _queue findIf {toUpper (_x param [5, "MISSION"]) isEqualTo _channel};
    if (_sameChannel >= 0) then {
        if (_queuePriority >= ((_queue select _sameChannel) param [8, 0])) then {_queue set [_sameChannel, _request]};
    } else {
        private _maximumQueued = ((missionNamespace getVariable ["Waldo_UiNotification_MaximumQueued", 12]) max 1) min 50;
        if (count _queue < _maximumQueued) then {
            _queue pushBack _request;
        } else {
            private _lowestIndex = 0;
            for "_index" from 1 to ((count _queue) - 1) do {
                if (((_queue select _index) param [8, 0]) < ((_queue select _lowestIndex) param [8, 0])) then {_lowestIndex = _index};
            };
            if (_queuePriority >= ((_queue select _lowestIndex) param [8, 0])) then {_queue set [_lowestIndex, _request]};
        };
    };
    uiNamespace setVariable ["Waldo_UiPanelQueue", _queue];
    "QUEUED"
};
if (_existingIndex >= 0) then {
    private _old = _registry deleteAt _existingIndex;
    {if (!isNull _x) then {ctrlDelete _x;};} forEach (_old param [1, []]);
};

private _frame = _display ctrlCreate ["RscText", -1];
private _chrome0 = _display ctrlCreate ["RscText", -1];
private _chrome1 = _display ctrlCreate ["RscText", -1];
private _chrome2 = _display ctrlCreate ["RscText", -1];
private _chrome3 = _display ctrlCreate ["RscText", -1];
private _chrome4 = _display ctrlCreate ["RscText", -1];
private _chrome5 = _display ctrlCreate ["RscText", -1];
private _accent = _display ctrlCreate ["RscText", -1];
private _trim = _display ctrlCreate ["RscText", -1];
private _content = _display ctrlCreate ["RscStructuredText", -1];
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.012, 0.020, 0.028, 0.94]]);
{
    _x params ["_control", "_colour"];
    _control ctrlSetBackgroundColor _colour;
    _control ctrlShow false;
} forEach [
    [_chrome0, _theme getOrDefault ["chromePrimary", [0, 0, 0, 0]]],
    [_chrome1, _theme getOrDefault ["chromeSecondary", [0, 0, 0, 0]]],
    [_chrome2, _theme getOrDefault ["chromeTertiary", [0, 0, 0, 0]]],
    [_chrome3, _theme getOrDefault ["chromePrimary", [0, 0, 0, 0]]],
    [_chrome4, _theme getOrDefault ["chromeSecondary", [0, 0, 0, 0]]],
    [_chrome5, _theme getOrDefault ["chromeTertiary", [0, 0, 0, 0]]]
];
_accent ctrlSetBackgroundColor _accentColour;
_trim ctrlSetBackgroundColor (_theme getOrDefault ["trim", _theme getOrDefault ["accent", [0.10, 0.38, 0.66, 1]]]);
_content ctrlSetBackgroundColor [0, 0, 0, 0];

private _styledSource = (_theme getOrDefault ["sourcePrefix", ""]) + toUpper _source + (_theme getOrDefault ["sourceSuffix", ""]);
private _styledTitle = (_theme getOrDefault ["titlePrefix", ""]) + _title + (_theme getOrDefault ["titleSuffix", ""]);
private _chromeMode = _theme getOrDefault ["chromeMode", "STANDARD"];
private _copyMode = toUpperANSI (_theme getOrDefault ["copyMode", "STANDARD"]);
private _copyProfile = switch (_copyMode) do {
    case "HERALDIC": {["center", 0.64, 1.16, 0.86]};
    case "BROADCAST": {["center", 0.64, 1.16, 0.86]};
    default {["left", 0.64, 1.16, 0.86]};
};
_copyProfile params ["_copyAlign", "_sourceSize", "_titleSize", "_messageSize"];
_content ctrlSetStructuredText parseText format [
    "<t align='%14' font='%6' color='%7' size='%11' shadow='0'>%1 // %10</t><br/>" +
    "<t align='%14' font='%8' color='%2' size='%12' shadow='0'>%3 %4</t><br/>" +
    "<t align='%14' font='%6' color='%9' size='%13' shadow='0'>%5</t>",
    _styledSource,
    _colour,
    _symbol,
    _styledTitle,
    _messageText,
    _theme getOrDefault ["font", "RobotoCondensed"],
    _theme getOrDefault ["sourceHex", _theme getOrDefault ["mutedHex", "#9FB3C8"]],
    _theme getOrDefault ["fontBold", "RobotoCondensedBold"],
    _theme getOrDefault ["textHex", "#FFFFFF"],
    _theme getOrDefault ["motif", "TACTICAL INTERFACE"],
    _sourceSize * _sizeScale,
    _titleSize * _sizeScale,
    _messageSize * _sizeScale,
    _copyAlign
];

private _visibleW = safeZoneW;
private _visibleH = safeZoneH;
// Cap the horizontal layout canvas at a 16:9 safe-zone shape. Cards therefore remain readable on
// ultrawide displays instead of stretching with the whole desktop, while 4:3 and 16:10 layouts can
// still use all of their narrower safe width.
private _layoutW = _visibleW min (_visibleH * 1.333333);
private _maximumPanelW = (switch (_placement) do {
    case "BOTTOM_RIGHT": {_layoutW * 0.20};
    case "TOP_RIGHT": {_layoutW * 0.23};
    case "BOTTOM_LEFT": {_layoutW * 0.28};
    case "BOTTOM_CENTER": {_layoutW * 0.26};
    case "CENTER": {_layoutW * 0.38};
    default {_layoutW * 0.40};
}) * _panelScale * _widthScale;
private _minimumPanelW = (switch (_placement) do {
    case "BOTTOM_RIGHT": {_layoutW * 0.13};
    case "TOP_RIGHT": {_layoutW * 0.15};
    case "BOTTOM_LEFT": {_layoutW * 0.18};
    case "BOTTOM_CENTER": {_layoutW * 0.17};
    case "CENTER": {_layoutW * 0.21};
    default {_layoutW * 0.23};
}) * _panelScale;
private _panelW = _maximumPanelW;
private _padX = _layoutW * 0.008 * _resolutionScale * _personalScale;
private _padY = _visibleH * 0.006 * _resolutionScale * _personalScale;
private _maximumContentH = _visibleH * 0.18 * _sizeScale;
private _contentWidthFactor = if ((toUpperANSI _chromeMode) isEqualTo "STANDARD") then {1} else {0.88};
_content ctrlSetPosition [0, 0, (_panelW * _contentWidthFactor) - (2 * _padX), _maximumContentH];
_content ctrlCommit 0;
private _measuredTextW = ctrlTextWidth _content;
if (_measuredTextW > 0) then {
    private _requiredPanelW = ((_measuredTextW + (2 * _padX) + (_layoutW * 0.012)) / _contentWidthFactor);
    _panelW = (_requiredPanelW max _minimumPanelW) min _maximumPanelW;
    _content ctrlSetPosition [0, 0, (_panelW * _contentWidthFactor) - (2 * _padX), _maximumContentH];
    _content ctrlCommit 0;
};
private _textHeight = ctrlTextHeight _content;
private _textGutter = ((_textHeight * 0.08) max (_visibleH * 0.004 * _sizeScale)) min (_visibleH * 0.012 * _sizeScale);
private _contentH = ((_textHeight + _textGutter) max (_visibleH * 0.050 * _sizeScale)) min _maximumContentH;
private _materialPadY = if ((toUpperANSI _chromeMode) isEqualTo "STANDARD") then {0} else {_visibleH * 0.012 * _sizeScale};
private _panelH = _contentH + (2 * _padY) + _materialPadY + _textGutter;
private _accentH = (_visibleH * 0.003 * _resolutionScale * _personalScale) max 0.0015;
{_x ctrlShow !(uiNamespace getVariable ["Waldo_UI_PanelsSuppressed", false]);} forEach [_frame, _accent, _trim, _content];

private _token = format ["%1_%2", diag_tickTime, random 1e9];
private _controls = [_frame, _accent, _trim, _content, _chrome0, _chrome1, _chrome2, _chrome3, _chrome4, _chrome5];
private _railMode = _theme getOrDefault ["railMode", "TOP"];
private _trimH = (_visibleH * 0.002) max 0.001;
_registry pushBack [_channel, _controls, _token, _placement, _panelW, _panelH, _padX, _padY, _accentH, _contentH, _priority, diag_tickTime, _railMode, _trimH, [_title, _messageText, _state, _source], _chromeMode, _textGutter];
uiNamespace setVariable ["Waldo_UiPanelRegistry", _registry];
[0] call Waldo_fnc_ReflowUiPanels;
[_token, _placement] call Waldo_fnc_AnimateUiNotificationEntryLocal;

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
