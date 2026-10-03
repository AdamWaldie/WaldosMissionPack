/*
 * Author: WaldoTheWarfighter
 * Converts a verified fresh contact into finite, independent combined-arms roles.
 * The server selects at most two nearby ground-vehicle groups and one airborne group. The first
 * capable ground asset supplies direct fire; a second receives a distinct, finite manoeuvre role
 * whose route is kept on one side of the support-to-target fire lane. Aircraft are
 * not rejected for a momentary low-speed sample; the finite attack controller owns acceleration,
 * progress and stuck detection after accepting an aircraft that is physically off the ground. Each
 * role is dispatched immediately; infantry never waits for acceptance and no shared assembly state exists.
 * Vehicle discovery accepts either the effective commander's or driver's group so turret ownership
 * cannot hide an otherwise valid aircraft, while passenger-only groups remain ineligible.
 * Locality/authority: server validates the sender, target, hostility, range, communications and role
 * feature gates; the current asset owner applies targeting through Waldo_fnc_CortexCombinedArmsLocal.
 * Vehicle and aircraft cooperation depends on contact communication and each asset's own feature
 * gate. It does not depend on the infantry coordinated-assault switch: disabling infantry bounds
 * must not silently disable otherwise enabled armour or aircraft support. Aircraft use their own
 * operational support radius rather than the short squad-to-squad report radius; both ends must
 * still be able to transmit, so jamming continues to prevent long-range composition.
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
    || {!([_requester,"Waldo_AIPass_ContactReports_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) exitWith {0};
if (serverTime < (_requester getVariable ["Waldo_Cortex_CombinedDue",0])) exitWith {0};
_requester setVariable ["Waldo_Cortex_CombinedDue",serverTime+18];
private _serial=(missionNamespace getVariable ["Waldo_Cortex_CombinedSerial",0])+1;
missionNamespace setVariable ["Waldo_Cortex_CombinedSerial",_serial];
private _token=format ["%1:%2",netId _requester,_serial];
private _expiry=serverTime+35;
private _ground=0;
private _groundAnchor=[];
private _air=0;
private _dispatched=0;
private _roleGroups=[];
private _voiceRange=missionNamespace getVariable ["Waldo_AIPass_ContactReports_VoiceRange",35];
private _groundRange=missionNamespace getVariable ["Waldo_AIPass_ContactReports_Radius",500];
private _airRange=missionNamespace getVariable ["Waldo_Cortex_CombinedArms_AirRange",4000];
private _senderRadio=[leader _requester] call Waldo_fnc_CortexCanTransmit;
{
    private _candidate=_x;
    private _distance=leader _candidate distance2D leader _requester;
    private _candidateRadio=[leader _candidate] call Waldo_fnc_CortexCanTransmit;
    if (_candidate != _requester && {side _candidate == side _requester} && {alive leader _candidate}
        && {[_candidate] call Waldo_fnc_CortexIsEligible}
        && {_distance <= _voiceRange || {_senderRadio && {_candidateRadio}}}) then {
        private _asset=objNull;
        {
            private _vehicle=vehicle _x;
            private _commander=effectiveCommander _vehicle;
            private _driver=driver _vehicle;
            if (_vehicle != _x && {alive _vehicle}
                && {(!isNull _commander && {group _commander == _candidate})
                    || {!isNull _driver && {group _driver == _candidate}}}) exitWith {_asset=_vehicle};
        } forEach units _candidate;
        private _role="";
        if (!isNull _asset && {_asset isKindOf "Air"} && {_distance <= _airRange} && {_air < 1} && {!isTouchingGround _asset}
            && {combatMode _candidate in ["YELLOW","RED"]}
            && {[_candidate,"Waldo_Cortex_AirAttack_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
            _role="AIR_ATTACK"; _air=_air+1;
        } else {
            if (!isNull _asset && {_asset isKindOf "LandVehicle"} && {_distance <= _groundRange} && {!(_asset isKindOf "StaticWeapon")}
                && {_ground < 2} && {canFire _asset} && {!(_asset getVariable ["Waldo_Convoy_Active",false])}
                && {[_candidate,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled}
                && {[_candidate,"Waldo_AIPass_VehicleGunnery_Enable",true] call Waldo_fnc_CortexFeatureEnabled}) then {
                _role=["GROUND_FIRE","GROUND_MANOEUVRE"] select (_ground > 0);
                if (_ground == 0) then {_groundAnchor=getPosATL _asset};
                _ground=_ground+1;
            };
        };
        if (_role != "") then {
            private _context=if (_role == "GROUND_MANOEUVRE") then {+_groundAnchor} else {[]};
            private _opportunity=[_token,_requester,_target,+_position,_role,_expiry,_context];
            _candidate setVariable ["Waldo_Cortex_CombinedRole",_opportunity,true];
            _candidate setVariable ["Waldo_Cortex_CombinedApplied",nil,true];
            _candidate setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"DISPATCHED",serverTime,_target],true];
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
            private _role=(_x getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""];
            private _target=(_x getVariable ["Waldo_Cortex_CombinedRole",[]]) param [2,objNull];
            _x setVariable ["Waldo_Cortex_CombinedResult",[_token,_role,"EXPIRED",serverTime,_target],true];
            _x setVariable ["Waldo_Cortex_CombinedRole",nil,true];
            _x setVariable ["Waldo_Cortex_CombinedApplied",nil,true];
        };
    } forEach _roleGroups;
},[_requester,_token,_roleGroups],(_expiry-serverTime) max 0] call CBA_fnc_waitAndExecute;
_dispatched
