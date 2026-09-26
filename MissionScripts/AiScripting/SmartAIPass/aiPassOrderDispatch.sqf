/*
 * Author: WaldoTheWarfighter
 * Routes named Zeus settings to the group owner and keeps a bounded pending result until acknowledgement or timeout.
 * Locality/authority: server authenticates dispatch; the current owner executes group commands.
 * Repeat/JIP: request tokens are consumed once; no stale order is replayed for JIP.
 * Arguments: 0: settings <ARRAY> of named pairs; 1: requesting owner <NUMBER>, default 2.
 * Return Value: Boolean, dispatch accepted.
 * Current callers: authenticated FeatureRuntimeApply next-frame callback.
 * Example: [[["order", "RELEASE"], ["group", _group]], 2] call Waldo_fnc_AIPassOrderDispatch;
 */
params [["_pairs", [], [[]]], ["_requestOwner", 2, [0]]];
if (!isServer || {remoteExecutedOwner > 0}) exitWith {false};
if (_pairs findIf {!(_x isEqualType []) || {count _x != 2} || {!((_x select 0) isEqualType "")}} >= 0) exitWith {false};
private _settings = createHashMapFromArray _pairs;
private _group = _settings getOrDefault ["group", grpNull];
private _order = _settings getOrDefault ["order", ""];
if (!(_group isEqualType grpNull) || {!(_order isEqualType "")}) exitWith {false};
private _radius = _settings getOrDefault ["radius", 50];
private _facing = _settings getOrDefault ["facing", 0];
private _building = _settings getOrDefault ["building", objNull];
private _unit = _settings getOrDefault ["unit", objNull];
if (!(_radius isEqualType 0) || {!(_facing isEqualType 0)} || {!(_building isEqualType objNull)} || {!(_unit isEqualType objNull)}) exitWith {false};
private _serial = (missionNamespace getVariable ["Waldo_AIPass_OrderSerial", 0]) + 1;
missionNamespace setVariable ["Waldo_AIPass_OrderSerial", _serial];
private _token = str _serial;
private _pending = missionNamespace getVariable ["Waldo_AIPass_OrderPending", createHashMap];
_pending set [_token, [_requestOwner, _group, groupOwner _group, _order]];
missionNamespace setVariable ["Waldo_AIPass_OrderPending", _pending];
private _valid = !isNull _group && {(units _group) findIf {isPlayer _x} < 0}
    && {_order in ["GARRISON", "DEFEND", "RELEASE", "CLEAR", "AIRBORNE", "ARTY_SUPPORT", "ARTY_COUNTER", "ARTY_BOTH", "EXCLUDE", "RETURN", "SPOTTER_ON", "SPOTTER_OFF"]};
if (_order in ["GARRISON", "DEFEND"]) then {
    private _pos = _settings getOrDefault ["position", []];
    _valid = _valid && {_pos isEqualType []} && {count _pos >= 2} && {_pos findIf {!(_x isEqualType 0)} < 0};
};
if (_order == "CLEAR") then {_valid = _valid && {!isNull (_settings getOrDefault ["building", objNull])}};
if (!_valid) exitWith {[_token, false] call Waldo_fnc_AIPassOrderResult; false};
if (_order in ["SPOTTER_ON", "SPOTTER_OFF"]) exitWith {
    private _unit = _settings getOrDefault ["unit", objNull];
    private _accepted = !isNull _unit && {group _unit == _group} && {[_unit, _order == "SPOTTER_ON"] call Waldo_fnc_AIPassSetSpotter};
    [_token, _accepted] call Waldo_fnc_AIPassOrderResult;
    _accepted
};
[_token, _pairs] remoteExecCall ["Waldo_fnc_AIPassOrderLocal", groupOwner _group];
[{
    params ["_token"];
    if (_token in (missionNamespace getVariable ["Waldo_AIPass_OrderPending", createHashMap])) then {
        [_token, false, true] call Waldo_fnc_AIPassOrderResult;
    };
}, [_token], 12] call CBA_fnc_waitAndExecute;
true
