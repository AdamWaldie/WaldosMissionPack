/*
 * Author: WaldoTheWarfighter
 * Captures pending Cortex edits and draws one scrollable purpose page from the shared settings spec.
 * Locality/authority: local display only; never publishes settings or starts AI workers.
 * Repeat/JIP: replaces previous page controls; no PFH, global event handler or JIP side effects.
 * Arguments: 0: display <DISPLAY>; 1: section <STRING> (default empty: capture only).
 * Return: Nothing.
 * Current callers: CortexControlOpenLocal tab and Apply handlers.
 * Example: [_display,"VEHICLES"] call Waldo_fnc_CortexControlPageLocal;
 */
disableSerialization;
params [["_display",displayNull,[displayNull]],["_section","",[""]]];
if (isNull _display) exitWith {};
private _draft = _display getVariable "Cortex_Draft";
{
    _x params ["_control","_row"];
    _row params ["_key","","","_kind","_options"];
    private _value = switch (_kind) do {
        case "CHECKBOX": {lbCurSel _control == 1};
        case "SLIDER": {private _scale = 10 ^ (_options select 2); round (sliderPosition _control * _scale) / _scale};
        default {(_options select 0) select ((lbCurSel _control) max 0)};
    };
    _draft set [_key,_value];
} forEach (_display getVariable ["Cortex_Editors",[]]);
private _original = _display getVariable "Cortex_Original";
private _pending = 0;
{if !(_y isEqualTo (_original get _x)) then {_pending = _pending + 1}} forEach _draft;
(_display getVariable "Cortex_Status") ctrlSetText format ["Mission-wide | Saved Cortex behaviours: %1 | %2 pending changes | Apply to commit",["Disabled","Enabled"] select (missionNamespace getVariable ["Waldo_AIPass_Enable",false]),_pending];
if (_section == "") exitWith {};
{ctrlDelete _x} forEach (_display getVariable ["Cortex_PageControls",[]]);
private _theme = [] call Waldo_fnc_UiTheme;
(_display getVariable "Cortex_Bounds") params ["_x","_y","_w","_h"];
private _group = _display ctrlCreate ["RscControlsGroup",-1];
_group ctrlSetPosition [_x+_w*0.28,_y+_h*0.15,_w*0.69,_h*0.72]; _group ctrlCommit 0;
private _editors = [];
// A compiled mission can contain an older extension which appended the same setting twice.
// Build one editor per authoritative key so repeated flags cannot produce two controls or two
// conflicting values in the Apply payload.
private _pageRows = [];
private _seenKeys = createHashMap;
{
    private _key = _x select 0;
    if !(_seenKeys getOrDefault [_key,false]) then {
        _seenKeys set [_key,true];
        _pageRows pushBack _x;
    };
} forEach ((_display getVariable "Cortex_Spec") select {(_x select 6) == _section});
private _guide = switch (_section) do {
    case "GENERAL": {"MISSION-WIDE CONTROL<br/>Skill profiles change AI ability. Cortex behaviours enable the automatic tactics below. Convoy control is separate. Use purpose modules to command or configure a specific group or asset. Changes take effect only after Apply."};
    case "CONTACT": {"CONTACT &amp; AWARENESS<br/>Controls how eligible squads notice and respond to threats. Cortex behaviours must be enabled. Contact handling is required for contact-driven tactics; enabling a child option alone does not start them."};
    case "MOVEMENT": {"MOVEMENT &amp; COVER<br/>Controls automatic infantry movement during combat. Requires Cortex behaviours and the relevant contact tactics. Zeus orders and excluded groups take priority. Disable overlapping behaviours when another AI mod controls them."};
    case "SUPPORT": {"REPORTS &amp; SUPPORT<br/>Controls sharing sightings and calling nearby squads to help. Requires Cortex behaviours. Reports use configured communication rules; jamming can block radio reports. Reinforcements need eligible friendly squads nearby."};
    case "MORALE": {"MORALE &amp; SURVIVORS<br/>Controls retreat, surrender and regrouping. Requires Cortex behaviours; surrender is optional. Turning these on allows the behaviour when its conditions are met, rather than immediately ordering every squad to perform it."};
    case "VEHICLES": {"VEHICLES &amp; CONVOYS<br/>Vehicle drills belong to Cortex behaviours. Convoy options are independent: first use Create Convoy on a group of AI vehicles with a route. Halt unloads cargo when enabled; operating crew stay aboard. Resume is an explicit convoy command."};
    case "ARTILLERY": {"ARTILLERY<br/>Enable Cortex behaviours and the required fire role. Assign a spotter and configure a friendly battery using the setup modules. Counter-battery can work without radar; radar speeds detection. Fire uses finite bursts with offset opening rounds. Aim safety cannot guarantee every shell impact."};
    case "AIR": {"AIRBORNE &amp; AIRCRAFT<br/>Automatic insertion requires Cortex behaviours, AI passengers and an AI-flown aircraft in suitable conditions. The passenger module gives an explicit order. Flare and break-away options apply to supported WMP aircraft; enabling them does not spawn an aircraft."};
    default {"Mission-wide feature settings. Apply commits your pending changes."};
};
private _intro = _display ctrlCreate ["RscStructuredText",-1,_group];
_intro ctrlSetPosition [0,0,_w*0.64,_h*0.15];
_intro ctrlSetStructuredText parseText format ["<t size='0.85'>%1</t>",_guide];
_intro ctrlSetTextColor (_theme get "text"); _intro ctrlCommit 0;
private _introH = (ctrlTextHeight _intro) max (_h*0.08);
_intro ctrlSetPositionH _introH; _intro ctrlCommit 0;
private _rowY = _introH + _h*0.025;
{
    _x params ["_key","_label","_help","_kind","_options","_default"];
    private _value = _draft getOrDefault [_key,_default];
    private _text = _display ctrlCreate ["RscText",-1,_group];
    _text ctrlSetPosition [0,_rowY,_w*0.64,_h*0.04]; _text ctrlSetText _label; _text ctrlSetTooltip _help; _text ctrlSetTextColor (_theme get "text"); _text ctrlCommit 0;
    private _editor = _display ctrlCreate [["RscCombo","RscXSliderH"] select (_kind == "SLIDER"),-1,_group];
    _editor ctrlSetPosition [0,_rowY+_h*0.045,_w*0.49,_h*0.04]; _editor ctrlSetTooltip _help;
    switch (_kind) do {
        case "CHECKBOX": {{_editor lbAdd _x} forEach ["Disabled","Enabled"]; _editor lbSetCurSel ([0,1] select _value)};
        case "SLIDER": {
            _options params ["_min","_max","_decimals"];
            _editor sliderSetRange [_min,_max]; _editor sliderSetSpeed [1/(10^_decimals),(_max-_min)/10]; _editor sliderSetPosition _value;
            private _number = _display ctrlCreate ["RscText",-1,_group];
            _number ctrlSetPosition [_w*0.51,_rowY+_h*0.045,_w*0.12,_h*0.04]; _number ctrlSetText (_value toFixed _decimals); _number ctrlSetTextColor (_theme get "text"); _number ctrlCommit 0;
            _editor setVariable ["Cortex_Number",_number]; _editor setVariable ["Cortex_Decimals",_decimals];
            _editor ctrlAddEventHandler ["SliderPosChanged",{params ["_c","_v"]; (_c getVariable "Cortex_Number") ctrlSetText (_v toFixed (_c getVariable "Cortex_Decimals"))}];
        };
        default {_options params ["_values","_labels"]; {_editor lbAdd _x} forEach _labels; _editor lbSetCurSel ((_values find _value) max 0)};
    };
    _editor ctrlAddEventHandler [["LBSelChanged","SliderPosChanged"] select (_kind == "SLIDER"),{[ctrlParent (_this select 0),""] call Waldo_fnc_CortexControlPageLocal}];
    _editor ctrlCommit 0;
    private _helpControl = _display ctrlCreate ["RscStructuredText",-1,_group];
    _helpControl ctrlSetPosition [0,_rowY+_h*0.09,_w*0.64,_h*0.08];
    _helpControl ctrlSetStructuredText parseText format ["<t size='0.8'>%1</t>",_help];
    _helpControl ctrlSetTextColor (_theme get "muted"); _helpControl ctrlCommit 0;
    private _helpH = (ctrlTextHeight _helpControl) max (_h*0.04);
    _helpControl ctrlSetPositionH _helpH; _helpControl ctrlCommit 0;
    _editors pushBack [_editor,_x];
    _rowY = _rowY + _h*0.12 + _helpH;
} forEach _pageRows;
_display setVariable ["Cortex_Editors",_editors];
_display setVariable ["Cortex_PageControls",[_group]];
[_display,true] call Waldo_fnc_UiThemeApplyDisplayLocal;
["CORTEX_CONTROL",(allControls _display select {isNull ctrlParentControlsGroup _x}),["CENTER","BOTTOM_CENTER"],true] call Waldo_fnc_RegisterUiReservationLocal;
