/*
 * Author: WaldoTheWarfighter
 * Repositions every active notification card into bounded, non-overlapping screen stacks. Top and
 * centre stacks retain oldest-to-newest order from top to bottom and close gaps upward. Bottom
 * stacks retain newest-to-oldest order from top to bottom and close gaps downward. It
 * preserves the selected placement and procedurally lays out each theme's rails, material plates,
 * inset screens, stepped edges and frame details without changing channel ownership, queue order
 * or accessibility semantic labels. No theme-specific texture asset or script is required.
 *
 * Arguments:
 * 0: animation duration <NUMBER> (default Waldo_UiNotification_ReflowDuration)
 *
 * Return Value: BOOL - true after every live stack has been positioned.
 *
 * Example: [0.18] call Waldo_fnc_ReflowUiPanels;
 * Current callers: ShowUiNotification, notification expiry and UI-theme live restyling.
 */
if (!hasInterface) exitWith {false};
params [["_duration", missionNamespace getVariable ["Waldo_UiNotification_ReflowDuration", 0.18], [0]]];
_duration = [_duration] call Waldo_fnc_UiNotificationMotionDuration;
private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _reservations = uiNamespace getVariable ["Waldo_UI_ReservationRegistry", []];
private _gap = safeZoneH * 0.008;
private _layoutW = safeZoneW min (safeZoneH * 1.333333);
private _horizontalMargin = (_layoutW * 0.025) max (pixelW * 8);
private _topBoundary = safeZoneY + (safeZoneH * 0.025);
private _bottomBoundary = safeZoneY + safeZoneH - (safeZoneH * 0.025);
{
    private _placement = _x;
    private _entries = _registry select {(_x param [3, "TOP"]) isEqualTo _placement};
    private _cursor = switch (_placement) do {
        case "BOTTOM_RIGHT": {safeZoneY + safeZoneH - (safeZoneH * 0.187)};
        case "BOTTOM_LEFT": {safeZoneY + safeZoneH - (safeZoneH * 0.05)};
        case "BOTTOM_CENTER": {safeZoneY + safeZoneH - (safeZoneH * 0.055)};
        default {safeZoneY + (safeZoneH * 0.045)};
    };
    {
        _x params ["_reservationKey", "_controls", "_placements", ["_active", true]];
        if (_active && {_placement in _placements}) then {
            private _visibleControls = _controls select {!isNull _x && {ctrlShown _x}};
            if !(_visibleControls isEqualTo []) then {
                if (_placement in ["BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]) then {
                    {_cursor = _cursor min (((ctrlPosition _x) select 1) - _gap)} forEach _visibleControls;
                } else {
                    {_cursor = _cursor max (((ctrlPosition _x) select 1) + ((ctrlPosition _x) select 3) + _gap)} forEach _visibleControls;
                };
            };
        };
    } forEach _reservations;
    private _stackHeight = _gap * (((count _entries) - 1) max 0);
    {_stackHeight = _stackHeight + (_x param [5, 0]);} forEach _entries;
    if (_placement isEqualTo "CENTER") then {
        _cursor = safeZoneY + ((safeZoneH - _stackHeight) / 2);
    } else {
        if (_placement in ["BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]) then {
            _cursor = (_cursor min _bottomBoundary) max ((_topBoundary + _stackHeight) min _bottomBoundary);
        } else {
            _cursor = (_cursor max _topBoundary) min ((_bottomBoundary - _stackHeight) max _topBoundary);
        };
    };
    private _stackPanelW = 0;
    {_stackPanelW = _stackPanelW max (_x param [4, 0]);} forEach _entries;
    {
        _x params ["_channel", "_controls", "_token", "_slot", "_panelW", "_panelH", "_padX", "_padY", "_accentH", "_contentH", "_priority", "_created", ["_railMode", "TOP"], ["_trimH", 0.001], ["_metadata", []], ["_chromeMode", "STANDARD"], ["_textGutter", 0]];
        _panelW = _stackPanelW max _panelW;
        private _panelX = switch (_slot) do {
            case "TOP_RIGHT";
            case "BOTTOM_RIGHT": {safeZoneX + safeZoneW - _panelW - _horizontalMargin};
            case "BOTTOM_LEFT": {safeZoneX + _horizontalMargin};
            case "BOTTOM_CENTER": {safeZoneX + ((safeZoneW - _panelW) / 2)};
            default {safeZoneX + ((safeZoneW - _panelW) / 2)};
        };
        _panelX = (_panelX max (safeZoneX + _horizontalMargin)) min (safeZoneX + safeZoneW - _horizontalMargin - _panelW);
        private _panelY = _cursor;
        if (_slot in ["BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]) then {
            _panelY = _cursor - _panelH;
            _cursor = _panelY - _gap;
        } else {
            _cursor = _panelY + _panelH + _gap;
        };
        private _frame = _controls param [0, controlNull];
        private _accent = _controls param [1, controlNull];
        private _trim = if (count _controls >= 4) then {_controls select 2} else {controlNull};
        private _content = _controls param [[2, 3] select (count _controls >= 4), controlNull];
        private _chrome = if (count _controls > 4) then {_controls select [4, 6]} else {[]};
        {_x ctrlShow false;} forEach _chrome;
        private _framePosition = switch (toUpperANSI _chromeMode) do {
            case "GOTHIC": {[_panelX + (_panelW * 0.008), _panelY, _panelW * 0.984, _panelH]};
            case "ATOMIC": {[_panelX + (_panelW * 0.012), _panelY + (_panelH * 0.025), _panelW * 0.976, _panelH * 0.95]};
            case "SCRAP": {[_panelX + (_panelW * 0.010), _panelY + (_panelH * 0.025), _panelW * 0.98, _panelH * 0.95]};
            case "CONTRACT": {[_panelX + (_panelW * 0.012), _panelY + (_panelH * 0.030), _panelW * 0.976, _panelH * 0.97]};
            default {[_panelX, _panelY, _panelW, _panelH]};
        };
        _frame ctrlSetPosition _framePosition;
        private _contentX = _panelX + _padX;
        private _contentY = _panelY + _padY + _accentH;
        private _contentW = _panelW - (2 * _padX);
        switch (_railMode) do {
            case "BOTTOM": {
                _accent ctrlSetPosition [_panelX, _panelY + _panelH - _accentH, _panelW, _accentH];
                if (!isNull _trim) then {_trim ctrlSetPosition [_panelX, _panelY, _panelW, _trimH];};
                _contentY = _panelY + _padY + _trimH;
            };
            case "DOUBLE": {
                _accent ctrlSetPosition [_panelX, _panelY, _panelW, _accentH];
                if (!isNull _trim) then {_trim ctrlSetPosition [_panelX, _panelY + _panelH - _trimH, _panelW, _trimH];};
            };
            case "SIDE": {
                _accent ctrlSetPosition [_panelX, _panelY, _accentH, _panelH];
                if (!isNull _trim) then {_trim ctrlSetPosition [_panelX + _accentH, _panelY, _panelW - _accentH, _trimH];};
                _contentX = _contentX + _accentH;
                _contentW = _contentW - _accentH;
                _contentY = _panelY + _padY + _trimH;
            };
            default {
                _accent ctrlSetPosition [_panelX, _panelY, _panelW, _accentH];
                if (!isNull _trim) then {_trim ctrlSetPosition [_panelX + (_panelW * 0.68), _panelY + _accentH, _panelW * 0.32, _trimH];};
            };
        };
        // Reserve real content margins for each construction. Decorative plates may sit behind
        // those margins, but never cross the live text block.
        switch (toUpperANSI _chromeMode) do {
            case "GRID": {_contentX = _panelX + (_panelW * 0.060); _contentW = _panelW * 0.88; _contentY = _contentY + (safeZoneH * 0.007);};
            default {
                if !((toUpperANSI _chromeMode) isEqualTo "STANDARD") then {
                    _contentX = _panelX + (_panelW * 0.060);
                    _contentW = _panelW * 0.88;
                    _contentY = _contentY + (safeZoneH * 0.004);
                };
            };
        };
        _contentY = _contentY + _textGutter;
        if (count _chrome >= 6) then {
            private _placeChrome = {
                params ["_index", "_position"];
                private _control = _chrome param [_index, controlNull];
                if (!isNull _control) then {
                    _control ctrlSetPosition _position;
                    _control ctrlShow true;
                };
            };
            switch (toUpperANSI _chromeMode) do {
                case "GOTHIC": {
                    [0, [_panelX + (_panelW * 0.20), _panelY + (_panelH * 0.025), _panelW * 0.60, _panelH * 0.065]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.012), _panelY + (_panelH * 0.10), _panelW * 0.022, _panelH * 0.78]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.966), _panelY + (_panelH * 0.10), _panelW * 0.022, _panelH * 0.78]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.12), _panelY + (_panelH * 0.91), _panelW * 0.76, _panelH * 0.035]] call _placeChrome;
                    [4, [_panelX + (_panelW * 0.012), _panelY + (_panelH * 0.025), _panelW * 0.12, _panelH * 0.045]] call _placeChrome;
                    [5, [_panelX + (_panelW * 0.868), _panelY + (_panelH * 0.025), _panelW * 0.12, _panelH * 0.045]] call _placeChrome;
                };
                case "ATOMIC": {
                    [0, [_panelX + (_panelW * 0.025), _panelY + (_panelH * 0.045), _panelW * 0.95, _panelH * 0.14]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.035), _panelY + (_panelH * 0.87), _panelW * 0.93, _panelH * 0.055]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.025), _panelY + (_panelH * 0.24), _panelW * 0.016, _panelH * 0.52]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.030), _panelY + (_panelH * 0.055), _panelW * 0.012, _panelH * 0.055]] call _placeChrome;
                    [4, [_panelX + (_panelW * 0.958), _panelY + (_panelH * 0.055), _panelW * 0.012, _panelH * 0.055]] call _placeChrome;
                    [5, [_panelX + (_panelW * 0.958), _panelY + (_panelH * 0.865), _panelW * 0.012, _panelH * 0.055]] call _placeChrome;
                };
                case "SCRAP": {
                    [0, [_panelX + (_panelW * 0.020), _panelY + (_panelH * 0.055), _panelW * 0.96, _panelH * 0.89]] call _placeChrome;
                    [1, [_panelX, _panelY, _panelW * 0.63, _panelH * 0.075]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.36), _panelY + (_panelH * 0.925), _panelW * 0.64, _panelH * 0.075]] call _placeChrome;
                    [3, [_panelX, _panelY + (_panelH * 0.20), _panelW * 0.012, _panelH * 0.58]] call _placeChrome;
                };
                case "CORPORATE": {
                    [0, [_panelX, _panelY, _panelW, _panelH * 0.16]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.76), _panelY, _panelW * 0.24, _panelH * 0.16]] call _placeChrome;
                    [2, [_panelX, _panelY + (_panelH * 0.92), _panelW, _panelH * 0.08]] call _placeChrome;
                };
                case "CRT": {
                    [0, [_panelX + (_panelW * 0.012), _panelY + (_panelH * 0.04), _panelW * 0.976, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.022), _panelY + (_panelH * 0.06), _panelW * 0.956, _panelH * 0.035]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.022), _panelY + (_panelH * 0.905), _panelW * 0.956, _panelH * 0.025]] call _placeChrome;
                    [5, [_panelX + (_panelW * 0.965), _panelY + (_panelH * 0.12), _panelW * 0.006, _panelH * 0.74]] call _placeChrome;
                };
                case "DIESEL": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.030), _panelY + (_panelH * 0.075), _panelW * 0.94, _panelH * 0.85]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.12), _panelY + (_panelH * 0.02), _panelW * 0.76, _panelH * 0.07]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.12), _panelY + (_panelH * 0.91), _panelW * 0.76, _panelH * 0.05]] call _placeChrome;
                    [4, [_panelX + (_panelW * 0.030), _panelY + (_panelH * 0.16), _panelW * 0.018, _panelH * 0.68]] call _placeChrome;
                    [5, [_panelX + (_panelW * 0.952), _panelY + (_panelH * 0.16), _panelW * 0.018, _panelH * 0.68]] call _placeChrome;
                };
                case "CONTRACT": {
                    [0, [_panelX + (_panelW * 0.045), _panelY, _panelW * 0.32, _panelH * 0.16]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.012), _panelY + (_panelH * 0.16), _panelW * 0.016, _panelH * 0.76]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.028), _panelY + (_panelH * 0.91), _panelW * 0.96, _panelH * 0.06]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.82), _panelY + (_panelH * 0.03), _panelW * 0.168, _panelH * 0.11]] call _placeChrome;
                };
                case "BROADCAST": {
                    [0, [_panelX, _panelY, _panelW, _panelH * 0.16]] call _placeChrome;
                    [1, [_panelX, _panelY, _panelW * 0.018, _panelH]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.018), _panelY + (_panelH * 0.94), _panelW * 0.982, _panelH * 0.06]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.80), _panelY, _panelW * 0.20, _panelH * 0.12]] call _placeChrome;
                };
                case "FIELD": {
                    [0, [_panelX + (_panelW * 0.018), _panelY + (_panelH * 0.045), _panelW * 0.964, _panelH * 0.91]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.030), _panelY + (_panelH * 0.08), _panelW * 0.012, _panelH * 0.74]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.055), _panelY + (_panelH * 0.88), _panelW * 0.45, _panelH * 0.035]] call _placeChrome;
                };
                case "HUD": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.025), _panelY + (_panelH * 0.06), _panelW * 0.30, _panelH * 0.025]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.025), _panelY + (_panelH * 0.90), _panelW * 0.50, _panelH * 0.025]] call _placeChrome;
                    [5, [_panelX + (_panelW * 0.975), _panelY + (_panelH * 0.18), _panelW * 0.006, _panelH * 0.64]] call _placeChrome;
                };
                case "SCROLL": {
                    [0, [_panelX + (_panelW * 0.035), _panelY + (_panelH * 0.05), _panelW * 0.93, _panelH * 0.90]] call _placeChrome;
                    [1, [_panelX, _panelY + (_panelH * 0.08), _panelW * 0.045, _panelH * 0.84]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.955), _panelY + (_panelH * 0.08), _panelW * 0.045, _panelH * 0.84]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.02), _panelY + (_panelH * 0.03), _panelW * 0.16, _panelH * 0.045]] call _placeChrome;
                    [4, [_panelX + (_panelW * 0.82), _panelY + (_panelH * 0.03), _panelW * 0.16, _panelH * 0.045]] call _placeChrome;
                    [5, [_panelX + (_panelW * 0.40), _panelY + (_panelH * 0.91), _panelW * 0.20, _panelH * 0.035]] call _placeChrome;
                };
                case "CIC": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.90), _panelY + (_panelH * 0.04), _panelW * 0.085, _panelH * 0.92]] call _placeChrome;
                };
                case "CLASSIFIED": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.84), _panelY + (_panelH * 0.04), _panelW * 0.145, _panelH * 0.92]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.08), _panelY + (_panelH * 0.03), _panelW * 0.28, _panelH * 0.06]] call _placeChrome;
                };
                case "INCIDENT": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.030, _panelH * 0.92]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.06), _panelY + (_panelH * 0.89), _panelW * 0.90, _panelH * 0.030]] call _placeChrome;
                };
                case "DOCUMENT": {
                    [0, [_panelX + (_panelW * 0.025), _panelY + (_panelH * 0.04), _panelW * 0.95, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.025), _panelY + (_panelH * 0.04), _panelW * 0.035, _panelH * 0.92]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.10), _panelY + (_panelH * 0.05), _panelW * 0.28, _panelH * 0.040]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.10), _panelY + (_panelH * 0.90), _panelW * 0.82, _panelH * 0.025]] call _placeChrome;
                };
                case "SITREP": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.025, _panelH * 0.92]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.06), _panelY + (_panelH * 0.06), _panelW * 0.90, _panelH * 0.055]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.06), _panelY + (_panelH * 0.89), _panelW * 0.90, _panelH * 0.030]] call _placeChrome;
                };
                case "GRID": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.055), _panelW * 0.97, _panelH * 0.89]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.055), _panelW * 0.035, _panelH * 0.89]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.05), _panelY + (_panelH * 0.055), _panelW * 0.93, _panelH * 0.055]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.35), _panelY + (_panelH * 0.91), _panelW * 0.63, _panelH * 0.035]] call _placeChrome;
                    [4, [_panelX + (_panelW * 0.05), _panelY, _panelW * 0.30, _panelH * 0.075]] call _placeChrome;
                };
                case "SECTOR": {
                    [0, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.97, _panelH * 0.92]] call _placeChrome;
                    [1, [_panelX + (_panelW * 0.015), _panelY + (_panelH * 0.04), _panelW * 0.020, _panelH * 0.92]] call _placeChrome;
                    [2, [_panelX + (_panelW * 0.965), _panelY + (_panelH * 0.04), _panelW * 0.020, _panelH * 0.92]] call _placeChrome;
                    [3, [_panelX + (_panelW * 0.035), _panelY + (_panelH * 0.04), _panelW * 0.36, _panelH * 0.045]] call _placeChrome;
                    [4, [_panelX + (_panelW * 0.605), _panelY + (_panelH * 0.04), _panelW * 0.36, _panelH * 0.045]] call _placeChrome;
                };
            };
        };
        _content ctrlSetPosition [_contentX, _contentY, _contentW, _contentH];
        {_x ctrlCommit _duration;} forEach _controls;
    } forEach _entries;
} forEach ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
true
