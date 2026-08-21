/*
 * Author: WaldoTheWarfighter
 * Performs the Vehicle Customisation Editor's final, deterministic layout pass after the shared
 * prompt fitter has completed. The editor is substantially larger than ordinary Economy prompts and
 * contains nested tab groups. This pass measures the actual top-level panels, tabs, pending controls
 * and buttons, uniformly shrinks them only when required, reserves a separate title row, and sizes
 * the existing shared WMP card around the result. It does not create another background.
 *
 * Locality and repeat/JIP behaviour:
 * Interface-client local; changes only controls on the supplied display. Repeat-safe for one display:
 * the WaldoVehCust_LayoutFinalized guard prevents cumulative scaling. No persistent/JIP state.
 *
 * Arguments:
 * 0: Vehicle Customisation display <DISPLAY> (default displayNull).
 *
 * Return Value: BOOL - true after a valid layout is present, otherwise false.
 *
 * Current caller: vehicleCustomizationPromptEditor.sqf, 0.6 seconds after its shared fit request.
 *
 * Example:
 * [_display] call Waldo_fnc_VehCust_finalizeLayout;
 */

params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {false};
if (_display getVariable ["WaldoVehCust_LayoutFinalized", false]) exitWith {true};

private _baseline = _display getVariable ["WaldoEcoCore_PromptBaselineControls", []];
private _chrome = _display getVariable ["WaldoEcoCore_PromptChromeControls", []];
private _topControls = (allControls _display) select {
    private _position = ctrlPosition _x;
    !(_x in _baseline)
    && {!(_x in _chrome)}
    && {isNull (ctrlParent _x)}
    && {(count _position) >= 4}
    && {(_position select 2) > 0}
    && {(_position select 3) > 0}
};
if (_topControls isEqualTo []) exitWith {false};

private _nestedControls = (allControls _display) select {
    private _position = ctrlPosition _x;
    !(_x in _baseline)
    && {!(_x in _chrome)}
    && {!isNull (ctrlParent _x)}
    && {(count _position) >= 4}
    && {(_position select 2) > 0}
    && {(_position select 3) > 0}
};

private _minX = 1e6;
private _minY = 1e6;
private _maxX = -1e6;
private _maxY = -1e6;
{
    (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
    _minX = _minX min _xPos;
    _minY = _minY min _yPos;
    _maxX = _maxX max (_xPos + _width);
    _maxY = _maxY max (_yPos + _height);
} forEach _topControls;

private _sourceWidth = 0.01 max (_maxX - _minX);
private _sourceHeight = 0.01 max (_maxY - _minY);
private _maxCardX = safeZoneX + (safeZoneW * 0.04);
private _maxCardY = safeZoneY + (safeZoneH * 0.04);
private _maxCardWidth = safeZoneW * 0.92;
private _maxCardHeight = safeZoneH * 0.92;
private _headerHeight = (safeZoneH * 0.052) max 0.045;
private _padX = safeZoneW * 0.016;
private _padY = safeZoneH * 0.014;
private _availableWidth = _maxCardWidth - (2 * _padX);
private _availableHeight = _maxCardHeight - _headerHeight - (2 * _padY);
private _scale = ((_availableWidth / _sourceWidth) min (_availableHeight / _sourceHeight)) min 1;
private _layoutWidth = _sourceWidth * _scale;
private _layoutHeight = _sourceHeight * _scale;
private _cardWidth = _layoutWidth + (2 * _padX);
private _cardHeight = _headerHeight + _layoutHeight + (2 * _padY);
private _cardX = _maxCardX + ((_maxCardWidth - _cardWidth) * 0.5);
private _cardY = _maxCardY + ((_maxCardHeight - _cardHeight) * 0.5);
private _contentX = _cardX + _padX;
private _contentY = _cardY + _headerHeight + _padY;

{
    (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
    _x ctrlSetPosition [
        _contentX + ((_xPos - _minX) * _scale),
        _contentY + ((_yPos - _minY) * _scale),
        _width * _scale,
        _height * _scale
    ];
    private _fontHeight = ctrlFontHeight _x;
    if (_fontHeight > 0) then {_x ctrlSetFontHeight (_fontHeight * _scale);};
    _x ctrlCommit 0;
} forEach _topControls;

{
    (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
    _x ctrlSetPosition [_xPos * _scale, _yPos * _scale, _width * _scale, _height * _scale];
    private _fontHeight = ctrlFontHeight _x;
    if (_fontHeight > 0) then {_x ctrlSetFontHeight (_fontHeight * _scale);};
    _x ctrlCommit 0;
} forEach _nestedControls;

private _card = _display getVariable ["WaldoEcoCore_PromptCardControl", controlNull];
private _header = _display getVariable ["WaldoEcoCore_PromptHeaderControl", controlNull];
if (!isNull _card) then {
    _card ctrlSetPosition [_cardX, _cardY, _cardWidth, _cardHeight];
    _card ctrlCommit 0;
};
if (!isNull _header) then {
    _header ctrlSetPosition [_cardX, _cardY, _cardWidth, _headerHeight];
    _header ctrlSetFontHeight ((_headerHeight * 0.48) min 0.034);
    _header ctrlCommit 0;
};

_display setVariable ["WaldoEcoCore_PromptCardBounds", [_cardX, _cardY, _cardWidth, _cardHeight]];
_display setVariable ["WaldoEcoCore_PromptContentBounds", [_contentX, _contentY, _layoutWidth, _layoutHeight]];
_display setVariable ["WaldoVehCust_LayoutFinalized", true];
diag_log format [
    "[WMP VEHCUST UI] final layout card=%1 content=%2 scale=%3 topControls=%4 nestedControls=%5",
    [_cardX, _cardY, _cardWidth, _cardHeight],
    [_contentX, _contentY, _layoutWidth, _layoutHeight],
    _scale,
    count _topControls,
    count _nestedControls
];
true
