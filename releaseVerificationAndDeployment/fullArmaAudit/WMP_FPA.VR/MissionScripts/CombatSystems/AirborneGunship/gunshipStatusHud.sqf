/*
 * Author: WaldoTheWarfighter
 * Draws a persistent off-station status panel for a gunship's assigned controller. The map
 * marker's status text updates silently once a second and easily scrolls off attention; this keeps
 * "why is my gunship not available right now" visible without spamming toast notifications.
 * Visible only while the aircraft is not ON_STATION/CONTROLLED; hidden otherwise. Passing
 * enabled=false hides it.
 *
 * Locality and authority: runs only on the receiving interface client and mutates only local main
 * display controls. It never mutates gunship or any other server state.
 *
 * Arguments:
 * 0: Enabled <BOOL> - false hides the panel (optional, default: true)
 * 1: Callsign <STRING> - the gunship's display callsign (optional, default: "")
 * 2: Status <STRING> - current gunship status (optional, default: "")
 * 3: Off-station reason <STRING> - "REQUEST", "AUTO", "RETASK" or "" (optional, default: "")
 * 4: Service complete at <NUMBER> - serverTime the current SERVICING cycle finishes, -1 if none
 *    (optional, default: -1)
 *
 * Return Value:
 * Boolean - true when the panel was updated or hidden; false without a player interface.
 *
 * Current callers: Waldo_fnc_GunshipUpdateMarkersLocal.
 *
 * Example:
 * [true, "SPECTRE 1", "SERVICING", "REQUEST", serverTime + 120] call Waldo_fnc_GunshipStatusHud;
 * [false] call Waldo_fnc_GunshipStatusHud;
 */

if !(hasInterface) exitWith {false};
params [
    ["_enabled", true, [true]],
    ["_callsign", "", [""]],
    ["_status", "", [""]],
    ["_offStationReason", "", [""]],
    ["_serviceCompleteAt", -1, [0]]
];

private _display = findDisplay 46;
if (isNull _display) exitWith {false};
private _theme = [] call Waldo_fnc_UiTheme;
private _frame = _display displayCtrl 5360;
private _content = _display displayCtrl 5361;
if (isNull _frame) then {
    _frame = _display ctrlCreate ["RscText", 5360];
    _frame ctrlCommit 0;
};
_frame ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.015, 0.02, 0.025, 0.92]]);
if (isNull _content) then {
    _content = _display ctrlCreate ["RscStructuredText", 5361];
    _content ctrlSetBackgroundColor [0, 0, 0, 0];
    _content ctrlCommit 0;
};

if !(_enabled) exitWith {
    _content ctrlShow false;
    _frame ctrlShow false;
    ["GUNSHIP_STATUS", [_frame, _content], ["BOTTOM_CENTER"], false] call Waldo_fnc_RegisterUiReservationLocal;
    true
};

private _isRetask = _offStationReason == "RETASK";
private _isServiceRun = _offStationReason in ["REQUEST", "AUTO"];
private _detail = switch (_status) do {
    case "SERVICING": {format ["Resupplying - back on station in ~%1s.", ceil ((_serviceCompleteAt - serverTime) max 0)]};
    case "RTB": {if (_isRetask) then {"Off station - retasked to a new orbit."} else {"Returning for resupply - not yet on station."}};
    case "TRANSIT": {
        if (_isRetask) then {
            "Off station - retasked to a new orbit."
        } else {
            if (_isServiceRun) then {"Returning for resupply - not yet on station."} else {"En route to its assigned orbit."}
        }
    };
    default {"Currently unavailable for tasking."};
};

private _fontMuted = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];
private _mutedHex = _theme getOrDefault ["mutedHex", "#9FB3C8"];
private _textHex = _theme getOrDefault ["textHex", "#FFFFFF"];
_content ctrlSetStructuredText parseText format [
    "<t align='center' font='%1' color='%2' size='0.72'>GUNSHIP OFF STATION</t><br/>" +
    "<t align='center' font='%3' color='%4' size='1.0' shadow='1'>%5</t><br/>" +
    "<t align='center' font='%1' color='%2' size='0.82'>%6</t>",
    _fontMuted, _mutedHex, _fontBold, _textHex, _callsign, _detail
];

private _panelW = safeZoneW * 0.30;
private _padX = _panelW * 0.03;
private _padY = safeZoneH * 0.008;
private _panelX = safeZoneX + ((safeZoneW - _panelW) / 2);
private _panelBottomMargin = safeZoneH * 0.16;
private _maximumContentH = safeZoneH * 0.10;
_content ctrlSetPosition [_panelX + _padX, (safeZoneY + safeZoneH) - _panelBottomMargin - _maximumContentH, _panelW - (2 * _padX), _maximumContentH];
_content ctrlCommit 0;
private _contentH = ((ctrlTextHeight _content) max (safeZoneH * 0.065)) min _maximumContentH;
private _panelH = _contentH + (2 * _padY);
private _panelY = (safeZoneY + safeZoneH) - _panelBottomMargin - _panelH;
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_content ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_content ctrlCommit 0;
["GUNSHIP_STATUS", [_frame, _content], ["BOTTOM_CENTER"], true] call Waldo_fnc_RegisterUiReservationLocal;
true
