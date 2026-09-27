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
 * Locality and authority: Repositions only this client's active WMP notification controls.
 * Repeated passes replace layout, not gameplay state; JIP builds its own interface.
 * Result: Current cards occupy their assigned lanes without overlapping reservations.
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
        [_x, _panelX, _panelY, _panelW, _duration] call Waldo_fnc_LayoutUiNotificationCardLocal;
    } forEach _entries;
} forEach ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"];
true
