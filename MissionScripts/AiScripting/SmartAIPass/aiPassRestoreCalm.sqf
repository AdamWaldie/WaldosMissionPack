/*
 * Author: WaldoTheWarfighter
 * Returns a group to CALM and undoes everything the pass changed for the engagement.
 *
 * Exact restore, fixing Smart Combat V2's unconditional re-enables: behaviour goes back to the value
 * recorded at first contact only if the pass changed it and the group is still in COMBAT; speed goes
 * back only if the pass changed it. Pass waypoints are removed so the group resumes its own
 * waypoints, the search team rejoins formation, and infantry dismounted by the pass remount their
 * vehicle. Morale is kept and recovers slowly.
 * Locality and authority: call where the group is local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP> - from Waldo_fnc_AIPassGroupState
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_group, _state] call Waldo_fnc_AIPassRestoreCalm;
 * Result: the group carries on with its mission as it was before contact.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick and Waldo_fnc_AIPassReleaseGroup.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]]];
if (isNull _group || {!local _group}) exitWith {};
private _leader = leader _group;
[_group] call Waldo_fnc_AIPassGroupMoveClear;
{
    if (alive _x && {local _x}) then {_x doFollow _leader};
} forEach (_state getOrDefault ["searchTeam", []]);
if (_state getOrDefault ["behaviourChanged", false] && {behaviour _leader == "COMBAT"}) then {
    _group setBehaviour (_state getOrDefault ["baseBehaviour", "AWARE"]);
};
if (_state getOrDefault ["speedChanged", false]) then {
    _group setSpeedMode (_state getOrDefault ["baseSpeed", "NORMAL"]);
};
{
    _x params ["_unit", "_vehicle"];
    if (alive _unit && {local _unit} && {alive _vehicle} && {canMove _vehicle} && {vehicle _unit == _unit} && {group _unit == _group}) then {
        _unit assignAsCargo _vehicle;
        [_unit] orderGetIn true;
    };
} forEach (_state getOrDefault ["dismounted", []]);
{_state deleteAt _x} forEach [
    "enemyPos", "behaviourChanged", "speedChanged", "searchTeam", "dismounted", "reinforceRequested",
    "withdrawn", "contactLeader", "lastSeen"
];
_state set ["phase", "CALM"];
_state set ["phaseStart", time];
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP AI PASS] %1 CALM restored", _group]};
