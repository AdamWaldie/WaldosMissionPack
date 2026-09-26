/*
 * Author: WaldoTheWarfighter
 * Returns a group to CALM and undoes everything the pass changed for the engagement.
 *
 * Restores recorded changes: behaviour goes back to the value
 * recorded at first contact only if the pass changed it and the group is still in COMBAT (a squad
 * that was SAFE before an actual firefight comes back AWARE, not SAFE); speed goes
 * back only if the pass changed it. Pass waypoints are removed so the group resumes its own
 * waypoints, the search or investigation team and soldiers holding ground from a drill rejoin
 * formation, stances the pass set go back to AUTO, and infantry dismounted by the pass remount their
 * vehicle. Morale is kept and recovers slowly.
 * Locality and authority: call where the group is local.
 *
 * Review contract: Investigation can change SAFE to AWARE; cleanup restores that recorded behaviour as well as a COMBAT change. Only the local group owner performs restoration.
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
} forEach ((_state getOrDefault ["searchTeam", []]) + (_state getOrDefault ["holders", []]));
{
    if (local _x && {_x getVariable ["Waldo_AIPass_StanceSet", false]}) then {
        _x setUnitPos "AUTO";
        _x setVariable ["Waldo_AIPass_StanceSet", nil, true];
    };
} forEach units _group;
if (_state getOrDefault ["behaviourChanged", false] && {behaviour _leader in ["COMBAT", "AWARE"]}) then {
    private _base = _state getOrDefault ["baseBehaviour", "AWARE"];
    // After a real firefight a squad stays alert rather than slinging weapons, as the engine does.
    if (_base == "SAFE" && {_state getOrDefault ["hadContact", false]}) then {_base = "AWARE"};
    _group setBehaviour _base;
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
    "withdrawn", "contactLeader", "lastSeen", "holders", "baseBehaviour", "baseSpeed", "armourSeen",
    "armourRequested", "coordinated", "reserveCommitted", "arrivedAt", "assaulting", "hadContact"
];
_group setVariable ["Waldo_AIPass_Checkpoint", [], true];
_state set ["phase", "CALM"];
_state set ["phaseStart", time];
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP AI PASS] %1 CALM restored", _group]};
