/*
 * Author: WaldoTheWarfighter
 * Decides whether a squad in contact should flank, and if so plans the manoeuvre.
 *
 * Base of fire and manoeuvre uses multiple movement bounds. The leader, machine gunners and anti-tank gunners stay as the base of fire,
 * which Waldo_fnc_CortexFireControl uses to suppress. Up to half the squad (2-5 riflemen) becomes
 * the manoeuvre element. Candidate two-leg routes are sampled against the firing corridors from the
 * squad's own base of fire and at most four nearby friendly squads which are actually in CONTACT
 * or assigned a coordinated COVER role. Merely knowing about the target does not create a firing
 * corridor. Cortex chooses a side and
 * width that stays outside a 30 m firing corridor and, when it begins clearly on one side of another
 * supporting squad's fire axis, remains on that side. All six bounded candidates are scored once at start;
 * fixed geometry samples reward terrain and solid objects which screen the manoeuvre from the
 * objective. If neither side is safe the flank is cancelled rather than sending troops across
 * friendly fire. Each accepted leg is cut into bounds by
 * Waldo_fnc_CortexPlanRoute. Where a leg crosses a road
 * (Waldo_AIPass_StreetCrossing_Enable), the route stops at the near edge, throws smoke and crosses in
 * one bound to the far edge. Legs over water switch to the other flank or cancel the drill. When the
 * element reaches its flanking position it may go on to a final assault (Waldo_fnc_CortexFlankStep).
 * Gates: infantry squad of at least Waldo_AIPass_Flank_MinGroupSize with 60% of its peak strength,
 * morale STEADY, a seen enemy between Waldo_AIPass_Flank_MinRange and MaxRange, no drill running, no
 * cooldown. Waldo_fnc_CortexTacticalStart chooses from the live authored-order/contact context and
 * calls this deterministic viability/start function, so a profile or failed random roll cannot idle
 * an otherwise capable squad.
 * Actors completing a short grenade-evasion or anti-armour relocation lease are omitted from the
 * new element rather than having their destination replaced.
 * Locality and authority: call where the group is local. The drill runs as its own scheduler job.
 *
 * Repeat/JIP: a running drill, shared movement lease or cooldown refuses duplicate starts; owner
 * migration retires local jobs. Each start gives its queued step a unique drill token and publishes
 * a rolling TACTICAL_DRILL lease so another feature cannot replace its direct actor movement.
 * The drill heartbeat lets GroupTick restore every owned engine setting if its scheduler job stalls.
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: enemies <ARRAY> - from Waldo_fnc_CortexKnowledge
 *
 * Return Value:
 * Boolean - true when a drill started
 *
 * Example:
 * [_group, _state, _enemies] call Waldo_fnc_CortexFlankStart;
 * Result: half the squad moves round the enemy's flank in covered bounds while the rest suppresses.
 *
 * Support integration: active reinforcement/assault responders decline new drills until released.
 * Current caller: Waldo_fnc_CortexTacticalStart.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
private _refuse={
    params ["_reason",["_detail",[]]];
    private _previous=_group getVariable ["Waldo_Cortex_FlankRefusal",[]];
    if ((_previous param [0,""]) != _reason) then {
        _group setVariable ["Waldo_Cortex_FlankRefusal",[_reason,serverTime,_detail],true];
    };
    false
};
// A live support assignment owns group movement until release; do not split its
// responders into a competing local drill when they acquire contact.
if (_state getOrDefault ["responding", false] || {_state getOrDefault ["assaulting", false]}) exitWith {["SUPPORT_OWNS_MOVEMENT"] call _refuse};
private _movementLease = _state getOrDefault ["movementLease",[]];
if (count _movementLease == 2 && {time < (_movementLease select 1)}) exitWith {["MOVEMENT_LEASE",_movementLease] call _refuse};
if (count (_state getOrDefault ["drill", createHashMap]) > 0) exitWith {["DRILL_ACTIVE"] call _refuse};
if ([_state, "flank"] call Waldo_fnc_CortexCooldown) exitWith {["COOLDOWN"] call _refuse};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {["MORALE",[_state getOrDefault ["moraleState","UNKNOWN"]]] call _refuse};
private _leader = leader _group;
if (vehicle _leader != _leader) exitWith {["LEADER_MOUNTED"] call _refuse};
private _onFoot = (units _group) select {
    private _actorMove = _x getVariable ["Waldo_Cortex_ActorMove",[]];
    alive _x && {local _x} && {vehicle _x == _x} && {_x checkAIFeature "PATH"} && {_x checkAIFeature "MOVE"}
        && {count _actorMove != 3 || {time >= (_actorMove select 2)}}
};
if (count _onFoot < (missionNamespace getVariable ["Waldo_AIPass_Flank_MinGroupSize", 6])) exitWith {["INSUFFICIENT_ACTORS",[count _onFoot]] call _refuse};
if (count _onFoot / ((_group getVariable ["Waldo_AIPass_PeakSize", count _onFoot]) max 1) < 0.6) exitWith {["CASUALTY_STRENGTH",[count _onFoot,_group getVariable ["Waldo_AIPass_PeakSize",count _onFoot]]] call _refuse};
private _targetIndex = _enemies findIf {
    (_x select 2) <= 15
    && {(_x select 3) >= (missionNamespace getVariable ["Waldo_AIPass_Flank_MinRange", 60])}
    && {(_x select 3) <= (missionNamespace getVariable ["Waldo_AIPass_Flank_MaxRange", 400])}
};
if (_targetIndex < 0) exitWith {["NO_TARGET_IN_RANGE",[_enemies apply {_x select [2,2]}]] call _refuse};
private _target = (_enemies select _targetIndex) select 0;
private _enemyPos = (_enemies select _targetIndex) select 1;
private _distance = (_enemies select _targetIndex) select 3;
private _riflemen = _onFoot select {_x != _leader && {!(([_x] call Waldo_fnc_CortexUnitRole) in ["MG", "AT", "LEADER"])}};
private _candidates = [];
{_candidates pushBack [_x distance2D _leader, _forEachIndex]} forEach _riflemen;
_candidates sort true;
private _size = ((floor (count _onFoot / 2)) min 5) min count _candidates;
if (_size < 2) exitWith {[_state, "flank", 30] call Waldo_fnc_CortexCooldown; ["NO_MANOEUVRE_ELEMENT",[count _riflemen]] call _refuse};
private _element = (_candidates select [0, _size]) apply {_riflemen select (_x select 1)};

private _start = [0, 0, 0];
{_start = _start vectorAdd getPosATL _x} forEach _element;
_start = _start vectorMultiply (1 / count _element);
private _base = _onFoot - _element;
private _supportOrigins = [];
private _supportCandidates = [];
if (_base isNotEqualTo []) then {
    private _origin = [0,0,0];
    {_origin = _origin vectorAdd getPosATL _x} forEach _base;
    _supportOrigins pushBack (_origin vectorMultiply (1/count _base));
};
{
    private _friendlyGroup = _x;
    private _friendlyLeader = leader _friendlyGroup;
    private _supportRole = _friendlyGroup getVariable ["Waldo_Cortex_SupportRole",[]];
    private _activeSupport = (_friendlyGroup getVariable ["Waldo_AIPass_PublicPhase","CALM"]) == "CONTACT"
        || {count _supportRole == 5 && {(_supportRole select 2) == "COVER"}};
    if (_friendlyGroup != _group && {!isNull _friendlyLeader} && {alive _friendlyLeader}
        && {_activeSupport}
        && {(side _group) getFriend (side _friendlyGroup) >= 0.6}
        && {_friendlyLeader distance2D _enemyPos < 500}
        && {_friendlyLeader knowsAbout _target > 0.5}) then {
        private _friendlyFoot = (units _friendlyGroup) select {alive _x && {vehicle _x == _x}};
        if (_friendlyFoot isNotEqualTo []) then {
            private _origin = [0,0,0];
            {_origin = _origin vectorAdd getPosATL _x} forEach _friendlyFoot;
            _supportCandidates pushBack [
                _friendlyLeader distance2D _enemyPos,
                count _supportCandidates,
                _origin vectorMultiply (1/count _friendlyFoot)
            ];
        };
    };
} forEach allGroups;
_supportCandidates sort true;
{
    _supportOrigins pushBack (_x select 2);
} forEach (_supportCandidates select [0,(count _supportCandidates) min 4]);

// Generate six bounded flank shapes. The shared selector rejects water, support-lane crossings and
// side changes while preferring terrain or object screening. It evaluates this fixed set once.
private _toGroup = _enemyPos getDir _leader;
private _avenueCandidates=[];
{
    _x params ["_side","_wideAngle","_closeAngle"];
    private _wide = _enemyPos getPos [(_distance * 0.8) max 60, _toGroup + _side*_wideAngle];
    private _close = _enemyPos getPos [((_distance * 0.35) max 35) min 60, _toGroup + _side*_closeAngle];
    _avenueCandidates pushBack [_wide,_close];
} forEach [[1,70,60],[-1,70,60],[1,90,75],[-1,90,75],[1,110,90],[-1,110,90]];
private _legs=[_start,_avenueCandidates,_enemyPos,_supportOrigins,_target] call Waldo_fnc_CortexSelectAvenue;
if (_legs isEqualTo []) exitWith {[_state, "flank", 30] call Waldo_fnc_CortexCooldown; ["NO_SAFE_AVENUE",[_start,_enemyPos,_supportOrigins]] call _refuse};

private _points = [_start, _legs, "FINAL", _group] call Waldo_fnc_CortexPlanRoute;

// Keep native target sharing and engagement available to the covering element.
// CortexFlankStep leases pursuit features only from the soldiers currently moving;
// disabling attack assignment for the whole squad made its base of fire inert.
private _serial = (missionNamespace getVariable ["Waldo_Cortex_DrillSerial",0]) + 1;
missionNamespace setVariable ["Waldo_Cortex_DrillSerial",_serial];
private _token = format ["%1:%2",clientOwner,_serial];
_group setVariable ["Waldo_Cortex_DrillResult",[],true];
_group setVariable ["Waldo_Cortex_DrillFailure",[],true];
_group setVariable ["Waldo_Cortex_DrillReinforcements",[],true];
_state set ["drill", createHashMapFromArray [
    ["token",_token],["target",(_enemies select _targetIndex) select 0],
    ["type", "FLANK"], ["units", _element], ["desiredStrength",count _element], ["points", _points], ["index", 0], ["stage", ""], ["enemyPos", _enemyPos],
    ["disabled", []], ["spots", []], ["started", time], ["lastStep",time], ["boundStart", time], ["pauseUntil", 0]
]];
if !([_group,"TACTICAL_DRILL",true,serverTime+90] call Waldo_fnc_CortexLambsLease) exitWith {
    _state deleteAt "drill";
    ["EXTERNAL_MOVEMENT_BUSY"] call _refuse
};
[_group,_state get "drill","START","FLANK_ACCEPTED"] call Waldo_fnc_CortexDrillSetStage;
_group setVariable ["Waldo_Cortex_FlankRefusal",nil,true];
// The drill moves selected actors directly rather than adding a group waypoint.
// Publish that ownership so support, vehicles and artillery cannot replace it mid-bound.
_state set ["movementLease",["TACTICAL_DRILL",time+90]];
[Waldo_fnc_CortexFlankStep, createHashMapFromArray [["group", _group],["drillToken",_token]], 0] call Waldo_fnc_CortexQueueJob;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {
    diag_log format ["[WMP CORTEX] %1 FLANK element=%2 points=%3 crossings=%4", _group, count _element, count _points, {(_x select 1) == "CROSS_NEAR"} count _points];
};
true
