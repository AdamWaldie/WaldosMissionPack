/*
 * Author: WaldoTheWarfighter
 * Builds one finite, threat-aware Cortex attack plan for an AI aircraft and its assigned target.
 * The planner chooses a strafe, offset, hook, standoff or helicopter lateral run from aircraft type, live
 * guided-ground ammunition and a bounded sample of targets already known to the pilot. A standoff
 * plan retains the real loaded weapon/turret pair; a lateral pass retains the real independent turret
 * and operator weapon. Observed AA shifts the run away from the threat sector and prefers a usable
 * standoff pair unless that aircraft recently failed to acquire a firing solution.
 * Locality/authority: read-only; called on the aircraft owner. It does not reveal enemies, add
 * waypoints, move the aircraft or change crew orders. Immutable magazine facts are cached locally.
 * Repeat/JIP: safe to repeat. Each result is a new owner-local plan and has no JIP side effects.
 * Aircraft may set Waldo_Cortex_AirAttackPattern to STRAFE, OFFSET, HOOK, STANDOFF or LATERAL
 * for a finite mission-maker/test override. Invalid or platform-incompatible values fall back to
 * automatic selection; LATERAL still requires a living armed independent turret.
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
private _standoffWeapon="";
private _standoffTurret=[];
// Retain the actual muzzle/turret pair. Magazine metadata alone cannot fire a weapon and previously
// allowed STANDOFF plans that sprayed rockets or waited forever with no usable target solution.
{
    private _turret=_x;
    {
        private _weapon=_x;
        private _compatible=compatibleMagazines _weapon;
        private _loaded=(magazinesAllTurrets _aircraft) findIf {
            (_x select 1) isEqualTo _turret && {(_x select 2) > 0} && {(_x select 0) in _compatible}
                && {([_x select 0] call _ammoFacts) select 1}
        };
        if (_loaded >= 0) exitWith {_standoff=true; _standoffWeapon=_weapon; _standoffTurret=_turret};
    } forEach (_aircraft weaponsTurret _turret);
    if (_standoff) exitWith {};
} forEach ([[-1]] + allTurrets [_aircraft,true]);
// A lateral pass needs an independently aimed, occupied turret. A fixed-forward pilot weapon cannot
// engage abeam and previously made LATERAL a label on an impossible route. Person turrets are troop
// firing positions, not aircraft weapon stations.
private _lateralTurret=false;
private _lateralTurretPath=[];
private _lateralWeapon="";
{
    _x params ["_crew","_role","_cargoIndex","_turret","_personTurret"];
    if (!_personTurret && {toLowerANSI _role in ["gunner","commander","turret"]}
        && {!isNull _crew} && {alive _crew}) then {
        private _usable=(_aircraft weaponsTurret _turret) findIf {
            private _weapon=_x;
            (magazinesAllTurrets _aircraft) findIf {
                (_x select 1) isEqualTo _turret && {(_x select 2) > 0}
                    && {(_x select 0) in compatibleMagazines _weapon}
            } >= 0
        };
        if (_usable >= 0) exitWith {
            _lateralTurret=true;
            _lateralTurretPath=_turret;
            _lateralWeapon=(_aircraft weaponsTurret _turret) select _usable;
        };
    };
} forEach fullCrew _aircraft;

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
private _targetDistance=_aircraft distance2D _target;
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
private _standoffAvailable=_standoff && {serverTime >= (_aircraft getVariable ["Waldo_Cortex_AirStandoffBlockedUntil",0])};
private _pattern=if (_aaPositions isNotEqualTo []) then {
    if (_standoffAvailable) then {"STANDOFF"} else {"OFFSET"}
} else {
    if (_isPlane) then {
        selectRandomWeighted ["STRAFE",0.45,"OFFSET",0.3,"HOOK",0.25]
    } else {
        private _choices=["STRAFE",0.4,"HOOK",0.3];
        if (_lateralTurret) then {_choices append ["LATERAL",0.3]};
        if (_standoffAvailable) then {_choices append ["STANDOFF",0.1]};
        selectRandomWeighted _choices
    }
};
private _patternOverride=toUpperANSI (_aircraft getVariable ["Waldo_Cortex_AirAttackPattern","AUTO"]);
private _overrideValid=_patternOverride in ["STRAFE","OFFSET","HOOK","STANDOFF","LATERAL"]
    && {!(_patternOverride == "LATERAL") || {!_isPlane && {_lateralTurret}}}
    && {!(_patternOverride == "STANDOFF") || {_standoffAvailable}};
if (_overrideValid) then {_pattern=_patternOverride};
private _altitude=if (_isPlane) then {if (_aaPositions isNotEqualTo []) then {450} else {260}} else {if (_aaPositions isNotEqualTo []) then {180} else {110}};
private _speed=if (_isPlane) then {430} else {if (_pattern == "LATERAL") then {110} else {if (_pattern == "STANDOFF") then {90} else {170}}};
private _point={params ["_along","_lateral"]; private _p=_targetPos vectorAdd (_axis vectorMultiply _along); _p=_p vectorAdd (_sideVector vectorMultiply _lateral); _p set [2,_altitude]; _p};
private _ingress=[];
private _attack=[];
private _egress=[];
switch _pattern do {
    case "STANDOFF": {
        // Fixed-wing aircraft launch on a stable inbound leg and continue through an offset escape.
        // Build the release leg ahead of the aircraft when contact is acquired inside the nominal
        // 1.6 km setup range. Fixed points behind a fast jet forced a turn-back loop before every
        // shot. The retained 650-1400 m release range remains useful for guided ground weapons.
        if (_isPlane) then {
            private _releaseRange=((_targetDistance-350) max 650) min 1400;
            private _ingressRange=((_releaseRange+250) min ((_targetDistance-80) max _releaseRange));
            _ingress=[-_ingressRange,500] call _point;
            _attack=[-_releaseRange,350] call _point;
            _egress=[700,800] call _point
        }
        else {_ingress=[-700,450] call _point; _attack=[-550,300] call _point; _egress=[-800,-450] call _point};
    };
    case "OFFSET": {
        if (_isPlane) then {_ingress=[-1100,700] call _point; _attack=[-250,320] call _point; _egress=[850,650] call _point}
        else {_ingress=[-650,550] call _point; _attack=[-180,300] call _point; _egress=[650,550] call _point};
    };
    case "HOOK": {
        if (_isPlane) then {_ingress=[-950,800] call _point; _attack=[-180,250] call _point; _egress=[850,-650] call _point}
        else {_ingress=[-600,650] call _point; _attack=[-120,260] call _point; _egress=[550,-600] call _point};
    };
    // Remain on one side of the target and translate along the attack axis. This keeps the target
    // abeam throughout the firing leg instead of crossing its position and becoming a nose-on pass.
    case "LATERAL": {_ingress=[-650,420] call _point; _attack=[0,340] call _point; _egress=[650,420] call _point};
    default {
        if (_isPlane) then {_ingress=[-950,0] call _point; _attack=[-180,0] call _point; _egress=[900,0] call _point}
        else {_ingress=[-650,0] call _point; _attack=[-140,0] call _point; _egress=[650,0] call _point};
    };
};
createHashMapFromArray [
    ["token",format ["%1:%2:%3",netId _aircraft,round serverTime,round random 1e6]],
    ["pattern",_pattern],["target",_target],["aaPositions",_aaPositions],["standoff",_standoff],
    ["points",[_ingress,_attack,_egress]],["altitude",_altitude],["speed",_speed],
    ["lateralTurret",_lateralTurret],["lateralTurretPath",_lateralTurretPath],
    ["lateralWeapon",_lateralWeapon],["standoffWeapon",_standoffWeapon],
    ["standoffTurret",_standoffTurret],["platform",["HELICOPTER","PLANE"] select _isPlane]
]
