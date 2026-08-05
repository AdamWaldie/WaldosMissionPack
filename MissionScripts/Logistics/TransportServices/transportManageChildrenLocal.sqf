/*
 * Author: WaldoTheWarfighter, Val
 * Builds the live ACE self-interaction list for transport services the player may manage. Each
 * transport is shown by its mission-maker name and current state, then exposes controls tied to that
 * exact vehicle. This avoids guessing from the vehicle the player currently occupies.
 * Locality and authority: interface-client display logic only. Every state change is still sent to
 * Waldo_fnc_TransportRequestServer for authoritative validation.
 *
 * Arguments:
 * 0: player <OBJECT> - player for whom the service list is being built.
 *
 * Return Value: <ARRAY> - ACE dynamic child-action rows.
 *
 * Example:
 * [player] call Waldo_fnc_TransportManageChildrenLocal;
 * Result: returns named entries for services reserved by, or currently carrying, the player.
 * Current caller: Manage Active Services under ACE Self Interact > WMP Transport.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_player", objNull, [objNull]]];
if (!hasInterface || {isNull _player}) exitWith {[]};

private _uid = getPlayerUID _player;
private _services = vehicles select {
    _x getVariable ["Waldo_TransportService_Registered", false]
    && {
        _player in crew _x
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
                    [_type, _message, "INFO"] call Waldo_fnc_TransportNotifyLocal;
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
                    _state in ["TO_PICKUP", "BOARDING"] && {_uid != "" && {_service getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid} || {!isNull getAssignedCuratorLogic player}}
                }, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_move, [], player];
            private _destination = [
                "Waldo_Transport_ExactDestination", "Select Destination",
                "\a3\ui_f_oldman\data\igui\cfg\holdactions\map_ca.paa",
                {private _service = _this select 2; ["SET_DESTINATION", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service] call Waldo_fnc_TransportOpenMapLocal},
                {private _service = _this select 2; _service getVariable ["Waldo_TransportService_State", ""] == "BOARDING" && {player in crew _service || {!isNull getAssignedCuratorLogic player}}}, {}, _service
            ] call ace_interact_menu_fnc_createAction;
            _controls pushBack [_destination, [], player];
            private _retry = [
                "Waldo_Transport_ExactRetry", "Retry Current Route",
                "\a3\ui_f\data\igui\cfg\actions\reload_ca.paa",
                {private _service = _this select 2; ["RETRY", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service, [], player] remoteExecCall ["Waldo_fnc_TransportRequestServer", 2]},
                {
                    private _service = _this select 2;
                    private _uid = getPlayerUID player;
                    _service getVariable ["Waldo_TransportService_State", ""] == "STUCK" && {player in crew _service || {_uid != "" && {_service getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} || {!isNull getAssignedCuratorLogic player}}
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
                    !(_state in ["AVAILABLE", "RTB"]) && {player in crew _service || {_uid != "" && {_service getVariable ["Waldo_TransportService_RequesterUID", ""] == _uid}} || {!isNull getAssignedCuratorLogic player}}
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
