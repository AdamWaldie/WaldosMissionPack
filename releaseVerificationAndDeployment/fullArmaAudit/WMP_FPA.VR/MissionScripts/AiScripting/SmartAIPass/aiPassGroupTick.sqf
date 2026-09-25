/*
 * Author: WaldoTheWarfighter
 * Runs one Smart AI Pass step for one locally owned group: reads the situation, moves it along the
 * group state ladder and calls each enabled behaviour.
 *
 * State ladder (Digii's ladder, with Scorpion's post-contact doctrine and built-in hysteresis):
 * CALM -> CONTACT when an enemy was seen in the last 10 s.
 * CONTACT -> SECURITY after Waldo_AIPass_PostContact_LostSeconds without a sighting (or straight back
 *   to CALM when post-contact is off).
 * SECURITY (hold) -> SEARCH (two riflemen check the last known enemy position) -> REGROUP (wait for
 *   the squad to close up) -> CALM, which restores the recorded behaviour and speed exactly.
 * RETREAT (morale broken or a damaged vehicle withdrawing) -> REGROUP.
 * Any sighting during SECURITY, SEARCH or REGROUP returns the group to CONTACT.
 * CARELESS groups are left entirely to the mission maker.
 *
 * Cadence (Digii's distance tiers, measured to the nearest player): Waldo_AIPass_TickContact in
 * contact near players; Waldo_AIPass_TickNear within Waldo_AIPass_NearRange; Waldo_AIPass_TickMid
 * within Waldo_AIPass_FarRange; Waldo_AIPass_TickFar beyond. Beyond FarRange only the state ladder
 * and morale run; drills, fire control and support calls are skipped.
 * With LAMBS Danger loaded and Waldo_AIPass_LambsMode "SPLIT", LAMBS keeps in-contact unit tactics
 * (flanking, fire control, anti-armour, vehicles, contact sharing) for groups it manages; WMP keeps
 * the ladder, post-contact, morale, reinforcement and artillery.
 * Locality and authority: runs as a scheduler job on the group owner. When the group stops being
 * local the job retires and the new owner's discovery sweep starts a fresh one.
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
    20
};
// Survivor regroup owns a remnant while it is being merged.
if (_group getVariable ["Waldo_AIPass_RegroupQueued", false]) exitWith {5};
private _leader = leader _group;
if (behaviour _leader == "CARELESS") exitWith {10};

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
private _ordered = _garrisoned || {_group getVariable ["Waldo_AIPass_ClearBuilding", false]};
private _lambsCombat = (missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false])
    && {toUpperANSI (["Waldo_AIPass_LambsMode", "SPLIT"] call _get) == "SPLIT"}
    && {!(_group getVariable ["lambs_danger_disableGroupAI", false])};
private _contactDelay = if (_nearTier) then {["Waldo_AIPass_TickContact", 2] call _get} else {_delay};
private _enterContact = {
    _state set ["phase", "CONTACT"];
    _state set ["phaseStart", _now];
    _state set ["lastSeen", _now];
    _state set ["enemyPos", (_visible select 0) select 1];
    _state set ["contactLeader", _leader];
    if (_state getOrDefault ["responding", false]) then {
        [_group] call Waldo_fnc_AIPassGroupMoveClear;
        _state set ["responding", false];
    };
};

switch (_state get "phase") do {
    case "CALM": {
        if (_state getOrDefault ["responding", false]) then {
            private _requester = _state getOrDefault ["respondingTo", grpNull];
            private _requesterPhase = if (isNull _requester) then {"CALM"} else {([_requester] call Waldo_fnc_AIPassGroupState) get "phase"};
            if (isNull _requester || {({alive _x} count units _requester) == 0} || {_requesterPhase == "CALM"}
                || {_now > (_state getOrDefault ["respondUntil", 0])}) then {
                [_group] call Waldo_fnc_AIPassGroupMoveClear;
                _state set ["responding", false];
                _state set ["respondingTo", grpNull];
            };
        };
        if (_visible isNotEqualTo []) then {
            _state set ["baseBehaviour", behaviour _leader];
            _state set ["baseSpeed", speedMode _group];
            _state set ["behaviourChanged", false];
            _state set ["speedChanged", false];
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
        if (_garrisoned) then {
            private _orderStrength = ((_group getVariable ["Waldo_AIPass_Garrison", []]) param [2, count _alive]) max 1;
            if (count _alive / _orderStrength <= (["Waldo_AIPass_Garrison_BreakFraction", 0.5] call _get)) then {
                [_group] call Waldo_fnc_AIPassGarrisonRelease;
                _garrisoned = false;
                _ordered = _group getVariable ["Waldo_AIPass_ClearBuilding", false];
            };
        };
        if (_outcome == "RETREAT") exitWith {
            if (_garrisoned) then {[_group] call Waldo_fnc_AIPassGarrisonRelease} else {
                if !(_group getVariable ["Waldo_AIPass_ClearBuilding", false]) then {[_group, _state] call Waldo_fnc_AIPassRetreat};
            };
        };
        if (_nearTier) then {
            {
                if (local _x && {binocular _x != ""} && {currentWeapon _x == binocular _x} && {primaryWeapon _x != ""}) then {
                    _x selectWeapon (primaryWeapon _x);
                };
            } forEach _alive;
            if (!_lambsCombat) then {
                if (["Waldo_AIPass_FireControl_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassFireControl};
                if (["Waldo_AIPass_AntiArmour_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassAntiArmour};
                if (["Waldo_AIPass_Vehicles_Enable", true] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassVehicles};
                if (!_ordered && {["Waldo_AIPass_Flank_Enable", true] call _get}) then {[_group, _state, _enemies] call Waldo_fnc_AIPassFlankStart};
                if ((["Waldo_AIPass_ContactReports_Enable", true] call _get) && {_now - (_state getOrDefault ["lastReport", -1e6]) >= 20}) then {
                    [_group, _state, _visible] call Waldo_fnc_AIPassContactReport;
                };
            };
            if (["Waldo_AIPass_Artillery_Enable", false] call _get) then {[_group, _state, _enemies] call Waldo_fnc_AIPassArtilleryRequest};
            if (!_ordered && {["Waldo_AIPass_Reinforce_Enable", true] call _get}) then {[_group, _state] call Waldo_fnc_AIPassReinforce};
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
        if (_visible isNotEqualTo []) exitWith {call _enterContact; _delay = _contactDelay};
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
            if (_visible isNotEqualTo []) then {call _enterContact; _delay = _contactDelay} else {
                _state set ["phase", "REGROUP"];
                _state set ["phaseStart", _now];
                _delay = 3;
            };
        } else {
            _delay = 3;
        };
    };
    case "REGROUP": {
        if (_visible isNotEqualTo []) exitWith {call _enterContact; _delay = _contactDelay};
        private _closed = _alive findIf {vehicle _x == _x && {_x distance2D _leader > 60}} < 0;
        if (_closed || {_now - (_state get "phaseStart") > (["Waldo_AIPass_PostContact_RegroupSeconds", 30] call _get)}) then {
            [_group, _state] call Waldo_fnc_AIPassRestoreCalm;
        } else {
            _delay = 3;
        };
    };
    case "RETREAT": {
        _delay = 3;
        if (["Waldo_AIPass_Morale_Enable", true] call _get) then {
            if (([_group, _state, _enemies] call Waldo_fnc_AIPassMorale) == "SURRENDER") exitWith {[_group] call Waldo_fnc_AIPassSurrender};
        };
        private _moving = (waypoints _group) findIf {waypointDescription _x == "WMP AI PASS"} >= 0;
        if (!_moving || {_now - (_state get "phaseStart") > 120}) then {
            [_group] call Waldo_fnc_AIPassGroupMoveClear;
            _state set ["phase", "REGROUP"];
            _state set ["phaseStart", _now];
        };
    };
};
_delay
