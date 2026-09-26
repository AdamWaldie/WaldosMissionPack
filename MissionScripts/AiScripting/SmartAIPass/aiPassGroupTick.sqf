/*
 * Author: WaldoTheWarfighter
 * Runs one Smart AI Pass step for one locally owned group: reads the situation, moves it along the
 * group state ladder and calls each enabled behaviour.
 *
 * State ladder with post-contact search and hysteresis:
 * CALM -> CONTACT when an enemy was seen in the last 10 s.
 * CALM -> INVESTIGATE when the squad knows about an enemy within
 *   Waldo_AIPass_Investigate_Range that it has not seen, for example one revealed by a contact report
 *   or heard firing, and the behaviour profile's investigateChance roll succeeds (at most every
 *   120 s). Within 150 m, two riflemen check the believed position while the rest watch it; a small
 *   squad, or any farther contact, has the whole squad move up together. It ends after
 *   Waldo_AIPass_Investigate_Seconds or on arrival, back in CALM.
 * CONTACT -> SECURITY after Waldo_AIPass_PostContact_LostSeconds without a sighting (or straight back
 *   to CALM when post-contact is off).
 * SECURITY (hold) -> SEARCH (two riflemen check the last known enemy position) -> REGROUP (wait for
 *   the squad to close up) -> CALM, which restores the recorded behaviour and speed (a squad that
 *   was SAFE before a real firefight returns AWARE).
 * RETREAT (morale broken or a damaged vehicle withdrawing) -> REGROUP.
 * Any sighting during SECURITY, SEARCH or REGROUP returns the group to CONTACT.
 * CARELESS groups are left entirely to the mission maker.
 * Waldo_AIPass_ReactionSpeed (AI Tuning) divides the step interval, so squads re-assess faster or slower.
 * A squad riding as cargo in an AI-flown aircraft is handled by airborne insertion instead
 * (Waldo_fnc_AIPassAirborneCheck) until it has parachuted and landed.
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
 * Zeus always wins: a group Zeus is commanding is ineligible (Waldo_fnc_AIPassZeusHeld), so it is
 * released, and Zeus waypoints also release WMP garrison, defence and clear orders on it.
 * Locality and authority: runs as a scheduler job on the group owner. When the group stops being
 * local the job retires and the new owner's discovery sweep starts a fresh one.
 *
 * Review contract: Waypoint completion compares tagged indices with currentWaypoint; completed waypoints may remain in the engine list. This allows rally arrival and retreat completion to be detected.
 *
 * Arguments:
 * 0: job <HASHMAP> - contains "group"
 *
 * Return Value:
 * Number - seconds until the next step, or -1 to retire the job
 *
 * Example:
 * [Waldo_fnc_AIPassGroupTick, createHashMapFromArray [["group", _group]], 1] call Waldo_fnc_AIPassQueueJob;
 * Result: the group is managed by the pass on this machine.
 *
 * Current caller: jobs queued by Waldo_fnc_AIPassDiscover.
 */

params [["_job", createHashMap, [createHashMap]]];
private _group = _job getOrDefault ["group", grpNull];
if (isNull _group) exitWith {-1};
if (!local _group || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}) exitWith {
    _group setVariable ["Waldo_AIPass_Managed", nil];
    -1
};
private _alive = (units _group) select {alive _x};
if (_alive isEqualTo []) exitWith {
    _group setVariable ["Waldo_AIPass_Managed", nil];
    -1
};
if !([_group] call Waldo_fnc_AIPassIsEligible) exitWith {
    if (count (_group getVariable ["Waldo_AIPass_State", createHashMap]) > 0) then {[_group, false] call Waldo_fnc_AIPassReleaseGroup};
    // Zeus waypoints outrank a WMP order that holds soldiers in place: release it so they can move.
    if (_group getVariable ["Waldo_AIPass_ZeusWaypoints", false]) then {
        if ((_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_AIPassGarrisonRelease};
        if ((_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo []) then {[_group] call Waldo_fnc_AIPassDefendRelease};
        if (_group getVariable ["Waldo_AIPass_ClearBuilding", false]) then {_group setVariable ["Waldo_AIPass_ClearBuilding", nil, true]; _group setVariable ["Waldo_AIPass_ClearOrder", nil, true]};
    };
    [20, 5] select ([_group] call Waldo_fnc_AIPassZeusHeld)
};
// Survivor regroup owns a remnant while it is being merged.
if (_group getVariable ["Waldo_AIPass_RegroupQueued", false]) exitWith {5};
private _leader = leader _group;
if (behaviour _leader == "CARELESS") exitWith {10};
// Airborne insertion owns a squad while it rides an aircraft or is parachuting down.
if (_group getVariable ["Waldo_AIPass_Dropping", false]) exitWith {3};
private _airborneDelay = [_group, [_group] call Waldo_fnc_AIPassGroupState] call Waldo_fnc_AIPassAirborneCheck;
if (_airborneDelay >= 0) exitWith {_airborneDelay};

private _state = [_group] call Waldo_fnc_AIPassGroupState;
private _now = time;
private _get = {missionNamespace getVariable _this};

private _nearest = 1e6;
{_nearest = _nearest min (_leader distance2D _x)} forEach (missionNamespace getVariable ["Waldo_AIPass_PlayerPositions", []]);
private _farRange = ["Waldo_AIPass_FarRange", 2500] call _get;
private _nearTier = _nearest <= _farRange;
private _delay = switch (true) do {
    case (_nearest <= (["Waldo_AIPass_NearRange", 1000] call _get)): {["Waldo_AIPass_TickNear", 4] call _get};
    case (_nearTier): {["Waldo_AIPass_TickMid", 8] call _get};
    default {["Waldo_AIPass_TickFar", 20] call _get};
};
if !(["Waldo_AIPass_Contact_Enable", true] call _get) exitWith {_delay};

([_group] call Waldo_fnc_AIPassKnowledge) params ["_enemies", "_seenCount"];
private _visible = _enemies select {(_x select 2) <= 10};
private _garrisoned = (_group getVariable ["Waldo_AIPass_Garrison", []]) isNotEqualTo [];
private _defending = (_group getVariable ["Waldo_AIPass_Defend", []]) isNotEqualTo [];
private _ordered = _garrisoned || {_defending} || {_group getVariable ["Waldo_AIPass_ClearBuilding", false]};
private _lambsCombat = (missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false])
    && {toUpperANSI (["Waldo_AIPass_LambsMode", "SPLIT"] call _get) == "SPLIT"}
    && {!(_group getVariable ["lambs_danger_disableGroupAI", false])};
private _contactDelay = if (_nearTier) then {["Waldo_AIPass_TickContact", 2] call _get} else {_delay};

// Soldiers holding ground from a finished drill rejoin once the leader has caught up with them.
private _holders = (_state getOrDefault ["holders", []]) select {alive _x && {local _x} && {group _x == _group}};
if (_holders isNotEqualTo []) then {
    private _rejoin = _holders select {_x distance2D _leader < 30};
    {_x doFollow _leader} forEach _rejoin;
    _state set ["holders", _holders - _rejoin];
};

private _enterContact = {
    _state set ["phase", "CONTACT"];
    _state set ["phaseStart", _now];
    _state set ["lastSeen", _now];
    _state set ["hadContact", true];
    _state set ["enemyPos", (_visible select 0) select 1];
    _state set ["contactLeader", _leader];
    // A responder keeps its assault waypoint; one still moving to the rally point fights where it is.
    if (_state getOrDefault ["responding", false] && {!(_state getOrDefault ["assaulting", false])}) then {
        [_group] call Waldo_fnc_AIPassGroupMoveClear;
        _state set ["responding", false];
    };
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
    if !(_state getOrDefault ["assaulting", false]) then {[_group] call Waldo_fnc_AIPassGroupMoveClear};
    call _enterContact;
    if (behaviour _leader in ["SAFE", "AWARE"]) then {
        _group setBehaviour "COMBAT";
        _state set ["behaviourChanged", true];
    };
    if (_nearTier && {!_lambsCombat} && {["Waldo_AIPass_ContactReports_Enable", true] call _get}) then {
        [_group, _state, _visible] call Waldo_fnc_AIPassContactReport;
    };
    if (_nearTier && {!_ordered} && {["Waldo_AIPass_Reinforce_Enable", true] call _get}) then {
        [_group, _state] call Waldo_fnc_AIPassReinforce;
    };
    if (["Waldo_AIPass_Debug", false] call _get) then {
        diag_log format ["[WMP AI PASS] %1 CONTACT enemies=%2 seen=%3", _group, count _enemies, _seenCount];
    };
    _delay = _contactDelay;
};

switch (_state get "phase") do {
    case "CALM": {
        if (_state getOrDefault ["responding", false]) then {
            private _requester = _state getOrDefault ["respondingTo", grpNull];
            // Read only: never create pass state on the requester's group from here.
            private _requesterPhase = if (isNull _requester) then {"CALM"} else {
                (_requester getVariable ["Waldo_AIPass_State", createHashMap]) getOrDefault ["phase", "CALM"]
            };
            if (isNull _requester || {({alive _x} count units _requester) == 0} || {_requesterPhase == "CALM"}
                || {_now > (_state getOrDefault ["respondUntil", 0])}) then {
                [_group] call Waldo_fnc_AIPassGroupMoveClear;
                {_state deleteAt _x} forEach ["responding", "respondingTo", "arrivedAt", "assaulting"];
            } else {
                // Arrived at the rally point once the inserted waypoint has been completed.
                if ((_state getOrDefault ["arrivedAt", -1]) < 0 && {(waypoints _group) findIf {(_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}} < 0}) then {
                    _state set ["arrivedAt", _now];
                };
            };
        };
        if (_visible isNotEqualTo []) exitWith {call _beginContact};
        if (!_ordered && {!(_state getOrDefault ["responding", false])} && {_enemies isNotEqualTo []}
            && {["Waldo_AIPass_Investigate_Enable", true] call _get}
            && {((_enemies select 0) select 3) <= (["Waldo_AIPass_Investigate_Range", 300] call _get)}
            && {!([_state, "investigate"] call Waldo_fnc_AIPassCooldown)}) then {
            [_state, "investigate", 120] call Waldo_fnc_AIPassCooldown;
            if (random 1 < ([_group, "investigateChance"] call Waldo_fnc_AIPassProfile)) then {
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
                    _team = (_onFoot select {_x != _leader && {([_x] call Waldo_fnc_AIPassUnitRole) == "RIFLE"}}) select [0, 2];
                };
                if (_team isEqualTo []) then {
                    [_group, _target getPos [30, _target getDir _leader], 25] call Waldo_fnc_AIPassGroupMove;
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
            [_group, _state] call Waldo_fnc_AIPassRestoreCalm;
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
            _outcome = [_group, _state, _enemies] call Waldo_fnc_AIPassMorale;
        };
        if (_outcome == "SURRENDER") exitWith {[_group] call Waldo_fnc_AIPassSurrender};
        if (_garrisoned || {_defending}) then {
            private _order = if (_garrisoned) then {_group getVariable ["Waldo_AIPass_Garrison", []]} else {_group getVariable ["Waldo_AIPass_Defend", []]};
            private _orderStrength = (_order param [[3, 2] select _garrisoned, count _alive]) max 1;
            if (count _alive / _orderStrength <= (["Waldo_AIPass_Garrison_BreakFraction", 0.5] call _get)) then {
                if (_garrisoned) then {[_group] call Waldo_fnc_AIPassGarrisonRelease} else {[_group] call Waldo_fnc_AIPassDefendRelease};
                _garrisoned = false;
                _defending = false;
                _ordered = _group getVariable ["Waldo_AIPass_ClearBuilding", false];
            } else {
                if (_defending) then {[_group, _state, _enemies] call Waldo_fnc_AIPassDefendStep};
            };
        };
        if (_outcome == "RETREAT") exitWith {
            switch (true) do {
                case (_garrisoned): {[_group] call Waldo_fnc_AIPassGarrisonRelease};
                case (_defending): {[_group] call Waldo_fnc_AIPassDefendRelease};
                case (_group getVariable ["Waldo_AIPass_ClearBuilding", false]): {};
                default {[_group, _state] call Waldo_fnc_AIPassRetreat};
            };
        };
        _state set ["armourSeen", (_state getOrDefault ["armourSeen", false]) || {_enemies findIf {
            private _enemy = vehicle (_x select 0);
            (_enemy isKindOf "Tank" || {_enemy isKindOf "Wheeled_APC_F"}) && {(_x select 2) <= 60} && {(_x select 3) <= 800}
        } >= 0}];
        if (_nearTier) then {
            {
                if (local _x && {!(_x getVariable ["Waldo_AIPass_Spotter", false])} && {binocular _x != ""} && {currentWeapon _x == binocular _x} && {primaryWeapon _x != ""}) then {
                    _x selectWeapon (primaryWeapon _x);
                };
            } forEach _alive;
            if (!_lambsCombat) then {
                if (["Waldo_AIPass_FireControl_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassFireControl};
                if (["Waldo_AIPass_Stance_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassStance};
                if (["Waldo_AIPass_AntiArmour_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassAntiArmour};
                if (["Waldo_AIPass_Vehicles_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassVehicles};
                if (!_ordered && {["Waldo_AIPass_Flank_Enable", true] call _get}) then {[_group, _state, _enemies] call Waldo_fnc_AIPassFlankStart};
                if (!_ordered && {["Waldo_AIPass_Advance_Enable", true] call _get}) then {[_group, _state, _enemies] call Waldo_fnc_AIPassAdvanceStart};
                if ((["Waldo_AIPass_ContactReports_Enable", true] call _get) && {_now - (_state getOrDefault ["lastReport", -1e6]) >= 20}) then {
                    [_group, _state, _visible] call Waldo_fnc_AIPassContactReport;
                };
            };
            if (["Waldo_AIPass_Artillery_Enable", false] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassArtilleryRequest};
            if (!_ordered && {["Waldo_AIPass_Reinforce_Enable", true] call _get}) then {[_group, _state] call Waldo_fnc_AIPassReinforce};
            if (["Waldo_AIPass_CoordinatedAssault_Enable", true] call _get) then {[_group, _state] call Waldo_fnc_AIPassCoordinatedAssault};
            if (["Waldo_AIPass_AmmoShare_Enable", true] call _get) then {[_group, _state] call Waldo_fnc_AIPassAmmoShare};
        };
        if (_now - (_state getOrDefault ["lastSeen", _now]) > (["Waldo_AIPass_PostContact_LostSeconds", 30] call _get)) then {
            if (["Waldo_AIPass_PostContact_Enable", true] call _get) then {
                _state set ["phase", "SECURITY"];
                _state set ["phaseStart", _now];
            } else {
                [_group, _state] call Waldo_fnc_AIPassRestoreCalm;
            };
        };
    };
    case "SECURITY": {
        if (_visible isNotEqualTo []) exitWith {call _beginContact};
        if (_now - (_state get "phaseStart") < (["Waldo_AIPass_PostContact_SecuritySeconds", 10] call _get)) exitWith {_delay = 2};
        private _searchPos = _state getOrDefault ["enemyPos", []];
        private _team = [];
        if (!_ordered && {count _searchPos >= 2}) then {
            private _riflemen = _alive select {local _x && {_x != _leader} && {vehicle _x == _x} && {([_x] call Waldo_fnc_AIPassUnitRole) == "RIFLE"}};
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
        if (_visible isNotEqualTo []) exitWith {call _beginContact};
        if (["Waldo_AIPass_AmmoShare_Enable", true] call _get) then {[_group, _state] call Waldo_fnc_AIPassAmmoShare};
        private _closed = _alive findIf {vehicle _x == _x && {_x distance2D _leader > 60}} < 0;
        if (_closed || {_now - (_state get "phaseStart") > (["Waldo_AIPass_PostContact_RegroupSeconds", 30] call _get)}) then {
            [_group, _state] call Waldo_fnc_AIPassRestoreCalm;
        } else {
            _delay = 3;
        };
    };
    case "RETREAT": {
        _delay = 3;
        if ((["Waldo_AIPass_Morale_Enable", true] call _get)
            && {([_group, _state, _enemies] call Waldo_fnc_AIPassMorale) == "SURRENDER"}) exitWith {[_group] call Waldo_fnc_AIPassSurrender};
        private _moving = (waypoints _group) findIf {(_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}} >= 0;
        if (!_moving || {_now - (_state get "phaseStart") > 120}) then {
            [_group] call Waldo_fnc_AIPassGroupMoveClear;
            _state set ["phase", "REGROUP"];
            _state set ["phaseStart", _now];
        };
    };
};
// Reaction speed (AI Tuning): above 1 squads re-assess more often, below 1 less often.
(_delay / ((missionNamespace getVariable ["Waldo_AIPass_ReactionSpeed", 1]) max 0.25)) max 0.5
