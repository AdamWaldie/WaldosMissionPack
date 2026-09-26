/*
 * Author: WaldoTheWarfighter
 * Advances a running drill (flank or bounding advance) by one step: issue a bound, wait for arrival,
 * pause and overwatch, cross streets under smoke, and finish by holding the ground won or assaulting.
 *
 * Bounds: each member gets his own spot, spread 5 m apart across the direction of travel. Ordinary
 * bounds, the final position and the assault position are snapped to cover facing the enemy
 * (Waldo_fnc_AIPassFindCover); street crossings and the clearing rush are not. On ordinary bounds and
 * street crossings, members have TARGET and AUTOTARGET switched off so they do not stop to trade fire
 * mid-bound; the final approach, assault and clearing rush keep both on so they can engage. Only features
 * that were on are switched off, and they are switched back on at every halt, so mission-maker
 * disableAI settings survive (Smart Combat V2 re-enabled them unconditionally). A bound ends when
 * every member is within 7 m of his spot or after Waldo_AIPass_Flank_BoundTimeout. Halts last
 * Waldo_AIPass_Flank_BoundPause seconds, 3 s at a street edge, and 20 s (flank) or 10 s (advance) at
 * the final position.
 * Final assault (Smart Combat V2's phased assault; Waldo_AIPass_Assault_Enable): after a flank's hold,
 * if the enemy is believed within Waldo_AIPass_Assault_Range of the element, morale is STEADY and the
 * behaviour profile's assaultChance roll succeeds, one member throws a fragmentation grenade
 * (Waldo_fnc_AIPassThrowGrenade, never near friendlies). The element then bounds to a covered spot
 * 12 m short of the enemy and rushes the position, while the base of fire keeps suppressing.
 * Ending: a completed drill leaves the element holding the ground it took. Members rejoin formation
 * when the leader comes within 30 m, when the squad returns to CALM, or when it retreats (Digii's
 * flank without the audited faults: the element no longer runs straight back to the leader, which
 * undid the manoeuvre). The drill aborts, with members following the leader again, when the group
 * leaves CONTACT, Zeus takes the group (Waldo_fnc_AIPassZeusHeld), or half the element is lost. It
 * also ends, holding ground, when an enemy is believed within 30 m before the assault. Only element
 * members receive move orders; the leader never does.
 * Locality and authority: scheduler job on the group owner.
 *
 * Review contract: Every step rechecks full group eligibility and its behaviour switch. Existing jobs stop after exclusion, remote control or a live disable.
 *
 * Arguments:
 * 0: job <HASHMAP> - contains "group"
 *
 * Return Value:
 * Number - seconds until the next step, or -1 when the drill ended
 *
 * Example:
 * [Waldo_fnc_AIPassFlankStep, createHashMapFromArray [["group", _group]], 0] call Waldo_fnc_AIPassQueueJob;
 * Result: the element moves one stage further.
 *
 * Current callers: Waldo_fnc_AIPassFlankStart and Waldo_fnc_AIPassAdvanceStart.
 */

params [["_job", createHashMap, [createHashMap]]];
private _group = _job getOrDefault ["group", grpNull];
if (isNull _group || {!local _group}) exitWith {-1};
private _state = _group getVariable ["Waldo_AIPass_State", createHashMap];
private _drill = _state getOrDefault ["drill", createHashMap];
if (count _drill == 0) exitWith {-1};
private _end = {
    [_group, _state, _this] call Waldo_fnc_AIPassFlankEnd;
    -1
};
if (!(missionNamespace getVariable ["Waldo_AIPass_Active", false]) || {(_state getOrDefault ["phase", ""]) != "CONTACT"}
    || {!([_group] call Waldo_fnc_AIPassIsEligible)}
    || {!(missionNamespace getVariable [["Waldo_AIPass_Flank_Enable", "Waldo_AIPass_Advance_Enable"] select ((_drill getOrDefault ["type", "FLANK"]) == "ADVANCE"), true])}) exitWith {"ABORT" call _end};
private _allUnits = _drill get "units";
private _units = _allUnits select {alive _x && {local _x} && {vehicle _x == _x} && {group _x == _group}};
if (count _units < ((count _allUnits / 2) max 1)) exitWith {"LOSSES" call _end};
private _centroid = [0, 0, 0];
{_centroid = _centroid vectorAdd getPosATL _x} forEach _units;
_centroid = _centroid vectorMultiply (1 / count _units);
private _enemyPos = _state getOrDefault ["enemyPos", _drill get "enemyPos"];
private _assaulting = _drill getOrDefault ["assaulting", false];
if (!_assaulting && {_centroid distance2D _enemyPos < 30}) exitWith {"CLOSE" call _end};

private _points = _drill get "points";
private _now = time;
private _restoreFeatures = {
    {
        _x params ["_unit", "_feature"];
        if (alive _unit && {local _unit}) then {_unit enableAI _feature};
    } forEach (_drill get "disabled");
    _drill set ["disabled", []];
};
private _issue = {
    (_points select (_drill get "index")) params ["_point", "_kind"];
    private _direction = _centroid getDir _point;
    private _spots = [];
    private _disabled = [];
    {
        private _unit = _x;
        private _spot = _point getPos [(_forEachIndex - (count _units - 1) / 2) * ([5, 3] select (_kind == "CLEAR")), _direction + 90];
        if (_kind in ["BOUND", "FINAL", "ASSAULT"]) then {
            _spot = ([_spot, _enemyPos, [10, 6] select (_kind == "ASSAULT"), _spots] call Waldo_fnc_AIPassFindCover) select 0;
        };
        _spots pushBack _spot;
        // Only movement bounds suppress target switching; the final approach, assault and clear
        // must be able to engage the enemy they are closing on.
        if (_kind in ["BOUND", "CROSS_NEAR", "CROSS_FAR"]) then {
            {
                if (_unit checkAIFeature _x) then {
                    _unit disableAI _x;
                    _disabled pushBack [_unit, _x];
                };
            } forEach ["TARGET", "AUTOTARGET"];
        };
        _unit doMove _spot;
    } forEach _units;
    _drill set ["spots", _spots];
    _drill set ["movers", +_units];
    _drill set ["disabled", _disabled];
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
        {
            if (alive _x && {_x in _units} && {_x distance2D (_spots select _forEachIndex) > 7}) exitWith {_arrived = false};
        } forEach _movers;
        if (_arrived || {_now - (_drill get "boundStart") > (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundTimeout", 25])}) then {
            call _restoreFeatures;
            switch ((_points select (_drill get "index")) select 1) do {
                case "CROSS_NEAR": {
                    _drill set ["stage", "PAUSE"];
                    _drill set ["pauseUntil", _now + 3];
                    [selectRandom _units, _enemyPos, "SMOKE"] call Waldo_fnc_AIPassThrowGrenade;
                };
                case "FINAL": {
                    _drill set ["stage", "HOLD"];
                    _drill set ["pauseUntil", _now + ([10, 20] select ((_drill getOrDefault ["type", "FLANK"]) == "FLANK"))];
                };
                case "CLEAR": {
                    _drill set ["stage", "HOLD"];
                    _drill set ["pauseUntil", _now + 10];
                };
                default {
                    _drill set ["stage", "PAUSE"];
                    _drill set ["pauseUntil", _now + (missionNamespace getVariable ["Waldo_AIPass_Flank_BoundPause", 4])];
                };
            };
        };
    };
    case "PAUSE": {
        if (_now >= (_drill get "pauseUntil")) then {
            _drill set ["index", (_drill get "index") + 1];
            if ((_drill get "index") >= count _points) then {_result = "COMPLETE" call _end} else {call _issue};
        };
    };
    case "HOLD": {
        if (_now >= (_drill get "pauseUntil")) then {
            private _assault = !_assaulting
                && {(_drill getOrDefault ["type", "FLANK"]) == "FLANK"}
                && {missionNamespace getVariable ["Waldo_AIPass_Assault_Enable", true]}
                && {(_state getOrDefault ["moraleState", "STEADY"]) == "STEADY"}
                && {_centroid distance2D _enemyPos <= (missionNamespace getVariable ["Waldo_AIPass_Assault_Range", 80])}
                && {random 1 < ([_group, "assaultChance"] call Waldo_fnc_AIPassProfile)};
            if (_assault) then {
                _drill set ["assaulting", true];
                _points pushBack [_enemyPos getPos [12, _enemyPos getDir _centroid], "ASSAULT"];
                _points pushBack [_enemyPos, "CLEAR"];
                private _thrower = _units select {_x distance2D _enemyPos <= 40};
                if (_thrower isNotEqualTo []) then {[selectRandom _thrower, _enemyPos, "FRAG"] call Waldo_fnc_AIPassThrowGrenade};
                missionNamespace setVariable ["Waldo_AIPass_Assaults", (missionNamespace getVariable ["Waldo_AIPass_Assaults", 0]) + 1];
                _drill set ["stage", "PAUSE"];
                _drill set ["pauseUntil", _now + 3];
            } else {
                _result = "COMPLETE" call _end;
            };
        };
    };
};
_result
