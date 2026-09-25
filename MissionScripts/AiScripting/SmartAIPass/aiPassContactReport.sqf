/*
 * Author: WaldoTheWarfighter
 * Shares what a squad in contact can see with nearby friendly squads, by radio or by voice.
 *
 * From Smart Combat V2's contact reports, kept machine-local instead of broadcast. Up to three enemies
 * seen in the last 10 s are reported. With a working radio (Waldo_fnc_AIPassCanTransmit: carried and
 * not jammed) the report reaches friendly squads whose leader is within
 * Waldo_AIPass_ContactReports_Radius; without one, only squads within
 * Waldo_AIPass_ContactReports_VoiceRange hear it. Each receiving leader gets the information after
 * 1.5 s plus 1 s per 250 m, at no better than the sender's own knowledge and never above 1.5 (reveal
 * knowledge scale 0-4). Repeated reports are at least 20 s apart. Receivers must be owned by the same
 * machine (reveal has local effect); squads owned elsewhere still learn through normal engine
 * mechanisms. Player-led groups are never given information.
 * Locality and authority: call where the reporting group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: visible <ARRAY> - enemies from Waldo_fnc_AIPassKnowledge seen in the last 10 s
 *
 * Return Value:
 * Number - squads informed
 *
 * Example:
 * [_group, _state, _visible] call Waldo_fnc_AIPassContactReport;
 * Result: the neighbouring squad turns to face the enemy the patrol just ran into.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_visible", [], [[]]]];
_state set ["lastReport", time];
if (_visible isEqualTo []) exitWith {0};
private _leader = leader _group;
private _range = if ([_leader] call Waldo_fnc_AIPassCanTransmit) then {
    missionNamespace getVariable ["Waldo_AIPass_ContactReports_Radius", 500]
} else {
    missionNamespace getVariable ["Waldo_AIPass_ContactReports_VoiceRange", 35]
};
private _reports = (_visible select [0, 3]) apply {
    private _enemy = _x select 0;
    [_enemy, (_leader knowsAbout _enemy) min 1.5]
};
private _side = side _group;
private _informed = 0;
{
    private _receiver = leader _x;
    if (_x != _group && {local _x} && {side _x == _side} && {alive _receiver} && {!isPlayer _receiver}
        && {(units _x) findIf {isPlayer _x} < 0} && {_receiver distance2D _leader <= _range}) then {
        [{
            params ["_job"];
            private _receiver = _job get "receiver";
            if (alive _receiver) then {
                {
                    _x params ["_enemy", "_knowledge"];
                    if (alive _enemy && {_receiver knowsAbout _enemy < _knowledge}) then {_receiver reveal [_enemy, _knowledge]};
                } forEach (_job get "reports");
            };
            -1
        }, createHashMapFromArray [["receiver", _receiver], ["reports", _reports]], 1.5 + (_receiver distance2D _leader) / 250] call Waldo_fnc_AIPassQueueJob;
        _informed = _informed + 1;
    };
} forEach allGroups;
_informed
