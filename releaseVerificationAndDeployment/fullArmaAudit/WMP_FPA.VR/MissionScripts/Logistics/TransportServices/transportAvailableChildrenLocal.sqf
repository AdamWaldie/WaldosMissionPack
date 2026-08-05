/*
 * Author: WaldoTheWarfighter, Val
 * Builds a live, scalable list of named available transports of one type that this player may use.
 * Selecting a row opens the normal map picker and requests that exact vehicle instead of allowing
 * the server to choose the nearest eligible service.
 * Locality and authority: interface-client display filtering only. The server repeats all access,
 * availability and requester checks before atomically reserving the selected transport.
 *
 * Arguments:
 * 0: player <OBJECT>
 * 1: service type <STRING> - HELICOPTER or GROUND.
 *
 * Return Value: <ARRAY> - ACE dynamic child-action rows for eligible available services.
 * Example: [player, "HELICOPTER"] call Waldo_fnc_TransportAvailableChildrenLocal;
 * Current callers: Select Specific Transport under the helicopter and ground self-action branches.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */

params [["_player", objNull, [objNull]], ["_type", "GROUND", [""]]];
if (!hasInterface || {isNull _player}) exitWith {[]};
_type = toUpperANSI _type;
if !(_type in ["HELICOPTER", "GROUND"]) exitWith {[]};

private _isCurator = !isNull getAssignedCuratorLogic _player;
private _playerSide = side group _player;
private _playerGroup = toUpperANSI groupId group _player;
private _services = vehicles select {
    private _service = _x;
    private _registration = _service getVariable ["Waldo_TransportService_Registration", []];
    private _optionRows = _registration param [3, []];
    private _config = createHashMap;
    {if (_x isEqualType [] && {count _x >= 2}) then {_config set [_x select 0, _x select 1]}} forEach _optionRows;
    private _allowedSides = _config getOrDefault ["allowedSides", []];
    private _allowedGroups = _config getOrDefault ["allowedGroups", []];
    private _sideAllowed = _allowedSides isEqualTo [] || {_playerSide in _allowedSides};
    private _groupAllowed = _allowedGroups isEqualTo [] || {_playerGroup in (_allowedGroups apply {toUpperANSI _x})};
    private _leaderAllowed = !(_config getOrDefault ["leadersOnly", false]) || {leader group _player == _player};
    _service getVariable ["Waldo_TransportService_Registered", false]
    && {_service getVariable ["Waldo_TransportService_Type", ""] == _type}
    && {_service getVariable ["Waldo_TransportService_State", ""] == "AVAILABLE"}
    && {alive _service}
    && {!isNull driver _service}
    && {alive driver _service}
    && {_isCurator || {_sideAllowed && _groupAllowed && _leaderAllowed}}
};
_services = [_services, [], {_x getVariable ["Waldo_TransportService_Name", "Transport Service"]}, "ASCEND"] call BIS_fnc_sortBy;

private _children = [];
{
    private _service = _x;
    private _name = _service getVariable ["Waldo_TransportService_Name", "Transport Service"];
    private _className = getText (configOf _service >> "displayName");
    private _icon = if (_type == "HELICOPTER") then {"\a3\ui_f\data\igui\cfg\simpletasks\types\Heli_ca.paa"} else {"\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa"};
    private _action = [
        format ["Waldo_Transport_Select_%1", _service getVariable ["Waldo_TransportService_Id", netId _service]],
        format ["%1 — %2", _name, _className],
        _icon,
        {
            private _service = _this select 2;
            ["REQUEST_SPECIFIC", _service getVariable ["Waldo_TransportService_Type", "GROUND"], _service] call Waldo_fnc_TransportOpenMapLocal;
        },
        {
            private _service = _this select 2;
            alive _service
            && {!isNull driver _service}
            && {alive driver _service}
            && {_service getVariable ["Waldo_TransportService_State", ""] == "AVAILABLE"}
        },
        {},
        _service
    ] call ace_interact_menu_fnc_createAction;
    _children pushBack [_action, [], _player];
} forEach _services;
_children
