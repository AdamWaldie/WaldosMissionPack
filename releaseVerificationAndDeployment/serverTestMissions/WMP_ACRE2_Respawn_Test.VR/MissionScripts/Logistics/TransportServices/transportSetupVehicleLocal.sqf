/*
 * Author: WaldoTheWarfighter, Val
 * Adds repeat-safe controls directly to one registered transport. Its mission-maker name and live state
 * make clear which exact vehicle will move. ACE users receive a Transport Service category; vanilla
 * users receive equivalent WMP-blue actions. Every player currently inside the vehicle may send a
 * valid-state transport to a destination or order it to RTB, regardless of requester or seat. The
 * server rechecks crew membership, registration and state before accepting either request.
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
private _role = switch (_type) do {case "HELICOPTER": {"Helicopter Transport"}; case "BOAT": {"Boat Transport"}; default {"Ground Transport"}};
private _typeIcon = switch (_type) do {
    case "HELICOPTER": {"\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa"};
    case "BOAT": {"\a3\ui_f\data\map\vehicleicons\iconShip_ca.paa"};
    default {"\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa"};
};
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
if (!_aceReady) then {
_moveId = _vehicle addAction [
    "<t color='#79C7FF'>Move This Transport's Pickup Point</t>",
    {params ["_target"]; ["MOVE_PICKUP", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal},
    [], -91, false, true, "",
    "private _uid = getPlayerUID _this; (_target getVariable ['Waldo_TransportService_State','']) in ['TO_PICKUP','BOARDING'] && {_uid != '' && {_target getVariable ['Waldo_TransportService_RequesterUID',''] == _uid} || {!isNull getAssignedCuratorLogic _this}}",
    8
];
_destinationId = _vehicle addAction [
    "<t color='#79C7FF'>Send This Transport to Destination</t>",
    {params ["_target"]; ["SET_DESTINATION", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal},
    [], -92, false, true, "",
    "_this in crew _target && {(_target getVariable ['Waldo_TransportService_State',''] in ['AVAILABLE','TO_PICKUP','BOARDING','TO_DESTINATION','DISEMBARKING','STUCK'])}",
    8
];
_rtbId = _vehicle addAction [
    "<t color='#79C7FF'>Return This Transport to Base</t>",
    {params ["_target", "_caller"]; ["RTB", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _caller] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
    [], -93, false, true, "",
    "_this in crew _target && {(_target getVariable ['Waldo_TransportService_State','']) != 'RTB'}",
    8
];
_retryId = _vehicle addAction [
    "<t color='#79C7FF'>Retry This Transport's Route</t>",
    {params ["_target", "_caller"]; ["RETRY", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _caller] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
    [], -94, false, true, "",
    "private _uid = getPlayerUID _this; _target getVariable ['Waldo_TransportService_State',''] == 'STUCK' && {_this in crew _target || {_uid != '' && {_target getVariable ['Waldo_TransportService_RequesterUID',''] == _uid}} || {!isNull getAssignedCuratorLogic _this}}",
    8
];
};
_vehicle setVariable ["Waldo_TransportService_ActionIds", [_infoId, _moveId, _destinationId, _rtbId, _retryId]];
_vehicle setVariable ["Waldo_TransportService_InfoActionId", _infoId];

private _aceActionVersion = 2;
if (_aceReady && {_vehicle getVariable ["Waldo_TransportService_AceActionVersion", 0] != _aceActionVersion}) then {
    private _rootId = format ["Waldo_Transport_Object_%1", _vehicle getVariable ["Waldo_TransportService_Id", netId _vehicle]];
    private _crewRootId = format ["%1_Crew", _rootId];
    // Versioned removal upgrades transports already present on a client without leaving the old
    // external-only action tree behind. Removing the root also removes its child actions.
    if !(isNil "ace_interact_menu_fnc_removeActionFromObject") then {
        [_vehicle, 0, ["ACE_MainActions", _rootId]] call ace_interact_menu_fnc_removeActionFromObject;
        [_vehicle, 1, ["ACE_SelfActions", _crewRootId]] call ace_interact_menu_fnc_removeActionFromObject;
    };
    private _root = [_rootId, format ["Transport: %1", _name], _typeIcon, {}, {true}] call ace_interact_menu_fnc_createAction;
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

    // ACE exposes type-1 object actions through the vehicle self-interaction menu while the player
    // occupies that exact vehicle. Operational crew controls belong here, not in the external
    // ACE_MainActions tree where the crew condition made them effectively unreachable.
    private _crewRoot = [_crewRootId, format ["Control %1", _name], _typeIcon, {}, {
        params ["_target", "_player"];
        vehicle _player isEqualTo _target
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 1, ["ACE_SelfActions"], _crewRoot] call ace_interact_menu_fnc_addActionToObject;
    private _destination = [format ["%1_Destination", _rootId], "Send to Destination", "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa", {
        params ["_target"]; ["SET_DESTINATION", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target] call Waldo_fnc_TransportOpenMapLocal;
    }, {
        params ["_target", "_player"];
        vehicle _player isEqualTo _target && {_player in crew _target} && {_target getVariable ["Waldo_TransportService_State", ""] in ["AVAILABLE", "TO_PICKUP", "BOARDING", "TO_DESTINATION", "DISEMBARKING", "STUCK"]}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 1, ["ACE_SelfActions", _crewRootId], _destination] call ace_interact_menu_fnc_addActionToObject;
    private _retry = [format ["%1_Retry", _rootId], "Retry Current Route", "\a3\ui_f\data\igui\cfg\actions\reload_ca.paa", {
        params ["_target", "_player"]; ["RETRY", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
    }, {
        params ["_target", "_player"];
        vehicle _player isEqualTo _target && {_target getVariable ["Waldo_TransportService_State", ""] == "STUCK"} && {_player in crew _target}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 1, ["ACE_SelfActions", _crewRootId], _retry] call ace_interact_menu_fnc_addActionToObject;
    private _rtb = [format ["%1_RTB", _rootId], "Return This Transport to Base", "\a3\ui_f_oldman\data\igui\cfg\holdactions\meet_ca.paa", {
        params ["_target", "_player"]; ["RTB", _target getVariable ["Waldo_TransportService_Type", "GROUND"], _target, [], _player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2];
    }, {
        params ["_target", "_player"];
        vehicle _player isEqualTo _target && {_player in crew _target} && {_target getVariable ["Waldo_TransportService_State", ""] != "RTB"}
    }] call ace_interact_menu_fnc_createAction;
    [_vehicle, 1, ["ACE_SelfActions", _crewRootId], _rtb] call ace_interact_menu_fnc_addActionToObject;
    _vehicle setVariable ["Waldo_TransportService_AceInstalled", true];
    _vehicle setVariable ["Waldo_TransportService_AceActionVersion", _aceActionVersion];
};
true
