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
 * 10-12: Internal queue replay flag and timestamps (defaults false, 0, 0).
 * 13: Explicit preview theme <STRING> (default empty = personal notification theme).
 * Return Value: <STRING> token, or empty string if queued while no gameplay display exists.
 *
 * Example:
 * ["SUPPLY DELIVERED", "The forward crate is ready.", "SUCCESS", 8, "TOP", "LOGISTICS"]
 *     call Waldo_fnc_ShowUiNotification;
 * Current callers: all WMP feature notification adapters and direct mission-maker scripts.
 * Locality and authority: Creates or queues cards on the addressed interface client.
 * Repeated channel messages coalesce; visual cards are transient and not JIP replayed.
 * Result: A WMP card appears in a free lane or waits in the bounded local queue.
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
    ["_fromQueue", false, [true]],
    ["_queuedAt", 0, [0]],
    ["_expiresAt", 0, [0]],
    ["_previewThemeId", "", [""]]
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
private _theme = if (_previewThemeId isEqualTo "") then {[] call Waldo_fnc_UiNotificationTheme} else {[_previewThemeId] call Waldo_fnc_UiTheme};
private _notificationScaleId = toUpperANSI (missionNamespace getVariable ["Waldo_UI_NotificationScaleLocal", profileNamespace getVariable ["Waldo_UI_NotificationScale", "MEDIUM"]]);
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
    private _request = [_title, _message, _state, _duration, _placement, _channel, _source, _policy, _queuePriority, _allowLocalOverride, false, diag_tickTime, diag_tickTime + _ttl, _previewThemeId];
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

private _entry = [_display, _theme, [_title, _messageText, _state, _source], _placement, _notificationScaleId] call Waldo_fnc_CreateUiNotificationCardLocal;
private _token = _entry select 2;
_entry set [0, _channel];
_entry set [10, _priority];
_entry set [17, _previewThemeId];
{_x ctrlShow !(uiNamespace getVariable ["Waldo_UI_PanelsSuppressed", false]);} forEach (_entry select 1);
_registry pushBack _entry;
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
