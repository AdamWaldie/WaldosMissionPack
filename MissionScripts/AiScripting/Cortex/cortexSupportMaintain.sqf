/*
 * Author: WaldoTheWarfighter
 * Releases only the current WMP support assignment when it expires, is revoked or loses its feature gate.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Restores the recorded autonomous-attack setting when the support move is released.
 * Measures physical rally arrival in both calm and contact phases; seeing an enemy
 * does not cancel an accepted reinforcement reservation.
 * A failed bound keeps its PATH holds until a new MOVE sequence or reservation release;
 * the old MOVE role must not release them on the next group tick.
 * On release, actors held by Cortex resume formation even when engine combat has
 * relabelled the owned doStop as ATTACK/FIRE. Commands which can only have arrived
 * after the hold are preserved, and new-bound movement is not replaced.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: group <GROUP>; 1: local state <HASHMAP>.
 * Return Value: Nothing.
 * Current callers: GroupTick.
 * Example: [_group, _state] call Waldo_fnc_CortexSupportMaintain;
 */
params ["_group","_state"];
if (!local _group) exitWith {};
private _movementLease = _state getOrDefault ["movementLease",[]];
private _movementLeaseActive = count _movementLease == 2 && {time < (_movementLease select 1)} && {
    (waypoints _group) findIf {
        (_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}
    } >= 0
};
private _token = _state getOrDefault ["supportToken",""];
if (_token == "") exitWith {};
private _restoreAttack={
    if (_state getOrDefault ["attackChanged",false]) then {_group enableAttack (_state getOrDefault ["baseAttack",true])};
    _state deleteAt "attackChanged"; _state deleteAt "baseAttack";
};
private _lease = _group getVariable ["Waldo_AIPass_SupportLease",[]];
if (_lease isEqualTo [] || {(_lease select 0) != _token} || {serverTime >= (_lease select 2)}
    || {!([_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!([_group,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) then {
    // The support token owns only its own rally/assault. If a later vehicle or artillery
    // behaviour has acquired the shared route, retire stale support state without deleting it.
    if (!_movementLeaseActive && {_state getOrDefault ["responding",false] || {_state getOrDefault ["assaulting",false]}}) then {
        [_group] call Waldo_fnc_CortexGroupMoveClear
    };
    call _restoreAttack;
    {_state deleteAt _x} forEach ["supportToken","responding","respondingTo","respondUntil","arrivedAt","assaulting"];
};

if (_state getOrDefault ["assaulting",false] && {!([_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) then {
    if (!_movementLeaseActive) then {[_group] call Waldo_fnc_CortexGroupMoveClear};
    call _restoreAttack;
    _state set ["assaulting",false]; _state set ["responding",false];
};

// Contact can begin before the rally is reached. Readiness must not depend on CALM.
if ((_state getOrDefault ["supportToken",""]) == _token
    && {_state getOrDefault ["responding",false]}
    && {!(_state getOrDefault ["assaulting",false])}
    && {(_state getOrDefault ["arrivedAt",-1]) < 0}
    && {count _lease == 6}) then {
    private _fit=(units _group) select {[_x] call Waldo_fnc_CortexCombatEffective};
    if (count _fit >= 3 && {_fit findIf {_x distance2D (_lease select 3) > 45} < 0}) then {
        _state set ["arrivedAt",time];
    };
};

// Server roles own inter-squad timing; the existing drill owns the two local fire teams.
private _role=_group getVariable ["Waldo_Cortex_SupportRole",[]];
private _coordinating=(_state getOrDefault ["supportToken",""]) == _token
    && {_state getOrDefault ["assaulting",false]} && {count _role == 5} && {(_role select 0) == _token};
private _moving=_coordinating && {(_role select 2) == "MOVE"};
private _held=_state getOrDefault ["supportHeld",[]];
private _newMove=_moving && {(_state getOrDefault ["supportBoundSequence",-1]) != (_role select 1)};
if (_newMove || {!_coordinating}) then {
    {
        if (local _x && {group _x == _group}) then {
            _x enableAI "PATH";
            // supportHeld is the ownership record. Combat can relabel our doStop
            // as ATTACK or FIRE without cancelling it, so currentCommand == STOP
            // is not a valid ownership check. Preserve commands which cannot be a
            // combat-side effect of the hold. A new bound supplies its own target.
            private _command=toUpperANSI currentCommand _x;
            if (!_coordinating && {_command in ["","STOP","ATTACK","FIRE","SUPPRESS"]}) then {
                _x doFollow leader _group;
            };
        };
    } forEach _held;
    _state set ["supportHeld",[]];
};
if (_coordinating) then {
    if (_moving) then {
        if ((_state getOrDefault ["supportBoundSequence",-1]) != (_role select 1)) then {
            [_group,_state,_role] call Waldo_fnc_CortexSupportBoundStart;
        };
    } else {
        private _drill=_state getOrDefault ["drill",createHashMap];
        if ((_drill getOrDefault ["supportToken",""]) == _token) then {[_group,_state,"ABORT"] call Waldo_fnc_CortexFlankEnd};
        {
            if (local _x && {vehicle _x == _x} && {[_x] call Waldo_fnc_CortexCombatEffective} && {_x checkAIFeature "PATH"}) then {
                doStop _x; _x disableAI "PATH"; _held pushBackUnique _x;
            };
        } forEach units _group;
        _state set ["supportHeld",_held];
    };
};
