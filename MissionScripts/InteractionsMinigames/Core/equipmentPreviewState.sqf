/* Applies a non-resolving developer-gallery state to the real equipment display. */
disableSerialization;
params [["_display", displayNull, [displayNull]], ["_state", "ACTIVE", [""]]];
if (isNull _display) exitWith {false};
_state = toUpper _state;
if (_state != "BRIEFING") then {
    private _begin = _display getVariable ["Waldo_IMG_BriefingBegin", controlNull];
    if (!isNull _begin) then {
        [_begin] call (_display getVariable ["Waldo_IMG_BriefingActivate", {}]);
    };
};
if (_state == "ACTIVE" || {_state == "BRIEFING"}) exitWith {true};
private _status = _display getVariable ["Waldo_MG_UI_StatusCtrl", controlNull];
private _interactive = (_display getVariable ["Waldo_MG_UI_EquipmentControls", []]) select {
    !isNull _x && {ctrlType _x in [1, 11, 16, 41]} && {ctrlEnabled _x}
};
if (_state in ["HOVER", "SELECTED", "DISABLED"] && {count _interactive > 0}) then {
    private _control = _interactive select ((count _interactive) - 1);
    if (_state == "DISABLED") then {
        _control ctrlEnable false;
        _control ctrlSetTextColor [0.48, 0.49, 0.46, 1];
        _control ctrlSetTooltip "Disabled in this equipment state";
    } else {
        _control ctrlSetBackgroundColor (if (_state == "HOVER") then {[0.36, 0.31, 0.12, 1]} else {[0.18, 0.42, 0.48, 1]});
        _control ctrlSetTooltip format ["Developer preview: %1 state", _state];
    };
};
if (_state == "WARNING" && {!isNull _status}) then {
    _status ctrlSetText "[!] WARNING // OPERATOR ATTENTION REQUIRED";
    _status ctrlSetTextColor [0.96, 0.78, 0.30, 1];
};
if (_state in ["SUCCESS", "FAILURE", "TIMEOUT"]) then {
    {{if (!isNull _x) then {_x ctrlEnable false;};} forEach _x;} forEach [_interactive];
    private _success = _state == "SUCCESS";
    private _result = [_display, "RscText", [4, 10, 32, 5], format ["developer preview %1 result", _state]] call Waldo_fnc_MiniGameEquipmentCreateControl;
    _result ctrlSetText switch (_state) do {
        case "SUCCESS": {"[OK] PROCEDURE COMPLETE"};
        case "TIMEOUT": {"[!] OPERATING WINDOW EXPIRED"};
        default {"[X] PROCEDURE FAILED"};
    };
    _result ctrlSetTextColor (if (_success) then {[0.68, 1, 0.76, 1]} else {[1, 0.68, 0.78, 1]});
    _result ctrlSetBackgroundColor (if (_success) then {[0.04, 0.19, 0.08, 0.98]} else {[0.22, 0.03, 0.08, 0.98]});
    _result ctrlSetFontHeight 0.035;
    if (!isNull _status) then {
        _status ctrlSetText ctrlText _result;
        _status ctrlSetTextColor (if (_success) then {[0.55, 1, 0.65, 1]} else {[1, 0.48, 0.62, 1]});
    };
};
true
