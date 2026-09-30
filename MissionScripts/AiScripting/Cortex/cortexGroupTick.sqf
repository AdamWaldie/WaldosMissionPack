/*
 * Author: WaldoTheWarfighter
 * Pending remounts yield to a replacement vehicle assignment; cleanup only cancels the original seat order.
 * Runs one Cortex step for one locally owned group: reads the situation, moves it along the
 * group state ladder and calls each enabled behaviour. Casualty succession selects a living,
 * conscious local successor by rank before leader-dependent tactics; combat-effective leaders are preserved.
 *
 * State ladder with post-contact search and hysteresis:
 * CALM -> CONTACT when an enemy was seen in the last 10 s.
 * CALM -> INVESTIGATE when the squad knows about an enemy within
 *   Waldo_AIPass_Investigate_Range that it has not seen, for example one revealed by a contact report
 *   or heard firing, and the behaviour profile's investigateChance roll succeeds (at most every
 *   120 s). Within 150 m, two riflemen check the believed position while the rest watch it; a small
 *   squad, or any farther contact, has the whole squad move up together. It ends after
 *   Waldo_AIPass_Investigate_Seconds or on arrival, back in CALM.
 * CONTACT -> SECURITY after Waldo_AIPass_PostContact_LostSeconds without a sighting and after any
 *   bounded flank, advance or coordinated assault has finished (or straight back to CALM when
 *   post-contact is off). Temporary occlusion therefore cannot revoke an active manoeuvre.
 * SECURITY (hold) -> SEARCH (two riflemen check the last known enemy position) -> REGROUP (wait for
 *   the squad to close up) -> CALM, which restores the recorded behaviour and speed (a squad that
 *   was SAFE before a real firefight returns AWARE).
 * RETREAT (morale broken or a damaged vehicle withdrawing) -> REGROUP. A garrison, defence or
 * building-clear order is released before the same retreat transition; releasing the prior order
 * alone never counts as withdrawal.
 * Any sighting during SECURITY, SEARCH or REGROUP returns the group to CONTACT.
 * CARELESS groups are left entirely to the mission maker.
 * Waldo_AIPass_ReactionSpeed (AI Tuning) divides the step interval, so squads re-assess faster or slower.
 * A squad riding as cargo in an AI-flown aircraft is handled by airborne insertion instead
 * (Waldo_fnc_CortexAirborneCheck) until it has parachuted and landed.
 *
 * Cadence (distance tiers measured to the nearest player): Waldo_AIPass_TickContact in
 * contact near players; Waldo_AIPass_TickNear within Waldo_AIPass_NearRange; Waldo_AIPass_TickMid
 * within Waldo_AIPass_FarRange; Waldo_AIPass_TickFar beyond. Beyond FarRange only the state ladder
 * and morale run; drills, fire control and support calls are skipped.
 * In CONTACT near players, each enabled behaviour runs: fire control, stance, anti-armour, vehicles,
 * flanking (with final assault), bounding advance, contact reports, ammo sharing, artillery,
 * reinforcement and coordinated assault. Garrison and defence orders run their own break and reserve
 * logic instead of flanking or retreating. Soldiers left holding ground by a drill rejoin when the
 * leader comes within 30 m. Responders mark their arrival at the rally point for a coordinated assault.
 * With LAMBS Danger loaded and Waldo_AIPass_LambsMode "SPLIT", LAMBS keeps in-contact unit tactics
 * (flanking, assault, advance, fire control, stance, anti-armour, vehicles, contact sharing) for groups
 * it manages; WMP keeps the ladder, investigation, post-contact, morale, reinforcement, coordinated
 * assault, ammo sharing and artillery.
 * Zeus always wins: a group Zeus is commanding is ineligible (Waldo_fnc_CortexZeusHeld), so it is
 * released, including WMP garrison, defence and clear orders. Stance cleanup preserves a later
 * different externally assigned posture instead of unconditionally resetting it.
 * Locality and authority: runs as a scheduler job on the group owner. When the group stops being
 * local the job retires and the new owner's discovery sweep starts a fresh one.
 *
 * Review contract: Waypoint completion compares tagged indices with currentWaypoint; completed waypoints may remain in the engine list. This allows rally arrival and retreat completion to be detected.
 *
 * Repeat/JIP: current feature gates and eligibility are rechecked; owner jobs are retired on migration.
 * Arguments:
 * 0: job <HASHMAP> - contains "group"
 *
 * Return Value:
 * Number - seconds until the next step, or -1 to retire the job
 *
 * Example:
 * [Waldo_fnc_CortexGroupTick, createHashMapFromArray [["group", _group]], 1] call Waldo_fnc_CortexQueueJob;
 * Result: the group is managed by the pass on this machine.
 *
 * Current caller: jobs queued by Waldo_fnc_CortexDiscover.
 */

params [["_job", createHashMap, [createHashMap]]];
private _group = _job getOrDefault ["group", grpNull];
if (isNull _group) exitWith {-1};
if (!local _group || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}) exitWith {
    _group setVariable ["Waldo_AIPass_Managed", nil];
    -1
};

{
    if (local _x && {_x getVariable ["Waldo_AIPass_StanceSet",false]} && {!([_group,"Waldo_AIPass_Stance_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) then {
        if (toUpperANSI (unitPos _x) == (_x getVariable ["Waldo_Cortex_AppliedStance",""])) then {_x setUnitPos "AUTO"};
        _x setVariable ["Waldo_Cortex_AppliedStance",nil,true];
        _x setVariable ["Waldo_AIPass_StanceSet",nil,true];
    };
    private _target = _x getVariable ["Waldo_AIPass_VehicleTarget",objNull];
    if (local _x && {!isNull _target} && {!([_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled) || {!([_group,"Waldo_AIPass_VehicleGunnery_Enable",true] call Waldo_fnc_CortexFeatureEnabled)} || {!(combatMode _group in ["YELLOW","RED"] && {unitCombatMode _x in ["YELLOW","RED"]})}}) then {
        if (assignedTarget _x == _target) then {_x doTarget objNull};
        _x setVariable ["Waldo_AIPass_VehicleTarget",nil,true];
        _x setVariable ["Waldo_AIPass_TargetHold",nil];
    };
} forEach units _group;
private _alive = (units _group) select {alive _x};
if (_alive isEqualTo []) exitWith {
    _group setVariable ["Waldo_AIPass_Managed", nil];
    -1
};
if !([_group] call Waldo_fnc_CortexIsEligible) exitWith {
    if (count (_group getVariable ["Waldo_AIPass_State", createHashMap]) > 0 || {(_group getVariable ["Waldo_Cortex_Remount",[]]) isNotEqualTo []}) then {[_group, false] call Waldo_fnc_CortexReleaseGroup};
    // Any active Zeus takeover outranks explicit holding orders, including target,
    // stance and ZEN commands that do not create a waypoint.
    if ([_group] call Waldo_fnc_CortexZeusHeld) then {
        if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group,false] call Waldo_fnc_CortexGarrisonRelease};
        if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {[_group,false] call Waldo_fnc_CortexDefendRelease};
        if (_group getVariable ["Waldo_AIPass_ClearBuilding", false]) then {[_group,false] call Waldo_fnc_CortexClearRelease};
    };
    [20, 5] select ([_group] call Waldo_fnc_CortexZeusHeld)
};
// Survivor regroup owns a remnant while it is being merged.
if (_group getVariable ["Waldo_AIPass_RegroupQueued", false]) exitWith {5};
// Resolve casualty succession before reading leader knowledge or issuing group orders.
// Only eligible, locally owned AI groups reach this point. An incapacitated leader cannot drive
// withdrawal, bounds or contact state, so appoint an acting leader instead of waiting for recovery.
private _leader = leader _group;
if ((isNull _leader || {!([_leader] call Waldo_fnc_CortexCombatEffective)}) && {[_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
    private _successors = _alive select {local _x && {[_x] call Waldo_fnc_CortexCombatEffective}};
    if (_successors isNotEqualTo []) then {
        private _successor = _successors select 0;
        {if (rankId _x > rankId _successor) then {_successor = _x}} forEach _successors;
        _group selectLeader _successor;
        _leader = leader _group;
    };
};
// Never drive leader-dependent tactics through an incapacitated actor while succession settles.
if (isNull _leader || {!([_leader] call Waldo_fnc_CortexCombatEffective)}) exitWith {5};
if (behaviour _leader == "CARELESS") exitWith {10};
// Airborne insertion owns a squad while it rides an aircraft or is parachuting down.
if (_group getVariable ["Waldo_AIPass_Dropping", false]) exitWith {3};
private _airborneDelay = [_group, [_group] call Waldo_fnc_CortexGroupState] call Waldo_fnc_CortexAirborneCheck;
if (_airborneDelay >= 0) exitWith {_airborneDelay};

private _state = [_group] call Waldo_fnc_CortexGroupState;
[_group,_state] call Waldo_fnc_CortexSupportMaintain;
private _movementLease = _state getOrDefault ["movementLease",[]];
private _groupMovementOwned = count _movementLease == 2 && {time < (_movementLease select 1)} && {
    (waypoints _group) findIf {
        (_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}
    } >= 0
};
if (!_groupMovementOwned && {_movementLease isNotEqualTo []}) then {_state deleteAt "movementLease"};
private _now = time;
private _get = {
    _this params ["_name", "_fallback"];
    if (_fallback isEqualType true) then {[_group, _name, _fallback] call Waldo_fnc_CortexFeatureEnabled} else {missionNamespace getVariable _this}
};

private _nearest = 1e6;
{_nearest = _nearest min (_leader distance2D _x)} forEach (missionNamespace getVariable ["Waldo_AIPass_PlayerPositions", []]);
private _farRange = ["Waldo_AIPass_FarRange", 2500] call _get;
private _nearTier = _nearest <= _farRange;
private _delay = switch (true) do {
    case (_nearest <= (["Waldo_AIPass_NearRange", 1000] call _get)): {["Waldo_AIPass_TickNear", 4] call _get};
    case (_nearTier): {["Waldo_AIPass_TickMid", 8] call _get};
    default {["Waldo_AIPass_TickFar", 20] call _get};
};
if !(["Waldo_AIPass_Contact_Enable", true] call _get) exitWith {[_group,false] call Waldo_fnc_CortexReleaseGroup; _delay};

([_group] call Waldo_fnc_CortexKnowledge) params ["_enemies", "_seenCount"];
private _visible = _enemies select {(_x select 2) <= 10};
private _garrisoned = (_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo [];
private _defending = (_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo [];
private _ordered = _garrisoned || {_defending} || {_group getVariable ["Waldo_AIPass_ClearBuilding", false]};
private _lambsCombat = (missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false])
    && {toUpperANSI (["Waldo_AIPass_LambsMode", "SPLIT"] call _get) == "SPLIT"}
    && {!(_group getVariable ["lambs_danger_disableGroupAI", false])};
// Passenger squads can hear their own vehicle crew without acquiring exact target knowledge.
if (_nearTier && {!_ordered} && {!_lambsCombat} && {_visible isEqualTo []}
    && {(_state getOrDefault ["phase",""]) in ["CALM","CONTACT"]}) then {
    [_group,_state] call Waldo_fnc_CortexOnboardContact;
};
// Retry calm boarding on the current owner only; a different assigned vehicle retires our intent. A missing seat or moving
// vehicle is temporary, not grounds to forget the passenger after one attempt.
private _remount = _group getVariable ["Waldo_Cortex_Remount",[]];
if (_remount isNotEqualTo []) then {
    _remount params ["_deadline","_passengers"];
    private _pending = _passengers select {alive (_x select 0) && {group (_x select 0) == _group} && {alive (_x select 1)} && {vehicle (_x select 0) != (_x select 1)} && {isNull assignedVehicle (_x select 0) || {assignedVehicle (_x select 0) == (_x select 1)}}};
    private _cancel = _visible isNotEqualTo [] || {_ordered}
        || {!(["Waldo_AIPass_Vehicles_Enable",true] call _get)}
        || {!(["Waldo_AIPass_VehicleRemount_Enable",true] call _get)};
    if (_cancel || {serverTime >= _deadline} || {_pending isEqualTo []}) then {
        if (_visible isNotEqualTo []) then {_state set ["dismounted",+_pending]};
        {
            private _unit=_x select 0;
            if (local _unit && {vehicle _unit == _unit} && {assignedVehicle _unit == (_x select 1)}) then {[_unit] orderGetIn false; unassignVehicle _unit};
        } forEach _pending;
        if (!_cancel && {_pending isNotEqualTo []}) then {diag_log format ["[WMP CORTEX] Remount incomplete group=%1 passengers=%2",_group,_pending]};
        _group setVariable ["Waldo_Cortex_Remount",nil,true];
    } else {
        {
            _x params ["_unit","_vehicle"];
            if ([_unit,_vehicle,true] call Waldo_fnc_CortexPassengerReady) then {
                // Preserve an in-progress boarding path; retry only a missing/interrupted order.
                if (assignedVehicle _unit != _vehicle) then {_unit assignAsCargo _vehicle};
                if (toUpperANSI (currentCommand _unit) != "GET IN") then {[_unit] orderGetIn true};
            };
        } forEach _pending;
    };
};
private _contactDelay = if (_nearTier) then {["Waldo_AIPass_TickContact", 2] call _get} else {_delay};

private _areaMode = _state getOrDefault ["areaInvestigation",""];
if (_areaMode != "" && {(!([_group,"Waldo_AIPass_Investigate_Enable",true] call Waldo_fnc_CortexFeatureEnabled))
    || {!([_group,["Waldo_AIPass_ContactReports_Enable","Waldo_AIPass_Hearing_Enable"] select (_areaMode == "SOUND"),true] call Waldo_fnc_CortexFeatureEnabled)}}) then {
    [_group,_state] call Waldo_fnc_CortexRestoreCalm;
    _state deleteAt "areaInvestigation";
};

// Soldiers holding ground from a finished drill rejoin once the leader has caught up with them.
// A previous completed bound must not issue doFollow over a replacement drill.
// Transfer these actors out of old holding ownership before considering reunion.
private _activeDrill = _state getOrDefault ["drill",createHashMap];
private _ownedMovers = _activeDrill getOrDefault ["units",[]];
private _holders = (_state getOrDefault ["holders", []]) select {alive _x && {local _x} && {group _x == _group} && {!(_x in _ownedMovers)}};
_state set ["holders",_holders];
// A completed coordinated bound still belongs to the squad-level MOVE/COVER cycle.
// Keep its hold record for release, but do not regroup between successive bounds.
if (_holders isNotEqualTo [] && {!(_state getOrDefault ["assaulting",false])}) then {
    private _rejoin = _holders select {_x distance2D _leader < 30};
    {_x doFollow _leader} forEach _rejoin;
    _state set ["holders", _holders - _rejoin];
};

// A reported coordinated objective permits safe covering fire before personal contact.
// Use the existing group tick; CONTACT already invokes this pass below.
if (_nearTier && {!_lambsCombat} && {(_state getOrDefault ["phase",""]) != "CONTACT"}
    && {_state getOrDefault ["assaulting",false]}) then {
    [_group,_state,_enemies] call Waldo_fnc_CortexFireControl;
};

private _enterContact = {
    _state deleteAt "areaInvestigation";
    _state set ["phase", "CONTACT"];
    _state set ["phaseStart", _now];
    _state set ["lastSeen", _now];
    _state set ["hadContact", true];
    _state set ["enemyPos", (_visible select 0) select 1];
    _state set ["contactLeader", _leader];
    // Contact does not revoke a server-reserved rally. SupportMaintain owns its
    // deadline and arrival; otherwise responders abandon the rendezvous on sighting.
};
private _beginContact = {
    if !("baseBehaviour" in _state) then {
        _state set ["baseBehaviour", behaviour _leader];
        _state set ["baseSpeed", speedMode _group];
        _state set ["behaviourChanged", false];
        _state set ["speedChanged", false];
    };
    {if (alive _x && {local _x}) then {_x doFollow _leader}} forEach (_state getOrDefault ["searchTeam", []]);
    _state set ["searchTeam", []];
    if (!_groupMovementOwned && {!(_state getOrDefault ["responding", false])} && {!(_state getOrDefault ["assaulting", false])}) then {[_group] call Waldo_fnc_CortexGroupMoveClear};
    call _enterContact;
    // A coordinated responder already has a finite assault movement order. Do not
    // lock the entire approach into script-forced COMBAT bounding; native
    // AUTOCOMBAT remains enabled and can still react to threats normally.
    if (!(_state getOrDefault ["assaulting", false]) && {behaviour _leader in ["SAFE", "AWARE"]}) then {
        _group setBehaviour "COMBAT";
        _state set ["behaviourChanged", true];
    };
    if (_nearTier && {!_lambsCombat} && {["Waldo_AIPass_ContactReports_Enable", true] call _get}) then {
        [_group, _state, _visible] call Waldo_fnc_CortexContactReport;
    };
    if (_nearTier && {!_ordered} && {["Waldo_AIPass_Reinforce_Enable", true] call _get}) then {
        [_group, _state] call Waldo_fnc_CortexReinforce;
    };
    if (["Waldo_AIPass_Debug", false] call _get) then {
        diag_log format ["[WMP CORTEX] %1 CONTACT enemies=%2 seen=%3", _group, count _enemies, _seenCount];
    };
    _delay = _contactDelay;
};

switch (_state get "phase") do {
    case "CALM": {
        if (_state getOrDefault ["responding", false]) then {
            private _requester = _state getOrDefault ["respondingTo", grpNull];
            // Read only: never create pass state on the requester's group from here.
            private _requesterPhase = if (isNull _requester) then {"CALM"} else {
                _requester getVariable ["Waldo_AIPass_PublicPhase", "CALM"]
            };
            if (isNull _requester || {({alive _x} count units _requester) == 0} || {_requesterPhase == "CALM"}
                || {_now > (_state getOrDefault ["respondUntil", 0])}) then {
                [_group] call Waldo_fnc_CortexGroupMoveClear;
                {_state deleteAt _x} forEach ["responding", "respondingTo", "arrivedAt", "assaulting"];
            } else {
                // Arrival is measured by SupportMaintain in every contact phase.
            };
        };
        if (_visible isNotEqualTo []) exitWith {call _beginContact};
        private _area = _group getVariable ["Waldo_AIPass_AreaReport",[]];
        if (_area isNotEqualTo [] && {serverTime >= (_area select 2)}) then {_group setVariable ["Waldo_AIPass_AreaReport",nil,true]; _area = []};
        if (!_ordered && {!_groupMovementOwned} && {!_lambsCombat} && {!(_state getOrDefault ["responding",false])} && {_enemies isEqualTo []} && {_area isNotEqualTo []}
            && {["Waldo_AIPass_Investigate_Enable",true] call _get} && {!([_state,"investigate"] call Waldo_fnc_CortexCooldown)}
            && {leader _group distance2D (_area select 0) <= (["Waldo_AIPass_Investigate_Range",300] call _get)}
            && {[_group, ["Waldo_AIPass_ContactReports_Enable","Waldo_AIPass_Hearing_Enable"] select ((_area select 3) == "SOUND"),true] call Waldo_fnc_CortexFeatureEnabled}) then {
            [_state,"investigate",120] call Waldo_fnc_CortexCooldown;
            private _target = _area select 0;
            [_group,_target getPos [30,_target getDir leader _group],25] call Waldo_fnc_CortexGroupMove;
            _state set ["phase","INVESTIGATE"];
            _state set ["phaseStart",_now];
            _state set ["enemyPos",_target];
            _state set ["areaInvestigation",_area select 3];
            _group setVariable ["Waldo_AIPass_AreaReport",nil,true];
        };

        if (!_ordered && {!_groupMovementOwned} && {!(_state getOrDefault ["responding", false])} && {_enemies isNotEqualTo []}
            && {["Waldo_AIPass_Investigate_Enable", true] call _get}
            && {((_enemies select 0) select 3) <= (["Waldo_AIPass_Investigate_Range", 300] call _get)}
            && {!([_state, "investigate"] call Waldo_fnc_CortexCooldown)}) then {
            [_state, "investigate", 120] call Waldo_fnc_CortexCooldown;
            if (random 1 < ([_group, "investigateChance"] call Waldo_fnc_CortexProfile)) then {
                private _target = (_enemies select 0) select 1;
                _state set ["baseBehaviour", behaviour _leader];
                _state set ["baseSpeed", speedMode _group];
                _state set ["behaviourChanged", false];
                _state set ["speedChanged", false];
                if (behaviour _leader == "SAFE") then {
                    _group setBehaviour "AWARE";
                    _state set ["behaviourChanged", true];
                };
                private _onFoot = _alive select {local _x && {vehicle _x == _x}};
                private _team = [];
                // A two-man team only checks out nearby contacts; a farther one takes the whole squad.
                if (count _onFoot >= 4 && {(_leader distance2D _target) <= 150}) then {
                    _team = (_onFoot select {_x != _leader && {([_x] call Waldo_fnc_CortexUnitRole) == "RIFLE"}}) select [0, 2];
                };
                if (_team isEqualTo []) then {
                    [_group, _target getPos [30, _target getDir _leader], 25] call Waldo_fnc_CortexGroupMove;
                } else {
                    {_x doMove (_target getPos [4 + _forEachIndex * 4, random 360])} forEach _team;
                    {if (!(_x in _team) && {local _x}) then {_x doWatch _target}} forEach _alive;
                };
                _state set ["searchTeam", _team];
                _state set ["enemyPos", _target];
                _state set ["phase", "INVESTIGATE"];
                _state set ["phaseStart", _now];
                missionNamespace setVariable ["Waldo_AIPass_Investigations", (missionNamespace getVariable ["Waldo_AIPass_Investigations", 0]) + 1];
                _delay = 3;
            };
        };
    };
    case "INVESTIGATE": {
        if (_visible isNotEqualTo []) exitWith {
            {if (local _x) then {_x doWatch objNull}} forEach _alive;
            call _beginContact;
        };
        private _team = (_state getOrDefault ["searchTeam", []]) select {alive _x && {local _x}};
        private _target = _state getOrDefault ["enemyPos", getPosATL _leader];
        private _moving = (waypoints _group) findIf {(_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}} >= 0;
        private _done = (_team isNotEqualTo [] && {_team findIf {_x distance2D _target > 15} < 0})
            || {_team isEqualTo [] && {!_moving}}
            || {_now - (_state get "phaseStart") > (["Waldo_AIPass_Investigate_Seconds", 60] call _get)};
        if (_done) then {
            {if (local _x) then {_x doWatch objNull}} forEach _alive;
            [_group, _state] call Waldo_fnc_CortexRestoreCalm;
        } else {
            _delay = 3;
        };
    };
    case "CONTACT": {
        _delay = _contactDelay;
        if (_visible isNotEqualTo []) then {
            _state set ["lastSeen", _now];
            _state set ["enemyPos", (_visible select 0) select 1];
        };
        private _outcome = "";
        if (["Waldo_AIPass_Morale_Enable", true] call _get) then {
            _outcome = [_group, _state, _enemies] call Waldo_fnc_CortexMorale;
        };
        if (_outcome == "SURRENDER") exitWith {[_group] call Waldo_fnc_CortexSurrender};
        if (_garrisoned || {_defending}) then {
            private _order = if (_garrisoned) then {_group getVariable ["Waldo_AIPass_Garrison", []]} else {_group getVariable ["Waldo_AIPass_Defend", []]};
            private _orderStrength = (_order param [[3, 2] select _garrisoned, count _alive]) max 1;
            if (count _alive / _orderStrength <= (["Waldo_AIPass_Garrison_BreakFraction", 0.5] call _get)) then {
                if (_garrisoned) then {[_group] call Waldo_fnc_CortexGarrisonRelease} else {[_group] call Waldo_fnc_CortexDefendRelease};
                _garrisoned = false;
                _defending = false;
                _ordered = _group getVariable ["Waldo_AIPass_ClearBuilding", false];
            } else {
                if (_defending) then {[_group, _state, _enemies] call Waldo_fnc_CortexDefendStep};
            };
        };
        if (_outcome == "RETREAT") exitWith {
            switch (true) do {
                case (_garrisoned): {[_group] call Waldo_fnc_CortexGarrisonRelease};
                case (_defending): {[_group] call Waldo_fnc_CortexDefendRelease};
                case (_group getVariable ["Waldo_AIPass_ClearBuilding", false]): {[_group] call Waldo_fnc_CortexClearRelease};
            };
            // The release above only relinquishes the previous movement owner. Every broken
            // non-surrendering squad must still acquire the common physical withdrawal state.
            [_group, _state] call Waldo_fnc_CortexRetreat;
        };
        _state set ["armourSeen", (_state getOrDefault ["armourSeen", false]) || {_enemies findIf {
            private _enemy = vehicle (_x select 0);
            (_enemy isKindOf "Tank" || {_enemy isKindOf "Wheeled_APC_F"}) && {(_x select 2) <= 60} && {(_x select 3) <= 800}
        } >= 0}];
        if (_nearTier) then {
            private _vehicleOwnsMovement = _groupMovementOwned;
            {
                if (local _x && {!(_x getVariable ["Waldo_AIPass_Spotter", false])} && {binocular _x != ""} && {currentWeapon _x == binocular _x} && {primaryWeapon _x != ""}) then {
                    _x selectWeapon (primaryWeapon _x);
                };
            } forEach _alive;
            if (!_lambsCombat) then {
                if (["Waldo_AIPass_FireControl_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_CortexFireControl};
                if (["Waldo_AIPass_Stance_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_CortexStance};
                if (["Waldo_AIPass_AntiArmour_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_CortexAntiArmour};
                if (["Waldo_AIPass_Vehicles_Enable", true] call _get) then {
                    _vehicleOwnsMovement = [_group, _state, _enemies] call Waldo_fnc_CortexVehicles;
                };
                if ((["Waldo_AIPass_ContactReports_Enable", true] call _get) && {_now - (_state getOrDefault ["lastReport", -1e6]) >= 20}) then {
                    [_group, _state, _visible] call Waldo_fnc_CortexContactReport;
                };
            };
            if (["Waldo_AIPass_Artillery_Enable", false] call _get) then {[_group, _state, _enemies] call Waldo_fnc_CortexArtilleryRequest};
            if (!_ordered && {["Waldo_AIPass_Reinforce_Enable", true] call _get}) then {[_group, _state] call Waldo_fnc_CortexReinforce};
            // Select one movement owner. A coordinated assault keeps this requester as the
            // base of fire while its responders manoeuvre; it must be decided before a local
            // flank or advance can acquire the same group's movement state.
            private _coordinatedOwnsMovement = _vehicleOwnsMovement;
            if (!_ordered && {!_vehicleOwnsMovement} && {["Waldo_AIPass_CoordinatedAssault_Enable", true] call _get}) then {
                _coordinatedOwnsMovement = [_group, _state] call Waldo_fnc_CortexCoordinatedAssault;
            };
            if (!_ordered && {!_coordinatedOwnsMovement} && {!_lambsCombat}) then {
                private _localTacticStarted = false;
                if (["Waldo_AIPass_Flank_Enable", true] call _get) then {
                    _localTacticStarted = [_group, _state, _enemies] call Waldo_fnc_CortexFlankStart;
                };
                if (!_localTacticStarted && {["Waldo_AIPass_Advance_Enable", true] call _get}) then {
                    [_group, _state, _enemies] call Waldo_fnc_CortexAdvanceStart;
                };
            };
            if (["Waldo_AIPass_AmmoShare_Enable", true] call _get) then {[_group, _state] call Waldo_fnc_CortexAmmoShare};
        };
        // Smoke, terrain and buildings can briefly hide a target while a bounded manoeuvre is still
        // making physical progress. Post-contact may take ownership only after that manoeuvre has
        // completed or explicitly aborted; each drill/support lease already has its own finite timeout.
        private _manoeuvreActive = count (_state getOrDefault ["drill",createHashMap]) > 0
            || {_state getOrDefault ["assaulting",false]}
            || {_state getOrDefault ["responding",false]};
        if (!_manoeuvreActive
            && {(_state getOrDefault ["phase",""]) == "CONTACT"}
            && {_now - (_state getOrDefault ["lastSeen", _now]) > (["Waldo_AIPass_PostContact_LostSeconds", 30] call _get)}) then {
            if (["Waldo_AIPass_PostContact_Enable", true] call _get) then {
                _state set ["phase", "SECURITY"];
                _state set ["phaseStart", _now];
            } else {
                [_group, _state] call Waldo_fnc_CortexRestoreCalm;
            };
        };
    };
    case "SECURITY": {
        if (_visible isNotEqualTo []) exitWith {call _beginContact};
        if (_now - (_state get "phaseStart") < (["Waldo_AIPass_PostContact_SecuritySeconds", 10] call _get)) exitWith {_delay = 2};
        private _searchPos = _state getOrDefault ["enemyPos", []];
        private _team = [];
        if (!_ordered && {count _searchPos >= 2}) then {
            private _riflemen = _alive select {local _x && {_x != _leader} && {vehicle _x == _x} && {([_x] call Waldo_fnc_CortexUnitRole) == "RIFLE"}};
            private _ranked = [];
            {_ranked pushBack [_x distance2D _searchPos, _forEachIndex]} forEach _riflemen;
            _ranked sort true;
            _team = (_ranked select [0, 2]) apply {_riflemen select (_x select 1)};
        };
        if (_team isEqualTo []) exitWith {
            _state set ["phase", "REGROUP"];
            _state set ["phaseStart", _now];
            _delay = 3;
        };
        {_x doMove (_searchPos getPos [4 + _forEachIndex * 4, random 360])} forEach _team;
        _state set ["searchTeam", _team];
        _state set ["phase", "SEARCH"];
        _state set ["phaseStart", _now];
        _delay = 3;
    };
    case "SEARCH": {
        private _team = (_state getOrDefault ["searchTeam", []]) select {alive _x && {local _x}};
        private _searchPos = _state getOrDefault ["enemyPos", []];
        private _done = _visible isNotEqualTo [] || {_team isEqualTo []}
            || {_team findIf {_x distance2D _searchPos > 15} < 0}
            || {_now - (_state get "phaseStart") > (["Waldo_AIPass_PostContact_SearchSeconds", 45] call _get)};
        if (_done) then {
            {_x doFollow _leader} forEach _team;
            _state set ["searchTeam", []];
            if (_visible isNotEqualTo []) then {call _beginContact} else {
                _state set ["phase", "REGROUP"];
                _state set ["phaseStart", _now];
                _delay = 3;
            };
        } else {
            _delay = 3;
        };
    };
    case "REGROUP": {
        if (_visible isNotEqualTo []) exitWith {
            _state deleteAt "consolidateIssued";
            _group setVariable ["Waldo_Cortex_Consolidation", ["CONTACT", 0, 0, 0], true];
            call _beginContact;
        };
        // Explicit holding orders and the post-contact gate outrank automatic consolidation.
        if (_ordered || {!(["Waldo_AIPass_PostContact_Enable", true] call _get)}) exitWith {
            [_group, _state] call Waldo_fnc_CortexRestoreCalm;
        };
        if (["Waldo_AIPass_AmmoShare_Enable", true] call _get) then {[_group, _state] call Waldo_fnc_CortexAmmoShare};
        private _members = _alive select {
            local _x && {vehicle _x == _x} && {lifeState _x != "INCAPACITATED"}
                && {_x checkAIFeature "PATH"} && {_x checkAIFeature "MOVE"}
        };
        // Preserve authored waypoints; following the leader allows the squad to resume its route.
        if (_now - (_state getOrDefault ["consolidateIssued", -1e6]) >= 8) then {
            {
                if (_x != _leader) then {_x doWatch objNull; _x doTarget objNull; _x doFollow _leader};
            } forEach _members;
            _state set ["consolidateIssued", _now];
            _state set ["holders", []];
        };
        private _radius = (12 + 2 * count _members) min 30;
        private _gathered = {_x distance2D _leader <= _radius} count _members;
        private _furthest = 0;
        {_furthest = _furthest max (_x distance2D _leader)} forEach _members;
        private _closed = _gathered == count _members;
        private _expired = _now - (_state get "phaseStart") > (["Waldo_AIPass_PostContact_RegroupSeconds", 30] call _get);
        private _status = if (_closed) then {"COHESIVE"} else {["CONSOLIDATING", "INCOMPLETE"] select _expired};
        private _snapshot = [_status, _gathered, count _members, round _furthest];
        if (_snapshot isNotEqualTo (_group getVariable ["Waldo_Cortex_Consolidation", []])) then {
            _group setVariable ["Waldo_Cortex_Consolidation", _snapshot, true];
        };
        if (_closed || {_expired}) then {
            // Expiry releases control but remains INCOMPLETE; it is never reported as arrival.
            [_group, _state] call Waldo_fnc_CortexRestoreCalm;
        } else {
            _delay = 3;
        };
    };
    case "RETREAT": {
        _delay = 3;
        if ((["Waldo_AIPass_Morale_Enable", true] call _get)
            && {([_group, _state, _enemies] call Waldo_fnc_CortexMorale) == "SURRENDER"}) exitWith {[_group] call Waldo_fnc_CortexSurrender};
        private _moving = (waypoints _group) findIf {(_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}} >= 0;
        private _start = _state getOrDefault ["retreatStart",getPosATL _leader];
        private _travel = _leader distance2D _start;
        private _progress = _state getOrDefault ["retreatProgress",[_now,0,0]];
        _progress params ["_progressAt","_bestTravel","_replans"];
        // Only net withdrawal counts. Sideways or back-and-forth motion must not keep a
        // broken route alive forever merely because the actor crossed a three-metre circle.
        if (_travel >= _bestTravel+3) then {
            _progressAt = _now;
            _bestTravel = _travel;
        };
        private _shortWithdrawal = !_moving && {_travel < 30};
        private _stalled = _moving && {_now-_progressAt >= 15};
        if ((_shortWithdrawal || {_stalled}) && {_replans < 4}) then {
            private _enemyPos = _state getOrDefault ["enemyPos",[]];
            private _target = _state getOrDefault ["retreatTarget",getPosATL _leader];
            private _distance = ((_leader distance2D _target) max 80) min 250;
            private _away = if (count _enemyPos >= 2) then {_enemyPos getDir _leader} else {(getDir _leader)+180};
            private _angle = [30,-30,60,-60] select (_replans mod 4);
            private _candidate = (getPosATL _leader) getPos [_distance,_away+_angle];
            if (surfaceIsWater _candidate) then {_candidate = (getPosATL _leader) getPos [_distance,_away-_angle]};
            [_group,_candidate,30] call Waldo_fnc_CortexGroupMove;
            _state set ["retreatTarget",_candidate];
            _replans = _replans+1;
            _progressAt = _now;
            _bestTravel = _travel;
            _moving = true;
        };
        _state set ["retreatProgress",[_progressAt,_bestTravel,_replans]];
        private _timedOut = _now - (_state get "phaseStart") > 120;
        private _status = if (_timedOut) then {"INCOMPLETE"} else {["MOVING","WITHDRAWN"] select (!_moving && {_travel >= 30})};
        _group setVariable ["Waldo_Cortex_Withdrawal",[_status,round _travel,_replans],true];
        if ((!_moving && {_travel >= 30}) || {_timedOut}) then {
            [_group] call Waldo_fnc_CortexGroupMoveClear;
            _state set ["phase", "REGROUP"];
            _state set ["phaseStart", _now];
        };
    };
};
// Reaction speed (AI Tuning): above 1 squads re-assess more often, below 1 less often.
(_delay / ((missionNamespace getVariable ["Waldo_AIPass_ReactionSpeed", 1]) max 0.25)) max 0.5
