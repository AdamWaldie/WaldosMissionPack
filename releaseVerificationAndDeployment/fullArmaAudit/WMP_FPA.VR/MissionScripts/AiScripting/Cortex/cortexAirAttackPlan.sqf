/*
 * Author: WaldoTheWarfighter
 * Builds one finite, threat-aware Cortex attack plan for an AI aircraft and its assigned target.
 * The planner chooses a strafe, offset, helicopter hook or standoff run from aircraft type, live
 * guided-ground ammunition and a bounded sample of targets already known to the pilot. Observed AA
 * shifts the run away from the threat sector and prefers standoff weapons when available.
 * Locality/authority: read-only; called on the aircraft owner. It does not reveal enemies, add
 * waypoints, move the aircraft or change crew orders. Immutable magazine facts are cached locally.
 * Repeat/JIP: safe to repeat. Each result is a new owner-local plan and has no JIP side effects.
 * Arguments: 0: aircraft <OBJECT>; 1: hostile target <OBJECT>.
 * Return Value: HASHMAP plan, or an empty HASHMAP when the request is invalid.
 * Current callers: Waldo_fnc_CortexAirAttack.
 * Example: private _plan = [_plane,_tank] call Waldo_fnc_CortexAirAttackPlan;
 */
params [["_aircraft",objNull,[objNull]],["_target",objNull,[objNull]]];
if (isNull _aircraft || {isNull _target} || {!alive _aircraft} || {!alive _target}) exitWith {createHashMap};
private _pilot=driver _aircraft;
if (isNull _pilot || {!alive _pilot} || {!local _aircraft}) exitWith {createHashMap};
private _side=side group _pilot;
if (_side getFriend side _target >= 0.6) exitWith {createHashMap};

private _ammoCache=missionNamespace getVariable ["Waldo_Cortex_AirAmmoFacts",createHashMap];
private _ammoFacts={
    params ["_magazine"];
    private _facts=_ammoCache getOrDefault [_magazine,[]];
    if (_facts isEqualTo []) then {
        private _ammo=configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
        private _flags=getNumber (_ammo >> "aiAmmoUsageFlags");
        private _simulation=toLowerANSI getText (_ammo >> "simulation");
        private _antiAir=getNumber (_ammo >> "airLock") > 0 || {(floor (_flags/256) mod 2) == 1};
        private _guidedGround=getNumber (_ammo >> "laserLock") > 0 || {getNumber (_ammo >> "irLock") > 0}
            || {getNumber (_ammo >> "nvLock") > 0} || {(floor (_flags/512) mod 2) == 1};
        private _standoff=_simulation in ["shotmissile","shotrocket"] && {getNumber (_ammo >> "hit") >= 100}
            && {!_antiAir} && {_guidedGround};
        _facts=[_antiAir,_standoff];
        _ammoCache set [_magazine,_facts];
    };
    _facts
};
private _standoff=false;
{
    _x params ["_magazine","_turret","_rounds"];
    if (_rounds > 0 && {([_magazine] call _ammoFacts) select 1}) exitWith {_standoff=true};
} forEach magazinesAllTurrets _aircraft;

private _aaPositions=[];
private _known=(_pilot nearTargets 2500) select [0,16];
{
    private _contact=_x param [4,objNull];
    if (!isNull _contact && {alive _contact} && {_side getFriend side _contact < 0.6}) then {
        private _antiAir=false;
        if (_contact isKindOf "CAManBase") then {
            _antiAir="AA" in ([_contact] call Waldo_fnc_CortexCapabilities);
        } else {
            {
                _x params ["_magazine","_turret","_rounds"];
                if (_rounds > 0 && {([_magazine] call _ammoFacts) select 0}) exitWith {_antiAir=true};
            } forEach magazinesAllTurrets _contact;
        };
        if (_antiAir) then {_aaPositions pushBack getPosATL _contact};
    };
} forEach _known;
missionNamespace setVariable ["Waldo_Cortex_AirAmmoFacts",_ammoCache];

private _airPos=getPosATL _aircraft;
private _targetPos=getPosATL _target;
private _axis=_targetPos vectorDiff _airPos;
_axis set [2,0];
if (vectorMagnitude _axis < 1) then {_axis=[sin getDir _aircraft,cos getDir _aircraft,0]};
_axis=vectorNormalized _axis;
private _left=[-(_axis select 1),_axis select 0,0];
private _right=_left vectorMultiply -1;
private _threatSide=0;
{
    private _relative=_x vectorDiff _targetPos;
    _threatSide=_threatSide+(_relative vectorDotProduct _left);
} forEach _aaPositions;
// Choose the side opposite the observed AA mass. With no AA, vary the geometry between runs.
private _sideVector=if (_threatSide > 0) then {_right} else {if (_threatSide < 0) then {_left} else {[ _left,_right] select (random 1 >= 0.5)}};
private _isPlane=_aircraft isKindOf "Plane";
private _pattern=if (_aaPositions isNotEqualTo []) then {
    if (_standoff) then {"STANDOFF"} else {"OFFSET"}
} else {
    if (_isPlane) then {["OFFSET","STRAFE"] select (random 1 < 0.7)} else {["STRAFE","HOOK"] select (random 1 < 0.7)}
};
private _altitude=if (_isPlane) then {if (_aaPositions isNotEqualTo []) then {450} else {260}} else {if (_aaPositions isNotEqualTo []) then {180} else {110}};
private _speed=if (_isPlane) then {430} else {170};
private _point={params ["_along","_lateral"]; private _p=_targetPos vectorAdd (_axis vectorMultiply _along); _p=_p vectorAdd (_sideVector vectorMultiply _lateral); _p set [2,_altitude]; _p};
private _ingress=[];
private _attack=[];
private _egress=[];
switch _pattern do {
    case "STANDOFF": {_ingress=[-1600,500] call _point; _attack=[-1150,350] call _point; _egress=[-1700,-650] call _point};
    case "OFFSET": {_ingress=[-1100,700] call _point; _attack=[-250,320] call _point; _egress=[850,650] call _point};
    case "HOOK": {_ingress=[-750,700] call _point; _attack=[-180,220] call _point; _egress=[650,700] call _point};
    default {_ingress=[-950,0] call _point; _attack=[-180,0] call _point; _egress=[900,0] call _point};
};
createHashMapFromArray [
    ["token",format ["%1:%2:%3",netId _aircraft,round serverTime,round random 1e6]],
    ["pattern",_pattern],["target",_target],["aaPositions",_aaPositions],["standoff",_standoff],
    ["points",[_ingress,_attack,_egress]],["altitude",_altitude],["speed",_speed]
]
