/*
 * Author: WaldoTheWarfighter
 * Installs one repeat-safe ACE Talk interaction or vanilla fallback on a registered speaker.
 * Locality/authority: interface-local action; completion sends only object/player references to server.
 * Repeat/JIP behaviour: removes this client's prior IDs before reinstalling from a snapshot.
 * Arguments: descriptor [speaker, kind, reference]. Return Value: BOOL.
 * Current caller: DialogueReceiveStateLocal. Example: server snapshot application.
 */
params [["_speaker", objNull, [objNull]], ["_kind", "SIMPLE", [""]], ["_reference", "", [""]]];
if (!hasInterface || {isNull _speaker}) exitWith {false};
[_speaker] call Waldo_fnc_DialogueRemoveActionLocal;
_speaker setVariable ["Waldo_Dialogue_LocalKind", _kind];
_speaker setVariable ["Waldo_Dialogue_LocalReference", _reference];
private _label = if (_kind == "ADVANCED") then {"Start Conversation"} else {"Talk"};
private _statement = {params ["_target", "_actor"]; [_target, _actor] remoteExecCall ["Waldo_fnc_DialogueRequestStartServer", 2]};
private _condition = {
    params ["_target", "_actor"];
    alive _target && {alive _actor} && {_actor distance _target <= (missionNamespace getVariable ["Waldo_Dialogue_InteractionDistance", 3])}
    && {_target getVariable ["Waldo_Dialogue_Available", false]} && {!(_target getVariable ["Waldo_Dialogue_Occupied", false])}
};
private _aceReady = !(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
if (_aceReady) then {
    private _safeNetId = [netId _speaker, "0123456789"] call BIS_fnc_filterString;
    private _actionId = format ["Waldo_Dialogue_Talk_%1", _safeNetId];
    private _action = [_actionId, _label, "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa", _statement, _condition] call ace_interact_menu_fnc_createAction;
    private _path = [_speaker, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    _speaker setVariable ["Waldo_Dialogue_LocalAcePaths", [_path]];
} else {
    private _id = [
        _speaker,
        format ["<t color='#79C7FF'>%1</t>", _label],
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
        "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
        "alive _target && {alive _this} && {_this distance _target <= (missionNamespace getVariable ['Waldo_Dialogue_InteractionDistance',3])} && {_target getVariable ['Waldo_Dialogue_Available',false]} && {!(_target getVariable ['Waldo_Dialogue_Occupied',false])}",
        "alive _target && {alive _caller} && {_caller distance _target <= (missionNamespace getVariable ['Waldo_Dialogue_InteractionDistance',3])}",
        {}, {},
        {params ["_target", "_actor"]; [_target, _actor] remoteExecCall ["Waldo_fnc_DialogueRequestStartServer", 2]},
        {}, [], 0.6, 1, false, false
    ] call BIS_fnc_holdActionAdd;
    _speaker setVariable ["Waldo_Dialogue_LocalActionIds", [_id]];
};
true
