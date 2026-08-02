/*
 * Author: WaldoTheWarfighter
 * Repositions every active notification card into bounded, non-overlapping screen stacks. It
 * preserves the selected placement and applies each era theme's top, bottom, double or side rail
 * without changing channel ownership, queue order or accessibility semantic labels.
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
_duration = (_duration max 0) min 1;
private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _gap = safeZoneH * 0.008;
{
    private _placement = _x;
    private _entries = _registry select {(_x param [3, "TOP"]) isEqualTo _placement};
    private _cursor = switch (_placement) do {
        case "BOTTOM_RIGHT": {safeZoneY + safeZoneH - (safeZoneH * 0.187)};
        case "BOTTOM_LEFT": {safeZoneY + safeZoneH - (safeZoneH * 0.05)};
        case "BOTTOM_CENTER": {safeZoneY + safeZoneH - (safeZoneH * 0.055)};
        default {safeZoneY + (safeZoneH * 0.045)};
    };
    if (_placement isEqualTo "CENTER") then {
        private _total = _gap * (((count _entries) - 1) max 0);
        {_total = _total + (_x param [5, 0]);} forEach _entries;
        _cursor = safeZoneY + ((safeZoneH - _total) / 2);
    };
    {
        _x params ["_channel", "_controls", "_token", "_slot", "_panelW", "_panelH", "_padX", "_padY", "_accentH", "_contentH", "_priority", "_created", ["_railMode", "TOP"], ["_trimH", 0.001]];
        private _panelX = switch (_slot) do {
            case "TOP_RIGHT";
            case "BOTTOM_RIGHT": {safeZoneX + safeZoneW - _panelW - (safeZoneW * 0.025)};
            case "BOTTOM_LEFT": {safeZoneX + (safeZoneW * 0.025)};
            case "BOTTOM_CENTER": {safeZoneX + ((safeZoneW - _panelW) / 2)};
            default {safeZoneX + ((safeZoneW - _panelW) / 2)};
        };
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
        _frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
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
        _content ctrlSetPosition [_contentX, _contentY, _contentW, _contentH - _accentH];
        {_x ctrlCommit _duration;} forEach _controls;
    } forEach _entries;
} forEach ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
true
