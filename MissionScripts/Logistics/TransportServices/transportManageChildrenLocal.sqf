/*
 * Author: WaldoTheWarfighter, Val
 * Builds the live ACE self-interaction list for transport services the player may manage. Each
 * transport is shown by its mission-maker name and current state, then exposes controls tied to that
 * exact vehicle. Requester object and UID are both recognized, so the surface remains available
 * after issuing an instruction and across player-object/JIP identity changes.
 * Locality and authority: interface-client display logic only. Every state change is still sent to
 * Waldo_fnc_TransportRequestServer for authoritative validation.
 *
 * Arguments:
 * 0: player <OBJECT> - player for whom the service list is being built.
 * 1: service type <STRING> - HELICOPTER or GROUND; empty includes both.
 *
 * Return Value: <ARRAY> - ACE dynamic child-action rows.
 *
 * Example:
 * [player, "HELICOPTER"] call Waldo_fnc_TransportManageChildrenLocal;
 * Result: returns named entries for services reserved by, or currently carrying, the player.
 * Current caller: each type's Select / Manage Transport list.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_player", objNull, [objNull]], ["_requestedType", "", [""]]];
if (!hasInterface || {isNull _player}) exitWith {[]};
_requestedType = toUpperANSI _requestedType;

private _uid = getPlayerUID _player;
private _services = vehicles select {
    _x getVariable ["Waldo_TransportService_Registered", false]
    && {_x getVariable ["Waldo_TransportService_State", "AVAILABLE"] != "AVAILABLE"}
    && {_requestedType == "" || {_x getVariable ["Waldo_TransportService_Type", ""] == _requestedType}}
    && {
        _player in crew _x
        || {_x getVariable ["Waldo_TransportService_Requester", objNull] isEqualTo _player}
        || {_uid != "" && {_x getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}}
        || {!isNull getAssignedCuratorLogic _player}
    }
};
_services = [_services, [], {_x getVariable ["Waldo_TransportService_Name", "Transport Service"]}, "ASCEND"] call BIS_fnc_sortBy;

private _children = [];
{
    private _service = _x;
    private _name = _service getVariable ["Waldo_TransportService_Name", "Transport Service"];
    private _state = _service getVariable ["Waldo_TransportService_State", "UNKNOWN"];
    private _type = _service getVariable ["Waldo_TransportService_Type", "GROUND"];
    private _icon = if (_type == "HELICOPTER") then {"\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa"} else {"\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa"};
    private _serviceAction = [
        format ["Waldo_Transport_Manage_%1", _service getVariable ["Waldo_TransportService_Id", netId _service]],
        format ["%1 [%2]", _name, _state],
        _icon,
        {},
        {true},
        {
            private _service = _this select 2;
            private _controls = [];
            private _status = [
                "Waldo_Transport_ExactStatus",
                format ["Status: %1", _service getVariable ["Waldo_TransportService_State", "UNKNOWN"]],
                "\a3\ui_f\data\igui\cfg\simpletasks\types\documents_ca.paa",
                {
                    private _service = _this select 2;
                    private _type = _service getVariable ["Waldo_TransportService_Type", "GROUND"];
                    private _message = format ["%1 is %2.", _service getVariable ["Waldo_TransportService_Name", "Transport Service"], _service getVariable ["Waldo_TransportService_State", "UNKNOWN"]];
                    [_type, _message, "INFO", _service getVariable ["Waldo_TransportService_Id", netId _service]] call Waldo_fnc_TransportNotifyLocal;
                },
                {true}, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_status, [], player];
            private _move = [
                "Waldo_Transport_ExactMovePickup", "Move Pickup Point",
                "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa",
                {private _service = _this select 2; ["MOVE_PICKUP", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service] call Waldo_fnc_TransportOpenMapLocal},
                {
                    private _service = _this select 2;
                    private _state = _service getVariable ["Waldo_TransportService_State", ""];
                    private _uid = getPlayerUID player;
                    _state in ["TO_PICKUP", "BOARDING"] && {
                        _service getVariable ["Waldo_TransportService_Requester", objNull] isEqualTo player
                        || {_uid != "" && {_service getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}}
                        || {!isNull getAssignedCuratorLogic player}
                    }
                }, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_move, [], player];
            private _destination = [
                "Waldo_Transport_ExactDestination", "Select Destination",
                "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa",
                {private _service = _this select 2; ["SET_DESTINATION", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service] call Waldo_fnc_TransportOpenMapLocal},
                {private _service = _this select 2; (_service getVariable ["Waldo_TransportService_State", ""] in ["AVAILABLE", "TO_PICKUP", "BOARDING", "TO_DESTINATION", "DISEMBARKING", "STUCK"]) && {player in crew _service || {!isNull getAssignedCuratorLogic player}}}, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_destination, [], player];
            private _retry = [
                "Waldo_Transport_ExactRetry", "Retry Current Route",
                "\a3\ui_f\data\igui\cfg\actions\reload_ca.paa",
                {private _service = _this select 2; ["RETRY", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service, [], player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
                {
                    private _service = _this select 2;
                    private _uid = getPlayerUID player;
                    _service getVariable ["Waldo_TransportService_State", ""] == "STUCK" && {
                        player in crew _service
                        || {_service getVariable ["Waldo_TransportService_Requester", objNull] isEqualTo player}
                        || {_uid != "" && {_service getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}}
                        || {!isNull getAssignedCuratorLogic player}
                    }
                }, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_retry, [], player];
            private _rtb = [
                "Waldo_Transport_ExactRTB", "Return This Transport to Base",
                "\a3\ui_f_oldman\data\igui\cfg\holdactions\meet_ca.paa",
                {private _service = _this select 2; ["RTB", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service, [], player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
                {
                    private _service = _this select 2;
                    private _state = _service getVariable ["Waldo_TransportService_State", ""];
                    private _uid = getPlayerUID player;
                    !(_state in ["AVAILABLE", "RTB"]) && {
                        player in crew _service
                        || {_service getVariable ["Waldo_TransportService_Requester", objNull] isEqualTo player}
                        || {_uid != "" && {_service getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}}
                        || {!isNull getAssignedCuratorLogic player}
                    }
                }, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_rtb, [], player];
            _controls
        },
        _service
    ] call ace_interact_menu_fnc_createAction;
    _children pushBack [_serviceAction, [], _player];
} forEach _services;
_children
