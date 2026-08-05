/*
 * Author: WaldoTheWarfighter, Val
 * Applies one validated pickup or RTB command to every eligible transport of one type. Bulk pickup
 * assigns deterministic grid slots around the clicked centre so vehicles are never intentionally
 * dispatched onto the same coordinate.
 * Locality and authority: server-only selection and orchestration. Each exact vehicle transition is
 * passed through Waldo_fnc_TransportRequestServer and retains its normal request-ID/locality rules.
 *
 * Arguments:
 * 0: command <STRING> - PICKUP_ALL or RTB_ALL.
 * 1: transport type <STRING> - HELICOPTER or GROUND.
 * 2: centre ATL position <ARRAY> - required for PICKUP_ALL.
 * 3: requester <OBJECT> - requesting player/curator.
 *
 * Return Value: <NUMBER> - number of transports that accepted the bulk command.
 *
 * Example:
 * ["PICKUP_ALL", "HELICOPTER", getPosATL player, player] remoteExecCall ["Waldo_fnc_TransportBulkRequestServer", 2];
 * Current callers: WMP Transport > Fleet Controls.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [
    ["_command", "", [""]], ["_type", "GROUND", [""]],
    ["_position", [], [[]]], ["_requester", objNull, [objNull]]
];
_command = toUpperANSI _command;
_type = toUpperANSI _type;
if (!isServer || {!(_command in ["PICKUP_ALL", "RTB_ALL"])} || {!(_type in ["HELICOPTER", "GROUND"])} || {isNull _requester} || {!isPlayer _requester}) exitWith {0};
if (remoteExecutedOwner > 0 && {owner _requester != remoteExecutedOwner}) exitWith {0};
if (_command == "PICKUP_ALL" && {count _position < 2}) exitWith {0};

private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
private _isCurator = !isNull getAssignedCuratorLogic _requester;
private _uid = getPlayerUID _requester;
private _ids = (keys _services) select {
    private _entry = _services get _x;
    private _vehicle = _entry getOrDefault ["vehicle", objNull];
    private _state = _entry getOrDefault ["state", ""];
    private _matches = _entry getOrDefault ["type", ""] == _type && {!isNull _vehicle} && {alive _vehicle} && {!isNull driver _vehicle} && {alive driver _vehicle};
    if (_command == "PICKUP_ALL") then {
        _matches && {_state == "AVAILABLE"}
    } else {
        _matches && {!(_state in ["AVAILABLE", "RTB"])} && {_isCurator || {_uid != "" && {_entry getOrDefault ["requesterUID", ""] == _uid}} || {_requester in crew _vehicle}}
    }
};
_ids = [_ids, [], {
    private _entry = _services get _x;
    if (_command == "PICKUP_ALL") then {(_entry get "vehicle") distance2D _position} else {_entry getOrDefault ["name", _x]}
}, "ASCEND"] call BIS_fnc_sortBy;

private _accepted = 0;
private _count = count _ids;
private _columns = ceil (sqrt (_count max 1));
// Each requested slot may be shifted while finding reachable ground. Use twice the single-service
// minimum so neighbouring searches do not begin on each other's exclusion boundary.
private _spacing = 2 * (if (_type == "HELICOPTER") then {missionNamespace getVariable ["Waldo_HeliTransport_DefaultSeparation", 60]} else {missionNamespace getVariable ["Waldo_GroundTransport_DefaultSeparation", 18]});
{
    private _entry = _services get _x;
    private _vehicle = _entry get "vehicle";
    private _ok = if (_command == "PICKUP_ALL") then {
        private _column = _forEachIndex mod _columns;
        private _row = floor (_forEachIndex / _columns);
        private _rows = ceil (_count / _columns);
        private _offsetX = (_column - ((_columns - 1) / 2)) * _spacing;
        private _offsetY = (_row - ((_rows - 1) / 2)) * _spacing;
        private _slot = [(_position select 0) + _offsetX, (_position select 1) + _offsetY, 0];
        ["REQUEST_SPECIFIC", _type, _vehicle, _slot, _requester, true] call Waldo_fnc_TransportRequestServer
    } else {
        ["RTB", _type, _vehicle, [], _requester, true] call Waldo_fnc_TransportRequestServer
    };
    if (_ok) then {_accepted = _accepted + 1};
} forEach _ids;

private _verb = if (_command == "PICKUP_ALL") then {"pickup"} else {"return-to-base"};
private _failed = _count - _accepted;
private _resultText = if (_count == 0) then {
    format ["No eligible %1 transports were available for the bulk %2 request.", toLowerANSI _type, _verb]
} else {
    format ["Bulk %1: %2 accepted%3.", _verb, _accepted, if (_failed > 0) then {format [", %1 could not be assigned a clear service point", _failed]} else {""}]
};
[_type, _resultText, if (_accepted > 0) then {"SUCCESS"} else {"WARNING"}, "FLEET"] remoteExecCall ["Waldo_fnc_TransportNotifyLocal", owner _requester];
_accepted
