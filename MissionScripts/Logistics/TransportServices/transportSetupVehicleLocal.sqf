/*
 * Author: WaldoTheWarfighter, Val
 * Adds repeat-safe controls directly to one registered transport. Its mission-maker name and live state
 * make clear which exact vehicle will move. ACE users receive a Transport Service category; vanilla
 * users receive equivalent WMP-blue actions. Controls only submit requests to server authority.
 * Locality and authority: runs locally on every interface client, including JIP. Public vehicle
 * state is read here, while Waldo_fnc_TransportRequestServer validates every requested change.
 *
 * Arguments:
 * 0: transport vehicle <OBJECT> - a vehicle registered by Waldo_fnc_TransportRegister.
 * 1: allow vanilla fallback after the ACE wait deadline <BOOL> - internal, default false.
 *
 * Return Value: <BOOL> - true when the local identification and control actions exist.
 *
 * Example:
 * [this] call Waldo_fnc_TransportSetupVehicleLocal;
 * Result: the transport gains named status, move-pickup, destination and RTB controls where valid.
 * Current caller: Waldo_fnc_TransportRegister through object-keyed JIP remote execution.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_vehicle", objNull, [objNull]], ["_allowVanillaFallback", false, [false]]];
if (!hasInterface || {isNull _vehicle}) exitWith {false};

private _aceReady = !(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")};
private _aceExpected = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
// Registration can arrive before ACE's functions finish initialising. Do not briefly install five
// vanilla actions and leave them beside the later ACE category. Wait once, then use vanilla only if
// ACE genuinely failed to become available on this client.
if (!_aceReady && {_aceExpected} && {!_allowVanillaFallback}) exitWith {
    if !(_vehicle getVariable ["Waldo_TransportService_AceWaitPending", false]) then {
        _vehicle setVariable ["Waldo_TransportService_AceWaitPending", true];
        [_vehicle] spawn {
            params ["_vehicle"];
            private _deadline = diag_tickTime + 60;
            waitUntil {
                sleep 0.25;
                isNull _vehicle
                || {!(isNil "ace_interact_menu_fnc_createAction") && {!(isNil "ace_interact_menu_fnc_addActionToObject")}}
                || {diag_tickTime >= _deadline}
            };
            if (!isNull _vehicle) then {
                _vehicle setVariable ["Waldo_TransportService_AceWaitPending", false];
                [_vehicle, true] call Waldo_fnc_TransportSetupVehicleLocal;
            };
        };
    };
    true
};

{
    if (_x >= 0) then {_vehicle removeAction _x};
} forEach (_vehicle getVariable ["Waldo_TransportService_ActionIds", []]);

private _type = _vehicle getVariable ["Waldo_TransportService_Type", "GROUND"];
private _name = _vehicle getVariable ["Waldo_TransportService_Name", "Transport"];
private _heli = _type == "HELICOPTER";
private _role = ["Ground Transport", "Helicopter Transport"] select _heli;
// The informational action is a discoverability cue, not a control ACE should take priority over -
// installed alongside ACE (not only as a vanilla fallback), the same dual-surface policy used
// elsewhere in the pack (loadout-save points, party tables, Field Hospital crates): a player who
// hasn't opened ACE Self Interact on this exact vehicle should still be able to scroll-wheel it and
// immediately see what it is and its current state. The four operational controls below remain
// ACE-priority/vanilla-fallback only, since ACE's own equivalents already cover them when available.
private _infoId = _vehicle addAction [
    format ["<t color='#79C7FF'>%1: %2</t>", _role, _name],
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        _arguments params ["_type", "_name", "_role"];
        [_type, format ["%1 is a %2 and is currently %3. Request and manage named transports through ACE Self Interact > WMP Transport, or use this transport's own controls.", _name, toLowerANSI _role, _target getVariable ["Waldo_TransportService_State", "UNKNOWN"]], "INFO", _target getVariable ["Waldo_TransportService_Id", netId _target]] call Waldo_fnc_TransportNotifyLocal;
    },
    [_type, _name, _role], -90, false, true, "",
    "_target getVariable ['Waldo_TransportService_Registered', false]", 8
];
private _moveId = -1;
private _destinationId = -1;
private _rtbId = -1;
private _retryId = -1;
private _takeManualId = -1;
private _releaseManualId = -1;
if (!_aceReady) then {
_moveId = _vehicle addAction [
    "<t color='#79C7FF'>Move This Transport's Pickup Point</t>",
    {params ["_target"]; ["MOVE_PICKUP", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal},
    [], -91, false, true, "",
    "private _uid = getPlayerUID _this; (_target getVariable ['Waldo_TransportService_State','']) in ['TO_PICKUP','BOARDING'] && {_uid != '' && {_target getVariable ['Waldo_TransportService_RequesterUID',''] == _uid} || {!isNull getAssignedCuratorLogic _this}}",
    8
];
_destinationId = _vehicle addAction [
    "<t color='#79C7FF'>Select This Transport's Destination</t>",
    {params ["_target"]; ["SET_DESTINATION", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal},
    [], -92, false, true, "",
    "(_target getVariable ['Waldo_TransportService_State',''] in ['BOARDING','TO_DESTINATION']) && {_this in crew _target || {!isNull getAssignedCuratorLogic _this}}",
    8
];
_rtbId = _vehicle addAction [
    "<t color='#79C7FF'>Return This Transport to Base</t>",
    {params ["_target", "_caller"]; ["RTB", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _caller] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
    [], -93, false, true, "",
    "private _uid = getPlayerUID _this; !((_target getVariable ['Waldo_TransportService_State','']) in ['AVAILABLE','RTB']) && {_this in crew _target || {_uid != '' && {_target getVariable ['Waldo_TransportService_RequesterUID',''] == _uid}} || {!isNull getAssignedCuratorLogic _this}}",
    8
];
_retryId = _vehicle addAction [
    "<t color='#79C7FF'>Retry This Transport's Route</t>",
    {params ["_target", "_caller"]; ["RETRY", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _caller] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
    [], -94, false, true, "",
    "private _uid = getPlayerUID _this; _target getVariable ['Waldo_TransportService_State',''] == 'STUCK' && {_this in crew _target || {_uid != '' && {_target getVariable ['Waldo_TransportService_RequesterUID',''] == _uid}} || {!isNull getAssignedCuratorLogic _this}}",
    8
];
// Manual control: any crew member already aboard (not only the requester/leader) can take direct
// control themselves instead of waiting on a remote dispatch; the current pilot or Zeus hands it back.
_takeManualId = _vehicle addAction [
    "<t color='#79C7FF'>Take Manual Control</t>",
    {params ["_target", "_caller"]; [_target, _caller] remoteExecCall ["Waldo_fnc_TransportTakeManualServer", 2]},
    [], -95, false, true, "",
    "_target getVariable ['Waldo_TransportService_State',''] != 'MANUAL' && {_this in crew _target || {!isNull getAssignedCuratorLogic _this}}",
    8
];
_releaseManualId = _vehicle addAction [
    "<t color='#79C7FF'>Release Manual Control</t>",
    {params ["_target", "_caller"]; [_target, _caller] remoteExecCall ["Waldo_fnc_TransportReleaseManualServer", 2]},
    [], -96, false, true, "",
    "_target getVariable ['Waldo_TransportService_State',''] == 'MANUAL' && {driver _target == _this || {!isNull getAssignedCuratorLogic _this}}",
    8
];
};
_vehicle setVariable ["Waldo_TransportService_ActionIds", [_infoId, _moveId, _destinationId, _rtbId, _retryId, _takeManualId, _releaseManualId]];
_vehicle setVariable ["Waldo_TransportService_InfoActionId", _infoId];

if (_aceReady && {!(_vehicle getVariable ["Waldo_TransportService_AceInstalled", false])}) then {
    private _rootId = format ["Waldo_Transport_Object_%1", _vehicle getVariable ["Waldo_TransportService_Id", netId _vehicle]];
    private _root = [_rootId, format ["Transport: %1", _name], if (_heli) then {"\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa"} else {"\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa"}, {}, {true}] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions"], _root] call ace_interact_menu_fnc_addActionToObject;
    private _status = [format ["%1_Status", _rootId], "Transport Status", "\a3\ui_f\data\igui\cfg\simpletasks\types\documents_ca.paa", {
        params ["_target"];
        [_target getVariable ["Waldo_TransportService_Type", "GROUND"], format ["%1 is %2.", _target getVariable ["Waldo_TransportService_Name", "Transport"], _target getVariable ["Waldo_TransportService_State", "UNKNOWN"]], "INFO", _target getVariable ["Waldo_TransportService_Id", netId _target]] call Waldo_fnc_TransportNotifyLocal;
    }, {true}] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _status] call ace_interact_menu_fnc_addActionToObject;
    private _move = [format ["%1_Move", _rootId], "Move Pickup Point", "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa", {
        params ["_target"]; ["MOVE_PICKUP", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal;
    }, {
        params ["_target", "_player"];
        private _uid = getPlayerUID _player;
        (_target getVariable ["Waldo_TransportService_State", ""]) in ["TO_PICKUP", "BOARDING"] && {_uid != "" && {_target getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid} || {!isNull getAssignedCuratorLogic _player}}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _move] call ace_interact_menu_fnc_addActionToObject;
    private _destination = [format ["%1_Destination", _rootId], "Select Destination", "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa", {
        params ["_target"]; ["SET_DESTINATION", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal;
    }, {params ["_target", "_player"]; (_target getVariable ["Waldo_TransportService_State", ""] in ["BOARDING", "TO_DESTINATION"]) && {_player in crew _target || {!isNull getAssignedCuratorLogic _player}}}] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _destination] call ace_interact_menu_fnc_addActionToObject;
    private _retry = [format ["%1_Retry", _rootId], "Retry Current Route", "\a3\ui_f\data\igui\cfg\actions\reload_ca.paa", {
        params ["_target", "_player"]; ["RETRY", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
    }, {
        params ["_target", "_player"];
        private _uid = getPlayerUID _player;
        _target getVariable ["Waldo_TransportService_State", ""] == "STUCK" && {_player in crew _target || {_uid != "" && {_target getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} || {!isNull getAssignedCuratorLogic _player}}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _retry] call ace_interact_menu_fnc_addActionToObject;
    private _rtb = [format ["%1_RTB", _rootId], "Return This Transport to Base", "\a3\ui_f_oldman\data\igui\cfg\holdactions\meet_ca.paa", {
        params ["_target", "_player"]; ["RTB", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
    }, {
        params ["_target", "_player"];
        private _uid = getPlayerUID _player;
        !((_target getVariable ["Waldo_TransportService_State", ""]) in ["AVAILABLE", "RTB"]) && {_player in crew _target || {_uid != "" && {_target getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} || {!isNull getAssignedCuratorLogic _player}}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _rtb] call ace_interact_menu_fnc_addActionToObject;
    // Manual control: any crew member already aboard (not only the requester/leader) can take direct
    // control themselves instead of waiting on a remote dispatch; the current pilot or Zeus hands it
    // back. Squad leaders retain remote command through the actions above whenever the transport is
    // AI-driven - both instruction sets are always available, whichever one currently applies is just
    // whichever machine is in the driver's seat.
    private _takeManual = [format ["%1_TakeManual", _rootId], "Take Manual Control", "\a3\ui_f\data\igui\cfg\actions\enter_ca.paa", {
        params ["_target", "_player"]; [_target, _player] remoteExecCall ["Waldo_fnc_TransportTakeManualServer", 2];
    }, {
        params ["_target", "_player"];
        _target getVariable ["Waldo_TransportService_State", ""] != "MANUAL" && {_player in crew _target || {!isNull getAssignedCuratorLogic _player}}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _takeManual] call ace_interact_menu_fnc_addActionToObject;
    private _releaseManual = [format ["%1_ReleaseManual", _rootId], "Release Manual Control", "\a3\ui_f\data\igui\cfg\actions\eject_ca.paa", {
        params ["_target", "_player"]; [_target, _player] remoteExecCall ["Waldo_fnc_TransportReleaseManualServer", 2];
    }, {
        params ["_target", "_player"];
        _target getVariable ["Waldo_TransportService_State", ""] == "MANUAL" && {driver _target == _player || {!isNull getAssignedCuratorLogic _player}}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 0, ["ACE_MainActions", _rootId], _releaseManual] call ace_interact_menu_fnc_addActionToObject;
    _vehicle setVariable ["Waldo_TransportService_AceInstalled", true];
};
true
