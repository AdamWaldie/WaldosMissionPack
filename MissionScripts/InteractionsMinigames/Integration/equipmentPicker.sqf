/* Opens the opt-in local Field Equipment procedure picker. */
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
private _w = (0.62 * safezoneW) min (0.92 * safezoneH);
private _h = 0.66 * safezoneH;
private _x = safezoneX + (safezoneW - _w) / 2;
private _y = safezoneY + (safezoneH - _h) / 2;

private _shade = _display ctrlCreate ["RscText", -1];
_shade ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_shade ctrlSetBackgroundColor [0,0,0,0.7];
_shade ctrlCommit 0;
private _case = _display ctrlCreate ["RscText", -1];
_case ctrlSetPosition [_x, _y, _w, _h];
_case ctrlSetBackgroundColor [0.13,0.14,0.12,0.99];
_case ctrlCommit 0;
private _head = _display ctrlCreate ["RscStructuredText", -1];
_head ctrlSetPosition [_x + 0.025 * safezoneW, _y + 0.022 * safezoneH, _w - 0.05 * safezoneW, 0.075 * safezoneH];
_head ctrlSetStructuredText parseText "<t size='1.35' color='#EEE9D8'>FIELD EQUIPMENT</t><br/><t size='0.75' color='#A5A697'>Select a standalone local operating procedure. Party-table state is unaffected.</t>";
_head ctrlCommit 0;
private _accent = _display ctrlCreate ["RscText", -1];
_accent ctrlSetPosition [_x, _y + 0.105 * safezoneH, _w, 0.004 * safezoneH];
_accent ctrlSetBackgroundColor [0.82,0.58,0.18,1];
_accent ctrlCommit 0;
private _list = _display ctrlCreate ["RscListbox", -1];
_list ctrlSetPosition [_x + 0.03 * safezoneW, _y + 0.135 * safezoneH, _w * 0.43, 0.40 * safezoneH];
_list ctrlSetBackgroundColor [0.035,0.04,0.038,1];
_list ctrlCommit 0;
private _details = _display ctrlCreate ["RscStructuredText", -1];
_details ctrlSetPosition [_x + _w * 0.51, _y + 0.135 * safezoneH, _w * 0.43, 0.40 * safezoneH];
_details ctrlSetBackgroundColor [0.055,0.06,0.055,1];
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
_display setVariable ["Waldo_IMG_PickerRefresh", {
    params ["_disp"];
    private _list = _disp getVariable ["Waldo_IMG_PickerList", controlNull];
    private _details = _disp getVariable ["Waldo_IMG_PickerDetails", controlNull];
    if (isNull _list || {isNull _details} || {(lbCurSel _list) < 0}) exitWith {};
    private _entry = (_disp getVariable ["Waldo_IMG_PickerEntries", []]) select (lbCurSel _list);
    private _profile = [_entry select 0, _entry select 2] call Waldo_fnc_MiniGameEquipmentProfile;
    private _difficulty = toUpper (_entry param [3, "custom"]);
    _details ctrlSetStructuredText parseText format [
        "<t size='1.15' color='#F2BE55'>%1</t><br/><t size='0.72' color='#9C9D8F'>%2<br/>%3</t><br/><br/><t color='#EEE9D8'>%4</t><br/><br/><t color='#D9B85C'>DIFFICULTY: %5</t><br/><t color='#C9C6B8'>Local solo procedure<br/>Result does not change party-game votes or readiness.</t>",
        _profile getOrDefault ["title", "EQUIPMENT"], _profile getOrDefault ["manufacturer", ""],
        _profile getOrDefault ["model", ""], _profile getOrDefault ["objective", ""], _difficulty
    ];
    _details ctrlCommit 0;
}];
_list ctrlAddEventHandler ["LBSelChanged", {[(ctrlParent (_this select 0))] call ((ctrlParent (_this select 0)) getVariable ["Waldo_IMG_PickerRefresh", {}]);}];
private _start = _display ctrlCreate ["RscButtonMenu", -1];
_start ctrlSetPosition [_x + _w - 0.25 * safezoneW, _y + _h - 0.075 * safezoneH, 0.22 * safezoneW, 0.05 * safezoneH];
_start ctrlSetText "INSPECT EQUIPMENT";
_start ctrlCommit 0;
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
_close ctrlSetPosition [_x + 0.03 * safezoneW, _y + _h - 0.075 * safezoneH, 0.16 * safezoneW, 0.05 * safezoneH];
_close ctrlSetText "CLOSE CASE";
_close ctrlCommit 0;
_close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 1;}];
_list lbSetCurSel 0;
[_display] call (_display getVariable ["Waldo_IMG_PickerRefresh", {}]);
true
