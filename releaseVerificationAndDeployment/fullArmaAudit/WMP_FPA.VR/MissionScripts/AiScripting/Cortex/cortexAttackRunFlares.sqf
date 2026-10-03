/*
 * Author: WaldoTheWarfighter
 * Releases countermeasure bursts while approaching and leaving an assigned attack target.
 * Locality/authority: aircraft owner only; never changes flight paths or target knowledge.
 * Repeat/JIP: one local scheduler job; public cooldown survives owner migration. No JIP effects.
 * Target discovery checks the effective commander, every operating crew member and every turret
 * assignment because helicopters commonly give the attack target to the gunner rather than pilot.
 * Arguments: 0: job <HASHMAP>, empty default; aircraft <OBJECT> is required.
 * Return: NUMBER, next sampling delay or -1 to retire.
 * Current callers: Waldo_fnc_CortexDiscover through the budgeted Cortex scheduler.
 * Example: [createHashMapFromArray [["aircraft",_plane]]] call Waldo_fnc_CortexAttackRunFlares;
 */
params [["_job",createHashMap,[createHashMap]]];
private _aircraft=_job getOrDefault ["aircraft",objNull];
if (isNull _aircraft) exitWith {-1};
private _pilot=driver _aircraft;
private _group=group _pilot;
private _allowed=local _aircraft && {alive _aircraft} && {!isNull _pilot} && {alive _pilot}
    && {!isPlayer _pilot} && {!unitIsUAV _aircraft}
    && {missionNamespace getVariable ["Waldo_AIPass_Active",false]}
    && {!([] call Waldo_fnc_CortexIsPaused)}
    && {[_group,"Waldo_Cortex_AttackRunFlares_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {[_group] call Waldo_fnc_CortexIsEligible || {[_aircraft] call Waldo_fnc_CortexAircraftEligible}};
if (!_allowed) exitWith {_aircraft setVariable ["Waldo_Cortex_AttackFlareJob",false]; -1};
// The adaptive attack controller owns approach/departure bursts while it holds a finite plan.
// Keeping this sampler idle avoids duplicate releases without removing its fallback coverage.
if !((_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo []) exitWith {1};
if (isTouchingGround _aircraft || {speed _aircraft < 40}) exitWith {_job deleteAt "target"; _job deleteAt "burst"; 1};
if (combatMode _group in ["BLUE","GREEN"]) exitWith {_job deleteAt "target"; _job deleteAt "burst"; 1};
private _target=_job getOrDefault ["target",objNull];
if (isNull _target) then {
    private _targetOwners=[];
    {
        if (!isNull _x && {alive _x}) then {_targetOwners pushBackUnique _x};
    } forEach ([effectiveCommander _aircraft,driver _aircraft,gunner _aircraft,commander _aircraft]+crew _aircraft);
    {
        private _candidate=assignedTarget _x;
        if (!isNull _candidate && {alive _candidate}
            && {(side _group) getFriend (side _candidate) < 0.6}) exitWith {_target=_candidate};
    } forEach _targetOwners;
    if (isNull _target || {!alive _target} || {(side _group) getFriend (side _target) >= 0.6}) exitWith {};
    private _offset=(getPosASL _target) vectorDiff (getPosASL _aircraft);
    if (vectorMagnitude _offset <= 1500 && {(velocity _aircraft) vectorDotProduct _offset > 0}
        && {serverTime >= (_aircraft getVariable ["Waldo_Cortex_AttackFlareCooldown",0])}) then {
        _job set ["target",_target];
        _job set ["expires",serverTime+90];
        _job set ["closest",_aircraft distance _target];
        _job set ["burst",3];
        _job set ["burstExpires",serverTime+8];
        _job set ["burstNext",serverTime];
        _aircraft setVariable ["Waldo_Cortex_AttackFlareCooldown",serverTime+30,true];
        _aircraft setVariable ["Waldo_Cortex_AttackFlarePhase","APPROACH",true];
    };
} else {
    private _distance=_aircraft distance _target;
    private _closest=_job getOrDefault ["closest",_distance];
    _job set ["closest",_closest min _distance];
    if (_distance > _closest+100 && {(velocity _aircraft) vectorDotProduct ((getPosASL _target) vectorDiff (getPosASL _aircraft)) < 0}) then {
        _job set ["burst",3];
        _job set ["burstExpires",serverTime+8];
        _job set ["burstNext",serverTime];
        _job deleteAt "target";
        _aircraft setVariable ["Waldo_Cortex_AttackFlareCooldown",serverTime+30,true];
        _aircraft setVariable ["Waldo_Cortex_AttackFlarePhase","DEPARTURE",true];
    } else {
        if (serverTime > (_job getOrDefault ["expires",0])) then {_job deleteAt "target"};
    };
};
private _burst=_job getOrDefault ["burst",0];
if (_burst > 0 && {serverTime <= (_job getOrDefault ["burstExpires",serverTime])}
    && {serverTime >= (_job getOrDefault ["burstNext",0])}) then {
    // A launcher may reject a request while cycling. Count only an actual release; bounded retries
    // keep fast jets from silently spending their whole departure burst between scheduler samples.
    if ([_aircraft] call Waldo_fnc_CortexFireCountermeasure) then {
        _job set ["burst",_burst-1];
    };
    _job set ["burstNext",serverTime+0.8+random 0.8];
};
if (_burst > 0 && {serverTime > (_job getOrDefault ["burstExpires",serverTime])}) then {
    _job set ["burst",0];
};
1
