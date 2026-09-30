/*
 * Author: WaldoTheWarfighter
 * Advances a running drill (flank or bounding advance) by one step: issue a bound, wait for arrival,
 * pause and overwatch, cross streets under smoke, and finish by holding the ground won or assaulting.
 *
 * Bounds: each member gets his own spot, spread 5 m apart across the direction to the last known enemy position. WEDGE uses staggered rear ranks; other formations use a broad line. Ordinary
 * bounds, the final position and the assault position are snapped to cover facing the enemy
 * (Waldo_fnc_CortexFindCover); street crossings and the clearing rush are not. On movement bounds, final approaches and
 * street crossings, pursuit (TARGET) is suspended while weapon aiming and firing remain enabled.
 * A RED group first receives a finite YELLOW movement lease: it remains fire-at-will, but the engine must keep
 * formation instead of creating independent ATTACK subgroups that compete with the bounds. The lease begins one
 * scheduler step before the first move, remains active for the whole manoeuvre, and is restored only if the group
 * still has the value Cortex applied. A later Zeus, waypoint or script ROE change cancels the manoeuvre and survives
 * cleanup. Automatic target acquisition is suspended only for movers; the paired fire team and covering squad
 * retain normal acquisition and provide fire. Movers watch the known threat direction.
 * COMBAT movers temporarily use per-unit AWARE with automatic combat switching suspended;
 * their previous behaviour is restored at halts, cancellation and ownership migration.
 * Bound handoff never issues doFollow: formation return competes with individual destinations.
 * No explicit attack target is assigned to movers, because that replaced bound destinations in live QA.
 * The lease never uses BLUE or disables firing. Same-frame BLUE/reset experiments did not reliably cancel stale
 * attack orders and briefly silenced the base of fire; they are intentionally not used.
 * Only features
 * that were on are switched off, and they are switched back on at every halt, so mission-maker
 * disableAI settings survive. A bound completes when every member is within 3 m of his spot, or after
 * six seconds when at least two soldiers and 60 percent of the assigned element have physically arrived.
 * Remaining actors become bounded recovery stragglers and keep moving toward their element; they are
 * never counted as arrived or teleported. Each arrival holds PATH until the next bound, preventing formation return. Waldo_AIPass_Flank_BoundTimeout limits stationary time; four times that value is the absolute bound limit. Stationary movement ends as STALLED; the absolute limit ends as TIME_LIMIT, never arrival. Halts last
 * Waldo_AIPass_Flank_BoundPause seconds (also after clearing and consolidation),
 * 3 s at a street edge, and twice the configured pause at a standalone flank final position.
 * Coordinated bounds already have a covering squad: fire-team and final handoffs add no
 * fixed pause. Arrival, normal scheduler cadence and the server role handoff still apply.
 * Final assault (Waldo_AIPass_Assault_Enable): after a flank or advance hold,
 * if the enemy is believed within Waldo_AIPass_Assault_Range of the element, morale is STEADY and the
 * behaviour profile's assaultChance roll succeeds, the element first reaches its assault position before one member may throw a fragmentation grenade
 * (Waldo_fnc_CortexThrowGrenade, never near friendlies). The approach uses a covered spot
 * 20 m short of the reported enemy and clears 20 m beyond that fixed objective, while the base of fire keeps suppressing. A queued frag is an opportunistic action: its own next-frame safety check may cancel it, but deployment never gates the assault or aborts movement. The assault axis stays fixed through the crossing; water destinations are rejected.
 * Consolidation: a flank brings its covering element forward even when no final assault
 * is selected; the manoeuvre element holds its gained position. After clearing through,
 * its surviving on-foot covering element moves
 * to a line 12 m beyond the fixed objective while the assault element holds. The same
 * arrival, retry, loss, Zeus and locality rules apply; unresolved stragglers remain PARTIAL.
 * Advance has already moved both elements through the objective.
 * Ending: a completed drill leaves the element holding the ground it took. Members rejoin formation
 * when the leader comes within 30 m, when the squad returns to CALM, or when it retreats . The drill aborts, with members following the leader again, when the group
 * leaves CONTACT, Zeus takes the group (Waldo_fnc_CortexZeusHeld), or half the element is lost. It
 * also ends, holding ground, when an enemy is believed within 30 m and assault is disabled. Flanks move only their selected element. Successive advances exchange two elements,
 * including the leader in the second element, only after physical arrival.
 * Coordinated bounds face the matching server role objective even before personal sight;
 * a stale local contact position cannot replace that shared objective.
 * Locality and authority: scheduler job on the group owner.
 *
 * Review contract: Every step rechecks full group eligibility and its behaviour switch. Existing jobs stop after exclusion, remote control or a live disable.
 *
 * Repeat/JIP: each job rechecks its drill token, locality and gates; completion publishes the real ending reason.
 * A stationary mover receives at most two route reissues per bound, eight seconds apart.
 * The same bounded retries also detect a return to the unchanged original group waypoint.
 * They never change that waypoint, and the eligibility check gives Zeus priority first.
 * Retries never reset the physical-progress clock or count as arrival. A viable majority
 * (at least two movers and 60 percent of the original element) may continue past blocked
 * actors. Separated actors receive at most six rejoin destinations, eight seconds apart.
 * Unresolved separation cannot produce COMPLETE; ownership changes cancel this local recovery.
 * Casualties are reassessed only on this group job. A flank draws replacements from surviving
 * uncommitted squad members. Advance and coordinated-bound fire teams first take unassigned
 * survivors, then rebalance only when one team falls below two. A casualty during movement restarts
 * the same bound so the surviving formation cannot inherit another soldier's destination.
 * Arguments:
 * 0: job <HASHMAP> - contains "group" and the matching "drillToken" (required)
 *
 * Return Value:
 * Number - seconds until the next step, or -1 when the drill ended
 *
 * Example:
 * [Waldo_fnc_CortexFlankStep, createHashMapFromArray [["group", _group],["drillToken",_drill get "token"]], 0] call Waldo_fnc_CortexQueueJob;
 * Result: the element moves one stage further.
 *
 * Current callers: Waldo_fnc_CortexFlankStart and Waldo_fnc_CortexAdvanceStart.
 */

params [["_job", createHashMap, [createHashMap]]];
private _group = _job getOrDefault ["group", grpNull];
if (isNull _group || {!local _group}) exitWith {-1};
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
private _drill = _state getOrDefault ["drill", createHashMap];
if (count _drill == 0) exitWith {-1};
// A cancelled job may still be queued when another drill starts on this group.
// Retire it without releasing or advancing the replacement drill.
private _token = _job getOrDefault ["drillToken",""];
if (_token == "" || {_token != (_drill getOrDefault ["token",""])}) exitWith {-1};
private _end = {
    [_group, _state, _this] call Waldo_fnc_CortexFlankEnd;
    -1
};
// RED explicitly permits independent pursuit. That engine-owned ATTACK state replaces
// individual doMove destinations and was the common cause of stalled bounds in live QA.
// YELLOW preserves fire-at-will while keeping the group in formation. Give the engine one
// scheduler step to retire its pursuit subgroups before issuing the first owned destination.
private _groupModeLease = _drill getOrDefault ["groupCombatMode",[]];
if (_groupModeLease isEqualTo [] && {combatMode _group == "RED"}) exitWith {
    _drill set ["groupCombatMode",["RED","YELLOW"]];
    _group setCombatMode "YELLOW";
    0.25
};
if (_groupModeLease isNotEqualTo [] && {combatMode _group != (_groupModeLease select 1)}) exitWith {
    "ROE_CHANGED" call _end
};
private _supportToken=_drill getOrDefault ["supportToken",""];
private _support=_supportToken != "";
private _supportRole=_group getVariable ["Waldo_Cortex_SupportRole",[]];
private _supportValid=_support && {count _supportRole == 5}
    && {(_supportRole select 0) == _supportToken}
    && {(_supportRole select 1) == (_drill get "supportSequence")}
    && {(_supportRole select 2) == "MOVE"}
    && {_state getOrDefault ["assaulting",false]};
private _gate=if (_support) then {"Waldo_AIPass_CoordinatedAssault_Enable"} else {
    ["Waldo_AIPass_Flank_Enable","Waldo_AIPass_Advance_Enable"] select ((_drill getOrDefault ["type","FLANK"]) == "ADVANCE")
};
if (!(missionNamespace getVariable ["Waldo_AIPass_Active", false])
    || {if (_support) then {!_supportValid} else {(_state getOrDefault ["phase",""]) != "CONTACT"}}
    || {!([_group] call Waldo_fnc_CortexIsEligible)}
    || {!([_group,_gate,true] call Waldo_fnc_CortexFeatureEnabled)}) exitWith {"ABORT" call _end};
// Rebuild depleted manoeuvre elements from the surviving squad inside this existing group job.
// There is no casualty event handler or per-unit scheduler. A change during a live bound restarts
// that bound from the same route point so spot indexes cannot drift after a casualty.
private _ownedPathUnits=(_drill getOrDefault ["disabled",[]]) select {(_x select 1) == "PATH"} apply {_x select 0};
private _fitSquad=(units _group) select {[_x] call Waldo_fnc_CortexCombatEffective && {local _x}
    && {vehicle _x == _x} && {group _x == _group} && {_x checkAIFeature "MOVE"}
    && {_x checkAIFeature "PATH" || {_x in _ownedPathUnits}}};
private _teams=_drill getOrDefault ["teams",[]];
private _desiredStrength=_drill getOrDefault ["desiredStrength",count (_drill get "units")];
private _reinforcements=[];
private _rankCandidates={
    params ["_candidates"];
    private _rifles=_candidates select {!(([_x] call Waldo_fnc_CortexUnitRole) in ["MG","AT","LEADER"])};
    private _support=_candidates select {!(_x in _rifles) && {_x != leader _group}};
    _rifles+_support+(_candidates select {_x == leader _group})
};
private _units=[];
if (_teams isEqualTo []) then {
    _units=(_drill get "units") select {_x in _fitSquad};
    private _candidates=[_fitSquad-_units] call _rankCandidates;
    while {count _units < _desiredStrength && {_candidates isNotEqualTo []}} do {
        private _replacement=_candidates deleteAt 0;
        _units pushBack _replacement;
        _reinforcements pushBack ["MANOEUVRE",netId _replacement];
    };
} else {
    _teams=_teams apply {_x select {_x in _fitSquad}};
    private _assigned=[];
    {_assigned append _x} forEach _teams;
    private _candidates=[_fitSquad-_assigned] call _rankCandidates;
    private _desiredSizes=_drill getOrDefault ["teamSizes",_teams apply {count _x}];
    {
        private _team=_x;
        private _desired=_desiredSizes param [_forEachIndex,count _team];
        while {count _team < _desired && {_candidates isNotEqualTo []}} do {
            private _replacement=_candidates deleteAt 0;
            _team pushBack _replacement;
            _reinforcements pushBack [format ["TEAM_%1",_forEachIndex+1],netId _replacement];
        };
    } forEach _teams;
    if (count _teams == 2) then {
        private _first=_teams select 0;
        private _second=_teams select 1;
        if (count _first < 2 && {count _second > 2}) then {
            private _replacement=_second deleteAt ((count _second)-1);
            _first pushBack _replacement;
            _reinforcements pushBack ["TEAM_1_REBALANCE",netId _replacement];
        };
        if (count _second < 2 && {count _first > 2}) then {
            private _replacement=_first deleteAt ((count _first)-1);
            _second pushBack _replacement;
            _reinforcements pushBack ["TEAM_2_REBALANCE",netId _replacement];
        };
    };
    {_units append _x} forEach _teams;
    _units=_units arrayIntersect _units;
    _drill set ["teams",_teams];
};
_drill set ["units",_units];
if (_reinforcements isNotEqualTo []) then {
    private _history=_group getVariable ["Waldo_Cortex_DrillReinforcements",[]];
    _history pushBack [serverTime,_drill getOrDefault ["type",""],_drill getOrDefault ["index",-1],_reinforcements];
    _group setVariable ["Waldo_Cortex_DrillReinforcements",_history,true];
    if ((_drill getOrDefault ["stage",""]) == "MOVE") then {
        _drill set ["stage","START"];
        _drill set ["spots",[]];
        _drill set ["boundStart",time];
    };
};
if (count _units < ((ceil (_desiredStrength / 2)) max 1)) exitWith {"LOSSES" call _end};
// Recovery stays in this existing bounded group job; no per-soldier loop is spawned.
private _recovery = (_drill getOrDefault ["recovery",[]]) select {(_x select 0) in _units};
private _recovering = _recovery apply {_x select 0};
private _main = _units - _recovering;
private _rejoined = [];
if (_main isNotEqualTo []) then {
    {
        _x params ["_actor","_attempts","_next"];
        // Rejoin this actor's element, not the empty space between separated bounds.
        private _peers = _main;
        private _teamIndex = _teams findIf {_actor in _x};
        if (_teamIndex >= 0) then {_peers = (_teams select _teamIndex) select {_x in _main}};
        private _rally = getPosATL leader _group;
        if (_peers isNotEqualTo []) then {
            _rally = [0,0,0];
            {_rally = _rally vectorAdd getPosATL _x} forEach _peers;
            _rally = _rally vectorMultiply (1/count _peers);
        };
        if (_actor distance2D _rally <= 12 && {_actor checkAIFeature "PATH"}
            && {_actor checkAIFeature "MOVE"} && {(_drill getOrDefault ["stage",""]) != "MOVE"}) then {
            _rejoined pushBack _actor;
        } else {
            if (time >= _next && {_attempts < 6} && {_actor checkAIFeature "PATH"} && {_actor checkAIFeature "MOVE"}) then {
                _actor doWatch objNull;
                _actor doTarget objNull;
                _actor doMove _rally;
                _x set [1,_attempts+1];
                _x set [2,time+8];
            };
        };
    } forEach _recovery;
};
_recovery = _recovery select {!((_x select 0) in _rejoined)};
_drill set ["recovery",_recovery];
_recovering = _recovery apply {_x select 0};
private _recoverySnapshot = [["NONE","REJOINING"] select (_recovering isNotEqualTo []),_recovering,_drill getOrDefault ["index",-1]];
if (_recoverySnapshot isNotEqualTo (_group getVariable ["Waldo_Cortex_DrillRecovery",[]])) then {
    _group setVariable ["Waldo_Cortex_DrillRecovery",_recoverySnapshot,true];
};
_units = _units - _recovering;
if (count _units < 2) exitWith {"RECOVERY_FAILED" call _end};
private _centroid = [0, 0, 0];
{_centroid = _centroid vectorAdd getPosATL _x} forEach _units;
_centroid = _centroid vectorMultiply (1 / count _units);
// Reserved squads may still be CALM without personal sight. Their authenticated
// role carries the shared objective; local discovery may contain an older position.
private _enemyPos = if (_support) then {+(_supportRole select 4)} else {
    _state getOrDefault ["enemyPos", _drill get "enemyPos"]
};
private _assaulting = _drill getOrDefault ["assaulting", false];
private _assaultEnabled = [_group,"Waldo_AIPass_Assault_Enable", true] call Waldo_fnc_CortexFeatureEnabled;
if (_assaulting && {!_assaultEnabled}) exitWith {"ABORT" call _end};
if (!_support && {!_assaulting} && {!_assaultEnabled} && {_centroid distance2D _enemyPos < 30}) exitWith {"CLOSE" call _end};

// Preserve the complete live participant set before selecting the fire team for this bound.
// HOLD uses this snapshot to bring the base-of-fire element forward; without it the
// consolidation transition can terminate and leave only the current team assaulting.
private _allUnits = +_units;
private _fit = +_allUnits;
if (_teams isNotEqualTo []) then {_units = (_teams select (_drill getOrDefault ["teamTurn",0])) select {_x in _fit}};
if (_units isEqualTo [] || {_teams isNotEqualTo [] && {count (_fit - _units) == 0}}) exitWith {"LOSSES" call _end};
private _points = _drill get "points";
private _now = time;
private _restoreFeatures = {
    params [["_keepHolds",false]];
    private _stillRecovering = (_drill getOrDefault ["recovery",[]]) apply {_x select 0};
    private _keptBehaviours = [];
    {
        _x params ["_unit","_previous","_owned"];
        if (_unit in _stillRecovering && {local _unit} && {behaviour _unit == _owned}) then {
            _keptBehaviours pushBack _x;
        } else {
            if (local _unit && {behaviour _unit == _owned}) then {_unit setCombatBehaviour _previous};
        };
    } forEach (_drill getOrDefault ["combatBehaviours",[]]);
    _drill set ["combatBehaviours",_keptBehaviours];
    private _keptModes = [];
    {
        _x params ["_unit","_mode",["_ownedMode","BLUE"]];
        if (_unit in _stillRecovering && {local _unit} && {unitCombatMode _unit == _ownedMode}) then {
            _keptModes pushBack _x;
        } else {
            if (local _unit && {unitCombatMode _unit == _ownedMode}) then {_unit setUnitCombatMode _mode};
        };
    } forEach (_drill getOrDefault ["combatModes",[]]);
    _drill set ["combatModes",_keptModes];
    private _kept = [];
    {
        _x params ["_unit", "_feature"];
        if ((_keepHolds && {_feature == "PATH"}) || {_unit in _stillRecovering && {_feature in ["AUTOTARGET","TARGET","AUTOCOMBAT"]}}) then {_kept pushBack _x} else {
            if (alive _unit && {local _unit}) then {_unit enableAI _feature};
        };
    } forEach (_drill get "disabled");
    _drill set ["disabled", _kept];
};
private _issue = {
    [] call _restoreFeatures;
    if (_teams isNotEqualTo []) then {_units = (_teams select (_drill get "teamTurn")) select {_x in _fit}};
    (_points select (_drill get "index")) params ["_point", "_kind"];
    private _direction = if (_kind in ["ASSAULT","CLEAR","CONSOLIDATE"]) then {_drill get "assaultDirection"} else {_point getDir _enemyPos};
    private _wedge = formation _group == "WEDGE";
    private _spots = [];
    // Retain only still-owned recovery overrides across the main element's next bound.
    // FlankEnd restores the same records on cancellation, migration or completion.
    private _disabled = +(_drill get "disabled");
    private _combatModes = +(_drill getOrDefault ["combatModes",[]]);
    private _combatBehaviours = +(_drill getOrDefault ["combatBehaviours",[]]);
    if (_teams isNotEqualTo []) then {
        {
            if (_x checkAIFeature "PATH") then {doStop _x; _x disableAI "PATH"; _disabled pushBack [_x,"PATH"]};
            _x doWatch _enemyPos;
        } forEach (_fit - _units);
    };
    {
        private _unit = _x;
        // Release only Cortex's matching cover stance when this soldier starts moving.
        // A later mission-maker or Zeus stance remains authoritative.
        if (_unit getVariable ["Waldo_AIPass_StanceSet",false]
            && {toUpperANSI (unitPos _unit) == (_unit getVariable ["Waldo_Cortex_AppliedStance",""])}) then {
            _unit setUnitPos "AUTO";
            _unit setVariable ["Waldo_AIPass_StanceSet",nil,true];
            _unit setVariable ["Waldo_Cortex_AppliedStance",nil,true];
        };
        private _spacing = [5, 3] select (_kind == "CLEAR");
        private _lateral = (_forEachIndex - (count _units - 1) / 2) * _spacing;
        private _depth = 0;
        if (_wedge) then {
            private _rank = ceil (_forEachIndex / 2);
            _lateral = _rank * _spacing * ([-1, 1] select (_forEachIndex mod 2 == 0));
            _depth = -_rank * _spacing * 0.5;
        };
        if (_teams isNotEqualTo []) then {_lateral = _lateral + ([-8,8] select (_drill get "teamTurn"))};
        private _spot = (_point getPos [_lateral, _direction + 90]) getPos [_depth, _direction];
        if (_kind in ["BOUND", "FINAL", "ASSAULT"]) then {
            private _cover = ([_spot, _enemyPos, 3, _spots, _group] call Waldo_fnc_CortexFindCover) select 0;
            // Cover may lie beyond the search radius on a large object. Preserve the formation slot.
            if (_cover distance2D _spot <= 2 && {_spots findIf {_cover distance2D _x < 2} < 0}) then {_spot = _cover};
        };
        _spots pushBack _spot;
        // Automatic target selection alone does not stop leader-assigned pursuit.
        // Keep the moving actor's bound authoritative without disabling its weapons.
        if (_unit checkAIFeature "TARGET") then {
            _unit disableAI "TARGET";
            _disabled pushBack [_unit,"TARGET"];
        };
        // AUTOTARGET can create an ATTACK command even while TARGET is disabled.
        // That left only one member of a three-soldier fire team moving in live QA.
        // The covering elements retain acquisition and fire; movers regain it at the halt.
        if (_unit checkAIFeature "AUTOTARGET") then {
            _unit disableAI "AUTOTARGET";
            _disabled pushBack [_unit,"AUTOTARGET"];
        };
        // Only the moving element leaves autonomous combat movement. Weapon aiming and
        // firing remain enabled; the covering element keeps its combat behaviour.
        if (_unit checkAIFeature "AUTOCOMBAT") then {
            _unit disableAI "AUTOCOMBAT";
            _disabled pushBack [_unit,"AUTOCOMBAT"];
        };
        if (behaviour _unit == "COMBAT") then {
            _combatBehaviours pushBack [_unit,"COMBAT","AWARE"];
            _unit setCombatBehaviour "AWARE";
        };
        // An explicit doTarget turned these movers into stationary ATTACK actors in live QA.
        // Facing a threat must not install a competing attack destination.
        // Group YELLOW owns disengagement for the finite manoeuvre. Do not restore RED
        // between bounds: that recreates engine ATTACK subgroups before the next move.
        // Do not issue doFollow here. It starts native formation movement and can
        // survive the immediate doMove, pulling this element back toward its leader.
        _unit doTarget objNull;
        // Clear the covering element's assigned target before giving its next movement role.
        _unit doWatch objNull;
        doStop _unit;
        _unit doWatch _enemyPos;
        _unit doMove _spot;
    } forEach _units;
    private _waypointIndex = currentWaypoint _group;
    _drill set ["boundWaypoint",[_waypointIndex,waypointPosition [_group,_waypointIndex]]];
    _drill set ["spots", _spots];
    _drill set ["movers", +_units];
    private _progress = [];
    {_progress pushBack [_x distance2D (_spots select _forEachIndex),_now,getPosATL _x,_now]} forEach _units;
    _drill set ["progress",_progress];
    _drill set ["retries",_units apply {[0,_now]}];
    _drill set ["disabled", _disabled];
    _drill set ["combatModes",_combatModes];
    _drill set ["combatBehaviours",_combatBehaviours];
    _drill set ["boundStart", _now];
    _drill set ["stage", "MOVE"];
};

private _result = 1.5;
switch (_drill get "stage") do {
    case "START": {call _issue};
    case "MOVE": {
        private _spots = _drill get "spots";
        private _movers = _drill get "movers";
        private _arrived = true;
        private _arrivedUnits = [];
        private _stalled = false;
        private _blocked = [];
        private _timeout = missionNamespace getVariable ["Waldo_AIPass_Flank_BoundTimeout",25];
        private _progress = _drill get "progress";
        private _retries = _drill getOrDefault ["retries",_movers apply {[0,_now]}];
        {
            private _unit = _x;
            if (alive _unit && {_unit in _units}) then {
                private _remaining = _unit distance2D (_spots select _forEachIndex);
                if (_remaining <= 3) then {
                    _arrivedUnits pushBack _unit;
                    if (_unit checkAIFeature "PATH") then {
                        doStop _unit;
                        _unit disableAI "PATH";
                        (_drill get "disabled") pushBack [_unit,"PATH"];
                        _unit doWatch _enemyPos;
                    };
                } else {
                    _arrived = false;
                    private _last = _progress select _forEachIndex;
                    if ((_last select 0)-_remaining >= 0.5) then {_last set [0,_remaining]; _last set [1,_now]};
                    // A valid obstacle detour can temporarily increase target distance.
                    // Keep net approach and physical movement clocks separate.
                    if (_unit distance2D (_last select 2) >= 0.5) then {_last set [2,getPosATL _unit]; _last set [3,_now]};
                    private _retry = _retries select _forEachIndex;
                    // Native formation movement can resume the group's original waypoint
                    // while this actor is still outside its bound. Physical movement alone
                    // is not evidence that the owned destination is still being followed.
                    private _waypoint = _drill getOrDefault ["boundWaypoint",[]];
                    private _returnedToWaypoint = count _waypoint == 2
                        && {currentWaypoint _group == (_waypoint select 0)}
                        && {waypointPosition [_group,_waypoint select 0] isEqualTo (_waypoint select 1)}
                        && {(_waypoint select 1) distance2D (_spots select _forEachIndex) > 5}
                        && {((expectedDestination _unit) select 0) distance2D (_waypoint select 1) < 1};
                    if ((_now-(_last select 3) >= 8 || {_returnedToWaypoint}) && {_now-(_retry select 1) >= 8}
                        && {(_retry select 0) < 2} && {_unit checkAIFeature "PATH"}
                        && {_unit checkAIFeature "MOVE"}) then {
                        // Replan the same destination; do not move the actor or waive arrival.
                            _unit doWatch objNull;
                        _unit doTarget objNull;
                        _unit doMove (_spots select _forEachIndex);
                        _retry set [0,(_retry select 0)+1];
                        _retry set [1,_now];
                        diag_log format ["[WMP CORTEX] Bound retry group=%1 unit=%2 bound=%3 attempt=%4 remaining=%5",_group,netId _unit,_drill get "index",_retry select 0,_remaining];
                    };
                    if (_now-(_last select 3) > _timeout) then {_stalled = true; _blocked pushBack _unit};
                };
            };
        } forEach _movers;
        private _originalElement = if (_teams isEqualTo []) then {_allUnits} else {_teams select (_drill getOrDefault ["teamTurn",0])};
        private _minimumArrivals = (ceil (count _originalElement * 0.6)) max 2;
        private _quorumReady = !_arrived
            && {_now - (_drill get "boundStart") >= 6}
            && {count _arrivedUnits >= _minimumArrivals};
        if (_quorumReady) then {
            private _stragglers = _units - _arrivedUnits;
            {
                private _straggler = _x;
                if ((_recovery findIf {(_x select 0) == _straggler}) < 0) then {
                    _recovery pushBack [_straggler,0,_now];
                };
            } forEach _stragglers;
            _drill set ["recovery",_recovery];
            _group setVariable ["Waldo_Cortex_DrillRecovery",["REJOINING",_recovery apply {_x select 0},_drill get "index"],true];
            diag_log format ["[WMP CORTEX] Bound role complete group=%1 arrived=%2/%3 recovery=%4",_group,count _arrivedUnits,count _originalElement,_stragglers];
            _arrived = true;
            _stalled = false;
        };
        if (_stalled && {count (_units - _blocked) >= 2}
            && {count (_units - _blocked) >= ceil (count _originalElement * 0.6)}) then {
            // Continue with a viable majority. These actors are separated, not arrived.
            {_recovery pushBack [_x,0,_now]} forEach _blocked;
            _drill set ["recovery",_recovery];
            _group setVariable ["Waldo_Cortex_DrillRecovery",["REJOINING",_recovery apply {_x select 0},_drill get "index"],true];
            diag_log format ["[WMP CORTEX] Bound continues with stragglers group=%1 separated=%2 continuing=%3",_group,_blocked,_units-_blocked];
            _stalled = false;
        };
        if (!_arrived && {_stalled || {_now-(_drill get "boundStart") > _timeout*4}}) exitWith {
            private _reason = ["TIME_LIMIT","STALLED"] select _stalled;
            private _measurements = [];
            {
                private _unit = _x;
                if (_unit in _units) then {
                    _measurements pushBack [netId _unit,_unit distance2D (_spots select _forEachIndex),
                        _now-((_progress select _forEachIndex) select 1),currentCommand _unit,expectedDestination _unit,
                        _now-((_progress select _forEachIndex) select 3),
                        ["movementOwner",attackEnabled _group,behaviour _unit,unitCombatMode _unit,
                            assignedTarget _unit,getAttackTarget _unit,_unit checkAIFeature "PATH",_unit checkAIFeature "MOVE",
                            _unit checkAIFeature "AUTOTARGET",_unit checkAIFeature "TARGET",_unit checkAIFeature "AUTOCOMBAT",
                            groupOwner _group,_group getVariable ["Waldo_Cortex_SupportRole",[]]]];
                };
            } forEach _movers;
            private _failure = [_reason,_drill get "index",(_points select (_drill get "index")) select 1,
                _now-(_drill get "boundStart"),_timeout,_measurements];
            _group setVariable ["Waldo_Cortex_DrillFailure",_failure,true];
            diag_log format ["[WMP CORTEX] Drill movement ended group=%1 details=%2",_group,_failure];
            _result = _reason call _end;
        };
        if (_arrived) then {
            [true] call _restoreFeatures;
            if (_teams isNotEqualTo [] && {(_drill get "teamTurn") == 0}) then {
                _drill set ["stage","PAUSE"];
                // A separate squad already covers a coordinated bound. Avoid stacking
                // a fixed team pause on top of the inter-squad handoff.
                private _teamPause=if (_support) then {0} else {missionNamespace getVariable ["Waldo_AIPass_Flank_BoundPause",4]};
                _drill set ["pauseUntil",_now + _teamPause];
            } else {
            switch ((_points select (_drill get "index")) select 1) do {
                case "CROSS_NEAR": {
                    _drill set ["stage", "PAUSE"];
                    _drill set ["pauseUntil", _now + 3];
                    // One empty inventory must not suppress another member's carried smoke.
                    // Stop after the first accepted throw; the helper owns safety and cooldowns.
                    {
                        if ([_x, _enemyPos, "SMOKE"] call Waldo_fnc_CortexThrowGrenade) exitWith {};
                    } forEach _units;
                };
                case "FINAL": {
                    _drill set ["stage", "HOLD"];
                    private _pause = if (_support) then {0} else {missionNamespace getVariable ["Waldo_AIPass_Flank_BoundPause",4]};
                    private _multiplier = [1,2] select (!_support && {(_drill getOrDefault ["type","FLANK"]) == "FLANK"});
                    _drill set ["pauseUntil",_now + _pause * _multiplier];
                };
                case "ASSAULT": {
                    private _objective = _drill get "assaultObjective";
                    // Both advance elements have arrived here. Check available carriers
                    // across the fit assault force; one empty inventory must not suppress
                    // every other soldier's carried grenade. The helper owns ammo/safety checks.
                    private _throwers = _fit select {_x distance2D _objective <= 40};
                    private _thrower = objNull;
                    private _queued = false;
                    {
                        if ([_x,_objective,"FRAG"] call Waldo_fnc_CortexThrowGrenade) exitWith {
                            _thrower = _x;
                            _queued = true;
                        };
                    } forEach _throwers;
                    // Grenades support the assault; they do not own its state transition.
                    // Reserve the actor briefly for the next-frame throw, then continue the
                    // ordinary tactical pause whether the throw succeeds, cancels or migrates.
                    _drill set ["stage","PAUSE"];
                    _drill set ["pauseUntil",_now + 3];
                    _drill set ["grenadeThrower",_thrower];
                    _drill set ["grenadeActionUntil",[_now,_now+2] select _queued];
                };
                case "CONSOLIDATE": {
                    _drill set ["stage","HOLD"];
                    _drill set ["pauseUntil",_now + (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundPause",4])];
                };
                case "CLEAR": {
                    _drill set ["stage", "HOLD"];
                    _drill set ["pauseUntil",_now + (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundPause",4])];
                };
                default {
                    _drill set ["stage", "PAUSE"];
                    _drill set ["pauseUntil", _now + (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundPause", 4])];
                };
            };
            };
        };
    };
    case "PAUSE": {
        if (_now >= (_drill get "pauseUntil")) then {
            if (_teams isNotEqualTo [] && {(_drill get "teamTurn") == 0}) then {
                _drill set ["teamTurn",1];
            } else {
                _drill set ["teamTurn",0];
            _drill set ["index", (_drill get "index") + 1];
            };
            if ((_drill get "index") >= count _points) then {_result = "COMPLETE" call _end} else {call _issue};
        };
    };
    case "HOLD": {
        if (_now >= (_drill get "pauseUntil")) then {
            // A flank left its leader/support weapons behind. Move those soldiers
            // forward under the assault element's cover before declaring completion.
            // Advance already brought both elements through the objective.
            if ((_assaulting || {_drill getOrDefault ["finishFlank",false]}) && {_teams isEqualTo []} && {!(_drill getOrDefault ["consolidating",false])}) exitWith {
                private _support = (units _group) select {
                    !(_x in _allUnits) && {local _x} && {vehicle _x == _x}
                    && {[_x] call Waldo_fnc_CortexCombatEffective}
                };
                if (_support isEqualTo []) then {
                    _result = "COMPLETE" call _end;
                } else {
                    if (!_assaulting) then {_drill set ["assaultDirection",_centroid getDir _enemyPos]};
                    _drill set ["consolidating",true];
                    _teams = [+_allUnits,+_support];
                    _drill set ["teams",_teams];
                    _drill set ["units",_allUnits + _support];
                    _fit append _support;
                    _drill set ["teamTurn",1];
                    _drill set ["index",count _points];
                    private _rally = if (_assaulting) then {(_drill get "assaultObjective") getPos [12,_drill get "assaultDirection"]} else {+_centroid};
                    _points pushBack [_rally,"CONSOLIDATE"];
                    call _issue;
                };
            };
            if (_drill getOrDefault ["consolidating",false]) exitWith {_result = "COMPLETE" call _end};
            private _assault = !_assaulting
                && {_assaultEnabled}
                && {(_state getOrDefault ["moraleState", "STEADY"]) == "STEADY"}
                && {_centroid distance2D _enemyPos <= (missionNamespace getVariable ["Waldo_AIPass_Assault_Range", 80])}
                && {random 1 < ([_group, "assaultChance"] call Waldo_fnc_CortexProfile)};
            private _assaultDirection = _centroid getDir _enemyPos;
            private _clearPoint = _enemyPos getPos [20, _assaultDirection];
            // Leave room for 3 m arrival tolerance and up to 2 m cover adjustment
            // outside the grenade helper's 12 m friendly exclusion radius.
            private _approachPoint = _enemyPos getPos [20, _assaultDirection + 180];
            if (_assault && {!surfaceIsWater _clearPoint} && {!surfaceIsWater _approachPoint}) then {
                // Snapshot the reported objective. New reports must not drag this crossing
                // behind the actors or reverse their frontage halfway through the assault.
                _drill set ["assaulting", true];
                _drill set ["assaultObjective",+_enemyPos];
                _drill set ["assaultDirection",_assaultDirection];
                _points pushBack [_approachPoint, "ASSAULT"];
                _points pushBack [_clearPoint, "CLEAR"];
                missionNamespace setVariable ["Waldo_AIPass_Assaults", (missionNamespace getVariable ["Waldo_AIPass_Assaults", 0]) + 1];
                _drill set ["stage", "PAUSE"];
                _drill set ["pauseUntil", _now + 3];
            } else {
                if ((_drill getOrDefault ["type","FLANK"]) == "FLANK" && {_teams isEqualTo []}) then {
                    // No assault is a valid tactical choice, not permission to leave
                    // the leader and covering element permanently at the old position.
                    _drill set ["finishFlank",true];
                    _drill set ["pauseUntil",_now];
                } else {_result = "COMPLETE" call _end};
            };
        };
    };
};
_result
