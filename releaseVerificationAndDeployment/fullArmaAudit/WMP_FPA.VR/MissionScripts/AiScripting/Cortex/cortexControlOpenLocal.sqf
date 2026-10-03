/*
 * Author: WaldoTheWarfighter
 * Opens Cortex Control, the curator's combined feature and tuning workspace.
 * Locality/authority: interface only; Apply uses the existing server-validated curator bridge.
 * Repeat/JIP: one modal per client; reopening reads current settings. No persistent UI or worker.
 * Arguments: 0: section <STRING> (default GENERAL), initial purpose tab.
 * Return: DISPLAY, or displayNull without an interface/assigned curator/game display.
 * Current callers: FeatureRuntimeZen AI and legacy AI_TUNING; audit scripts.
 * Example: ["ARTILLERY"] call Waldo_fnc_CortexControlOpenLocal;
 */
disableSerialization;
params [["_section","GENERAL",[""]]];
if (!hasInterface || {isNull getAssignedCuratorLogic player}) exitWith {displayNull};
private _old = uiNamespace getVariable ["Waldo_Cortex_Display",displayNull];
if (!isNull _old) exitWith {_old};
private _parent = findDisplay 312;
if (isNull _parent) then {_parent = findDisplay 46};
if (isNull _parent) exitWith {displayNull};
private _display = _parent createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith {displayNull};
uiNamespace setVariable ["Waldo_Cortex_Display",_display];
_display setVariable ["Waldo_UI_ThemedDisplay",true];
private _theme = [] call Waldo_fnc_UiTheme;
private _w = (safeZoneW * 0.92) min (safeZoneH * 1.5);
private _h = safeZoneH * 0.88;
private _x = safeZoneX + (safeZoneW - _w)/2;
private _y = safeZoneY + (safeZoneH - _h)/2;
_display setVariable ["Cortex_Bounds",[_x,_y,_w,_h]];
// Keep the settings snapshot canonical for the entire display lifetime. An old compiled
// extension or a mission override can otherwise append a second row for the same variable;
// that used to create duplicate controls and competing values in the Apply payload.
private _spec = [];
private _seenKeys = createHashMap;
{
    private _key = _x param [0,"",[""]];
    if (_key != "" && {!(_seenKeys getOrDefault [_key,false])}) then {
        _seenKeys set [_key,true];
        _spec pushBack _x;
    };
} forEach ([] call Waldo_fnc_CortexTuningSpec);
_display setVariable ["Cortex_Spec",_spec];
private _draft = createHashMap;
{_draft set [_x select 0,missionNamespace getVariable [_x select 0,_x select 5]]} forEach (_display getVariable "Cortex_Spec");
_display setVariable ["Cortex_Draft",_draft];
_display setVariable ["Cortex_Original",createHashMapFromArray ((_display getVariable "Cortex_Spec") apply {[_x select 0,_draft get (_x select 0)]})];
_display setVariable ["Cortex_Revision",missionNamespace getVariable ["Waldo_AIPass_SettingsRevision",0]];
private _back = _display ctrlCreate ["RscText",-1];
_back ctrlSetPosition [_x,_y,_w,_h];
_back ctrlSetBackgroundColor (_theme get "panel"); _back ctrlCommit 0;
private _title = _display ctrlCreate ["RscText",-1];
_title ctrlSetPosition [_x+_w*0.025,_y+_h*0.015,_w*0.95,_h*0.065];
_title ctrlSetText "WMP CORTEX / CONTROL"; _title ctrlSetTextColor (_theme get "text"); _title ctrlCommit 0;
private _status = _display ctrlCreate ["RscText",-1];
_status ctrlSetPosition [_x+_w*0.025,_y+_h*0.08,_w*0.95,_h*0.045];
_status ctrlSetText "Mission-wide settings. Changes stay pending across tabs until Apply."; _status ctrlSetTextColor (_theme get "text"); _status ctrlCommit 0;
_display setVariable ["Cortex_Status",_status];
private _tabs = _display ctrlCreate ["RscListbox",9601];
_tabs ctrlSetPosition [_x+_w*0.025,_y+_h*0.15,_w*0.23,_h*0.68]; _tabs ctrlCommit 0;
private _sections = ["GENERAL","CONTACT","MOVEMENT","SUPPORT","MORALE","VEHICLES","ARTILLERY","AIR"];
{private _i = _tabs lbAdd _x; _tabs lbSetData [_i,_sections select _forEachIndex]} forEach ["Overview & profiles","Contact & awareness","Movement & cover","Reports & support","Morale & survivors","Vehicles & convoys","Artillery","Airborne & aircraft"];
_tabs ctrlAddEventHandler ["LBSelChanged",{params ["_control","_index"]; if (_index >= 0) then {[ctrlParent _control,_control lbData _index] call Waldo_fnc_CortexControlPageLocal}}];
private _cancel = _display ctrlCreate ["RscButton",9602];
_cancel ctrlSetPosition [_x+_w*0.52,_y+_h*0.9,_w*0.20,_h*0.065];
_cancel ctrlSetText "Cancel"; _cancel ctrlCommit 0;
_cancel ctrlAddEventHandler ["ButtonClick",{(ctrlParent (_this select 0)) closeDisplay 2}];
private _apply = _display ctrlCreate ["RscButton",9603];
_apply ctrlSetPosition [_x+_w*0.74,_y+_h*0.9,_w*0.23,_h*0.065];
_apply ctrlSetText "Apply changes"; _apply ctrlCommit 0;
_apply ctrlAddEventHandler ["ButtonClick",{
    private _d = ctrlParent (_this select 0);
    [_d,""] call Waldo_fnc_CortexControlPageLocal;
    if ((_d getVariable "Cortex_Revision") != (missionNamespace getVariable ["Waldo_AIPass_SettingsRevision",0])) exitWith {
        (_d getVariable "Cortex_Status") ctrlSetText "Settings changed elsewhere. Cancel and reopen before applying.";
    };
    private _original = _d getVariable "Cortex_Original";
    private _pairs = [];
    {if !(_y isEqualTo (_original get _x)) then {_pairs pushBack [_x,_y]}} forEach (_d getVariable "Cortex_Draft");
    if (_pairs isNotEqualTo []) then {_pairs pushBack ["__expectedRevision",_d getVariable "Cortex_Revision"]};
    _d closeDisplay 1;
    if (_pairs isNotEqualTo []) then {["AI_TUNING",_pairs] call Waldo_fnc_FeatureRuntimeApply};
}];
_display displayAddEventHandler ["Unload",{
    uiNamespace setVariable ["Waldo_Cortex_Display",displayNull];
    ["CORTEX_CONTROL"] call Waldo_fnc_UnregisterUiReservationLocal;
}];
_tabs lbSetCurSel ((_sections find (toUpperANSI _section)) max 0);
[_display,true] call Waldo_fnc_UiThemeApplyDisplayLocal;
["CORTEX_CONTROL",(allControls _display select {isNull ctrlParentControlsGroup _x}),["CENTER","BOTTOM_CENTER"],true] call Waldo_fnc_RegisterUiReservationLocal;
_display
