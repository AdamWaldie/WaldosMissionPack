/*
 * Author: WaldoTheWarfighter
 * Builds one finite, threat-aware Cortex attack plan for an AI aircraft and its assigned target.
 * An airborne hostile receives an intercept plan; a surface target receives a gun strafe, fixed-rocket
 * offset/hook run, guided standoff, bomb run or helicopter lateral gun pass from aircraft type, live
 * ammunition and a bounded
 * sample of targets already known to the pilot. Intercept geometry leads the target's measured velocity,
 * varies height inside a platform-safe envelope and retains a real loaded air-to-air weapon when present.
 * This is an intercept/engage/disengage controller, not a scripted claim to full BFM. A standoff
 * plan retains the real loaded weapon/turret pair. Every surface pattern retains a loaded damaging
 * weapon/turret pair suited to its geometry; a lateral pass requires an armed independent turret.
 * Observed AA shifts the run away from the threat sector and prefers a usable
 * standoff pair unless that aircraft recently failed to acquire a firing solution.
 * Locality/authority: read-only; called on the aircraft owner. It does not reveal enemies, add
 * waypoints, move the aircraft or change crew orders. Immutable magazine facts are cached locally.
 * Each pattern carries separate ingress/attack/egress height, speed, capture radius and minimum
 * firing-leg time. STRAFE dives and accelerates through; OFFSET remains oblique; HOOK crosses the
 * target axis on a climbing exit; LATERAL stays abeam long enough for its retained turret; STANDOFF
 * uses a stable release leg and accelerates away. Repeat/JIP: safe to repeat. Each result is a new
 * owner-local plan and has no JIP side effects.
 * Aircraft may set Waldo_Cortex_AirAttackPattern to STRAFE, OFFSET, HOOK, STANDOFF, BOMB or LATERAL
 * for a finite mission-maker/test override. An incompatible forced type returns no plan instead of
 * silently substituting another weapon or manoeuvre; LATERAL requires a living gun-armed turret.
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
private _airToAir=_target isKindOf "Air" && {!isTouchingGround _target};

private _ammoCache=missionNamespace getVariable ["Waldo_Cortex_AirAmmoFacts",createHashMap];
private _ammoFacts={
    params ["_magazine"];
    private _facts=_ammoCache getOrDefault [_magazine,[]];
    if (count _facts < 8) then {
        private _ammo=configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
        private _flags=getNumber (_ammo >> "aiAmmoUsageFlags");
        private _simulation=toLowerANSI getText (_ammo >> "simulation");
        // aiAmmoUsageFlags alone marks some air-to-ground ordnance as useful against aircraft.
        // Require a real air lock for missiles; guns may use the engine's anti-air usage hint.
        private _antiAir=getNumber (_ammo >> "airLock") > 0
            || {_simulation in ["shotbullet","shotshell"] && {(floor (_flags/256) mod 2) == 1}};
        private _guidedGround=getNumber (_ammo >> "laserLock") > 0 || {getNumber (_ammo >> "irLock") > 0}
            || {getNumber (_ammo >> "nvLock") > 0} || {(floor (_flags/512) mod 2) == 1};
        // STANDOFF is reserved for a guided missile. Guided rockets still need a forward run and
        // belong to OFFSET/HOOK; treating them as stand-off ordnance created long-range overshoots.
        private _standoff=_simulation == "shotmissile" && {getNumber (_ammo >> "hit") >= 100}
            && {_guidedGround};
        private _hit=getNumber (_ammo >> "hit");
        // Cannons are commonly dual-purpose. An anti-air usage hint must not exclude the same
        // loaded gun from a ground attack. Missiles need a real ground seeker; bombs and fixed
        // rockets use their own delivery geometry rather than a lock classification.
        private _surface=_hit > 0 && {
            _simulation in ["shotbullet","shotshell","shotrocket","shotbomb"]
                || {_simulation == "shotmissile" && {_guidedGround}}
        };
        private _weaponClass=switch _simulation do {
            case "shotbullet";
            case "shotshell": {"GUN"};
            case "shotrocket": {"ROCKET"};
            case "shotmissile": {"GUIDED"};
            case "shotbomb": {"BOMB"};
            default {""};
        };
        _facts=[_antiAir,_standoff,_surface,_simulation,_hit,_guidedGround,_weaponClass,_magazine];
        _ammoCache set [_magazine,_facts];
    };
    _facts
};
private _standoff=false;
private _standoffWeapon="";
private _standoffTurret=[];
private _standoffSimulation="";
private _standoffMagazine="";
private _airWeapon="";
private _airWeaponTurret=[];
private _airSimulation="";
private _airWeaponClass="";
private _airMagazine="";
private _airWeaponScore=-1;
private _groundCandidates=[];
// Retain the actual muzzle/turret pair. Magazine metadata alone cannot fire a weapon and previously
// allowed STANDOFF plans that sprayed rockets or waited forever with no usable target solution.
{
    private _turret=_x;
    // Arma exposes fixed-wing and other driver-controlled weapons through `weapons`, while
    // `weaponsTurret [-1]` can be empty. Treat the driver station explicitly so an armed aircraft
    // cannot be misclassified as weaponless and fall back to an uncontrolled native engagement.
    private _stationWeapons=if (_turret isEqualTo [-1]) then {weapons _aircraft} else {_aircraft weaponsTurret _turret};
    {
        private _weapon=_x;
        private _compatible=compatibleMagazines _weapon;
        private _airLoaded=(magazinesAllTurrets _aircraft) findIf {
                (_x select 1) isEqualTo _turret && {(_x select 2) > 0} && {(_x select 0) in _compatible}
                    && {([_x select 0] call _ammoFacts) select 0}
        };
        if (_airLoaded >= 0) then {
            private _loadedAirMagazine=((magazinesAllTurrets _aircraft) select _airLoaded) select 0;
            private _airFacts=[_loadedAirMagazine] call _ammoFacts;
            private _airScore=(_airFacts select 4)+([0,1000] select ((_airFacts select 6) == "GUIDED"));
            if (_airScore > _airWeaponScore) then {
                _airWeaponScore=_airScore;
                _airWeapon=_weapon;
                _airWeaponTurret=_turret;
                _airSimulation=_airFacts select 3;
                _airWeaponClass=_airFacts select 6;
                _airMagazine=_loadedAirMagazine;
            };
        };
        private _loaded=(magazinesAllTurrets _aircraft) findIf {
            (_x select 1) isEqualTo _turret && {(_x select 2) > 0} && {(_x select 0) in _compatible}
                && {([_x select 0] call _ammoFacts) select 1}
        };
        if (_loaded >= 0 && {!_standoff}) then {
            _standoffMagazine=((magazinesAllTurrets _aircraft) select _loaded) select 0;
            _standoff=true;
            _standoffWeapon=_weapon;
            _standoffTurret=_turret;
            _standoffSimulation=([_standoffMagazine] call _ammoFacts) select 3;
        };
        private _surfaceLoaded=(magazinesAllTurrets _aircraft) findIf {
            (_x select 1) isEqualTo _turret && {(_x select 2) > 0} && {(_x select 0) in _compatible}
                && {([_x select 0] call _ammoFacts) select 2}
        };
        if (_surfaceLoaded >= 0) then {
            private _facts=[((magazinesAllTurrets _aircraft) select _surfaceLoaded) select 0] call _ammoFacts;
            _groundCandidates pushBack [_weapon,_turret,_facts select 3,_facts select 4,_facts select 6,
                ((magazinesAllTurrets _aircraft) select _surfaceLoaded) select 0];
        };
    } forEach _stationWeapons;
} forEach ([[-1]] + allTurrets [_aircraft,true]);
// A lateral pass needs an independently aimed, occupied turret. A fixed-forward pilot weapon cannot
// engage abeam and previously made LATERAL a label on an impossible route. Person turrets are troop
// firing positions, not aircraft weapon stations.
private _lateralTurret=false;
private _lateralTurretPath=[];
private _lateralWeapon="";
private _lateralSimulation="";
private _lateralMagazine="";
private _lateralWeaponScore=-1;
{
    _x params ["_crew","_role","_cargoIndex","_turret","_personTurret"];
    if (!_personTurret && {toLowerANSI _role in ["gunner","commander","turret"]}
        && {!isNull _crew} && {alive _crew}) then {
        {
            private _weapon=_x;
            private _loaded=(magazinesAllTurrets _aircraft) findIf {
                (_x select 1) isEqualTo _turret && {(_x select 2) > 0}
                    && {(_x select 0) in compatibleMagazines _weapon}
                    && {([_x select 0] call _ammoFacts) select 2}
            };
            if (_loaded >= 0) then {
                private _facts=[((magazinesAllTurrets _aircraft) select _loaded) select 0] call _ammoFacts;
                // Side-on flight requires a traversing gun. A guided missile on a nominal turret
                // does not make an airframe a gunship and produced the observed stationary circles.
                private _simulation=_facts select 3;
                private _score=(_facts select 4) min 300;
                if (_simulation in ["shotbullet","shotshell"] && {_score > _lateralWeaponScore}) then {
                    _lateralWeaponScore=_score;
                    _lateralTurret=true;
                    _lateralTurretPath=_turret;
                    _lateralWeapon=_weapon;
                    _lateralSimulation=_simulation;
                    _lateralMagazine=((magazinesAllTurrets _aircraft) select _loaded) select 0;
                };
            };
        } forEach (_aircraft weaponsTurret _turret);
    };
} forEach fullCrew _aircraft;

private _aaPositions=[];
private _known=(_pilot nearTargets ([8000,5000] select !(_aircraft isKindOf "Plane"))) select [0,16];
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
private _standoffAvailable=_standoff && {serverTime >= (_aircraft getVariable ["Waldo_Cortex_AirStandoffBlockedUntil",0])};
private _hasGun=_groundCandidates findIf {(_x select 2) in ["shotbullet","shotshell"]} >= 0;
private _hasRocket=_groundCandidates findIf {(_x select 4) == "ROCKET"} >= 0;
private _hasBomb=_groundCandidates findIf {(_x select 4) == "BOMB"} >= 0;
private _hasRunWeapon=_hasGun || {_hasRocket};
private _pattern=if (_airToAir) then {"INTERCEPT"} else {if (_aaPositions isNotEqualTo []) then {
    if (_standoffAvailable) then {"STANDOFF"} else {"OFFSET"}
} else {
    if (_isPlane) then {
        private _choices=[];
        if (_hasGun) then {_choices append ["STRAFE",0.35]};
        if (_hasRocket) then {_choices append ["OFFSET",0.25,"HOOK",0.15]};
        if (_hasBomb) then {_choices append ["BOMB",0.25]};
        if (_choices isEqualTo [] && {_standoffAvailable}) then {_choices=["STANDOFF",1]};
        if (_choices isEqualTo []) then {""} else {selectRandomWeighted _choices}
    } else {
        private _choices=[];
        if (_hasGun) then {_choices append ["STRAFE",0.4]};
        if (_hasRunWeapon) then {_choices append ["HOOK",0.3]};
        if (_lateralTurret) then {_choices append ["LATERAL",0.3]};
        if (_standoffAvailable) then {_choices append ["STANDOFF",0.1]};
        selectRandomWeighted _choices
    }
}};
private _patternOverride=toUpperANSI (_aircraft getVariable ["Waldo_Cortex_AirAttackPattern","AUTO"]);
private _overrideValid=_patternOverride in ["STRAFE","OFFSET","HOOK","STANDOFF","BOMB","LATERAL"]
    && {!(_patternOverride == "STRAFE") || {_hasGun}}
    && {!(_patternOverride in ["OFFSET","HOOK"]) || {_hasRocket}}
    && {!(_patternOverride == "BOMB") || {_isPlane && {_hasBomb}}}
    && {!(_patternOverride == "LATERAL") || {!_isPlane && {_lateralTurret}}}
    && {!(_patternOverride == "STANDOFF") || {_standoffAvailable}};
if (_patternOverride != "AUTO" && {!_airToAir} && {!_overrideValid}) exitWith {createHashMap};
if (_overrideValid && {!_airToAir}) then {_pattern=_patternOverride};
if (_pattern == "") exitWith {createHashMap};
private _groundWeapon="";
private _groundTurret=[];
private _groundSimulation="";
private _groundWeaponClass="";
private _groundMagazine="";
private _groundScore=-1;
{
    _x params ["_weapon","_turret","_simulation","_hit","_weaponClass","_magazine"];
    private _requiredClass=switch _pattern do {
        case "STRAFE": {"GUN"};
        case "OFFSET";
        case "HOOK": {"ROCKET"};
        case "BOMB": {"BOMB"};
        default {""};
    };
    private _compatible=_weaponClass == _requiredClass;
    private _score=(_hit min 1000);
    if (_compatible && {_score > _groundScore}) then {
        _groundScore=_score;
        _groundWeapon=_weapon;
        _groundTurret=_turret;
        _groundSimulation=_simulation;
        _groundWeaponClass=_weaponClass;
        _groundMagazine=_magazine;
    };
} forEach _groundCandidates;
if (!_airToAir && {_pattern in ["STRAFE","OFFSET","HOOK","BOMB"]} && {_groundWeapon == ""}) exitWith {createHashMap};
if (_airToAir && {_airWeapon == ""}) exitWith {createHashMap};
private _selectedWeapon=if (_airToAir) then {_airWeapon} else {
    if (_pattern == "LATERAL") then {_lateralWeapon} else {
        if (_pattern == "STANDOFF") then {_standoffWeapon} else {_groundWeapon}
    }
};
private _selectedTurret=if (_airToAir) then {_airWeaponTurret} else {
    if (_pattern == "LATERAL") then {_lateralTurretPath} else {
        if (_pattern == "STANDOFF") then {_standoffTurret} else {_groundTurret}
    }
};
private _selectedSimulation=if (_airToAir) then {_airSimulation} else {
    if (_pattern == "LATERAL") then {_lateralSimulation} else {
        if (_pattern == "STANDOFF") then {_standoffSimulation} else {_groundSimulation}
    }
};
private _selectedWeaponClass=if (_airToAir) then {_airWeaponClass} else {
    if (_pattern == "LATERAL") then {"GUN"} else {
        if (_pattern == "STANDOFF") then {"GUIDED"} else {_groundWeaponClass}
    }
};
private _selectedMagazine=if (_airToAir) then {_airMagazine} else {
    if (_pattern == "LATERAL") then {_lateralMagazine} else {
        if (_pattern == "STANDOFF") then {_standoffMagazine} else {_groundMagazine}
    }
};
// Sample once per finite plan. Bounded variation avoids identical attack profiles without adding
// per-frame work or accepting unsafe arbitrary heights.
private _altitude=if (_airToAir) then {
    private _targetHeight=(getPosATL _target) select 2;
    if (_isPlane) then {((_targetHeight+500+random 1800) max 500) min 4500}
    else {((_targetHeight+80+random 420) max 80) min 900}
} else {
    if (_isPlane) then {
        if (_pattern == "BOMB") then {1400+random 1800}
        else {if (_aaPositions isNotEqualTo [] || {_pattern == "STANDOFF"}) then {900+random 1500} else {450+random 750}}
    } else {
        if (_aaPositions isNotEqualTo [] || {_pattern == "STANDOFF"}) then {120+random 380} else {50+random 220}
    }
};
private _speed=if (_airToAir) then {
    if (_isPlane) then {520+random 220} else {150+random 100}
} else {
    if (_isPlane) then {480+random 170}
    else {if (_pattern == "LATERAL") then {110+random 55} else {if (_pattern == "STANDOFF") then {90+random 50} else {170+random 80}}}
};
private _point={params ["_along","_lateral"]; private _p=_targetPos vectorAdd (_axis vectorMultiply _along); _p=_p vectorAdd (_sideVector vectorMultiply _lateral); _p set [2,_altitude]; _p};
private _ingress=[];
private _attack=[];
private _egress=[];
switch _pattern do {
    case "INTERCEPT": {
        private _targetVelocity=velocity _target;
        private _lead=if (_isPlane) then {18+random 10} else {8+random 6};
        private _predicted=_targetPos vectorAdd (_targetVelocity vectorMultiply _lead);
        _predicted set [2,_altitude];
        private _attackLead=_targetPos vectorAdd (_targetVelocity vectorMultiply (_lead*0.35));
        _attackLead set [2,_altitude];
        private _escapeAxis=_airPos vectorDiff _targetPos;
        _escapeAxis set [2,0];
        if (vectorMagnitude _escapeAxis < 1) then {_escapeAxis=_sideVector};
        _escapeAxis=vectorNormalized _escapeAxis;
        _ingress=_predicted vectorAdd (_sideVector vectorMultiply ([1400,450] select !_isPlane));
        _attack=_attackLead;
        _egress=_targetPos vectorAdd (_escapeAxis vectorMultiply ([4500,1400] select !_isPlane));
        _egress=_egress vectorAdd (_sideVector vectorMultiply ([1800,500] select !_isPlane));
        _egress set [2,_altitude];
    };
    case "STANDOFF": {
        // Guided standoff uses a long, stable inbound leg to a release basket and then turns away.
        // It never commands a close target overflight: the shot itself ends the firing leg.
        if (_isPlane) then {
            _ingress=[-6500,1400] call _point;
            _attack=[-2800,300] call _point;
            _egress=[-6500,-2200] call _point
        }
        else {_ingress=[-2600,800] call _point; _attack=[-1400,350] call _point; _egress=[-2600,-900] call _point};
    };
    case "STRAFE": {
        if (_isPlane) then {_ingress=[-4200,350] call _point; _attack=[1300,0] call _point; _egress=[5500,900] call _point}
        else {_ingress=[-1900,250] call _point; _attack=[550,0] call _point; _egress=[2200,500] call _point};
    };
    case "OFFSET": {
        if (_isPlane) then {_ingress=[-5000,1400] call _point; _attack=[1500,250] call _point; _egress=[6000,1800] call _point}
        else {_ingress=[-2200,750] call _point; _attack=[650,200] call _point; _egress=[2500,900] call _point};
    };
    case "HOOK": {
        if (_isPlane) then {_ingress=[-5200,1700] call _point; _attack=[1700,300] call _point; _egress=[5600,-2400] call _point}
        else {_ingress=[-2300,900] call _point; _attack=[700,220] call _point; _egress=[2200,-1100] call _point};
    };
    case "BOMB": {
        _ingress=[-7000,700] call _point;
        _attack=[2200,0] call _point;
        _egress=[7000,1800] call _point;
    };
    // Remain on one side of the target and translate along the attack axis. This keeps the target
    // abeam throughout the firing leg instead of crossing its position and becoming a nose-on pass.
    case "LATERAL": {_ingress=[-1200,750] call _point; _attack=[900,750] call _point; _egress=[2200,1100] call _point};
    default {
        if (_isPlane) then {_ingress=[-4200,0] call _point; _attack=[1300,0] call _point; _egress=[5500,0] call _point}
        else {_ingress=[-1900,0] call _point; _attack=[550,0] call _point; _egress=[2200,0] call _point};
    };
};
// ZEN's disposable CAS aircraft always starts on a known three-kilometre inbound vector. Cortex
// accepts persistent aircraft from arbitrary natural flight, so a fixed setup point can lie behind
// the aircraft and make the native pilot turn a small circle before every run. Preserve the chosen
// attack geometry, but replace only an aft/too-close setup point with one bounded point on the live
// aircraft-to-attack leg. This is calculated once; the engine still flies the leg without steering.
if (!_airToAir) then {
    private _toIngress=_ingress vectorDiff _airPos;
    private _toAttack=_attack vectorDiff _airPos;
    private _forwardIngress=(_toIngress vectorDotProduct _axis) >= 100;
    if (!_forwardIngress && {vectorMagnitude _toAttack > 200}) then {
        private _setupDistance=((vectorMagnitude _toAttack)*0.45)
            max ([800,300] select !_isPlane) min ([1800,800] select !_isPlane);
        _ingress=_airPos vectorAdd ((vectorNormalized _toAttack) vectorMultiply _setupDistance);
        _ingress set [2,_altitude];
    };
};
private _stageAltitudes=[];
private _stageSpeeds=[];
private _captureRadii=[];
private _attackMinimum=2;
if (_isPlane) then {
    switch _pattern do {
        case "INTERCEPT": {
            _stageAltitudes=[_altitude,_altitude,_altitude+120];
            _stageSpeeds=[_speed,_speed+40,_speed+80];
            _captureRadii=[450,600,700];
            _attackMinimum=3;
        };
        case "STANDOFF": {
            _stageAltitudes=[_altitude+400,_altitude,_altitude+700];
            _stageSpeeds=[_speed,_speed+30,_speed+120];
            _captureRadii=[750,900,1200];
        };
        case "BOMB": {
            _stageAltitudes=[_altitude+500,_altitude,_altitude+900];
            _stageSpeeds=[_speed,_speed+50,_speed+140];
            _captureRadii=[900,1100,1400];
            _attackMinimum=2;
        };
        case "OFFSET": {
            _stageAltitudes=[_altitude+300,(_altitude*0.45) max 150,_altitude+500];
            _stageSpeeds=[_speed,_speed+40,_speed+80];
            _captureRadii=[700,900,1200];
            _attackMinimum=3;
        };
        case "HOOK": {
            _stageAltitudes=[_altitude+350,(_altitude*0.4) max 130,_altitude+650];
            _stageSpeeds=[_speed,_speed+30,_speed+100];
            _captureRadii=[700,900,1250];
            _attackMinimum=3;
        };
        default {
            _stageAltitudes=[_altitude+280,(_altitude*0.35) max 110,_altitude+600];
            _stageSpeeds=[_speed,_speed+80,_speed+60];
            _captureRadii=[650,850,1200];
            _attackMinimum=2;
        };
    };
} else {
    switch _pattern do {
        case "INTERCEPT": {
            _stageAltitudes=[_altitude,_altitude,_altitude+60];
            _stageSpeeds=[_speed,_speed+20,_speed+40];
            _captureRadii=[220,260,320];
            _attackMinimum=4;
        };
        case "STANDOFF": {
            _stageAltitudes=[_altitude+100,_altitude,_altitude+240];
            _stageSpeeds=[_speed+20,_speed,_speed+70];
            _captureRadii=[300,350,500];
            _attackMinimum=3;
        };
        case "OFFSET": {
            _stageAltitudes=[_altitude+120,(_altitude*0.55) max 55,_altitude+220];
            _stageSpeeds=[_speed,_speed+20,_speed+50];
            _captureRadii=[280,320,480];
            _attackMinimum=4;
        };
        case "HOOK": {
            _stageAltitudes=[_altitude+150,(_altitude*0.5) max 50,_altitude+280];
            _stageSpeeds=[_speed,_speed+15,_speed+60];
            _captureRadii=[280,320,500];
            _attackMinimum=5;
        };
        case "LATERAL": {
            _stageAltitudes=[_altitude+80,_altitude,_altitude+160];
            _stageSpeeds=[_speed,(_speed-15) max 70,_speed+45];
            _captureRadii=[350,400,550];
            _attackMinimum=4;
        };
        default {
            _stageAltitudes=[_altitude+120,(_altitude*0.45) max 45,_altitude+260];
            _stageSpeeds=[_speed,_speed+45,_speed+30];
            _captureRadii=[150,180,280];
            _attackMinimum=3;
        };
    };
};
{
    private _pointValue=_x;
    _pointValue set [2,_stageAltitudes select _forEachIndex];
} forEach [_ingress,_attack,_egress];
createHashMapFromArray [
    ["token",format ["%1:%2:%3",netId _aircraft,round serverTime,round random 1e6]],
    ["pattern",_pattern],["target",_target],["aaPositions",_aaPositions],["standoff",_standoff],
    ["points",[_ingress,_attack,_egress]],["altitude",_altitude],["speed",_speed],
    ["stageAltitudes",_stageAltitudes],["stageSpeeds",_stageSpeeds],
    ["captureRadii",_captureRadii],["attackMinimum",_attackMinimum],
    ["lateralTurret",_lateralTurret],["lateralTurretPath",_lateralTurretPath],
    ["lateralWeapon",_lateralWeapon],["lateralSimulation",_lateralSimulation],
    ["standoffWeapon",_standoffWeapon],["standoffSimulation",_standoffSimulation],
    ["standoffTurret",_standoffTurret],["airToAir",_airToAir],
    ["groundWeapon",_groundWeapon],["groundTurret",_groundTurret],["groundSimulation",_groundSimulation],
    ["airWeapon",_airWeapon],["airWeaponTurret",_airWeaponTurret],["airSimulation",_airSimulation],
    ["selectedWeapon",_selectedWeapon],["selectedTurret",_selectedTurret],
    ["selectedSimulation",_selectedSimulation],["selectedWeaponClass",_selectedWeaponClass],
    ["selectedMagazine",_selectedMagazine],
    ["platform",["HELICOPTER","PLANE"] select _isPlane]
]
