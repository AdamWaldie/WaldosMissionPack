/*
 * Author: WaldoTheWarfighter
 * Receives approximate onboard crew reports and dismounts this squad's safe cargo seats.
 * Locality/authority: passenger group owner; validates current reporting crew ownership.
 * Repeat/JIP: expiring reports cannot replay old exits; records each passenger once. No reveal.
 * Arguments: 0: group <GROUP>, grpNull; 1: state <HASHMAP>, empty.
 * Return: Nothing. Current caller: Waldo_fnc_CortexGroupTick after eligibility and order checks.
 * Example: [_group,_state] call Waldo_fnc_CortexOnboardContact;
 */
params [["_group",grpNull,[grpNull]],["_state",createHashMap,[createHashMap]]];
if (isNull _group || {!local _group} || {!([_group] call Waldo_fnc_CortexIsEligible)}) exitWith {};
if (!([_group,"Waldo_AIPass_Vehicles_Enable",true] call Waldo_fnc_CortexFeatureEnabled)
    || {!([_group,"Waldo_AIPass_VehicleDismount_Enable",true] call Waldo_fnc_CortexFeatureEnabled)}) exitWith {};
private _vehicles=[];
{if (alive _x && {vehicle _x != _x}) then {_vehicles pushBackUnique vehicle _x}} forEach units _group;
{
    private _vehicle=_x;
    private _report=_vehicle getVariable ["Waldo_Cortex_OnboardReport",[]];
    if (count _report == 4 && {_vehicle isKindOf "LandVehicle"} && {!(_vehicle isKindOf "StaticWeapon")}) then {
        _report params ["_reporter","_owner","_position","_expiry"];
        if (_reporter isEqualType grpNull && {_owner isEqualType 0} && {_position isEqualType []} && {_expiry isEqualType 0}
            && {!isNull _reporter} && {_reporter != _group} && {count _position == 3}
            && {_position findIf {!(_x isEqualType 0)} < 0}
            && {groupOwner _reporter == _owner} && {group effectiveCommander _vehicle == _reporter}
            && {alive effectiveCommander _vehicle} && {side _reporter == side _group}
            && {serverTime < _expiry} && {_expiry <= serverTime+12}
            && {_vehicle distance2D _position < 400}) then {
            private _cargo=(crew _vehicle) select {group _x == _group && {[_x,_vehicle] call Waldo_fnc_CortexPassengerReady}};
            private _owned=_state getOrDefault ["dismounted",[]];
            {
                private _unit=_x;
                if (_owned findIf {(_x select 0) == _unit} < 0) then {_owned pushBack [_unit,_vehicle]};
                _state set ["dismounted",_owned];
                _state set ["onboardContactUntil",serverTime+30];
                [_unit] orderGetIn false;
                unassignVehicle _unit;
                doGetOut _unit;
            } forEach _cargo;
        };
    };
} forEach _vehicles;
// Reports do not manufacture visual contact. If no native contact followed the exit,
// restore only this calm passenger episode through the normal guarded remount path.
if ("onboardContactUntil" in _state && {serverTime >= (_state get "onboardContactUntil")}
    && {(_state getOrDefault ["phase",""]) == "CALM"}) then {
    _state deleteAt "onboardContactUntil";
    [_group,_state] call Waldo_fnc_CortexRestoreCalm;
};
