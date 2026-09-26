/*
 * Author: WaldoTheWarfighter
 * Releases only the current WMP support assignment when it expires, is revoked or loses its feature gate.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: group <GROUP>; 1: local state <HASHMAP>.
 * Return Value: Nothing.
 * Current callers: GroupTick.
 * Example: [_group, _state] call Waldo_fnc_AIPassSupportMaintain;
 */
params ["_group","_state"];
if (!local _group) exitWith {};
private _token = _state getOrDefault ["supportToken",""];
if (_token == "") exitWith {};
private _lease = _group getVariable ["Waldo_AIPass_SupportLease",[]];
if (_lease isEqualTo [] || {(_lease select 0) != _token} || {serverTime >= (_lease select 2)}
    || {!([_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}
    || {!([_group,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}) then {
    if (_state getOrDefault ["responding",false] || {_state getOrDefault ["assaulting",false]}) then {[_group] call Waldo_fnc_AIPassGroupMoveClear};
    {_state deleteAt _x} forEach ["supportToken","responding","respondingTo","respondUntil","arrivedAt","assaulting"];
};

if (_state getOrDefault ["assaulting",false] && {!([_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}) then {
    [_group] call Waldo_fnc_AIPassGroupMoveClear;
    _state set ["assaulting",false]; _state set ["responding",false];
};
