/*
 * Author: WaldoTheWarfighter
 * Lets nearby AI react to a live hand grenade by moving away from it into cover.
 *
 * Grenade evasion is queued by the
 * ProjectileCreated handler that Waldo_fnc_CortexInit installs (Waldo_AIPass_GrenadeEvasion_Enable,
 * on by default; the handler and reaction job still restrict orders to locally owned AI. After a short
 * reaction delay, each local AI soldier
 * on foot within 12 m reacts if he can see the grenade or it is within 5 m, with a chance based on his
 * general skill and reduced by suppression. Escape spots are spread out, 9 m away from the grenade,
 * and moved into cover facing it where possible. One Cortex scheduler job per grenade checks every
 * reacting soldier six seconds later; no callback or scheduler is created per unit. Each escape
 * receives a six-second GRENADE_EVASION actor lease, so a tactical bound or anti-armour relocation
 * cannot overwrite it. A soldier held as part of a coordinated base of fire temporarily leaves that
 * owned PATH hold, evades, then becomes eligible for the covering role again. Flank element members
 * and actors with another live reservation are left to their current task. Delayed regroup requires
 * the same group, Zeus token, actor lease and evasion
 * destination, an on-foot combat-effective soldier and no newer drill; soldiers held in place by a
 * garrison order (PATH disabled) cannot move and are skipped.
 * Locality and authority: scheduler job on the machine that received the event; orders go only to
 * local units.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * 0: job <HASHMAP> - contains "projectile", or internal "regroup" actor records
 *
 * Return Value:
 * Number - -1 (one-shot)
 *
 * Example:
 * [Waldo_fnc_CortexGrenadeCheck, createHashMapFromArray [["projectile", _grenade]], 0.5] call Waldo_fnc_CortexQueueJob;
 * Result: soldiers next to the grenade dive away from it.
 *
 * Current caller: the ProjectileCreated handler installed by Waldo_fnc_CortexInit.
 */

params [["_job", createHashMap, [createHashMap]]];
private _regroup = _job getOrDefault ["regroup", []];
if (_regroup isNotEqualTo []) exitWith {
    {
        _x params ["_unit","_group","_spot","_hold"];
        private _actorMove = _unit getVariable ["Waldo_Cortex_ActorMove",[]];
        private _ownsEvasion = count _actorMove == 3 && {(_actorMove select 0) == "GRENADE_EVASION"}
            && {(_actorMove select 1) distance2D _spot <= 1};
        if (_ownsEvasion && {local _unit} && {group _unit == _group} && {vehicle _unit == _unit}
            && {[_unit] call Waldo_fnc_CortexCombatEffective}
            && {_unit checkAIFeature "PATH"}
            && {[_group] call Waldo_fnc_CortexIsEligible}
            && {(_group getVariable ["Waldo_AIPass_ZeusHold",[]]) isEqualTo _hold}
            && {((expectedDestination _unit) select 0) distance2D _spot <= 1}) then {
            private _drill = (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
            if (!(_unit in (_drill getOrDefault ["units",[]])) && {alive leader _group}) then {
                _unit doFollow (leader _group);
            };
            _unit setVariable ["Waldo_Cortex_ActorMove",nil];
        };
    } forEach _regroup;
    -1
};
private _grenade = _job getOrDefault ["projectile", objNull];
if (isNull _grenade || {!(missionNamespace getVariable ["Waldo_AIPass_GrenadeEvasion_Enable", true])}) exitWith {-1};
private _grenadePos = getPosATL _grenade;
private _grenadeASL = getPosASL _grenade;
private _checkedGroups = [];
private _checkedResults = [];
private _reacted = 0;
private _regroupActors = [];
{
    private _unit = _x;
    private _group = group _unit;
    private _groupIndex = _checkedGroups find _group;
    if (_groupIndex < 0) then {
        _groupIndex = count _checkedGroups;
        _checkedGroups pushBack _group;
        _checkedResults pushBack ([_group] call Waldo_fnc_CortexIsEligible && {[_group,"Waldo_AIPass_GrenadeEvasion_Enable",true] call Waldo_fnc_CortexFeatureEnabled});
    };
    private _state = _group getVariable ["Waldo_AIPass_State",createHashMap];
    private _drillUnits = (_state getOrDefault ["drill", createHashMap]) getOrDefault ["units", []];
    private _supportHeld = _state getOrDefault ["supportHeld",[]];
    private _actorMove = _unit getVariable ["Waldo_Cortex_ActorMove",[]];
    if (local _unit && {!isPlayer _unit} && {[_unit] call Waldo_fnc_CortexCombatEffective} && {vehicle _unit == _unit}
        && {_unit checkAIFeature "PATH" || {_unit in _supportHeld}}
        && {!(_unit in _drillUnits)} && {count _actorMove != 3 || {time >= (_actorMove select 2)}}
        && {_checkedResults select _groupIndex}) then {
        private _sees = _unit distance _grenade < 5 || {([objNull, "VIEW"] checkVisibility [eyePos _unit, _grenadeASL]) > 0.2};
        private _chance = (0.5 + 0.5 * (_unit skill "general")) * (1 - 0.5 * getSuppression _unit);
        if (_sees && {random 1 < _chance}) then {
            private _direction = (_grenadePos getDir _unit) + ((_reacted mod 3) - 1) * 35;
            private _spot = ([(getPosATL _unit) getPos [9, _direction], _grenadePos, 6, [], _group] call Waldo_fnc_CortexFindCover) select 0;
            if (_unit in _supportHeld) then {
                _unit enableAI "PATH";
                _state set ["supportHeld",_supportHeld-[_unit]];
            };
            _unit doMove _spot;
            _unit setVariable ["Waldo_Cortex_ActorMove",["GRENADE_EVASION",+_spot,time+6]];
            _reacted = _reacted + 1;
            _regroupActors pushBack [_unit,_group,+_spot,+(_group getVariable ["Waldo_AIPass_ZeusHold",[]])];
        };
    };
} forEach (_grenade nearEntities ["CAManBase", 12]);
if (_reacted > 0) then {
    missionNamespace setVariable ["Waldo_AIPass_GrenadeReactions", (missionNamespace getVariable ["Waldo_AIPass_GrenadeReactions", 0]) + _reacted];
    [Waldo_fnc_CortexGrenadeCheck,createHashMapFromArray [["regroup",_regroupActors]],6] call Waldo_fnc_CortexQueueJob;
};
-1
