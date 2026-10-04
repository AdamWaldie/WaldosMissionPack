/*
 * Author: WaldoTheWarfighter
 * Maintains one finite ground-vehicle manoeuvre issued by a combined-arms contact opportunity.
 * The vehicle uses one temporary Cortex waypoint to move to a safe-side firing position. It does
 * not wait for another arm, teleport, repeatedly replace the route or force progress through an
 * obstruction. Arrival, target loss, expiry, locality migration, feature closure or direct Zeus
 * influence releases only the Cortex waypoint and movement lease. A stalled vehicle gets one
 * bounded route replan; a second stall ends the role so gameplay roadblocks remain meaningful.
 * Locality/authority: runs only where the vehicle group is local after a server-authenticated role.
 * Repeat/JIP: the public role token rejects stale jobs; locality replay queues one replacement job.
 * Arguments: 0: job state <HASHMAP> containing group, asset, target, token, expiry and destination.
 * Return Value: Number of seconds before the next scheduler step, or -1 when complete.
 * Current callers: Waldo_fnc_CortexCombinedArmsLocal through Waldo_fnc_CortexQueueJob.
 * Example: [Waldo_fnc_CortexCombinedGroundStep,_job,1] call Waldo_fnc_CortexQueueJob;
 */
params [["_job",createHashMap,[createHashMap]]];
private _group=_job getOrDefault ["group",grpNull];
private _asset=_job getOrDefault ["asset",objNull];
private _target=_job getOrDefault ["target",objNull];
private _token=_job getOrDefault ["token",""];
private _destination=_job getOrDefault ["destination",[]];
private _finish={
    params ["_reason"];
    if (!isNull _group && {local _group}) then {
        [_group] call Waldo_fnc_CortexGroupMoveClear;
        private _state=[_group] call Waldo_fnc_CortexGroupState;
        private _lease=_state getOrDefault ["movementLease",[]];
        if ((_lease param [0,""]) == "COMBINED_GROUND") then {
            [_group,"COMBINED_GROUND",false] call Waldo_fnc_CortexLambsLease;
            _state deleteAt "movementLease";
        };
        if (((_group getVariable ["Waldo_Cortex_CombinedRole",[]]) param [0,""]) == _token) then {
            _group setVariable ["Waldo_Cortex_CombinedResult",[_token,"GROUND_MANOEUVRE",_reason,serverTime,_target,_destination],true];
        };
    };
    -1
};
if (isNull _group || {isNull _asset} || {!alive _asset}) exitWith {["ASSET_LOST"] call _finish};
if (!local _group) exitWith {-1};
private _role=_group getVariable ["Waldo_Cortex_CombinedRole",[]];
if (count _role != 7 || {(_role select 0) != _token} || {(_role select 4) != "GROUND_MANOEUVRE"}) exitWith {["ROLE_RELEASED"] call _finish};
if ([_group] call Waldo_fnc_CortexZeusHeld) exitWith {["ZEUS_HANDOVER"] call _finish};
if (!([_group] call Waldo_fnc_CortexIsEligible)
    || {!([_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!([_group,"Waldo_AIPass_VehicleGunnery_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) exitWith {["FEATURE_CLOSED"] call _finish};
if (isNull _target || {!alive _target}) exitWith {["TARGET_LOST"] call _finish};
if (serverTime >= (_job getOrDefault ["expiry",serverTime])) exitWith {["EXPIRED"] call _finish};
if (_asset distance2D _destination <= 70) exitWith {
    _group reveal [_target,3];
    private _gunner=gunner _asset;
    if (!isNull _gunner && {alive _gunner} && {local _gunner}) then {_gunner doTarget _target; _gunner doFire _target};
    ["POSITION_REACHED"] call _finish
};
if (time >= (_job getOrDefault ["progressAt",time])+10) then {
    private _travel=_asset distance2D (_job getOrDefault ["lastPosition",getPosATL _asset]);
    if (_travel < 8) then {
        private _stalls=_job getOrDefault ["stalls",0];
        if (_stalls >= 1) exitWith {_job set ["terminal","BLOCKED"]};
        // Ask the engine to rebuild the same tactical route once. The destination is unchanged,
        // so this cannot walk a scripted obstacle-avoidance spiral around a deliberate roadblock.
        [_group,_destination,55] call Waldo_fnc_CortexGroupMove;
        _job set ["stalls",_stalls+1];
    };
    _job set ["lastPosition",getPosATL _asset];
    _job set ["progressAt",time];
};
if ((_job getOrDefault ["terminal",""]) != "") exitWith {[_job get "terminal"] call _finish};
1
