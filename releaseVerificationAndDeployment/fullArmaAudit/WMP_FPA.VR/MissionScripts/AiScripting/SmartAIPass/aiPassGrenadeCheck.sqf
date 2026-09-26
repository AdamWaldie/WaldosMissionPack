/*
 * Author: WaldoTheWarfighter
 * Lets nearby AI react to a live hand grenade by moving away from it into cover.
 *
 * Grenade evasion is queued by the
 * ProjectileCreated handler that Waldo_fnc_AIPassInit installs (Waldo_AIPass_GrenadeEvasion_Enable,
 * off by default because that event's multiplayer locality still needs in-engine confirmation; with
 * the wrong locality the feature is simply inert). After a short reaction delay, each local AI soldier
 * on foot within 12 m reacts if he can see the grenade or it is within 5 m, with a chance based on his
 * general skill and reduced by suppression. Escape spots are spread out, 9 m away from the grenade,
 * and moved into cover facing it where possible. Soldiers rejoin formation 6 s later; flank element
 * members are left to their drill, and soldiers held in place by a garrison order (PATH disabled)
 * cannot move and are skipped.
 * Locality and authority: scheduler job on the machine that received the event; orders go only to
 * local units.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * 0: job <HASHMAP> - contains "projectile"
 *
 * Return Value:
 * Number - -1 (one-shot)
 *
 * Example:
 * [Waldo_fnc_AIPassGrenadeCheck, createHashMapFromArray [["projectile", _grenade]], 0.5] call Waldo_fnc_AIPassQueueJob;
 * Result: soldiers next to the grenade dive away from it.
 *
 * Current caller: the ProjectileCreated handler installed by Waldo_fnc_AIPassInit.
 */

params [["_job", createHashMap, [createHashMap]]];
private _grenade = _job getOrDefault ["projectile", objNull];
if (isNull _grenade || {!(missionNamespace getVariable ["Waldo_AIPass_GrenadeEvasion_Enable", false])}) exitWith {-1};
private _grenadePos = getPosATL _grenade;
private _grenadeASL = getPosASL _grenade;
private _checkedGroups = [];
private _checkedResults = [];
private _reacted = 0;
{
    private _unit = _x;
    private _group = group _unit;
    private _groupIndex = _checkedGroups find _group;
    if (_groupIndex < 0) then {
        _groupIndex = count _checkedGroups;
        _checkedGroups pushBack _group;
        _checkedResults pushBack ([_group] call Waldo_fnc_AIPassIsEligible && {[_group,"Waldo_AIPass_GrenadeEvasion_Enable",false] call Waldo_fnc_AIPassFeatureEnabled});
    };
    private _drillUnits = ((_group getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["drill", createHashMap]) getOrDefault ["units", []];
    if (local _unit && {!isPlayer _unit} && {alive _unit} && {vehicle _unit == _unit} && {_unit checkAIFeature "PATH"}
        && {!(_unit in _drillUnits)} && {_checkedResults select _groupIndex}) then {
        private _sees = _unit distance _grenade < 5 || {([objNull, "VIEW"] checkVisibility [eyePos _unit, _grenadeASL]) > 0.2};
        private _chance = (0.5 + 0.5 * (_unit skill "general")) * (1 - 0.5 * getSuppression _unit);
        if (_sees && {random 1 < _chance}) then {
            private _direction = (_grenadePos getDir _unit) + ((_reacted mod 3) - 1) * 35;
            private _spot = ([(getPosATL _unit) getPos [9, _direction], _grenadePos, 6, [], _group] call Waldo_fnc_AIPassFindCover) select 0;
            _unit doMove _spot;
            _reacted = _reacted + 1;
            [{
                params ["_unit"];
                if (alive _unit && {local _unit} && {[group _unit] call Waldo_fnc_AIPassIsEligible}) then {_unit doFollow (leader group _unit)};
            }, [_unit], 6] call CBA_fnc_waitAndExecute;
        };
    };
} forEach (_grenade nearEntities ["CAManBase", 12]);
if (_reacted > 0) then {
    missionNamespace setVariable ["Waldo_AIPass_GrenadeReactions", (missionNamespace getVariable ["Waldo_AIPass_GrenadeReactions", 0]) + _reacted];
};
-1
