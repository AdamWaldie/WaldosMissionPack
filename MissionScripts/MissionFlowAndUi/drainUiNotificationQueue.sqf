/* Starts queued cards in FIFO order whenever their channel and screen slot are free. */
if (!hasInterface) exitWith {false};
private _queue = +(uiNamespace getVariable ["Waldo_UiPanelQueue", []]);
private _started = true;
private _guard = 0;
while {_started && {_guard < 12}} do {
    _started = false;
    _guard = _guard + 1;
    private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
    private _index = _queue findIf {
        private _request = _x;
        private _channel = toUpper (_request param [5, "MISSION"]);
        private _placement = [_channel, _request param [4, "TOP"], _request param [9, false]] call Waldo_fnc_ResolveUiPanelPlacement;
        (_registry findIf {(_x param [0, ""]) isEqualTo _channel}) < 0
            && {({(_x param [3, ""]) isEqualTo _placement} count _registry) < 3}
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
