/*
 * Author: WaldoTheWarfighter
 * Applies one expiring combined-arms contact role on the selected asset owner.
 * A direct-fire ground vehicle receives target knowledge without losing its authored route. A second
 * ground vehicle receives a finite safe-side manoeuvre destination selected once from a bounded set
 * which keeps the support fire lane clear and avoids water, cliff-like slopes and unnecessarily rough
 * ground. Engine pathfinding remains responsible for the actual route. Airborne aircraft receive the
 * same target and may start their existing finite attack-run job;
 * its controller, rather than a single instantaneous speed sample, proves progress or handles a stall.
 * Locality/authority: current group owner only; server-issued public token must still match. Asset
 * discovery accepts the effective commander's or driver's group but never a passenger-only group.
 * Repeat/JIP: duplicate roles are harmless; expiry, Zeus takeover, feature closure and token replacement reject stale calls.
 * Arguments: 0: asset group <GROUP>; 1: opportunity <ARRAY>
 * [token,requester,target,position,role,expiry,ground-fire anchor].
 * Return Value: Boolean, true when the role was applied.
 * Current callers: Waldo_fnc_CortexCombinedArmsServer through remote execution.
 * Example: [_vehicleGroup,_opportunity] remoteExecCall ["Waldo_fnc_CortexCombinedArmsLocal",groupOwner _vehicleGroup];
 */
params [["_group",grpNull,[grpNull]],["_opportunity",[],[[]]]];
if (!local _group || {count _opportunity != 7} || {!([_group] call Waldo_fnc_CortexIsEligible)}) exitWith {false};
_opportunity params ["_token","_requester","_target","_position","_role","_expiry","_context"];
if ((_group getVariable ["Waldo_Cortex_CombinedRole",[]]) isNotEqualTo _opportunity
    || {serverTime >= _expiry} || {isNull _requester} || {isNull _target} || {!alive _target}
    || {side _group != side _requester} || {(side _group) getFriend side _target >= 0.6}
    || {!(_role in ["GROUND_FIRE","GROUND_MANOEUVRE","AIR_ATTACK"])}) exitWith {false};
private _asset=objNull;
{
    private _vehicle=vehicle _x;
    private _commander=effectiveCommander _vehicle;
    private _driver=driver _vehicle;
    if (_vehicle != _x && {alive _vehicle}
        && {(!isNull _commander && {group _commander == _group})
            || {!isNull _driver && {group _driver == _group}}}) exitWith {_asset=_vehicle};
} forEach units _group;
if (isNull _asset) exitWith {false};
if (_role in ["GROUND_FIRE","GROUND_MANOEUVRE"] && {
    !(_asset isKindOf "LandVehicle") || {_asset isKindOf "StaticWeapon"}
        || {!([_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
        || {!([_group,"Waldo_AIPass_VehicleGunnery_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
}) exitWith {false};
if (_role == "AIR_ATTACK" && {
    !(_asset isKindOf "Air") || {isTouchingGround _asset}
        || {!([_group,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
}) exitWith {false};
_group reveal [_target,2.5];
{
    if (alive _x && {local _x} && {!isPlayer _x}) then {_x doTarget _target};
} forEach crew _asset;
if (_role == "GROUND_FIRE") exitWith {
    private _gunner=gunner _asset;
    if (!isNull _gunner && {alive _gunner} && {local _gunner} && {combatMode _group in ["YELLOW","RED"]}) then {_gunner doFire _target};
    _group setVariable ["Waldo_Cortex_CombinedApplied",[_token,clientOwner,serverTime],true];
    _group setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"APPLIED",serverTime,_target],true];
    true
};
if (_role == "GROUND_MANOEUVRE") exitWith {
    private _start=getPosATL _asset;
    private _targetPosition=getPosATL _target;
    private _supportPosition=if (count _context >= 2) then {+_context} else {getPosATL leader _requester};
    private _axis=_targetPosition vectorDiff _supportPosition;
    _axis set [2,0];
    if (vectorMagnitude _axis < 1) then {_axis=[sin getDir _asset,cos getDir _asset,0]};
    _axis=vectorNormalized _axis;
    private _left=[-(_axis select 1),_axis select 0,0];
    private _relative=_start vectorDiff _supportPosition;
    private _side=if ((_relative vectorDotProduct _left) < 0) then {_left vectorMultiply -1} else {_left};
    // These are alternative firing areas, not a scripted movement profile. Sampling a few ranges
    // and lateral offsets makes the same contact opportunity usable on hills and rough terrain while
    // keeping the engine free to choose roads and avoid local obstacles.
    private _candidates=[];
    {
        private _standOff=_x;
        {
            private _destination=_targetPosition vectorAdd (_axis vectorMultiply -_standOff);
            _destination=_destination vectorAdd (_side vectorMultiply _x);
            _destination set [2,0];
            _candidates pushBack [_destination];
        } forEach [260,320,380];
    } forEach [180,240];
    private _selected=[_start,_candidates,_targetPosition,[_supportPosition],_target,"VEHICLE"]
        call Waldo_fnc_CortexSelectAvenue;
    if (_selected isEqualTo []) exitWith {
        _group setVariable ["Waldo_Cortex_CombinedApplied",[_token,clientOwner,serverTime],true];
        _group setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"NO_SAFE_ROUTE",serverTime,_target],true];
        false
    };
    private _destination=_selected select ((count _selected)-1);
    if !([_group,"COMBINED_GROUND",true,_expiry] call Waldo_fnc_CortexLambsLease) exitWith {
        _group setVariable ["Waldo_Cortex_CombinedApplied",[_token,clientOwner,serverTime],true];
        _group setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"EXTERNAL_BUSY",serverTime,_target],true];
        false
    };
    [_group,_destination,55] call Waldo_fnc_CortexGroupMove;
    private _state=[_group] call Waldo_fnc_CortexGroupState;
    _state set ["movementLease",["COMBINED_GROUND",time+((_expiry-serverTime) max 5)]];
    [Waldo_fnc_CortexCombinedGroundStep,createHashMapFromArray [
        ["group",_group],["asset",_asset],["target",_target],["token",_token],
        ["expiry",_expiry],["destination",_destination],["lastPosition",_start],
        ["progressAt",time],["stalls",0]
    ],1] call Waldo_fnc_CortexQueueJob;
    _group setVariable ["Waldo_Cortex_CombinedApplied",[_token,clientOwner,serverTime],true];
    _group setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"APPLIED",serverTime,_target,_destination],true];
    true
};
if (_role == "AIR_ATTACK") exitWith {
    if !(_asset getVariable ["Waldo_Cortex_AirAttackJob",false]) then {
        _asset setVariable ["Waldo_Cortex_AirAttackJob",true];
        // The server already authenticated this live hostile. Pass it into the finite controller;
        // doTarget is asynchronous and assignedTarget may not be populated half a second later.
        [Waldo_fnc_CortexAirAttack,createHashMapFromArray [["aircraft",_asset],["group",_group],["target",_target]],0.5] call Waldo_fnc_CortexQueueJob;
    };
    _group setVariable ["Waldo_Cortex_CombinedApplied",[_token,clientOwner,serverTime],true];
    _group setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"APPLIED",serverTime,_target],true];
    true
};
false
