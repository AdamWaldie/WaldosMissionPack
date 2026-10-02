/*
 * Author: WaldoTheWarfighter
 * Converts a verified fresh contact into finite, independent combined-arms roles.
 * The server selects at most two nearby ground-vehicle groups and one airborne group. Each role is
 * dispatched immediately; infantry never waits for acceptance and no shared assembly state exists.
 * Locality/authority: server validates the sender, target, hostility, range, communications and role
 * feature gates; the current asset owner applies targeting through Waldo_fnc_CortexCombinedArmsLocal.
 * Repeat/JIP: requester rate limit and expiring public role tokens replace older opportunities safely.
 * Arguments: 0: requester <GROUP>; 1: observed hostile <OBJECT>; 2: believed ATL <ARRAY>;
 * 3: observation server time <NUMBER>.
 * Return Value: Number of asset roles dispatched.
 * Current callers: Waldo_fnc_CortexCombinedArmsRequest through remote execution.
 * Example: [_group,_enemy,getPosATL _enemy,serverTime] remoteExecCall ["Waldo_fnc_CortexCombinedArmsServer",2];
 */
params [["_requester",grpNull,[grpNull]],["_target",objNull,[objNull]],["_position",[],[[]]],["_observedAt",-1,[0]]];
if (!isServer || {isNull _requester} || {isNull _target} || {!alive _target}
    || {remoteExecutedOwner > 0 && {remoteExecutedOwner != groupOwner _requester}}
    || {count _position < 2} || {_position findIf {!(_x isEqualType 0)} >= 0}
    || {serverTime-_observedAt > 10} || {_target distance2D _position > 75}
    || {(side _requester) getFriend side _target >= 0.6}
    || {!([_requester] call Waldo_fnc_CortexIsEligible)}
    || {!([_requester,"Waldo_AIPass_CoordinatedAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!([_requester,"Waldo_AIPass_ContactReports_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}
    || {!([leader _requester] call Waldo_fnc_CortexCanTransmit)}) exitWith {0};
if (serverTime < (_requester getVariable ["Waldo_Cortex_CombinedDue",0])) exitWith {0};
_requester setVariable ["Waldo_Cortex_CombinedDue",serverTime+18];
private _serial=(missionNamespace getVariable ["Waldo_Cortex_CombinedSerial",0])+1;
missionNamespace setVariable ["Waldo_Cortex_CombinedSerial",_serial];
private _token=format ["%1:%2",netId _requester,_serial];
private _expiry=serverTime+35;
private _ground=0;
private _air=0;
private _dispatched=0;
private _roleGroups=[];
{
    private _candidate=_x;
    if (_candidate != _requester && {side _candidate == side _requester} && {alive leader _candidate}
        && {leader _candidate distance2D leader _requester <= 1200}
        && {[_candidate] call Waldo_fnc_CortexIsEligible}
        && {[leader _candidate] call Waldo_fnc_CortexCanTransmit}) then {
        private _asset=objNull;
        {
            private _vehicle=vehicle _x;
            if (_vehicle != _x && {alive _vehicle} && {effectiveCommander _vehicle in units _candidate}) exitWith {_asset=_vehicle};
        } forEach units _candidate;
        private _role="";
        if (!isNull _asset && {_asset isKindOf "Air"} && {_air < 1} && {!isTouchingGround _asset} && {speed _asset >= 40}
            && {combatMode _candidate in ["YELLOW","RED"]}
            && {[_candidate,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
            _role="AIR_ATTACK"; _air=_air+1;
        } else {
            if (!isNull _asset && {_asset isKindOf "LandVehicle"} && {!(_asset isKindOf "StaticWeapon")}
                && {_ground < 2} && {canFire _asset} && {!(_asset getVariable ["Waldo_Convoy_Active",false])}
                && {[_candidate,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
                && {[_candidate,"Waldo_AIPass_VehicleGunnery_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
                _role="GROUND_FIRE"; _ground=_ground+1;
            };
        };
        if (_role != "") then {
            private _opportunity=[_token,_requester,_target,+_position,_role,_expiry];
            _candidate setVariable ["Waldo_Cortex_CombinedRole",_opportunity,true];
            [_candidate,_opportunity] remoteExecCall ["Waldo_fnc_CortexCombinedArmsLocal",groupOwner _candidate];
            _roleGroups pushBack _candidate;
            _dispatched=_dispatched+1;
        };
    };
    if (_ground >= 2 && {_air >= 1}) exitWith {};
} forEach allGroups;
_requester setVariable ["Waldo_Cortex_CombinedOpportunity",[_token,_target,+_position,_expiry,_dispatched],true];
[{
    params ["_requester","_token","_roleGroups"];
    if (!isNull _requester && {((_requester getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) param [0,""]) == _token}) then {
        _requester setVariable ["Waldo_Cortex_CombinedOpportunity",nil,true];
    };
    {
        if (!isNull _x && {((_x getVariable ["Waldo_Cortex_CombinedRole",[]]) param [0,""]) == _token}) then {
            _x setVariable ["Waldo_Cortex_CombinedRole",nil,true];
        };
    } forEach _roleGroups;
},[_requester,_token,_roleGroups],(_expiry-serverTime) max 0] call CBA_fnc_waitAndExecute;
_dispatched
