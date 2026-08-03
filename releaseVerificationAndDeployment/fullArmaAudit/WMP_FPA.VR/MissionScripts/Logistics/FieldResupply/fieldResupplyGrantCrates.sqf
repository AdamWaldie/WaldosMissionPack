/*
 * Author: WaldoTheWarfighter
 * Grants portable Field Resupply crates to one assigned infantry carrier.
 *
 * The server owns and broadcasts the carrier count. Remote requests are accepted only from an
 * assigned curator. By default the grant is clamped to spare carrier capacity; callers may
 * explicitly expand that capacity to fit the whole grant. Only the receiving player is notified,
 * and their client delays that notice until the mission introduction has finished.
 *
 * Arguments:
 * 0: carrier <OBJECT> - assigned infantry carrier.
 * 1: crates to grant <NUMBER> (default 1).
 * 2: expand capacity to fit <BOOL> (default false).
 *
 * Return Value:
 * Number - crates actually granted on the server; forwarded client requests return -1.
 *
 * Example:
 * if (isServer) then {[player, 2, false] call Waldo_fnc_FieldResupplyGrantCrates;};
 *
 * Current callers: Field Resupply Grant Crates ZEN module and mission-maker scripts.
 */

params [
    ["_unit", objNull, [objNull]],
    ["_amount", 1, [0]],
    ["_expandCapacity", false, [true]]
];
if !(isServer) exitWith {
    [_unit, _amount, _expandCapacity] remoteExecCall ["Waldo_fnc_FieldResupplyGrantCrates", 2];
    -1
};
if (isNull _unit || {!(_unit isKindOf "CAManBase")} || {!alive _unit}) exitWith {0};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {0};
};

_amount = round (_amount max 0);
if (_amount <= 0) exitWith {0};
private _maximum = _unit getVariable ["Waldo_FieldResupply_MaxCrates", 0];
if (_maximum <= 0) exitWith {0};
private _current = (_unit getVariable ["Waldo_FieldResupply_Crates", 0]) max 0;
if (_expandCapacity) then {
    _maximum = _maximum max (_current + _amount);
    _unit setVariable ["Waldo_FieldResupply_MaxCrates", _maximum, true];
};
private _granted = _amount min ((_maximum - _current) max 0);
if (_granted <= 0) exitWith {0};

_current = _current + _granted;
_unit setVariable ["Waldo_FieldResupply_Crates", _current, true];
[_granted, _current, _maximum] remoteExecCall ["Waldo_fnc_FieldResupplyNotifyGrantLocal", owner _unit];
_granted
