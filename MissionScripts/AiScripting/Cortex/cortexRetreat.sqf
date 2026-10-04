/*
 * Author: WaldoTheWarfighter
 * Pulls a broken squad back, away from the enemy, under smoke.
 *
 * The retreat point is Waldo_AIPass_Morale_RetreatDistance (scaled by the behaviour profile's
 * retreatScale) from the leader. Five bounded escape candidates spread up to 60 degrees around the
 * direction away from the enemy; Cortex rejects water and selects the shortest screened avenue
 * through terrain, solid cover or concealment. If that full-distance fan is water-blocked, three
 * shorter eight-direction fans seek a dry escape instead of silently leaving a broken squad idle.
 * A completely trapped squad reports BLOCKED and keeps fighting while GroupTick applies a bounded
 * retry delay. The squad moves through an inserted waypoint
 * (Waldo_fnc_CortexGroupMove) at FULL speed, so its own waypoints resume afterwards. Soldiers holding
 * ground from a drill fall back with it. One soldier throws smoke towards the enemy, and with
 * artillery support and Waldo_AIPass_ArtillerySmoke_Enable on, a friendly battery selected by the server across owners
 * lays a smoke screen between the squad and the enemy, never within 50 m of friendlies. A carried-smoke thrower is handed back
 * to the same withdrawal route after the throw animation; this is guarded by the exact public withdrawal intent and Zeus hold,
 * so it cannot revive an old retreat or replace a curator order. Any flank drill ends because the phase
 * leaves CONTACT. Individual attack assignments are suspended and behaviour set to AWARE for
 * withdrawal. A RED group temporarily uses YELLOW: it keeps firing, but the engine may no longer
 * replace the retreat waypoint with independent pursuit. GroupTick measures physical travel; a
 * vanished waypoint or 15 seconds without progress replans around the obstruction at a different
 * angle, without teleporting anyone. Attack, combat mode, behaviour and speed
 * changes are recorded for CALM, release and ownership cleanup. A later Zeus ROE change is preserved.
 * Locality and authority: call where the group is local; server selects and dispatches supporting artillery.
 * Repeat/JIP: caller phase prevents repeated entry. A public movement intent lets a new group owner
 * resume the same bounded withdrawal without repeating smoke or artillery effects.
 * A withdrawal releases an earlier coordinated-support LAMBS movement handover and any durable
 * Cortex PATH-hold markers before replacing them with the retreat route.
 *
 * Arguments:
 * 0: group <GROUP, default grpNull>
 * 1: state <HASHMAP, default empty HashMap>
 * 2: resume intent <ARRAY, default []> - ["INFANTRY", origin, target, enemy position,
 *    server start, replans, best travel]
 *
 * Return Value:
 * Boolean - true when the squad started retreating
 *
 * Example:
 * [_group, _state] call Waldo_fnc_CortexRetreat;
 * Result: the survivors fall back 200 m and regroup.
 *
 * Current callers: Waldo_fnc_CortexGroupTick and Waldo_fnc_CortexLocality.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_resume",[],[[]]]];
private _leader = leader _group;
private _resuming = count _resume == 7 && {(_resume select 0) == "INFANTRY"};
private _enemyPos = if (_resuming) then {_resume select 3} else {_state getOrDefault ["enemyPos", []]};
if (count _enemyPos < 2) exitWith {false};
private _distance = (missionNamespace getVariable ["Waldo_AIPass_Morale_RetreatDistance", 200]) * ([_group, "retreatScale"] call Waldo_fnc_CortexProfile);
private _away = _enemyPos getDir _leader;
private _point = if (_resuming) then {+(_resume select 2)} else {[]};
if (!_resuming) then {
    private _origin=getPosATL _leader;
    private _candidates=[];
    {
        _candidates pushBack [_origin getPos [_distance, _away+_x]];
    } forEach [0, 30, -30, 60, -60];
    private _legs=[_origin,_candidates,_enemyPos] call Waldo_fnc_CortexSelectAvenue;
    // Coastlines, islands and flooded terrain can invalidate every ideal endpoint. Search
    // progressively shorter rings in all directions; this remains bounded and only runs when a
    // morale transition starts. It never teleports the group or pretends that travel occurred.
    if (_legs isEqualTo []) then {
        {
            private _fallbackDistance=_distance*_x;
            private _fallbackCandidates=[];
            {
                _fallbackCandidates pushBack [_origin getPos [_fallbackDistance,_away+_x]];
            } forEach [0,45,-45,90,-90,135,-135,180];
            _legs=[_origin,_fallbackCandidates,_enemyPos] call Waldo_fnc_CortexSelectAvenue;
            if (_legs isNotEqualTo []) exitWith {};
        } forEach [0.75,0.5,0.25];
    };
    if (_legs isNotEqualTo []) then {_point=+(_legs select ((count _legs)-1))};
};
if (_point isEqualTo []) exitWith {
    _group setVariable ["Waldo_Cortex_Withdrawal",["BLOCKED",0,0],true];
    false
};
// Finish any manoeuvre before acquiring its attack-setting restoration record.
if (count (_state getOrDefault ["drill",createHashMap]) > 0) then {
    [_group,_state,"RETREAT"] call Waldo_fnc_CortexFlankEnd;
};
// Withdrawals, calm restoration and external handovers retire the shared assignment.
private _supportLease=_group getVariable ["Waldo_AIPass_SupportLease",[]];
if (count _supportLease == 6 && {(_state getOrDefault ["supportToken",""]) == (_supportLease select 0)}) then {
    [_group,_supportLease select 0,false,_supportLease,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAck",2];
};
[_group,"SUPPORT",false] call Waldo_fnc_CortexLambsLease;
private _remainingLease=(120-((serverTime-(if (_resuming) then {_resume select 4} else {serverTime})) max 0)) max 3;
if !([_group,"INFANTRY_WITHDRAW",true,serverTime+_remainingLease] call Waldo_fnc_CortexLambsLease) exitWith {
    _group setVariable ["Waldo_Cortex_Withdrawal",["EXTERNAL_BUSY",0,0],true];
    false
};
private _supportHeld=_state getOrDefault ["supportHeld",[]];
{
    if (_x getVariable ["Waldo_Cortex_SupportPathHold",false]) then {_supportHeld pushBackUnique _x};
} forEach units _group;
{
    if (local _x && {group _x == _group}) then {
        _x enableAI "PATH";
        _x setVariable ["Waldo_Cortex_SupportPathHold",nil,true];
        // supportHeld is an explicit Cortex ownership record. A withdrawal replaces that
        // hold with a group route, so every surviving member must rejoin the leader first.
        _x doFollow _leader;
    };
} forEach _supportHeld;
{_state deleteAt _x} forEach ["supportHeld","supportBoundSequence","supportToken","responding","assaulting","respondingTo","respondUntil"];
if (!("baseAttack" in _state)) then {
    _state set ["baseAttack",attackEnabled _group];
    _state set ["attackChanged",attackEnabled _group];
};
_group enableAttack false;
// RED grants the engine independent pursuit authority, which can replace the finite retreat
// waypoint while the smoke layer still runs. YELLOW retains fire-at-will and formation movement.
// Record both the previous and applied values so cleanup only restores a mode Cortex still owns.
if (combatMode _group == "RED" && {!("retreatCombatMode" in _state)}) then {
    _state set ["retreatCombatMode",["RED","YELLOW"]];
    _group setCombatMode "YELLOW";
};
// A withdrawal must leave individual attack manoeuvres and combat formation planning.
// Normal weapon engagement remains available; calm/release restores captured settings.
if (behaviour _leader != "AWARE") then {
    if !(_state getOrDefault ["behaviourChanged",false]) then {_state set ["baseBehaviour",behaviour _leader]};
    _state set ["behaviourChanged",true];
    _group setBehaviour "AWARE";
};
[_group, _point, 30] call Waldo_fnc_CortexGroupMove;
private _origin = if (_resuming) then {+(_resume select 1)} else {getPosATL _leader};
private _startedAt = if (_resuming) then {_resume select 4} else {serverTime};
private _replans = if (_resuming) then {_resume select 5} else {0};
private _bestTravel = if (_resuming) then {_resume select 6} else {0};
private _elapsed = (serverTime-_startedAt) max 0;
private _remaining = (120-_elapsed) max 3;
_state set ["movementLease",["INFANTRY_WITHDRAW",time+_remaining]];
_state set ["retreatStart",_origin];
_state set ["retreatTarget",_point];
_state set ["retreatProgress",[time,_bestTravel,_replans]];
_group setVariable ["Waldo_Cortex_Withdrawal",["MOVING",round (_leader distance2D _origin),_replans],true];
private _withdrawalIntent=["INFANTRY",_origin,_point,_enemyPos,_startedAt,_replans,_bestTravel];
_group setVariable ["Waldo_Cortex_WithdrawalIntent",_withdrawalIntent,true];
if (speedMode _group != "FULL") then {
    if !(_state getOrDefault ["speedChanged", false]) then {_state set ["baseSpeed", speedMode _group]};
    _state set ["speedChanged", true];
    _group setSpeedMode "FULL";
};
{if (alive _x && {local _x}) then {_x doFollow _leader}} forEach (_state getOrDefault ["holders", []]);
_state set ["holders", []];
if (!_resuming) then {
    private _smokers = (units _group) select {alive _x && {local _x} && {vehicle _x == _x}};
    // Preserve the leader's route ownership when another survivor can throw the screen.
    _smokers=(_smokers select {_x != _leader})+(_smokers select {_x == _leader});
    // Use one available carried smoke, rather than selecting a possibly empty carrier.
    private _smoker=objNull;
    {
        if ([_x, _enemyPos, "SMOKE"] call Waldo_fnc_CortexThrowGrenade) exitWith {_smoker=_x};
    } forEach _smokers;
    if (!isNull _smoker) then {
        [{
            params ["_group","_smoker","_target","_intent"];
            if (isNull _group || {!local _group} || {!alive _smoker} || {group _smoker != _group}
                || {(_group getVariable ["Waldo_Cortex_WithdrawalIntent",[]]) isNotEqualTo _intent}
                || {(_group getVariable ["Waldo_AIPass_ZeusHold",[]]) isNotEqualTo []}) exitWith {};
            private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
            private _lease=_state getOrDefault ["movementLease",[]];
            if ((_state getOrDefault ["phase",""]) == "RETREAT" && {count _lease == 2}
                && {(_lease select 0) == "INFANTRY_WITHDRAW"} && {time < (_lease select 1)}) then {
                if (_smoker == leader _group) then {_smoker doMove _target} else {_smoker doFollow leader _group};
            };
        },[_group,_smoker,+_point,+_withdrawalIntent],2] call CBA_fnc_waitAndExecute;
    };
    // A communicating retreating squad asks server-coordinated artillery for smoke; no radio item is required.
    if ((missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false]) && {[_group,"Waldo_AIPass_ArtillerySmoke_Enable", true] call Waldo_fnc_CortexFeatureEnabled}
        && {[_leader] call Waldo_fnc_CortexCanTransmit}) then {
        private _screen = _enemyPos getPos [((_enemyPos distance2D _leader) * 0.4) min 80, _enemyPos getDir _leader];
        private _side = side _group;
        private _friendlyNear = (_screen nearEntities [["CAManBase", "LandVehicle"], 50]) findIf {
            private _otherSide = side group _x;
            alive _x && {_otherSide == civilian || {_side getFriend _otherSide >= 0.6}}
        } >= 0;
        if (!_friendlyNear) then {
            [objNull,_screen,0,"SMOKE",-1,-1,"SUPPORT",objNull,objNull,_group] call Waldo_fnc_CortexArtilleryFire;
        };
    };
};
[_group,_state,"RETREAT",["MORALE_WITHDRAWAL","OWNERSHIP_RESUME"] select _resuming,time-_elapsed,_resuming] call Waldo_fnc_CortexSetPhase;
if (!_resuming) then {missionNamespace setVariable ["Waldo_AIPass_Retreats", (missionNamespace getVariable ["Waldo_AIPass_Retreats", 0]) + 1]};
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {diag_log format ["[WMP CORTEX] %1 RETREAT to %2", _group, _point]};
true
