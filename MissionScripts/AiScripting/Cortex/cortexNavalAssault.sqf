/*
 * Author: WaldoTheWarfighter
 * Delivers AI infantry from a boat with one finite, shallow-water approach and dry-ground egress.
 *
 * The crew uses only enemies its group already knows about. One bounded candidate pass compares
 * dry, gently sloped shore points around that contact with adjacent shallow-water landing and
 * approach points. The ordinary Arma driver follows one temporary MOVE waypoint; WMP never uses
 * setDriveOnPath, teleport, repair, unflip or a global group/unit scan. Crew and operating gunners
 * remain aboard. A separate passenger group owns and unloads only its members, then receives one
 * finite dry-ground egress. For a legacy combined crew/passenger group, cargo receives short
 * individual egress moves so the boat group is never assigned a land waypoint.
 *
 * PROTOCOL AI NAVY SEAL has exclusive naval ownership when its patch is loaded. LAMBS/VCOM busy
 * movement is also respected through CortexLambsLease. Zeus input releases the operation through
 * normal eligibility cleanup. Casualties simply reduce the surviving landing element; no readiness
 * barrier waits for a missing soldier.
 * Locality/authority: runs only inside the existing machine-local Cortex group job. Boat speed is
 * changed only where the boat is local. The tokenized plan is public so independently owned
 * passenger groups and a replacement owner can continue or release it.
 * Repeat/JIP: one token and deadline bound every approach. Completion, expiry, a closed feature
 * gate, external-mod ownership and Zeus cleanup all restore exact speed and remove only WMP orders.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: Cortex state <HASHMAP>
 * 2: known enemies <ARRAY> from CortexKnowledge
 *
 * Return Value:
 * Boolean - true while this naval operation owns or intentionally holds group movement
 *
 * Current caller: CortexGroupTick.
 *
 * Example:
 * private _owned=[_group,_state,_enemies] call Waldo_fnc_CortexNavalAssault;
 * Result: an eligible boat approaches a usable shore and its passenger squad lands without a new poller.
 */

params [
    ["_group",grpNull,[grpNull]],
    ["_state",createHashMap,[createHashMap]],
    ["_enemies",[],[[]]]
];
if (isNull _group || {!local _group}) exitWith {false};
private _enabled=[_group,"Waldo_AIPass_NavalAssault_Enable",true] call Waldo_fnc_CortexFeatureEnabled;
private _protocol=missionNamespace getVariable ["Waldo_AIPass_ProtocolNavyLoaded",false];
if (!_enabled || {_protocol}) exitWith {
    if ((_state getOrDefault ["navalOperation",[]]) isNotEqualTo []
        || {(_group getVariable ["Waldo_Cortex_NavalOperation",[]]) isNotEqualTo []}) then {
        [_group,_state] call Waldo_fnc_CortexNavalRelease
    };
    false
};

private _operation=_state getOrDefault ["navalOperation",[]];
// Local state belongs to the old owner. Reconstruct the semantic episode from the public token;
// never replay its previous waypoint or extend its original deadline.
if (_operation isEqualTo []) then {
    private _durable=_group getVariable ["Waldo_Cortex_NavalOperation",[]];
    if (count _durable == 5 && {serverTime >= (_durable select 4)}) exitWith {
        _state set ["navalOperation",+_durable];
        [_group,_state] call Waldo_fnc_CortexNavalRelease;
    };
    if (count _durable == 5 && {serverTime < (_durable select 4)}) then {
        _operation=+_durable;
        _state set ["navalOperation",_operation];
    };
};
// Continue a passenger landing after the last soldier has physically left the boat.
if (count _operation >= 4 && {(_operation param [2,""]) == "PASSENGER"}) exitWith {
    _operation params ["_token","_boat","_role","_egress","_expires"];
    private _survivors=(units _group) select {alive _x && {[_x] call Waldo_fnc_CortexCombatEffective}};
    private _aboard=_survivors select {vehicle _x == _boat};
    if (serverTime >= _expires || {_survivors isEqualTo []}) exitWith {
        [_group,_state] call Waldo_fnc_CortexNavalRelease;
        false
    };
    if (_aboard isNotEqualTo []) exitWith {true};
    private _movement=_state getOrDefault ["movementLease",[]];
    if ((_movement param [0,""]) != "NAVAL_LANDING") then {
        if ([_group,"NAVAL_LANDING",true,_expires] call Waldo_fnc_CortexLambsLease) then {
            [_group,_egress,25] call Waldo_fnc_CortexGroupMove;
            _state set ["movementLease",["NAVAL_LANDING",time+((_expires-serverTime) max 1)]];
            _group setVariable ["Waldo_Cortex_NavalStatus",["EGRESS",_egress,_expires],true];
        };
    };
    if ((leader _group distance2D _egress) <= 30) exitWith {
        [_group,_state] call Waldo_fnc_CortexNavalRelease;
        false
    };
    true
};

private _ships=[];
{
    private _vehicle=vehicle _x;
    if (_vehicle != _x && {_vehicle isKindOf "Ship"} && {!(_vehicle in _ships)}) then {_ships pushBack _vehicle};
} forEach units _group;
if (_ships isEqualTo []) exitWith {false};
private _boat=_ships select 0;
private _commandsBoat=effectiveCommander _boat in units _group;

if (!_commandsBoat) exitWith {
    private _plan=_boat getVariable ["Waldo_Cortex_NavalPlan",[]];
    if (count _plan != 9 || {serverTime >= (_plan select 7)}) exitWith {false};
    _plan params ["_token","_crewGroup","_plannedBoat","_approach","_landing","_shore","_egress","_expires","_phase"];
    if (_plannedBoat != _boat || {isNull _crewGroup} || {side _crewGroup != side _group}) exitWith {false};
    if (_phase == "APPROACH") exitWith {
        _group setVariable ["Waldo_Cortex_NavalStatus",["EMBARKED",_landing,_expires],true];
        true
    };
    private _cargo=(fullCrew [_boat,"",false]) select {
        private _unit=_x select 0;
        private _seat=_x select 1;
        alive _unit && {group _unit == _group} && {_seat == "cargo" || {_seat == "turret" && {_x select 4}}}
    };
    {
        private _unit=_x select 0;
        [_unit] orderGetIn false;
        unassignVehicle _unit;
        doGetOut _unit;
    } forEach _cargo;
    private _passengerOperation=[_token,_boat,"PASSENGER",_egress,_expires];
    _state set ["navalOperation",_passengerOperation];
    _group setVariable ["Waldo_Cortex_NavalOperation",_passengerOperation,true];
    _group setVariable ["Waldo_Cortex_NavalStatus",["DISEMBARK",_shore,_expires],true];
    true
};

// Boat crew: adopt or create the single public plan.
private _plan=_boat getVariable ["Waldo_Cortex_NavalPlan",[]];
if (count _plan == 9 && {(_plan select 8) == "LANDED"} && {serverTime < (_plan select 7)}) exitWith {false};
if (count _plan == 9 && {(_plan select 1) == _group} && {serverTime < (_plan select 7)}) exitWith {
    _plan params ["_token","_crewGroup","_plannedBoat","_approach","_landing","_shore","_egress","_expires","_phase"];
    private _crewOperation=[_token,_boat,"CREW",_egress,_expires];
    _state set ["navalOperation",_crewOperation];
    _group setVariable ["Waldo_Cortex_NavalOperation",_crewOperation,true];
    if (_phase == "APPROACH" && {(_boat distance2D _landing) <= 45}) then {
        if (local _boat) then {
            if ((_boat getVariable ["Waldo_Cortex_NavalForcedSpeed",[]]) isEqualTo []) then {
                _boat setVariable ["Waldo_Cortex_NavalForcedSpeed",[getForcedSpeed _boat]];
            };
            _boat forceSpeed 0;
        };
        _plan set [8,"DISEMBARK"];
        _boat setVariable ["Waldo_Cortex_NavalPlan",_plan,true];
        _group setVariable ["Waldo_Cortex_NavalStatus",["DISEMBARK",_shore,_expires],true];
    };
    private _remaining=(fullCrew [_boat,"",false]) findIf {
        private _unit=_x select 0;
        private _seat=_x select 1;
        alive _unit && {_unit != effectiveCommander _boat}
            && {_seat == "cargo" || {_seat == "turret" && {_x select 4}}}
    };
    if ((_plan select 8) == "DISEMBARK") then {
        // Combined crew/cargo groups cannot receive a land waypoint without beaching their boat.
        {
            private _unit=_x select 0;
            if (group _unit == _group) then {
                [_unit] orderGetIn false;
                unassignVehicle _unit;
                doGetOut _unit;
                _unit doMove (_egress getPos [4+(_forEachIndex mod 4)*3,90+_forEachIndex*35]);
            };
        } forEach ((fullCrew [_boat,"",false]) select {
            private _seat=_x select 1;
            _seat == "cargo" || {_seat == "turret" && {_x select 4}}
        });
    };
    if (_remaining < 0 || {serverTime >= _expires}) then {
        if (local _boat) then {
            private _saved=_boat getVariable ["Waldo_Cortex_NavalForcedSpeed",[]];
            if (_saved isNotEqualTo []) then {_boat forceSpeed (_saved param [0,-1])};
            _boat setVariable ["Waldo_Cortex_NavalForcedSpeed",nil];
        };
        [_group] call Waldo_fnc_CortexGroupMoveClear;
        [_group,"NAVAL_ASSAULT",false] call Waldo_fnc_CortexLambsLease;
        _state deleteAt "movementLease";
        _plan set [8,"LANDED"];
        _plan set [7,serverTime+45];
        _boat setVariable ["Waldo_Cortex_NavalPlan",_plan,true];
        _state deleteAt "navalOperation";
        _group setVariable ["Waldo_Cortex_NavalOperation",nil,true];
        _group setVariable ["Waldo_Cortex_NavalStatus",["COMPLETE",_shore,serverTime+45],true];
        false
    } else {
        true
    }
};

if (_enemies isEqualTo [] || {!surfaceIsWater (getPosATL _boat)}) exitWith {false};
private _contact=_enemies select 0;
private _target=_contact select 0;
private _targetPos=_contact select 1;
private _distance=_boat distance2D _targetPos;
if (isNull _target || {surfaceIsWater _targetPos} || {_distance < 120} || {_distance > 1800}) exitWith {false};
private _towardBoat=_targetPos getDir _boat;
private _candidates=[];
{
    private _bearing=_towardBoat+_x;
    {
        private _shore=_targetPos getPos [_x,_bearing];
        private _landing=_shore getPos [35,_shore getDir _boat];
        private _approach=_landing getPos [100,_landing getDir _boat];
        private _normal=surfaceNormal _shore;
        if (!surfaceIsWater _shore && {surfaceIsWater _landing} && {surfaceIsWater _approach}
            && {(_normal select 2) >= 0.7}) then {
            private _egress=_shore getPos [45,_boat getDir _targetPos];
            if (!surfaceIsWater _egress && {((surfaceNormal _egress) select 2) >= 0.65}) then {
                _candidates pushBack [(_boat distance2D _approach)+(_shore distance2D _targetPos)*0.35,_approach,_landing,_shore,_egress];
            };
        };
    } forEach [100,150,210,280];
} forEach [0,-25,25,-50,50,180];
if (_candidates isEqualTo []) exitWith {false};
_candidates sort true;
(_candidates select 0) params ["_score","_approach","_landing","_shore","_egress"];
private _expires=serverTime+240;
if !([_group,"NAVAL_ASSAULT",true,_expires] call Waldo_fnc_CortexLambsLease) exitWith {false};
private _token=format ["NAVAL:%1:%2:%3",netId _boat,clientOwner,round (serverTime*10)];
[_group,_landing,20] call Waldo_fnc_CortexGroupMove;
_state set ["movementLease",["NAVAL_ASSAULT",time+240]];
private _crewOperation=[_token,_boat,"CREW",_egress,_expires];
_state set ["navalOperation",_crewOperation];
_group setVariable ["Waldo_Cortex_NavalOperation",_crewOperation,true];
_boat setVariable ["Waldo_Cortex_NavalPlan",[_token,_group,_boat,_approach,_landing,_shore,_egress,_expires,"APPROACH"],true];
_group setVariable ["Waldo_Cortex_NavalStatus",["APPROACH",_landing,_expires],true];
true
