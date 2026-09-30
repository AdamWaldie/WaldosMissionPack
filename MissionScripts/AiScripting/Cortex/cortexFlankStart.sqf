/*
 * Author: WaldoTheWarfighter
 * Decides whether a squad in contact should flank, and if so plans the manoeuvre.
 *
 * Base of fire and manoeuvre uses multiple movement bounds. The leader, machine gunners and anti-tank gunners stay as the base of fire,
 * which Waldo_fnc_CortexFireControl uses to suppress. Up to half the squad (2-5 riflemen) becomes
 * the manoeuvre element. Candidate two-leg routes are sampled against the firing corridors from the
 * squad's own base of fire and nearby friendly squads to the objective. Cortex chooses a side and
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
 * cooldown, and a roll against the group's behaviour profile flankChance (Waldo_fnc_CortexProfile; a
 * failed roll waits 30 s).
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
 * Current caller: Waldo_fnc_CortexGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_enemies", [], [[]]]];
// A live support assignment owns group movement until release; do not split its
// responders into a competing local drill when they acquire contact.
if (_state getOrDefault ["responding", false] || {_state getOrDefault ["assaulting", false]}) exitWith {false};
private _movementLease = _state getOrDefault ["movementLease",[]];
if (count _movementLease == 2 && {time < (_movementLease select 1)}) exitWith {false};
if (count (_state getOrDefault ["drill", createHashMap]) > 0) exitWith {false};
if ([_state, "flank"] call Waldo_fnc_CortexCooldown) exitWith {false};
if ((_state getOrDefault ["moraleState", "STEADY"]) != "STEADY") exitWith {false};
private _leader = leader _group;
if (vehicle _leader != _leader) exitWith {false};
private _onFoot = (units _group) select {
    private _actorMove = _x getVariable ["Waldo_Cortex_ActorMove",[]];
    alive _x && {local _x} && {vehicle _x == _x} && {_x checkAIFeature "PATH"} && {_x checkAIFeature "MOVE"}
        && {count _actorMove != 3 || {time >= (_actorMove select 2)}}
};
if (count _onFoot < (missionNamespace getVariable ["Waldo_AIPass_Flank_MinGroupSize", 6])) exitWith {false};
if (count _onFoot / ((_group getVariable ["Waldo_AIPass_PeakSize", count _onFoot]) max 1) < 0.6) exitWith {false};
private _targetIndex = _enemies findIf {
    (_x select 2) <= 15
    && {(_x select 3) >= (missionNamespace getVariable ["Waldo_AIPass_Flank_MinRange", 60])}
    && {(_x select 3) <= (missionNamespace getVariable ["Waldo_AIPass_Flank_MaxRange", 400])}
};
if (_targetIndex < 0) exitWith {false};
if (random 1 >= ([_group, "flankChance"] call Waldo_fnc_CortexProfile)) exitWith {
    [_state, "flank", 30] call Waldo_fnc_CortexCooldown;
    false
};

private _target = (_enemies select _targetIndex) select 0;
private _enemyPos = (_enemies select _targetIndex) select 1;
private _distance = (_enemies select _targetIndex) select 3;
private _riflemen = _onFoot select {_x != _leader && {!(([_x] call Waldo_fnc_CortexUnitRole) in ["MG", "AT", "LEADER"])}};
private _candidates = [];
{_candidates pushBack [_x distance2D _leader, _forEachIndex]} forEach _riflemen;
_candidates sort true;
private _size = ((floor (count _onFoot / 2)) min 5) min count _candidates;
if (_size < 2) exitWith {[_state, "flank", 30] call Waldo_fnc_CortexCooldown; false};
private _element = (_candidates select [0, _size]) apply {_riflemen select (_x select 1)};

private _start = [0, 0, 0];
{_start = _start vectorAdd getPosATL _x} forEach _element;
_start = _start vectorMultiply (1 / count _element);
private _base = _onFoot - _element;
private _supportOrigins = [];
if (_base isNotEqualTo []) then {
    private _origin = [0,0,0];
    {_origin = _origin vectorAdd getPosATL _x} forEach _base;
    _supportOrigins pushBack (_origin vectorMultiply (1/count _base));
};
{
    private _friendlyGroup = _x;
    private _friendlyLeader = leader _friendlyGroup;
    if (_friendlyGroup != _group && {!isNull _friendlyLeader} && {alive _friendlyLeader}
        && {(side _group) getFriend (side _friendlyGroup) >= 0.6}
        && {_friendlyLeader distance2D _enemyPos < 500}
        && {_friendlyLeader knowsAbout _target > 0.5}) then {
        private _friendlyFoot = (units _friendlyGroup) select {alive _x && {vehicle _x == _x}};
        if (_friendlyFoot isNotEqualTo []) then {
            private _origin = [0,0,0];
            {_origin = _origin vectorAdd getPosATL _x} forEach _friendlyFoot;
            _supportOrigins pushBack (_origin vectorMultiply (1/count _friendlyFoot));
        };
    };
} forEach allGroups;

// Sample actual candidate legs rather than choosing a random flank. A route is unsafe when a point
// more than 10 m from its own start lies inside the 30 m-wide firing lane between friendly support
// and the objective. Wider candidates are tried as well, so cancellation is the last resort.
private _crossesFireLane = {
    params ["_route"];
    private _unsafe = false;
    private _from = _start;
    {
        private _to = _x;
        private _legLength = _from distance2D _to;
        private _samples = (ceil (_legLength/5)) max 1;
        for "_sampleIndex" from 1 to _samples do {
            private _fraction = _sampleIndex/_samples;
            private _point = [
                (_from select 0)+((_to select 0)-(_from select 0))*_fraction,
                (_from select 1)+((_to select 1)-(_from select 1))*_fraction,
                0
            ];
            if (_point distance2D _start > 10) then {
                {
                    private _support = _x;
                    private _laneX = (_enemyPos select 0)-(_support select 0);
                    private _laneY = (_enemyPos select 1)-(_support select 1);
                    private _laneLength = sqrt (_laneX*_laneX+_laneY*_laneY);
                    if (_laneLength > 40) then {
                        private _pointX = (_point select 0)-(_support select 0);
                        private _pointY = (_point select 1)-(_support select 1);
                        private _along = (_pointX*_laneX+_pointY*_laneY)/_laneLength;
                        private _lateral = abs (_pointX*_laneY-_pointY*_laneX)/_laneLength;
                        if (_along > 10 && {_along < _laneLength-10} && {_lateral < 30}) exitWith {_unsafe = true};
                    };
                } forEach _supportOrigins;
            };
            if (_unsafe) exitWith {};
        };
        if (_unsafe) exitWith {};
        _from = _to;
    } forEach _route;
    _unsafe
};
// Do not select a geometrically valid endpoint by crossing from one side of a supporting
// squad's active fire axis to the other. The own base of fire begins almost on the element,
// so a side lock applies only when the manoeuvre starts at least 30 m off an axis.
private _staysOnSupportSide = {
    params ["_route"];
    private _safe = true;
    {
        private _support = _x;
        private _laneX = (_enemyPos select 0)-(_support select 0);
        private _laneY = (_enemyPos select 1)-(_support select 1);
        private _laneLength = sqrt (_laneX*_laneX+_laneY*_laneY);
        if (_laneLength > 40) then {
            private _startX = (_start select 0)-(_support select 0);
            private _startY = (_start select 1)-(_support select 1);
            private _startSide = (_laneX*_startY-_laneY*_startX)/_laneLength;
            if (abs _startSide >= 30 && {_route findIf {
                private _pointX = (_x select 0)-(_support select 0);
                private _pointY = (_x select 1)-(_support select 1);
                private _pointSide = (_laneX*_pointY-_laneY*_pointX)/_laneLength;
                abs _pointSide >= 10 && {_pointSide*_startSide < 0}
            } >= 0}) then {_safe = false};
        };
        if (!_safe) exitWith {};
    } forEach _supportOrigins;
    _safe
};
private _toGroup = _enemyPos getDir _leader;
private _legs = [];
private _bestScore = 1e9;
private _routeProtection = {
    params ["_route"];
    private _protected = 0;
    private _enemyASL = (getPosASL _target) vectorAdd [0,0,1.4];
    private _from = _start;
    {
        private _to = _x;
        {
            private _sample = [
                (_from select 0)+((_to select 0)-(_from select 0))*_x,
                (_from select 1)+((_to select 1)-(_from select 1))*_x,
                0
            ];
            private _sampleASL = (AGLToASL _sample) vectorAdd [0,0,1.0];
            private _rayStart = _enemyASL vectorAdd ((_enemyASL vectorFromTo _sampleASL) vectorMultiply 2);
            if (terrainIntersectASL [_enemyASL,_sampleASL]
                || {(lineIntersectsSurfaces [_rayStart,_sampleASL,_target,objNull,true,1,"FIRE","GEOM"]) isNotEqualTo []}) then {
                _protected = _protected+1;
            };
        } forEach [0.25,0.5,0.75];
        _from = _to;
    } forEach _route;
    _protected
};
{
    _x params ["_side","_wideAngle","_closeAngle"];
    private _wide = _enemyPos getPos [(_distance * 0.8) max 60, _toGroup + _side*_wideAngle];
    private _close = _enemyPos getPos [((_distance * 0.35) max 35) min 60, _toGroup + _side*_closeAngle];
    private _candidate = [_wide,_close];
    if (!surfaceIsWater _wide && {!surfaceIsWater _close}
        && {!([_candidate] call _crossesFireLane)} && {[_candidate] call _staysOnSupportSide}) then {
        private _routeLength = (_start distance2D _wide)+(_wide distance2D _close);
        // Each screened sample offsets 20 m of route length. The candidate/sample counts
        // are fixed, so cover preference cannot become a hot scheduler loop.
        private _score = _routeLength-20*([_candidate] call _routeProtection);
        if (_score < _bestScore) then {_legs = _candidate; _bestScore = _score};
    };
} forEach [[1,70,60],[-1,70,60],[1,90,75],[-1,90,75],[1,110,90],[-1,110,90]];
if (_legs isEqualTo []) exitWith {[_state, "flank", 30] call Waldo_fnc_CortexCooldown; false};

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
    ["type", "FLANK"], ["units", _element], ["desiredStrength",count _element], ["points", _points], ["index", 0], ["stage", "START"], ["enemyPos", _enemyPos],
    ["disabled", []], ["spots", []], ["started", time], ["lastStep",time], ["boundStart", time], ["pauseUntil", 0]
]];
// The drill moves selected actors directly rather than adding a group waypoint.
// Publish that ownership so support, vehicles and artillery cannot replace it mid-bound.
_state set ["movementLease",["TACTICAL_DRILL",time+90]];
[Waldo_fnc_CortexFlankStep, createHashMapFromArray [["group", _group],["drillToken",_token]], 0] call Waldo_fnc_CortexQueueJob;
if (missionNamespace getVariable ["Waldo_AIPass_Debug", false]) then {
    diag_log format ["[WMP CORTEX] %1 FLANK element=%2 points=%3 crossings=%4", _group, count _element, count _points, {(_x select 1) == "CROSS_NEAR"} count _points];
};
true
