/*
 * Author: WaldoTheWarfighter
 * Applies one expiring combined-arms contact role on the selected asset owner.
 * Ground vehicles receive target knowledge and use the existing gunnery layer without a movement
 * order. Airborne aircraft receive the same target and may start their existing finite attack-run job;
 * its controller, rather than a single instantaneous speed sample, proves progress or handles a stall.
 * Locality/authority: current group owner only; server-issued public token must still match. Asset
 * discovery accepts the effective commander's or driver's group but never a passenger-only group.
 * Repeat/JIP: duplicate roles are harmless; expiry, Zeus takeover, feature closure and token replacement reject stale calls.
 * Arguments: 0: asset group <GROUP>; 1: opportunity <ARRAY> [token,requester,target,position,role,expiry].
 * Return Value: Boolean, true when the role was applied.
 * Current callers: Waldo_fnc_CortexCombinedArmsServer through remote execution.
 * Example: [_vehicleGroup,_opportunity] remoteExecCall ["Waldo_fnc_CortexCombinedArmsLocal",groupOwner _vehicleGroup];
 */
params [["_group",grpNull,[grpNull]],["_opportunity",[],[[]]]];
if (!local _group || {count _opportunity != 6} || {!([_group] call Waldo_fnc_CortexIsEligible)}) exitWith {false};
_opportunity params ["_token","_requester","_target","_position","_role","_expiry"];
if ((_group getVariable ["Waldo_Cortex_CombinedRole",[]]) isNotEqualTo _opportunity
    || {serverTime >= _expiry} || {isNull _requester} || {isNull _target} || {!alive _target}
    || {side _group != side _requester} || {(side _group) getFriend side _target >= 0.6}
    || {!(_role in ["GROUND_FIRE","AIR_ATTACK"])}) exitWith {false};
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
if (_role == "GROUND_FIRE" && {
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
