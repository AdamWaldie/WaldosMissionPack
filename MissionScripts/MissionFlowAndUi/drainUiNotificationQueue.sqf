/* Starts queued cards in FIFO order whenever their channel and screen slot are free. */
if (!hasInterface) exitWith {false};
private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
_queue = _queue select {(_x param [12, 1e11]) > diag_tickTime};
private _maximumPerPlacement = ((missionNamespace getVariable ["Waldo_UiNotification_MaximumPerPlacement", 3]) max 1) min 6;
private _started = true;
private _guard = 0;
while {_started && {_guard < 12}} do {
    _started = false;
    _guard = _guard + 1;
    private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
    private _index = _queue findIf {
        private _request = _x;
        private _channel = toUpper (_request param [5, "MISSION"]);
        private _placement = _request param [4, "TOP"];
        private _candidates = [_placement];
        if (missionNamespace getVariable ["Waldo_UiNotification_AllowPlacementOverflow", true]) then {
            {
                private _candidate = toUpper _x;
                if (_candidate in ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_RIGHT"]) then {
                    _candidates pushBackUnique _candidate;
                };
            } forEach (missionNamespace getVariable ["Waldo_UiNotification_OverflowPlacements", ["TOP_RIGHT", "BOTTOM_RIGHT", "TOP", "BOTTOM_LEFT"]]);
        };
        private _free = _candidates findIf {
            private _candidate = _x;
            ({(_x param [3, ""]) isEqualTo _candidate} count _registry) < _maximumPerPlacement
        };
        if (_free >= 0) then {_request set [4, _candidates select _free]};
        (_registry findIf {(_x param [0, ""]) isEqualTo _channel}) < 0
            && {_free >= 0}
    };
    if (_index >= 0) then {
        private _request = _queue deleteAt _index;
        _request set [10, true];
        uiNamespace setVariable ["Waldo_UiPanelQueue", _queue];
        _request call Waldo_fnc_ShowUiNotification;
        _started = true;
    };
};
uiNamespace setVariable ["Waldo_UiPanelQueue", _queue];
true
