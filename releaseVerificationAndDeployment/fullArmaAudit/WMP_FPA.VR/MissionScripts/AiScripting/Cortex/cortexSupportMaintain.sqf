/*
 * Author: WaldoTheWarfighter
 * Releases only the current WMP support assignment when it expires, is revoked or loses every
 * feature gate capable of owning it. A mode must remain enabled at both ends of the reservation;
 * independent requester/responder checks could otherwise preserve a lease whose next state no
 * longer existed. Disabling reinforcement still cannot cancel a shared coordinated assault.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Restores the recorded autonomous-attack setting when the support move is released.
 * Measures physical rally arrival in both calm and contact phases; seeing an enemy
 * does not cancel an accepted reinforcement reservation.
 * A failed bound keeps its PATH holds until a new MOVE sequence or reservation release;
 * the old MOVE role must not release them on the next group tick. A public per-actor ownership
 * marker survives HC migration and is cleared only when Cortex restores PATH.
 * A live actor-level grenade evasion temporarily outranks the covering PATH hold; the next cover
 * step reacquires that soldier only after the six-second safety move expires.
 * A MOVE role which cannot form two viable local teams reports NOT_READY immediately;
 * the server can yield the turn instead of waiting for its 180-second safety timeout.
 * A server retirement is consumed only when its token matches this local assignment, then releases
 * its PATH holds and movement immediately while the other coordinated squads continue.
 * On release, actors held by Cortex resume formation even when engine combat has
 * relabelled the owned doStop as ATTACK/FIRE. Commands which can only have arrived
 * after the hold are preserved, and new-bound movement is not replaced.
 * Movement ownership uses SUPPORT_RALLY and COORDINATED_ASSAULT leases. Cleanup removes only those
 * lease types and checks that a rally waypoint is still pending, so a completed waypoint is not
 * mistaken for active movement and a newer feature route is never deleted.
 * A live gate closure rejects the exact accepted token back to the server before clearing local
 * state, so a stopped responder cannot retain a coordinated role or consume a support slot.
 * Releasing support also restores the responder's pre-existing LAMBS group-AI setting. The scoped
 * lease prevents LAMBS and Cortex from issuing movement to the same group during rally or assault.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: group <GROUP>; 1: local state <HASHMAP>.
 * Return Value: Nothing.
 * Current callers: GroupTick.
 * Example: [_group, _state] call Waldo_fnc_CortexSupportMaintain;
 * Result: the active assignment advances, holds, or releases without competing movement owners.
 */
params ["_group","_state"];
if (!local _group) exitWith {};
private _movementLease = _state getOrDefault ["movementLease",[]];
private _movementOwner = _movementLease param [0,""];
private _movementLeaseActive = count _movementLease == 2 && {time < (_movementLease select 1)} && {
    switch (_movementOwner) do {
        case "SUPPORT_RALLY": {
            (waypoints _group) findIf {
                (_x select 1) >= currentWaypoint _group && {waypointDescription _x == "WMP AI PASS"}
            } >= 0
        };
        case "COORDINATED_ASSAULT": {_state getOrDefault ["assaulting",false]};
        default {true};
    }
};
private _supportOwnsMovement = _movementLeaseActive && {_movementOwner in ["SUPPORT_RALLY","COORDINATED_ASSAULT"]};
private _token = _state getOrDefault ["supportToken",""];
if (_token == "") exitWith {
    // A locality/checkpoint loss can leave the public movement lease after the local support token.
    // There is no remaining Cortex assignment to own movement, so return it immediately.
    private _lambsLease = _group getVariable ["Waldo_Cortex_LambsLease",[]];
    if (count _lambsLease == 3 && {(_lambsLease select 0) == "SUPPORT"}) then {
        [_group,"SUPPORT",false] call Waldo_fnc_CortexLambsLease;
    };
};
private _restoreAttack={
    if (_state getOrDefault ["attackChanged",false]) then {_group enableAttack (_state getOrDefault ["baseAttack",true])};
    _state deleteAt "attackChanged"; _state deleteAt "baseAttack";
};
private _lease = _group getVariable ["Waldo_AIPass_SupportLease",[]];
private _requester = _lease param [1,grpNull,[grpNull]];
private _sharedReinforce = !isNull _requester
    && {[_requester,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {[_group,"Waldo_AIPass_Reinforce_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _sharedCoordinated = !isNull _requester
    && {[_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
    && {[_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled};
private _supportEnabled = _sharedReinforce || {_sharedCoordinated};
private _releaseSupport={
    // Reject only the exact lease snapshot accepted by this owner. The server validates token,
    // snapshot and sender again, making repeated cleanup and a racing replacement lease harmless.
    if (count _lease == 6 && {_token == (_lease select 0)}) then {
        [_group,_token,false,_lease,clientOwner] remoteExecCall ["Waldo_fnc_CortexSupportAck",2];
    };
    // Delete only this support assignment's route. A later withdrawal, vehicle
    // manoeuvre, artillery scoot or tactical drill survives stale support cleanup.
    if ((_supportOwnsMovement || {!_movementLeaseActive})
        && {_state getOrDefault ["responding",false] || {_state getOrDefault ["assaulting",false]}}) then {
        [_group] call Waldo_fnc_CortexGroupMoveClear;
    };
    if (_supportOwnsMovement) then {_state deleteAt "movementLease"};
    [_group,"SUPPORT",false] call Waldo_fnc_CortexLambsLease;
    call _restoreAttack;
    {_state deleteAt _x} forEach ["supportToken","responding","respondingTo","respondUntil","arrivedAt","assaulting"];
};
private _abort = _group getVariable ["Waldo_Cortex_SupportAbort",[]];
if (count _abort == 4 && {(_abort select 0) == _token}) exitWith {
    _group setVariable ["Waldo_Cortex_SupportAbort",nil,true];
    call _releaseSupport;
};
if (_lease isEqualTo [] || {(_lease select 0) != _token} || {serverTime >= (_lease select 2)}
    || {!([_group,"Waldo_AIPass_Contact_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!_supportEnabled}) then {
    call _releaseSupport;
};

if (_state getOrDefault ["assaulting",false] && {!([_group,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) then {
    call _releaseSupport;
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
// The public actor marker is the durable ownership record. Local HashMap state disappears during
// HC migration, while the marker follows the actor and proves that Cortex, rather than a mission
// maker, disabled PATH. Merge both records before release so locality changes cannot strand a unit.
private _held=_state getOrDefault ["supportHeld",[]];
{
    if (_x getVariable ["Waldo_Cortex_SupportPathHold",false]) then {_held pushBackUnique _x};
} forEach units _group;
private _newMove=_moving && {(_state getOrDefault ["supportBoundSequence",-1]) != (_role select 1)};
if (_newMove || {!_coordinating}) then {
    {
        if (local _x && {group _x == _group}) then {
            _x enableAI "PATH";
            _x setVariable ["Waldo_Cortex_SupportPathHold",nil,true];
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
            private _started=[_group,_state,_role] call Waldo_fnc_CortexSupportBoundStart;
            if (!_started) then {
                _state set ["supportBoundSequence",_role select 1];
                _group setVariable ["Waldo_Cortex_SupportBoundResult",
                    [_token,_role select 1,"NOT_READY"],true];
            };
        };
    } else {
        private _drill=_state getOrDefault ["drill",createHashMap];
        if ((_drill getOrDefault ["supportToken",""]) == _token) then {[_group,_state,"ABORT"] call Waldo_fnc_CortexFlankEnd};
        {
            private _actorMove=_x getVariable ["Waldo_Cortex_ActorMove",[]];
            if (local _x && {vehicle _x == _x} && {[_x] call Waldo_fnc_CortexCombatEffective}
                && {_x checkAIFeature "PATH"} && {count _actorMove != 3 || {time >= (_actorMove select 2)}}) then {
                doStop _x;
                _x disableAI "PATH";
                _x setVariable ["Waldo_Cortex_SupportPathHold",true,true];
                _held pushBackUnique _x;
            };
        } forEach units _group;
        _state set ["supportHeld",_held];
    };
};
