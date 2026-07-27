/*
 * Author: WaldoTheWarfighter
 * Draws a persistent electronic-warfare HUD element. Arma's radio and UAV systems drop out for all
 * sorts of buggy reasons, so this makes jamming unmistakable: a dedicated control on the main
 * mission display that other scripts' hints cannot overwrite, showing a blinking banner, a strength
 * bar and concise operational guidance while active. Passing a factor of 0
 * hides it. Radio and UAV-link inputs are combined into one Electronic Warfare panel.
 * Called every tick by the watchers in Waldo_fnc_JammingInit.
 *
 * Arguments:
 * 0: Factor <NUMBER> - current effect strength, 0..1 (0 hides the HUD)
 * 1: Label <STRING> - the banner title (optional, default: "RADIO INTERFERENCE")
 * 2: IDC <NUMBER> - unique control id so multiple banners can coexist (optional, default: 5310)
 * 3: Sub <STRING> - the small explanatory line (optional, default: the radio wording)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [0.8] call Waldo_fnc_JammingHud;                                   // radio banner
 * [0.5, "UAV LINK DEGRADED", 5311, "DATALINK QUALITY REDUCED"] call Waldo_fnc_JammingHud;
 */

if !(hasInterface) exitWith {};

params [["_factor", 0], ["_label", "RADIO INTERFERENCE"], ["_idc", 5310], ["_sub", "LINK QUALITY DEGRADED"]];

private _display = findDisplay 46;
if (isNull _display) exitWith {};

private _legacyNotice = _display displayCtrl 5312;
if !(isNull _legacyNotice) then {_legacyNotice ctrlShow false;};
private _legacyUavPanel = _display displayCtrl 5311;
if !(isNull _legacyUavPanel) then {_legacyUavPanel ctrlShow false;};

private _channels = uiNamespace getVariable ["Waldo_JammingHudChannels", []];
private _channelIndex = _channels findIf {(_x param [0, -1]) == _idc};
if (_factor > 0) then {
    private _row = [_idc, _factor, _label, _sub];
    if (_channelIndex < 0) then {_channels pushBack _row;} else {_channels set [_channelIndex, _row];};
} else {
    if (_channelIndex >= 0) then {_channels deleteAt _channelIndex;};
};
uiNamespace setVariable ["Waldo_JammingHudChannels", _channels];

// One visual owner prevents radio and datalink watchers from stacking panels.
private _frame = _display displayCtrl 5309;
private _ctrl = _display displayCtrl 5310;
if (isNull _frame) then {
    _frame = _display ctrlCreate ["RscText", 5309];
    _frame ctrlSetBackgroundColor [0.015, 0.025, 0.035, 0.92];
    _frame ctrlCommit 0;
};
if (isNull _ctrl) then {
    _ctrl = _display ctrlCreate ["RscStructuredText", 5310];
    _ctrl ctrlSetBackgroundColor [0, 0, 0, 0];
    _ctrl ctrlCommit 0;
};

// Entry/restoration messages temporarily own the same EW panel. The watcher keeps sampling the
// signal, but must not replace or hide the current transition before it can be read.
if ((uiNamespace getVariable ["Waldo_JammingNoticeToken", ""]) != "") exitWith {};
if (_channels isEqualTo []) exitWith {_ctrl ctrlShow false; _frame ctrlShow false;};

_ctrl ctrlShow true;
_frame ctrlShow true;

private _combinedFactor = 0;
{_combinedFactor = _combinedFactor max (_x param [1, 0]);} forEach _channels;
private _radioActive = _channels findIf {(_x param [0, -1]) == 5310} >= 0;
private _uavActive = _channels findIf {(_x param [0, -1]) == 5311} >= 0;
private _combinedLabel = if (_radioActive && {_uavActive}) then {"RADIO + UAV INTERFERENCE"} else {(_channels select 0) param [2, "SIGNAL INTERFERENCE"]};
private _combinedSub = if (_radioActive && {_uavActive}) then {"RADIO LINK AND DATALINK DEGRADED"} else {(_channels select 0) param [3, "LINK QUALITY DEGRADED"]};
private _pct = round (_combinedFactor * 100);
private _filled = round (_combinedFactor * 10);
private _bar = "";
for "_i" from 1 to 10 do {
    _bar = _bar + (["-", "|"] select (_i <= _filled));
};

// A restrained pulse communicates changing signal state without flashing the whole panel.
private _blink = (floor (diag_tickTime * 2)) % 2 == 0;
private _col = ["#c8102e", "#ff6161"] select _blink;

_ctrl ctrlSetStructuredText parseText format [
    "<t align='left' color='#9FB3C8' size='0.72'>  ELECTRONIC WARFARE</t><br/>" +
    "<t align='left' color='%1' size='1.12' shadow='1'>  %2</t><br/>" +
    "<t align='left' color='#FFFFFF' size='0.88'>  LOSS %3%4   %5</t><br/>" +
    "<t align='left' color='#D9E2EC' size='0.72'>  %6</t>",
    _col, _combinedLabel, _pct, "%", _bar, _combinedSub
];
private _visibleX = safeZoneX;
private _visibleY = safeZoneY;
private _visibleRight = safeZoneX + safeZoneW;
private _visibleBottom = safeZoneY + safeZoneH;
private _visibleW = (_visibleRight - _visibleX) max 0.2;
private _visibleH = (_visibleBottom - _visibleY) max 0.2;
// Compact bottom-right card, immediately above the ACRE2/TFAR radio overlay.
// Width is deliberately restrained so it does not eat into the sight picture.
private _panelW = _visibleW * 0.235;
private _padX = _visibleW * 0.008;
private _padY = _visibleH * 0.007;
private _panelX = _visibleRight - _panelW - (_visibleW * 0.012);
private _reservedRadioH = _visibleH * 0.175;
_ctrl ctrlSetPosition [_panelX + _padX, _visibleBottom - _reservedRadioH - (_visibleH * 0.105), _panelW - (2 * _padX), _visibleH * 0.10];
_ctrl ctrlCommit 0;
private _contentH = ((ctrlTextHeight _ctrl) max (_visibleH * 0.078)) min (_visibleH * 0.10);
private _panelH = _contentH + (2 * _padY);
private _panelY = _visibleBottom - _reservedRadioH - _panelH - (_visibleH * 0.012);
_frame ctrlSetPosition [_panelX, _panelY, _panelW, _panelH];
_ctrl ctrlSetPosition [_panelX + _padX, _panelY + _padY, _panelW - (2 * _padX), _contentH];
_frame ctrlCommit 0;
_ctrl ctrlCommit 0;
