/*
 * Author: WaldoTheWarfighter
 * Allows explicitly assigned observers in the requesting group to ask the server for cross-owner fire support.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: group <GROUP>; 1: state <HASHMAP>; 2: known enemies <ARRAY>, default [].
 * Return Value: Boolean, a request was dispatched; no immediate firing claim.
 * Current callers: GroupTick.
 * Example: [_group, _state, _enemies] call Waldo_fnc_AIPassArtilleryRequest;
 */
params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
if (!local _group || {[_state, "artillery"] call Waldo_fnc_AIPassCooldown}) exitWith {false};
private _spotters = (units _group) select {alive _x && {local _x} && {_x getVariable ["Waldo_AIPass_Spotter", false]}};
private _sent = false;
{
    private _spotter = _x;
    {
        private _enemy = _x select 0;
        private _fix = [_spotter, _enemy] call Waldo_fnc_AIPassSpotterFix;
        if (_fix isNotEqualTo [] && {(_fix select 1) <= (missionNamespace getVariable ["Waldo_AIPass_Artillery_MaxError", 50])}) exitWith {
            [objNull, _fix select 0, _fix select 1, "HE", -1, -1, "SUPPORT", _spotter, _enemy] call Waldo_fnc_AIPassArtilleryFire;
            _sent = true;
        };
    } forEach _enemies;
    if (_sent) exitWith {};
} forEach _spotters;
[_state, "artillery", [20, missionNamespace getVariable ["Waldo_AIPass_Artillery_Cooldown", 120]] select _sent] call Waldo_fnc_AIPassCooldown;
_sent
