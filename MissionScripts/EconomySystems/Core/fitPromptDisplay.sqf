/*
 * Author: WaldoTheWarfighter
 * Fits dynamically drawn Economy controls into a protected safe-zone rectangle and applies
 * the shared WMP operations-console treatment. This post-layout pass prevents legacy prompt
 * coordinates from placing controls off-screen at 4:3, ultrawide or large UI scale.
 *
 * Only fits controls with no parent control (ctrlParent isNull) - a control created as the child of
 * an RscControlsGroup (e.g. MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf's
 * per-tab groups) is positioned relative to that group's own local origin, not this display's absolute
 * safe-zone coordinates; allControls _display still returns those nested children alongside every
 * top-level control, and treating a group child's small local coordinates as if they were absolute
 * corrupts the computed bounding box and shifts/clips that content. The group control itself (which has
 * no parent) is still fitted normally, and its children move/scale correctly along with it since their
 * positions are relative. No existing Economy prompt creates any control group, so this exclusion is
 * purely additive for them.
 *
 * Arguments: 0: Economy prompt display <DISPLAY>.
 * Return Value: BOOL - true when fitting was scheduled, false for an invalid display.
 *
 * Example: [_display] call Waldo_fnc_EcoCore_fitPromptDisplay;
 * Current caller: Economy prompt construction after controls have been created;
 * MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf.
 */
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {false};
if (_display getVariable ["WaldoEcoCore_FitScheduled", false]) exitWith {true};
_display setVariable ["WaldoEcoCore_FitScheduled", true];
private _promptToken = _display getVariable ["WaldoEcoCore_PromptToken", ""];
[_display, _promptToken] spawn {
    params ["_display", "_promptToken"];
    private _lastCount = -1;
    private _stableFrames = 0;
    for "_attempt" from 0 to 12 do {
        if (isNull _display || {(_display getVariable ["WaldoEcoCore_PromptToken", ""]) != _promptToken}) exitWith {};
        uiSleep 0.03;
        private _count = count allControls _display;
        if (_count == _lastCount && {_count > 0}) then {_stableFrames = _stableFrames + 1;} else {_stableFrames = 0;};
        _lastCount = _count;
        if (_stableFrames >= 2) exitWith {};
    };
    if (isNull _display || {(_display getVariable ["WaldoEcoCore_PromptToken", ""]) != _promptToken}) exitWith {};
    private _baseline = _display getVariable ["WaldoEcoCore_PromptBaselineControls", []];
    private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
    private _chrome = _display getVariable ["WaldoEcoCore_PromptChromeControls", []];
    private _controls = (allControls _display) select {
        private _p = ctrlPosition _x;
        // allControls _display recurses into every RscControlsGroup's own children too, not just this
        // display's direct top-level controls. A group child's own ctrlPosition is expressed relative
        // to its parent group's local origin (small numbers near [0,0]), not this display's absolute
        // safe-zone coordinates - if one of those slipped into this pass, its tiny local X/Y would
        // corrupt the computed min/max bounding box against every genuinely absolute-positioned
        // control, and it would then be moved to a wrong, shifted absolute position built from that
        // corrupted box (confirmed root cause of the Vehicle Customisation Editor's tab content
        // rendering shifted/clipped after this pass ran). ctrlParent only ever returns a real control
        // for an actual group child (controlNull for every ordinary top-level control), so this is a
        // reliable, purely additive exclusion - no existing Economy prompt creates any control group at
        // all, so this can only ever change behavior for a caller that does.
        !(_x in _baseline) && {!(_x in _chrome)} && {isNull (ctrlParent _x)} && {(count _p) >= 4} && {(_p select 2) > 0} && {(_p select 3) > 0}
    };
    if (_controls isEqualTo []) exitWith {};
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
    } forEach _controls;
    private _sourceW = 0.01 max (_maxX - _minX);
    private _sourceH = 0.01 max (_maxY - _minY);
    // Legacy prompts use a 0..1 canvas. Preserve their proportions: independent
    // X/Y stretching turns compact buttons into full-screen slabs and destroys
    // the visual grouping even when every rectangle remains technically in bounds.
    // Small prompts may grow modestly, while large forms only shrink as required.
    // The chrome follows the fitted form; it must not turn every compact modal
    // into a near-full-screen black panel.
    (_display getVariable ["WaldoEcoCore_PromptMaxCardBounds", [safeZoneX + safeZoneW * 0.055, safeZoneY + safeZoneH * 0.065, safeZoneW * 0.89, safeZoneH * 0.87]]) params ["_maxCardX", "_maxCardY", "_maxCardW", "_maxCardH"];
    private _headerH = (safeZoneH * 0.055) max 0.045;
    private _padX = safeZoneW * 0.022;
    private _padY = safeZoneH * 0.022;
    private _availableW = _maxCardW - (2 * _padX);
    private _availableH = _maxCardH - _headerH - (2 * _padY);
    private _scale = ((_availableW / _sourceW) min (_availableH / _sourceH)) min 1.35;
    private _layoutW = _sourceW * _scale;
    private _layoutH = _sourceH * _scale;
    private _cardW = (_layoutW + (2 * _padX)) max (safeZoneW * 0.30);
    private _cardH = (_headerH + _layoutH + (2 * _padY)) max (safeZoneH * 0.38);
    _cardW = _cardW min _maxCardW;
    _cardH = _cardH min _maxCardH;
    private _cardX = safeZoneX + ((safeZoneW - _cardW) * 0.5);
    private _cardY = safeZoneY + ((safeZoneH - _cardH) * 0.5);
    private _targetX = _cardX + ((_cardW - _layoutW) * 0.5);
    private _targetY = _cardY + _headerH + ((_cardH - _headerH - _layoutH) * 0.5);
    private _targetW = _layoutW;
    private _targetH = _layoutH;
    private _originX = _targetX;
    private _originY = _targetY;
    private _cardControl = _display getVariable ["WaldoEcoCore_PromptCardControl", controlNull];
    private _headerControl = _display getVariable ["WaldoEcoCore_PromptHeaderControl", controlNull];
    if (!isNull _cardControl) then {
        _cardControl ctrlSetPosition [_cardX, _cardY, _cardW, _cardH];
        _cardControl ctrlCommit 0;
    };
    if (!isNull _headerControl) then {
        _headerControl ctrlSetPosition [_cardX, _cardY, _cardW, _headerH];
        _headerControl ctrlCommit 0;
    };
    _display setVariable ["WaldoEcoCore_PromptCardBounds", [_cardX, _cardY, _cardW, _cardH]];
    _display setVariable ["WaldoEcoCore_PromptContentBounds", [_targetX, _targetY, _targetW, _targetH]];
    {
        (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
        private _newWidth = _width * _scale;
        private _newHeight = _height * _scale;
        _x ctrlSetPosition [
            _originX + ((_xPos - _minX) * _scale),
            _originY + ((_yPos - _minY) * _scale),
            _newWidth,
            _newHeight
        ];
        if ((ctrlType _x) in [0, 1, 2, 11, 16, 41] && {ctrlText _x != ""}) then {
            private _fontHeight = ctrlFontHeight _x;
            if (_fontHeight > 0) then {
                _fontHeight = _fontHeight min (_newHeight * 0.72);
                private _minimumFont = (0.012 max (_newHeight * 0.34)) min _fontHeight;
                _x ctrlSetFontHeight _fontHeight;
                _x ctrlCommit 0;
                while {
                    _fontHeight > _minimumFont
                    && {
                        ctrlTextHeight _x > (_newHeight * 0.94)
                        || {ctrlTextWidth _x > (_newWidth * 0.94)}
                    }
                } do {
                    _fontHeight = (_fontHeight - 0.001) max _minimumFont;
                    _x ctrlSetFontHeight _fontHeight;
                    _x ctrlCommit 0;
                };
            };
        };
        if ((ctrlType _x) in [1, 16]) then {
            _x ctrlSetBackgroundColor (_theme getOrDefault ["header", [0.035, 0.16, 0.28, 0.98]]);
            _x ctrlSetActiveColor (_theme getOrDefault ["accentActive", [0.08, 0.48, 0.78, 1]]);
            _x ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
            _x ctrlSetFont (_theme getOrDefault ["font", "RobotoCondensed"]);
        };
        _x ctrlCommit 0;
    } forEach _controls;
    private _findings = [];
    private _right = _targetX + _targetW;
    private _bottom = _targetY + _targetH;
    {
        (ctrlPosition _x) params ["_xPos", "_yPos", "_width", "_height"];
        if (_xPos < (_targetX - 0.001) || {_yPos < (_targetY - 0.001)} || {(_xPos + _width) > (_right + 0.001)} || {(_yPos + _height) > (_bottom + 0.001)}) then {
            _findings pushBack format ["IDC %1 OUTSIDE SAFE CARD", ctrlIDC _x];
        };
        if (_width <= 0 || {_height <= 0}) then {
            _findings pushBack format ["IDC %1 INVALID DIMENSIONS", ctrlIDC _x];
        };
        if ((ctrlType _x) == 13 && {ctrlText _x != ""} && {(ctrlTextHeight _x) > (_height * 1.04)}) then {
            _findings pushBack format ["IDC %1 TEXT HEIGHT CLIPPED text=%2", ctrlIDC _x, ctrlText _x];
        };
        // Editable and list controls intentionally scroll or wrap content; their
        // aggregate text width does not describe visible label clipping.
        if ((ctrlType _x) in [0, 1, 11, 16] && {ctrlText _x != ""} && {(ctrlTextWidth _x) > (_width * 0.96)}) then {
            _findings pushBack format ["IDC %1 TEXT WIDTH CLIPPED text=%2", ctrlIDC _x, ctrlText _x];
        };
        if ((ctrlType _x) in [1, 16] && {_height > (_targetH * 0.18)}) then {
            _findings pushBack format ["IDC %1 BUTTON HEIGHT EXCESSIVE", ctrlIDC _x];
        };
        if (
            (ctrlType _x) in [1, 16]
            && {(ctrlText _x) in ["<", ">"]}
            // Compact forms commonly allocate 13-16% to each previous/next
            // control. Flag only buttons large enough to dominate the row.
            && {_width > (_targetW * 0.18)}
        ) then {
            _findings pushBack format ["IDC %1 NAVIGATION BUTTON WIDTH EXCESSIVE", ctrlIDC _x];
        };
    } forEach _controls;
    private _cardBounds = [_cardX, _cardY, _cardW, _cardH];
    if ((count _cardBounds) == 4) then {
        _cardBounds params ["_cardX", "_cardY", "_cardW", "_cardH"];
        private _outerPadX = safeZoneW * 0.018;
        private _outerPadY = safeZoneH * 0.018;
        if (_targetX < (_cardX + _outerPadX) || {_targetY < (_cardY + _headerH + _outerPadY) || {_targetX + _targetW > (_cardX + _cardW - _outerPadX) || {_targetY + _targetH > (_cardY + _cardH - _outerPadY)}}}) then {
            _findings pushBack "PROMPT CONTENT VIOLATES CARD PADDING";
        };
    };
    _display setVariable ["WaldoEcoCore_PromptOwnedControls", _chrome + _controls];
    _display setVariable ["WaldoEcoCore_FitComplete", true];
    _display setVariable ["WaldoEcoCore_FitBounds", [_targetX, _targetY, _targetW, _targetH]];
    _display setVariable ["WaldoEcoCore_FitFindings", _findings];
    _display setVariable ["WaldoEcoCore_FitScheduled", false];
    diag_log format ["[WMP ECONOMY UI] safe-card validation complete: %1 finding(s) %2", count _findings, _findings];
};
true
