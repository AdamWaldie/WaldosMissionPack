/* Repositions all active generic cards into bounded, non-overlapping stacks. */
if (!hasInterface) exitWith {false};
private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
private _gap = safeZoneH * 0.008;
{
    private _placement = _x;
    private _entries = _registry select {(_x param [3, "TOP"]) isEqualTo _placement};
    private _cursor = switch (_placement) do {
        case "BOTTOM_RIGHT": {safeZoneY + safeZoneH - (safeZoneH * 0.187)};
        case "BOTTOM_LEFT": {safeZoneY + safeZoneH - (safeZoneH * 0.05)};
        default {safeZoneY + (safeZoneH * 0.045)};
    };
    if (_placement isEqualTo "CENTER") then {
        private _total = _gap * (((count _entries) - 1) max 0);
        {_total = _total + (_x param [5, 0]);} forEach _entries;
        _cursor = safeZoneY + ((safeZoneH - _total) / 2);
    };
    {
        _x params ["_channel", "_controls", "_token", "_slot", "_panelW", "_panelH", "_padX", "_padY", "_accentH", "_contentH"];
        private _panelX = switch (_slot) do {
            case "TOP_RIGHT";
            case "BOTTOM_RIGHT": {safeZoneX + safeZoneW - _panelW - (safeZoneW * 0.025)};
            case "BOTTOM_LEFT": {safeZoneX + (safeZoneW * 0.025)};
            default {safeZoneX + ((safeZoneW - _panelW) / 2)};
        };
        private _panelY = _cursor;
        if (_slot in ["BOTTOM_LEFT", "BOTTOM_RIGHT"]) then {
            _panelY = _cursor - _panelH;
            _cursor = _panelY - _gap;
        } else {
            _cursor = _panelY + _panelH + _gap;
        };
        _controls params ["_frame", "_accent", "_content"];
        _frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
        _accent ctrlSetPosition [_panelX, _panelY, _panelW, _accentH];
        _content ctrlSetPosition [_panelX + _padX, _panelY + _padY + _accentH, _panelW - (2 * _padX), _contentH - _accentH];
        {_x ctrlCommit 0;} forEach _controls;
    } forEach _entries;
} forEach ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_RIGHT"];
true
