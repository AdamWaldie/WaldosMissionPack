/*
 * Author: WaldoTheWarfighter
 * Drives mixed convoys along each predecessor trail, detects arrival and requests a persistent halt after pinned contact.
 * Locality/authority: server owns phase; group owner drives and reports, each cargo/turret owner applies crew work.
 * Spacing uses a size-aware target with a 20 percent tolerance band (at least 3 m).
 * Speed corrects toward the target; the tolerance band bounds catch-up and stronger close-gap braking.
 * Acceleration is bounded; outside contact the lead slows to let stretched followers catch up.
 * Path refreshes do not repeatedly stop drivers, and tracked vehicles receive longer look-ahead targets.
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
    _stretch = _stretch max (((_vehicles select _i) distance2D (_vehicles select (_i - 1))) / (_gaps select _i));
};
// During contact, keep the front moving instead of waiting inside the ambush for a disabled rear vehicle.
private _leadLimit = (_maximum - ((_stretch - 1.2) max 0) * 5 - (_turn min 60) * 0.4) max 5;
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
_leadLimit = [_lead,_leadLimit,_group] call Waldo_fnc_CortexInfantrySpeed;
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
    private _frontSpeed = abs speed _front;
    private _previous = _speedLimits getOrDefault [_key,[_frontSpeed,time-1]];
    // Match predecessor speed at the requested gap; proportional correction avoids drifting along a band edge.
    // Acceleration remains bounded below, while compression still applies an immediate braking cap.
    private _limit = (_frontSpeed + (_gap-_desiredGap)*0.4) max 0;
    if (_gap > _gapHigh) then {_limit = _limit max 5};
    if (_gap < _gapLow) then {_limit = _limit min ((_frontSpeed-(_gapLow-_gap)*1.2) max 0)};
    // A stationary/braking predecessor must still constrain us inside the tolerance band.
    private _closingCap = (_frontSpeed + ((_gap-_gapLow) max 0)*0.8) min _maximum;
    private _elapsed = ((time-(_previous select 1)) max 0.1) min 3;
    _limit = ((_limit min ((_previous select 0)+4*_elapsed)) min _closingCap) max 0;
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
