/*
 * Author: WaldoTheWarfighter
 * Opens the opt-in local field-equipment procedure picker for a configured table or supplied list.
 *
 * Arguments: 0: table <OBJECT>; 1: optional entry override <ARRAY>.
 * Return Value: BOOL - true when the local picker display opened.
 *
 * Example: [_table] call Waldo_fnc_MiniGameEquipmentPicker;
 * Current caller: the table's Field Equipment interaction action.
 */
disableSerialization;
params [
    ["_table", objNull, [objNull]],
    ["_entriesOverride", [], [[]]]
];
if (!hasInterface || {!isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])}) exitWith {false};
private _entries = if ((count _entriesOverride) > 0) then {_entriesOverride} else {
    if (isNull _table) then {[]} else {_table getVariable ["Waldo_IMG_TableProcedures", []]}
};
if ((count _entries) == 0) exitWith {false};
private _parent = findDisplay 46;
if (isNull _parent) exitWith {false};
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith {false};
_display setVariable ["Waldo_UI_ThemedDisplay", true];
private _visibleX = safezoneX;
private _visibleY = safezoneY;
private _visibleRight = safezoneX + safezoneW;
private _visibleBottom = safezoneY + safezoneH;
private _visibleW = (_visibleRight - _visibleX) max 0.2;
private _visibleH = (_visibleBottom - _visibleY) max 0.2;
private _w = 0.88 * _visibleW;
private _h = 0.84 * _visibleH;
private _x = _visibleX + 0.06 * _visibleW;
private _y = _visibleY + 0.08 * _visibleH;
private _padX = 0.035 * _w;
private _padY = 0.035 * _h;
private _theme = [] call Waldo_fnc_UiTheme;

private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [_visibleX, _visibleY, _visibleW, _visibleH];
_shade ctrlSetBackgroundColor (_theme getOrDefault ["shade", [0,0,0,0.7]]);
_shade ctrlCommit 0;
private _case = _display ctrlCreate ["RscText", -1];
_case ctrlSetPosition [_x, _y, _w, _h];
_case ctrlSetBackgroundColor (_theme getOrDefault ["casing", [0.13,0.14,0.12,0.99]]);
_case ctrlCommit 0;
private _head = _display ctrlCreate ["RscStructuredText", -1];
_head ctrlSetPosition [_x + _padX, _y + _padY, _w - 2 * _padX, 0.12 * _h];
[_head, format ["<t font='%1' size='%%1' color='%2'>FIELD EQUIPMENT</t><br/><t color='%3'>Select a standalone local operating procedure. Party-table state is unaffected.</t>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["textHex", "#EEE9D8"], _theme getOrDefault ["mutedHex", "#A5A697"]], 1.20, 0.62] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
private _accent = _display ctrlCreate ["RscText", -1];
_accent ctrlSetPosition [_x, _y + 0.15 * _h, _w, 0.006 * _h];
_accent ctrlSetBackgroundColor (_theme getOrDefault ["accent", [0.82,0.58,0.18,1]]);
_accent ctrlCommit 0;
private _list = _display ctrlCreate ["RscListbox", -1];
_list ctrlSetPosition [_x + _padX, _y + 0.19 * _h, 0.43 * _w, 0.64 * _h];
_list ctrlSetBackgroundColor (_theme getOrDefault ["panel", [0.035,0.04,0.038,1]]);
_list ctrlCommit 0;
private _details = _display ctrlCreate ["RscStructuredText", -1];
_details ctrlSetPosition [_x + 0.51 * _w, _y + 0.19 * _h, _w - (0.51 * _w) - _padX, 0.64 * _h];
_details ctrlSetBackgroundColor (_theme getOrDefault ["panelAlt", [0.055,0.06,0.055,1]]);
_details ctrlCommit 0;
{
    private _id = _x select 0;
    private _presentation = _x select 2;
    private _profile = [_id, _presentation] call Waldo_fnc_MiniGameEquipmentProfile;
    private _index = _list lbAdd (_profile getOrDefault ["title", toUpper _id]);
    _list lbSetData [_index, str _forEachIndex];
} forEach _entries;
_display setVariable ["Waldo_IMG_PickerEntries", _entries];
_display setVariable ["Waldo_IMG_PickerDetails", _details];
_display setVariable ["Waldo_IMG_PickerList", _list];
_display setVariable ["Waldo_IMG_PickerTheme", _theme];
_display setVariable ["Waldo_IMG_PickerRefresh", {
    params ["_disp"];
    private _list = _disp getVariable ["Waldo_IMG_PickerList", controlNull];
    private _details = _disp getVariable ["Waldo_IMG_PickerDetails", controlNull];
    if (isNull _list || {isNull _details} || {(lbCurSel _list) < 0}) exitWith {};
    private _entry = (_disp getVariable ["Waldo_IMG_PickerEntries", []]) select (lbCurSel _list);
    private _profile = [_entry select 0, _entry select 2] call Waldo_fnc_MiniGameEquipmentProfile;
    private _theme = _disp getVariable ["Waldo_IMG_PickerTheme", [] call Waldo_fnc_UiTheme];
    private _difficulty = toUpper (_entry param [3, "custom"]);
    private _detailsTemplate = format ["<t font='%1' size='%%1' color='%2'>", _theme getOrDefault ["font", "RobotoCondensed"], _theme getOrDefault ["accentHex", "#F2BE55"]]
        + (_profile getOrDefault ["title", "EQUIPMENT"])
        + format ["</t><br/><t color='%1'>", _theme getOrDefault ["mutedHex", "#9C9D8F"]]
        + (_profile getOrDefault ["manufacturer", ""])
        + "<br/>"
        + (_profile getOrDefault ["model", ""])
        + format ["</t><br/><br/><t color='%1'>", _theme getOrDefault ["textHex", "#EEE9D8"]]
        + (_profile getOrDefault ["objective", ""])
        + format ["</t><br/><br/><t color='%1'>DIFFICULTY: ", _theme getOrDefault ["warningHex", "#D9B85C"]]
        + _difficulty
        + format ["</t><br/><t color='%1'>Local solo procedure<br/>Result does not change party-game votes or readiness.</t>", _theme getOrDefault ["mutedHex", "#C9C6B8"]];
    [_details, _detailsTemplate, 1.05, 0.58] call Waldo_fnc_MiniGameEquipmentFitStructuredText;
}];
_list ctrlAddEventHandler ["LBSelChanged", {[(ctrlParent (_this select 0))] call ((ctrlParent (_this select 0)) getVariable ["Waldo_IMG_PickerRefresh", {}]);}];
private _start = _display ctrlCreate ["RscButtonMenu", -1];
_start ctrlSetPosition [_x + 0.68 * _w, _y + 0.87 * _h, 0.285 * _w, 0.075 * _h];
_start ctrlSetText "INSPECT EQUIPMENT";
_start ctrlCommit 0;
[_start, 0.035, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
_start ctrlAddEventHandler ["ButtonClick", {
    private _disp = ctrlParent (_this select 0);
    private _list = _disp getVariable ["Waldo_IMG_PickerList", controlNull];
    if (isNull _list || {(lbCurSel _list) < 0}) exitWith {};
    private _entry = (_disp getVariable ["Waldo_IMG_PickerEntries", []]) select (lbCurSel _list);
    _disp closeDisplay 1;
    [_entry] spawn {
        params ["_entry"];
        uiSleep 0.05;
        [_entry select 0, _entry select 1, {systemChat "Field procedure complete.";}, {systemChat "Field procedure failed.";}, player, [], _entry select 2] call Waldo_fnc_MiniGameChallenge;
    };
}];
private _close = _display ctrlCreate ["RscButtonMenu", -1];
_close ctrlSetPosition [_x + _padX, _y + 0.87 * _h, 0.22 * _w, 0.075 * _h];
_close ctrlSetText "CLOSE CASE";
_close ctrlCommit 0;
[_close, 0.035, 0.016] call Waldo_fnc_MiniGameEquipmentFitText;
_close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 1;}];
_list lbSetCurSel 0;
[_display] call (_display getVariable ["Waldo_IMG_PickerRefresh", {}]);
true
