/*
 * Author: WaldoTheWarfighter
 * Drives mixed convoys along each predecessor trail, detects arrival and requests a persistent halt after pinned contact.
 * Locality/authority: server owns phase; group owner drives and reports, each cargo/turret owner applies crew work.
 * Spacing uses a size-aware target with a 20 percent tolerance band (at least 3 m).
 * Aligned vehicles use forward separation, so lateral spread cannot satisfy the gap and stabilize a wedge.
 * Speed corrects toward the target; the tolerance band bounds catch-up and stronger close-gap braking.
 * Acceleration is bounded; outside contact the lead slows to let stretched followers catch up.
 * Path refreshes do not repeatedly stop drivers, and tracked vehicles receive longer look-ahead targets.
 * A three-second lead-vehicle road sample anticipates sharp curves, junctions and grades. Speed changes
 * accelerate gradually while safety, contact, arrival and close-gap braking remain immediate.
 * The route watchdog remembers only the unchanged final MOVE waypoint. If the engine marks it complete
 * more than 75 m early, the same waypoint is selected again; no waypoint is synthesized or rewritten.
 * Repeat/JIP: ordered snapshots carry phase/cargo/baselines; a five-second contact checkpoint survives HC migration.
 * Arguments: 0: group <GROUP>; 1: configuration <ARRAY> [revision, km/h, gap, pushThrough, vehicles, phase, cargo, restore, halt reason, believed threat ATL, expiry].
 * Return Value: Nothing.
 * Current callers: single round-robin ConvoySync worker on server/headless clients.
 * Example: [_group, _configuration] call Waldo_fnc_ConvoyTick;
 */
params ["_group", "_configuration"];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {};
if (isNull _group) exitWith {};
_configuration params ["_revision", "_speed", "_separation", "_pushThrough", "_registered", "_phase", "_cargo", "_restore"];
if (time < (_group getVariable ["Waldo_Convoy_NextTick", -1])) exitWith {};
_group setVariable ["Waldo_Convoy_NextTick", time + 1];
private _state = _group getVariable ["Waldo_Convoy_LocalState", createHashMap];
private _paused = [] call Waldo_fnc_CortexIsPaused || {_group getVariable ["Waldo_AI_ExternalControl",false]} || {"ALL" in (_group getVariable ["Waldo_AIPass_DisabledFeatures",[]])};
private _playerCrew = _registered findIf {(crew _x) findIf {isPlayer _x || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner", objNull])}} >= 0} >= 0;
private _zeus = [_group] call Waldo_fnc_CortexZeusHeld;
if (_paused || {_playerCrew} || {_zeus}) exitWith {
    [_group,_configuration,true] call Waldo_fnc_ConvoyDismountLocal;
    if (!(_group getVariable ["Waldo_Convoy_Suspended", false])) then {
        [_group, false, _restore] call Waldo_fnc_ConvoyReleaseLocal;
        _group setVariable ["Waldo_Convoy_Suspended", true];
        if (local _group) then {_group setVariable ["Waldo_Convoy_ContactProgress", nil, true]};
    };
};
_group setVariable ["Waldo_Convoy_Suspended", false];
[_group, _configuration] call Waldo_fnc_ConvoyCrewLocal;
if (_phase == "HALT" || {!local _group}) exitWith {};
private _vehicles = _registered select {alive _x && {canMove _x} && {local _x} && {alive driver _x} && {local driver _x}
    && {group driver _x == _group} && {!((driver _x) getVariable ["ACE_isUnconscious", false])} && {lifeState driver _x != "INCAPACITATED"}};
// Do not treat temporary split locality as damage or arrival.
if (count _vehicles < count (_registered select {alive _x && {canMove _x} && {alive driver _x} && {group driver _x == _group}})) exitWith {};
if (_vehicles isEqualTo []) exitWith {
    if (time >= (_state getOrDefault ["haltRequest", -1])) then {
        [_group, _revision, "IMMOBILE"] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
        _state set ["haltRequest", time + 5];
        _group setVariable ["Waldo_Convoy_LocalState", _state];
    };
};
private _lead = _vehicles select 0;
if (!(vehicle leader _group in _vehicles)) then {_group selectLeader driver _lead};
if ((_state getOrDefault ["revision", -1]) != _revision || {(_state getOrDefault ["lead", objNull]) != _lead} || {_vehicles isNotEqualTo (_state getOrDefault ["vehicles", []])}) then {
    // A local halt/resume or speed edit must not discard the predecessor route.
    // Only a changed vehicle order or a new owner needs fresh trail acquisition.
    private _sameLine = _vehicles isEqualTo (_state getOrDefault ["vehicles",[]]);
    private _resumeTrails = if (_sameLine) then {_state getOrDefault ["frontTrails",createHashMap]} else {createHashMap};
    private _resumeFollowers = if (_sameLine) then {_state getOrDefault ["followers",createHashMap]} else {createHashMap};
    {private _v=_x; private _key=netId _v; private _record=_resumeFollowers getOrDefault [_key,[]]; if (_record isNotEqualTo []) then {_record set [0,getPosATL _v]; _record set [1,time]; _record set [2,-1]}} forEach _vehicles;
    // A revision alone does not relinquish driving authority to native formation.
    if (count _state > 0 && {!_sameLine}) then {[_group, false, _restore, _registered] call Waldo_fnc_ConvoyReleaseLocal};
    private _savedProgress = _group getVariable ["Waldo_Convoy_ContactProgress", []];
    private _progress = if (_savedProgress isNotEqualTo [] && {(_savedProgress select 0) == _revision}) then {+(_savedProgress select 1)} else {[]};
    _state = createHashMapFromArray [["revision", _revision], ["lead", _lead], ["frontTrails", _resumeTrails],
        ["heading", getDir _lead], ["vehicles", +_vehicles], ["followers", _resumeFollowers], ["speedLimits", createHashMap], ["contactProgress", _progress]];
    _group setVariable ["Waldo_Convoy_LocalState", _state];
    private _specs = createHashMap;
    {
        private _bounds = boundingBoxReal _x;
        _specs set [netId _x, [getNumber (configOf _x >> "maxSpeed"), abs (((_bounds select 1) select 1) - ((_bounds select 0) select 1))]];
    } forEach _vehicles;
    _state set ["specs", _specs];
    _group setFormation "COLUMN";
    // Vehicle movement remains a convoy task. Mounted gunners can fire without breaking formation.
    _group enableAttack false;
    // Clear a previous HALT doStop on the lead driver without deleting or replacing route waypoints.
    if (currentWaypoint _group < count waypoints _group) then {
        (driver _lead) doFollow leader _group;
    };
    {_x setUnloadInCombat [false, false]} forEach _vehicles;
    private _initialPathOwners=createHashMap;
    {
        if (_forEachIndex > 0) then {
            if (isAISteeringComponentEnabled _x) then {
                // Relinquish formation before the predecessor has recorded its first trail segment.
                // Waiting for a large gap lets native formation compress/overtake during startup.
                doStop driver _x;
                _initialPathOwners set [netId _x,true];
            } else {(driver _x) doFollow leader _group};
            _x setConvoySeparation _separation;
        };
    } forEach _vehicles;
    _state set ["pathOwners",_initialPathOwners];
};
// Active waypoints can change formation after initial setup. Enforce the convoy
// formation only while this owner controls travel; suspension above preserves Zeus control.
if (formation _group != "COLUMN") then {_group setFormation "COLUMN"};
// Query existing group knowledge at most every five seconds; never reveal hidden attackers.
if (time >= (_state getOrDefault ["contactDue", -1])) then {
    private _report = [];
    // A rear escort can be under fire while the lead vehicle has no endangered target.
    // One observer per vehicle, at most the registered 20 vehicles, every five seconds.
    {
        private _observer = gunner _x;
        if (isNull _observer || {!local _observer} || {!alive _observer}) then {_observer = driver _x};
        private _candidate = [_observer] call Waldo_fnc_ConvoyThreat;
        if (_candidate isNotEqualTo []) then {
            if (_report isEqualTo [] || {_candidate select 2}) then {_report = _candidate};
        };
        if (_report isNotEqualTo [] && {_report select 2}) exitWith {};
    } forEach _registered;
    private _contact = _report isNotEqualTo [] && {_report select 2};
    _contact = _contact || {_registered findIf {serverTime - (_x getVariable ["Waldo_Convoy_HitAt", -1e9]) <= 15} >= 0}
        || {(units _group) findIf {alive _x && {getSuppression _x > 0.2}} >= 0};
    _state set ["contact", _contact];
    _state set ["threat", if (_report isEqualTo []) then {[]} else {+(_report select 1)}];
    _state set ["contactDue", time + 5];
};
private _contact = _state getOrDefault ["contact", false];
private _pinned = false;
private _contactProgress = _state getOrDefault ["contactProgress", []];
if (_contact) then {
    {
        private _vehicle = _x;
        if (alive _vehicle) then {
            private _index = _contactProgress findIf {(_x select 0) == _vehicle};
            if (_index < 0) then {_contactProgress pushBack [_vehicle, getPosATL _vehicle, serverTime]; _index = count _contactProgress - 1};
            private _entry = _contactProgress select _index;
            if (_vehicle distance2D (_entry select 1) >= 3) then {_entry = [_vehicle, getPosATL _vehicle, serverTime]; _contactProgress set [_index, _entry]};
            if (serverTime - (_entry select 2) >= 15 && {abs speed _vehicle < 3}) then {_pinned = true};
        };
    } forEach _registered;
} else {_contactProgress = []};
_state set ["contactProgress", _contactProgress];
if (time >= (_state getOrDefault ["checkpointDue", -1])) then {
    private _checkpoint = [_revision, _contactProgress apply {+_x}];
    if (_checkpoint isNotEqualTo (_group getVariable ["Waldo_Convoy_ContactProgress", []])) then {_group setVariable ["Waldo_Convoy_ContactProgress", _checkpoint, true]};
    _state set ["checkpointDue", time + 5];
};
if (_contact && {!_pushThrough || {_pinned}} && {[_group,"Waldo_Convoy_ContactHalt_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) exitWith {
    if (time >= (_state getOrDefault ["haltRequest", -1])) then {
        [_group, _revision, "AMBUSH", _state getOrDefault ["threat", []]] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
        _state set ["haltRequest", time + 5];
    };
};
// Size-aware gaps prevent a long IFV and a truck from being treated like two short cars.
private _gaps = [0];
private _maximum = _speed;
private _specs = _state get "specs";
for "_i" from 0 to (count _vehicles - 1) do {
    private _vehicle = _vehicles select _i;
    private _topSpeed = (_specs get (netId _vehicle)) select 0;
    if (_topSpeed > 0) then {_maximum = _maximum min (_topSpeed * 0.8)};
    if (_i > 0) then {
        private _front = _vehicles select (_i - 1);
        private _lengths = ((_specs get (netId _vehicle)) select 1) + ((_specs get (netId _front)) select 1);
        _gaps pushBack (_separation max (_lengths * 0.5 + 5));
    };
};
private _lastWaypoint = [_group, (count waypoints _group) - 1];
if (count waypoints _group > 1 && {currentWaypoint _group < count waypoints _group}
    && {waypointType _lastWaypoint == "MOVE"}) then {
    _state set ["routeWatch",[(count waypoints _group)-1,waypointPosition _lastWaypoint,waypointCompletionRadius _lastWaypoint]];
};
private _routeWatch=_state getOrDefault ["routeWatch",[]];
if ([_group,"Waldo_Convoy_RouteRecovery_Enable",true] call Waldo_fnc_CortexFeatureEnabled
    && {_routeWatch isNotEqualTo []} && {currentWaypoint _group >= count waypoints _group}
    && {time >= (_state getOrDefault ["routeRecoveryAt",-1])}) then {
    _routeWatch params ["_watchedIndex","_watchedPosition","_watchedRadius"];
    // A Zeus edit changes or deletes the stored waypoint and therefore fails this identity check.
    // The Zeus suspension path above also clears local state before WMP may resume.
    if (_watchedIndex < count waypoints _group) then {
        private _watchedWaypoint=[_group,_watchedIndex];
        if (waypointType _watchedWaypoint == "MOVE"
            && {waypointPosition _watchedWaypoint distance2D _watchedPosition < 2}
            && {_lead distance2D _watchedPosition > (_watchedRadius max 20)+75}) then {
            _group setCurrentWaypoint _watchedWaypoint;
            (driver _lead) doMove _watchedPosition;
            _state set ["routeRecoveryAt",time+15];
            private _recoveries=(_group getVariable ["Waldo_Convoy_RouteRecoveries",0])+1;
            _group setVariable ["Waldo_Convoy_RouteRecoveries",_recoveries,true];
        };
    };
};
private _routeDone = count waypoints _group > 1 && {currentWaypoint _group >= count waypoints _group}
    && {_lead distance2D waypointPosition _lastWaypoint <= (waypointCompletionRadius _lastWaypoint max 20)};
private _settled = _routeDone && {_vehicles findIf {abs speed _x >= 1} < 0};
for "_i" from 1 to (count _vehicles - 1) do {
    if ((_vehicles select _i) distance2D (_vehicles select (_i - 1)) > (_gaps select _i) * 1.5) then {_settled = false};
};
if (!_settled) then {_state set ["arrivalAt", time + 5]};
if (_settled && {time >= (_state getOrDefault ["arrivalAt", time + 5])}) exitWith {
    if (time >= (_state getOrDefault ["haltRequest", -1])) then {
        [_group, _revision, "ARRIVED"] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
        _state set ["haltRequest", time + 5];
    };
};
if (isNil {_state get "arrivalAt"}) then {_state set ["arrivalAt", time + 5]};
// Record each predecessor's actual route. Followers must not converge on the group leader.
private _frontTrails = _state get "frontTrails";
{
    private _key = netId _x;
    private _record = _frontTrails getOrDefault [_key, [[getPosATL _x], 0]];
    private _trail = _record select 0;
    if ((_trail select (count _trail - 1)) distance2D _x >= 5) then {_trail pushBack getPosATL _x};
    if (count _trail > 128) then {
        private _remove = count _trail - 128;
        _trail deleteRange [0, _remove];
        _record set [1, (_record select 1) + _remove];
    };
    _frontTrails set [_key, _record];
} forEach _vehicles;
private _turn = abs (((getDir _lead - (_state get "heading") + 540) mod 360) - 180);
_state set ["heading", getDir _lead];
private _stretch = 0;
for "_i" from 1 to (count _vehicles - 1) do {
    private _follower=_vehicles select _i;
    private _front=_vehicles select (_i-1);
    private _pairGap=_follower distance2D _front;
    private _headingDifference=abs (((getDir _follower-getDir _front+540) mod 360)-180);
    // On a common heading, Euclidean distance rewards lateral spread: a 40 m
    // side-by-side offset looks like a perfect 40 m convoy gap. Measure the
    // forward component instead. Turning pairs retain normal distance so the
    // controller does not mistake a legitimate corner for compression.
    if (_headingDifference <= 25 && {_pairGap <= (_gaps select _i)*1.8}) then {
        private _direction=vectorDir _front;
        _direction set [2,0];
        private _delta=(getPosATL _front) vectorDiff (getPosATL _follower);
        _delta set [2,0];
        _pairGap=(_delta vectorDotProduct _direction) max 0;
    };
    _stretch = _stretch max (_pairGap / (_gaps select _i));
};
// One bounded road walk per convoy every three seconds is enough to anticipate geometry without
// multiplying raycasts or schedulers per vehicle. It influences speed only: Arma retains route
// choice, collision handling and the ability to remain stopped behind a deliberate roadblock.
private _roadCap = _maximum;
if ([_group,"Waldo_Convoy_DrivingAssist_Enable",true] call Waldo_fnc_CortexFeatureEnabled) then {
    if (time >= (_state getOrDefault ["roadLookAt",-1])) then {
        private _road = roadAt _lead;
        if (isNull _road) then {_road=(_lead nearRoads 8) param [0,objNull]};
        private _maximumTurn=0;
        private _maximumGrade=0;
        private _junction=false;
        if (!isNull _road) then {
            private _previousRoad=objNull;
            private _roadPosition=getPosATL _road;
            private _roadHeading=getDir _lead;
            private _travel=0;
            for "_sample" from 1 to 8 do {
                private _allConnected=roadsConnectedTo _road;
                if (count _allConnected >= 3) then {_junction=true};
                private _connected=_allConnected-[_previousRoad];
                private _nextRoad=objNull;
                private _bestTurn=181;
                {
                    private _candidateHeading=_roadPosition getDir _x;
                    private _candidateTurn=abs (((_candidateHeading-_roadHeading+540) mod 360)-180);
                    if (_candidateTurn < _bestTurn) then {_bestTurn=_candidateTurn; _nextRoad=_x};
                } forEach _connected;
                if (isNull _nextRoad || {_bestTurn > 110}) exitWith {};
                private _nextPosition=getPosATL _nextRoad;
                private _segment=_roadPosition distance2D _nextPosition;
                if (_segment < 1) exitWith {};
                _maximumTurn=_maximumTurn max _bestTurn;
                _maximumGrade=_maximumGrade max (abs ((_nextPosition select 2)-(_roadPosition select 2))/_segment);
                _travel=_travel+_segment;
                _roadHeading=_roadPosition getDir _nextPosition;
                _previousRoad=_road;
                _road=_nextRoad;
                _roadPosition=_nextPosition;
                if (_travel >= 70) exitWith {};
            };
        };
        _roadCap=if (_maximumTurn > 70) then {18} else {if (_maximumTurn > 45) then {25} else {if (_maximumTurn > 25) then {35} else {_maximum}}};
        if (_junction) then {_roadCap=_roadCap min 30};
        if (_maximumGrade > 0.2) then {_roadCap=_roadCap min 18} else {if (_maximumGrade > 0.12) then {_roadCap=_roadCap min 25}};
        _state set ["roadAssist",[_roadCap,_maximumTurn,_maximumGrade,_junction]];
        _state set ["roadLookAt",time+3];
    } else {_roadCap=(_state getOrDefault ["roadAssist",[_maximum]]) select 0};
};
// During contact, keep the front moving instead of waiting inside the ambush for a disabled rear vehicle.
private _leadLimit = ((_maximum - ((_stretch - 1.2) max 0) * 5 - (_turn min 60) * 0.4) max 5) min _roadCap;
// A stretched but mobile convoy slows progressively; a hard zero here creates stop/start waves.
// Actual arrival, pinned contact and pedestrian safety still request a full stop.
// Outside contact, do not let the lead outrun a follower still acquiring its path.
// Use measured progress, retain a walking-speed floor, and recover the requested speed
// as the line closes. Real obstruction recovery remains a separate bounded halt path.
if (!_contact) then {
    for "_i" from 1 to (count _vehicles - 1) do {
        private _follower=_vehicles select _i;
        private _gap=_follower distance2D (_vehicles select (_i-1));
        private _target=_gaps select _i;
        private _catchupThreshold=_target+((_target*0.05) max 1);
        // Followers share the cruise speed cap. Waiting until the outer band before
        // pacing the lead leaves no speed reserve to close a persistent gap inside it.
        if (_gap > _catchupThreshold) then {
            // Within the spacing band, reserve speed from cruise rather than from
            // instantaneous follower speed. Feeding acceleration lag back into the
            // leader here ratchets the whole convoy down on every small gap change.
            private _catchup=(_maximum - (((_gap-_target)*0.4) min 8)) max 5;
            if (_gap > _target*1.2) then {
                _catchup=_catchup min ((abs speed _follower - (((_gap-_target*1.2)*0.15) min 8)) max 5);
            };
            _leadLimit=_leadLimit min _catchup;
        };
    };
};
if (_routeDone) then {_leadLimit = 0};
// Avoid converting small one-second spacing corrections into a visible throttle pulse. Acceleration
// is gradual; arrival remains an immediate stop and the infantry corridor below can still stop now.
private _leadSpeedState=_state getOrDefault ["leadSpeedLimit",[_leadLimit,time-1]];
private _leadElapsed=((time-(_leadSpeedState select 1)) max 0.1) min 3;
if (!_routeDone && {_leadLimit > (_leadSpeedState select 0)}) then {
    _leadLimit=_leadLimit min ((_leadSpeedState select 0)+6*_leadElapsed);
};
_leadLimit = [_lead,_leadLimit,_group] call Waldo_fnc_CortexInfantrySpeed;
_state set ["leadSpeedLimit",[_leadLimit,time]];
_lead forceSpeed (_leadLimit / 3.6);
// Speed limits cannot restart an engine movement order that stopped short. Retry only
// after ten seconds without progress, while a real route destination remains active.
private _leadProgress = _state getOrDefault ["leadProgress", [getPosATL _lead, time, 0]];
if (_lead distance2D (_leadProgress select 0) > 3 || {_leadLimit <= 0}) then {_leadProgress = [getPosATL _lead, time, 0]};
private _waypointIndex = currentWaypoint _group;
if (!_routeDone && {_leadLimit > 0} && {_waypointIndex < count waypoints _group}
    && {time - (_leadProgress select 1) >= 10} && {abs speed _lead < 1}) then {
    private _waypoint = [_group, _waypointIndex];
    private _destination = waypointPosition _waypoint;
    if (waypointType _waypoint == "MOVE" && {_lead distance2D _destination > (waypointCompletionRadius _waypoint max 20)}) then {
        private _attempts=(_leadProgress param [2,0])+1;
        if (_attempts > 3) then {
            [_group,_revision,"STALLED",[],_lead] remoteExecCall ["Waldo_fnc_ConvoyHaltServer",2];
        } else {driver _lead doMove _destination};
        _leadProgress set [2,_attempts];
    };
    _leadProgress set [0,getPosATL _lead]; _leadProgress set [1,time];
};
_state set ["leadProgress", _leadProgress];
private _followers = _state get "followers";
private _speedLimits = _state get "speedLimits";
private _pathOwners = _state getOrDefault ["pathOwners",createHashMap];
_state set ["pathOwners",_pathOwners];
for "_i" from 1 to (count _vehicles - 1) do {
    private _vehicle = _vehicles select _i;
    private _front = _vehicles select (_i - 1);
    private _record = _frontTrails get (netId _front);
    private _trail = _record select 0;
    private _trailBase = _record select 1;
    private _gap = _vehicle distance2D _front;
    private _desiredGap = _gaps select _i;
    private _native = !isAISteeringComponentEnabled _vehicle;
    private _key = netId _vehicle;
    private _tolerance = (_desiredGap * 0.2) max 3;
    private _bodyGap = (((_specs get (netId _vehicle)) select 1) + ((_specs get (netId _front)) select 1))*0.5+5;
    private _gapLow = (_desiredGap - _tolerance) max _bodyGap;
    private _gapHigh = _desiredGap + _tolerance;
    private _controlGap = _gap;
    private _lateralOffset = 0;
    private _headingDifference=abs (((getDir _vehicle-getDir _front+540) mod 360)-180);
    if (_headingDifference <= 25 && {_gap <= _desiredGap*1.8}) then {
        private _direction=vectorDir _front;
        _direction set [2,0];
        private _delta=(getPosATL _front) vectorDiff (getPosATL _vehicle);
        _delta set [2,0];
        _controlGap=(_delta vectorDotProduct _direction) max 0;
        _lateralOffset=sqrt ((_gap*_gap-_controlGap*_controlGap) max 0);
    };
    private _frontSpeed = abs speed _front;
    private _previous = _speedLimits getOrDefault [_key,[_frontSpeed,time-1]];
    // Match predecessor speed at the requested gap; proportional correction avoids drifting along a band edge.
    // Acceleration remains bounded below, while compression still applies an immediate braking cap.
    private _limit = (_frontSpeed + (_controlGap-_desiredGap)*0.4) max 0;
    if (_controlGap > _gapHigh) then {_limit = _limit max 5};
    if (_controlGap < _gapLow) then {_limit = _limit min ((_frontSpeed-(_gapLow-_controlGap)*1.2) max 0)};
    // A stationary/braking predecessor must still constrain us inside the tolerance band.
    private _closingCap = (_frontSpeed + ((_controlGap-_gapLow) max 0)*0.8) min _maximum;
    private _elapsed = ((time-(_previous select 1)) max 0.1) min 3;
    _limit = ((_limit min ((_previous select 0)+4*_elapsed)) min _closingCap) max 0;
    // Keep enough motion to steer back onto the recorded predecessor track.
    // A full stop while physically clear but offset would preserve the wedge indefinitely.
    if (_lateralOffset > _tolerance && {_gap > _gapLow} && {_pathOwners getOrDefault [_key,false]}) then {_limit=_limit max 5};
    _limit = [_vehicle,_limit,_group] call Waldo_fnc_CortexInfantrySpeed;
    _vehicle forceSpeed (_limit / 3.6);
    _speedLimits set [_key,[_limit,time]];
    private _progress = _followers getOrDefault [_key, [getPosATL _vehicle, time, -1, _trailBase]];
    if (_vehicle distance2D (_progress select 0) > 3) then {_progress = [getPosATL _vehicle, time, _progress select 2, _progress select 3]};
    // Let the normal engine route around an obstruction after a bounded timeout. Never teleport.
    if (time - (_progress select 1) > 20 && {_limit > 2} && {_gap > _gapLow+3}
        && {_frontSpeed > 1 || {_gap > _gapHigh}}) then {
        private _attempts=(_progress param [4,0])+1;
        if (_attempts > 3) then {
            [_group,_revision,"STALLED",[],_vehicle] remoteExecCall ["Waldo_fnc_ConvoyHaltServer",2];
        } else {
            _pathOwners set [_key,false];
            (driver _vehicle) doFollow leader _group;
            _vehicle setConvoySeparation _desiredGap;
        };
        _progress = [getPosATL _vehicle, time, time + 10, _progress select 3, _attempts];
    };
    if (time >= (_progress select 2) && {count _trail >= 1} && {_gap > _desiredGap * 0.8 || {_pathOwners getOrDefault [_key,false]}}) then {
        private _nearest = -1;
        private _distance = 18;
        private _frontIndex = count _trail - 1;
        private _start = ((_progress select 3) - _trailBase) max 0;
        for "_j" from _start to (_frontIndex min (count _trail - 1)) do {
            private _d = _vehicle distance2D (_trail select _j);
            if (_d < _distance) then {_distance = _d; _nearest = _j};
        };
        private _joining = false;
        // The first recorded predecessor point starts a full gap ahead. A fixed
        // 18 m capture circle strands 30/50 m starts in native formation forever.
        // Acquire an ahead point in a forward cone, never an old point behind us.
        if (_nearest < 0) then {
            private _origin=getPosATL _vehicle;
            private _heading=vectorDir _vehicle;
            private _best=150;
            for "_j" from _start to _frontIndex do {
                private _point=_trail select _j;
                private _delta=_point vectorDiff _origin;
                _delta set [2,0];
                private _length=vectorMagnitude _delta;
                if (_length > 3 && {_length < _best} && {(_delta vectorDotProduct _heading) > _length*0.5}) then {
                    _nearest=_j; _best=_length; _joining=true;
                };
            };
        };
        if (_nearest >= 0) then {
            private _path = [];
            _progress set [3, _nearest + _trailBase];
            private _end = (_nearest + 10) min _frontIndex min (count _trail - 1);
            for "_j" from (_nearest + ([1,0] select _joining)) to _end do {
                private _point = _trail select _j;
                // The trail is navigation, not a second spacing brake. Trimming its endpoint to
                // the requested gap leaves only a few metres of driveable path at short spacing.
                // The speed controller above maintains the physical gap independently.
                _path pushBack _point;
            };
            // The predecessor trail is already available, so followers can anticipate its curve
            // without another road/object query. This cap affects the current refresh only.
            if ([_group,"Waldo_Convoy_DrivingAssist_Enable",true] call Waldo_fnc_CortexFeatureEnabled && {count _path >= 3}) then {
                private _pathTurn=0;
                private _pathGrade=0;
                for "_j" from 1 to (count _path-2) do {
                    private _a=_path select (_j-1);
                    private _b=_path select _j;
                    private _c=_path select (_j+1);
                    private _segment=_b distance2D _c;
                    if (_segment >= 1) then {
                        _pathTurn=_pathTurn max (abs ((((_b getDir _c)-(_a getDir _b)+540) mod 360)-180));
                        _pathGrade=_pathGrade max (abs ((_c select 2)-(_b select 2))/_segment);
                    };
                };
                private _pathCap=if (_pathTurn > 70) then {18} else {if (_pathTurn > 45) then {25} else {if (_pathTurn > 25) then {35} else {_maximum}}};
                if (_pathGrade > 0.2) then {_pathCap=_pathCap min 18} else {if (_pathGrade > 0.12) then {_pathCap=_pathCap min 25}};
                _limit=_limit min _pathCap;
                _vehicle forceSpeed (_limit/3.6);
                _speedLimits set [_key,[_limit,time]];
            };
            if (_native && {_path isNotEqualTo []}) then {
                // Vehicles without steering support retain native pathfinding.
                // A long straight look-ahead keeps tracks moving; stop the destination at a bend
                // so native pathfinding cannot cut across the predecessor's right-angle corner.
                private _destination = _path select (count _path - 1);
                if (count _path >= 3) then {
                    for "_j" from 1 to (count _path - 2) do {
                        private _before = (_path select (_j-1)) getDir (_path select _j);
                        private _after = (_path select _j) getDir (_path select (_j+1));
                        private _turn = abs (((_after-_before+540) mod 360)-180);
                        if (_turn > 25) exitWith {_destination = _path select _j};
                    };
                };
                driver _vehicle doMove _destination;
                _progress set [2, time + 1];
            } else {
                if (count _path >= 2) then {
                    // Normal AI must relinquish its formation movement before path driving.
                    // Stop once per acquisition, not on every refreshed path (which would cancel it).
                    if (!(_pathOwners getOrDefault [_key,false])) then {
                        doStop driver _vehicle;
                        _pathOwners set [_key,true];
                    };
                    // Path driving consumes its own speed component in metres per second.
                    // Refresh it even inside the gap band so an earlier faster path cannot outrun braking.
                    _vehicle setDriveOnPath (_path apply {_x + [_limit / 3.6]});
                    _progress set [2, time + 1];
                };
            };
        } else {
            // A steering-capable follower waits for a forward trail; never hand it back to
            // formation merely because its predecessor has not yet travelled five metres.
            // Native formation here recreates side-by-side traffic and can close the gap first.
            if (_native) then {
                _pathOwners set [_key,false];
                (driver _vehicle) doFollow leader _group;
                _vehicle setConvoySeparation _desiredGap;
            } else {
                if (!(_pathOwners getOrDefault [_key,false])) then {doStop driver _vehicle};
                _pathOwners set [_key,true];
            };
            _progress set [2, time + 1];
        };
    };
    _followers set [_key, _progress];
};
