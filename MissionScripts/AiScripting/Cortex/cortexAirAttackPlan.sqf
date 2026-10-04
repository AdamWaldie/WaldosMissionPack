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
 * firing-leg time. A bounded route corridor is sampled once while the plan is built. When
 * intervening relief intrudes into the platform's clearance envelope, the same lift is added to all
 * three stages so the attack angle remains intact without a per-frame terrain controller. The join
 * from the aircraft's live position to ingress is sampled as well: relief close enough that the
 * aircraft cannot climb over it causes the plan to be refused rather than hidden by an ingress-only
 * clearance result. A route
 * requiring more than the bounded platform lift is refused so native control remains authoritative;
 * a knowingly unsafe clamped plan is never returned. STRAFE
 * dives and accelerates through; OFFSET remains oblique; HOOK crosses the
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
        private _magazineConfig=configFile >> "CfgMagazines" >> _magazine;
        private _ammo=configFile >> "CfgAmmo" >> getText (_magazineConfig >> "ammo");
        private _flags=getNumber (_ammo >> "aiAmmoUsageFlags");
        private _simulation=toLowerANSI getText (_ammo >> "simulation");
        private _pylonWeapon=toUpperANSI getText (_magazineConfig >> "pylonWeapon");
        private _hardpoints=(getArray (_magazineConfig >> "hardpoints")) apply {toUpperANSI _x};
        private _ordnanceName=toUpperANSI (_magazine+" "+_pylonWeapon+" "+(_hardpoints joinString " "));
        // Pylon bombs are not consistently represented by shotBomb. The magazine is the authoritative
        // loadout item, so retain its pylon metadata instead of inferring delivery solely from CfgAmmo.
        private _bombHint="BOMB" in (toUpperANSI _magazine) || {"BOMB" in _pylonWeapon}
            || {_hardpoints findIf {"BOMB" in _x} >= 0};
        // Several vanilla and modded fixed-rocket pylons use shotMissile because the engine's
        // projectile family does not describe the tactical delivery. The loaded pylon metadata does:
        // classify explicit rocket racks as run weapons before considering seeker flags. Without
        // this, OFFSET and HOOK could be offered from _hasRocket and then rejected because the same
        // magazine was later called GUIDED.
        private _rocketHint=!_bombHint && {"ROCKET" in _ordnanceName || {"DAGR" in _ordnanceName}};
        // aiAmmoUsageFlags alone marks some air-to-ground ordnance as useful against aircraft.
        // Require a real air lock for missiles; guns may use the engine's anti-air usage hint.
        private _antiAir=getNumber (_ammo >> "airLock") > 0
            || {_simulation in ["shotbullet","shotshell"] && {(floor (_flags/256) mod 2) == 1}};
        private _guidedGround=getNumber (_ammo >> "laserLock") > 0 || {getNumber (_ammo >> "irLock") > 0}
            || {getNumber (_ammo >> "nvLock") > 0} || {(floor (_flags/512) mod 2) == 1};
        // STANDOFF is reserved for a guided missile. Guided rockets still need a forward run and
        // belong to OFFSET/HOOK; treating them as stand-off ordnance created long-range overshoots.
        private _hit=(getNumber (_ammo >> "hit")) max (getNumber (_ammo >> "indirectHit"));
        private _standoff=_simulation == "shotmissile" && {!_rocketHint} && {_hit >= 100}
            && {_guidedGround} && {!_antiAir} && {!_bombHint};
        // Cannons are commonly dual-purpose. An anti-air usage hint must not exclude the same
        // loaded gun from a ground attack. Missiles need a real ground seeker; bombs and fixed
        // rockets use their own delivery geometry rather than a lock classification.
        private _surface=_hit > 0 && {
            _bombHint || {_rocketHint || {_simulation in ["shotbullet","shotshell","shotrocket","shotbomb"]
                || {_simulation == "shotmissile" && {_guidedGround}}
            }}
        };
        private _weaponClass=if (_bombHint) then {"BOMB"} else {if (_rocketHint) then {"ROCKET"} else {
            switch _simulation do {
                case "shotbullet";
                case "shotshell": {"GUN"};
                case "shotrocket": {"ROCKET"};
                case "shotmissile": {"GUIDED"};
                case "shotbomb": {"BOMB"};
                default {""};
            }
        }};
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
private _standoffScore=-1;
private _airWeapon="";
private _airWeaponTurret=[];
private _airSimulation="";
private _airWeaponClass="";
private _airMagazine="";
private _airWeaponScore=-1;
private _groundCandidates=[];
private _loadedMagazines=magazinesAllTurrets _aircraft;
// Start from actual loaded magazines. Dynamic pylons define their firing weapon through pylonWeapon;
// compatibleMagazines alone omits valid rocket and bomb racks on several vanilla and modded aircraft.
// The retained station still has to expose that weapon, preserving a real operator/muzzle pair.
{
    private _turret=_x;
    // Arma exposes fixed-wing and other driver-controlled weapons through `weapons`, while
    // Bohemia defines [-1] as the driver weapon station. Some aircraft expose those weapons through
    // weaponsTurret, while other vehicle/config combinations expose part of the same station through
    // weapons. Use the union: choosing only either command misclassified the armed CAS jet as
    // weaponless and prevented the attack plan from existing at all.
    private _stationWeapons=if (_turret isEqualTo [-1]) then {
        private _driverWeapons=(weapons _aircraft)+(_aircraft weaponsTurret [-1]);
        _driverWeapons arrayIntersect _driverWeapons
    } else {_aircraft weaponsTurret _turret};
    {
        _x params ["_loadedMagazine","_loadedTurret","_rounds"];
        if (_loadedTurret isEqualTo _turret && {_rounds > 0}) then {
            private _pylonWeapon=getText (configFile >> "CfgMagazines" >> _loadedMagazine >> "pylonWeapon");
            private _weapon="";
            if (_pylonWeapon != "" && {_pylonWeapon in _stationWeapons}) then {
                _weapon=_pylonWeapon;
            } else {
                private _weaponIndex=_stationWeapons findIf {_loadedMagazine in compatibleMagazines _x};
                if (_weaponIndex >= 0) then {_weapon=_stationWeapons select _weaponIndex};
            };
            if (_weapon != "") then {
                private _airFacts=[_loadedMagazine] call _ammoFacts;
                if (_airFacts select 0) then {
            private _airScore=(_airFacts select 4)+([0,1000] select ((_airFacts select 6) == "GUIDED"));
            if (_airScore > _airWeaponScore) then {
                _airWeaponScore=_airScore;
                _airWeapon=_weapon;
                _airWeaponTurret=_turret;
                _airSimulation=_airFacts select 3;
                _airWeaponClass=_airFacts select 6;
                        _airMagazine=_loadedMagazine;
                    };
                };
                if ((_airFacts select 1) && {(_airFacts select 4) > _standoffScore}) then {
                    _standoffScore=_airFacts select 4;
                    _standoff=true;
                    _standoffWeapon=_weapon;
                    _standoffTurret=_turret;
                    _standoffSimulation=_airFacts select 3;
                    _standoffMagazine=_loadedMagazine;
                };
                if (_airFacts select 2) then {
                    _groundCandidates pushBack [_weapon,_turret,_airFacts select 3,_airFacts select 4,
                        _airFacts select 6,_loadedMagazine];
                };
            };
        };
    } forEach _loadedMagazines;
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
// Target protection changes weights, not geometry or damage. Reading the vehicle config once when a
// plan is built is cheap and works for modded subclasses without maintaining a classname table.
private _targetArmour=if (_target isKindOf "CAManBase") then {0}
    else {getNumber (configFile >> "CfgVehicles" >> typeOf _target >> "armor")};
private _armouredTarget=_targetArmour >= 180 || {_target isKindOf "Tank"};
private _pattern=if (_airToAir) then {"INTERCEPT"} else {if (_aaPositions isNotEqualTo []) then {
    // Do not invent an offset run when the aircraft has no fixed rockets. In that case native AI
    // keeps control; a cannon-only aircraft should not be driven into known AA by this feature.
    if (_standoffAvailable) then {"STANDOFF"} else {if (_hasRocket) then {"OFFSET"} else {""}}
} else {
    if (_isPlane) then {
        private _choices=[];
        if (_hasGun) then {_choices append ["STRAFE",[0.42,0.12] select _armouredTarget]};
        if (_hasRocket) then {_choices append ["OFFSET",[0.25,0.22] select _armouredTarget,
            "HOOK",[0.18,0.16] select _armouredTarget]};
        if (_hasBomb) then {_choices append ["BOMB",[0.08,0.22] select _armouredTarget]};
        if (_standoffAvailable) then {_choices append ["STANDOFF",[0.07,0.38] select _armouredTarget]};
        if (_choices isEqualTo []) then {""} else {selectRandomWeighted _choices}
    } else {
        private _choices=[];
        if (_hasGun) then {_choices append ["STRAFE",[0.42,0.15] select _armouredTarget]};
        // A hook is a fixed-rocket delivery profile. Previously a helicopter gun alone made HOOK
        // selectable, after which the weapon-compatibility gate correctly rejected the same plan.
        // That contradictory offer/reject path looked like an aircraft accepting an attack and then
        // doing nothing. Only advertise a manoeuvre when the live loadout can execute it.
        if (_hasRocket) then {_choices append ["OFFSET",0.18,"HOOK",0.22]};
        if (_lateralTurret) then {_choices append ["LATERAL",[0.28,0.08] select _armouredTarget]};
        if (_standoffAvailable) then {_choices append ["STANDOFF",[0.08,0.37] select _armouredTarget]};
        if (_choices isEqualTo []) then {""} else {selectRandomWeighted _choices}
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
        // These are practical delivery heights, not cruise bands. The old 2.2-4.6 km bomb
        // profile and 0.8-1.7 km gun profile made the jet spend the entire finite lease descending,
        // then release from a shallow or already-past angle. Variation remains sampled once.
        if (_pattern == "BOMB") then {950+random 500}
        else {if (_aaPositions isNotEqualTo [] || {_pattern == "STANDOFF"}) then {1300+random 900} else {850+random 450}}
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
// OFFSET and HOOK change the attack bearing around the target. They do not offset the firing leg
// itself: a laterally displaced endpoint made the aircraft fly beside the target and guaranteed
// that fixed guns and rockets would miss. Once rolled in, every fixed-wing delivery leg is a
// straight line through the aim point. HOOK uses a larger bearing change and exits across the far
// side; OFFSET uses a shallower oblique pass.
private _deliveryAxis=+_axis;
if (_isPlane && {_pattern in ["OFFSET","HOOK"]}) then {
    private _bearingAngle=[22,38] select (_pattern == "HOOK");
    _deliveryAxis=vectorNormalized (
        (_axis vectorMultiply cos _bearingAngle)
        vectorAdd (_sideVector vectorMultiply sin _bearingAngle)
    );
};
private _deliverySide=[-(_deliveryAxis select 1),_deliveryAxis select 0,0];
private _point={params ["_along","_lateral"]; private _p=_targetPos vectorAdd (_deliveryAxis vectorMultiply _along); _p=_p vectorAdd (_deliverySide vectorMultiply _lateral); _p set [2,_altitude]; _p};
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
        // Guided standoff still needs a line through the target. The shot ends the firing leg well
        // before overflight, after which the egress turns away from the threat.
        if (_isPlane) then {
            _ingress=[-11000,0] call _point;
            _attack=[1800,0] call _point;
            _egress=[-8500,-4500] call _point
        }
        else {_ingress=[-3000,0] call _point; _attack=[650,0] call _point; _egress=[-2400,-1200] call _point};
    };
    case "STRAFE": {
        if (_isPlane) then {_ingress=[-6500,0] call _point; _attack=[900,0] call _point; _egress=[7500,1200] call _point}
        else {_ingress=[-1900,250] call _point; _attack=[550,0] call _point; _egress=[2200,500] call _point};
    };
    case "OFFSET": {
        if (_isPlane) then {_ingress=[-7000,0] call _point; _attack=[1000,0] call _point; _egress=[8000,2400] call _point}
        else {_ingress=[-2200,750] call _point; _attack=[650,200] call _point; _egress=[2500,900] call _point};
    };
    case "HOOK": {
        if (_isPlane) then {_ingress=[-7800,0] call _point; _attack=[1200,0] call _point; _egress=[6500,-4800] call _point}
        else {_ingress=[-2300,900] call _point; _attack=[700,220] call _point; _egress=[2200,-1100] call _point};
    };
    case "BOMB": {
        _ingress=[-8500,0] call _point;
        _attack=[3500,0] call _point;
        _egress=[10500,3000] call _point;
    };
    // Remain on one side of the target and translate along the attack axis. This keeps the target
    // abeam throughout the firing leg instead of crossing its position and becoming a nose-on pass.
    case "LATERAL": {_ingress=[-1200,750] call _point; _attack=[900,750] call _point; _egress=[2200,1100] call _point};
    default {
        if (_isPlane) then {_ingress=[-4200,0] call _point; _attack=[1300,0] call _point; _egress=[5500,0] call _point}
        else {_ingress=[-1900,0] call _point; _attack=[550,0] call _point; _egress=[2200,0] call _point};
    };
};
// ZEN's disposable CAS aircraft always starts on a known inbound vector. Cortex accepts persistent
// aircraft from arbitrary natural flight. A rotorcraft can shorten an aft setup leg without changing
// its weapon geometry, but doing that to a fixed-wing run moves the delivery start off the selected
// axis and guarantees an oblique rocket/missile miss. Planes therefore retain the complete roll-in;
// the engine may make one broad joining turn, then flies the immutable target-crossing attack line.
if (!_airToAir && {!_isPlane}) then {
    private _toIngress=_ingress vectorDiff _airPos;
    private _toAttack=_attack vectorDiff _airPos;
    private _forwardIngress=(_toIngress vectorDotProduct _deliveryAxis) >= 100;
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
            _stageAltitudes=[_altitude+250,_altitude,_altitude+700];
            _stageSpeeds=[_speed,_speed+30,_speed+120];
            _captureRadii=[750,900,1200];
        };
        case "BOMB": {
            // Keep the bomb run nearly level. The live ballistic basket decides release distance;
            // a multi-kilometre scripted dive merely delays the engine and ruins the approach.
            _stageAltitudes=[_altitude+100,_altitude,_altitude+650];
            _stageSpeeds=[_speed,_speed+20,_speed+120];
            _captureRadii=[900,1100,1400];
            _attackMinimum=2;
        };
        case "OFFSET": {
            // Complete the descent before the final rocket basket. A steep 1.2 km drop across one
            // leg made native pilots dive at more than 130 m/s and was unsafe even in flat VR;
            // rolling terrain only amplifies that failure. This shallow line preserves a useful
            // depression angle while leaving at least 600 m AGL at the far-side pullout point.
            private _deliveryAltitude=620+random 80;
            _stageAltitudes=[_deliveryAltitude+650,_deliveryAltitude,_altitude+900];
            _stageSpeeds=[_speed,_speed+40,_speed+80];
            _captureRadii=[700,900,1200];
            _attackMinimum=3;
        };
        case "HOOK": {
            private _deliveryAltitude=650+random 90;
            _stageAltitudes=[_deliveryAltitude+750,_deliveryAltitude,_altitude+1000];
            _stageSpeeds=[_speed,_speed+30,_speed+100];
            _captureRadii=[700,900,1250];
            _attackMinimum=3;
        };
        default {
            // Guns use a shallow, stable pass rather than a terminal dive. Native aircraft need
            // time to align and fire; terrain sampling can lift this complete corridor as one unit.
            private _deliveryAltitude=600+random 100;
            private _approachAltitude=_deliveryAltitude+550;
            _stageAltitudes=[_approachAltitude,_deliveryAltitude,_altitude+700];
            _stageSpeeds=[_speed,_speed+80,_speed+60];
            _captureRadii=[650,850,1200];
            _attackMinimum=2;
        };
    };
} else {
    switch _pattern do {
        case "INTERCEPT": {
            _stageAltitudes=[_altitude,_altitude,_altitude+40];
            _stageSpeeds=[_speed,_speed+20,_speed+40];
            _captureRadii=[220,260,320];
            _attackMinimum=4;
        };
        case "STANDOFF": {
            _stageAltitudes=[_altitude+70,_altitude,_altitude+100];
            _stageSpeeds=[_speed+20,_speed,_speed+70];
            _captureRadii=[300,350,500];
            _attackMinimum=3;
        };
        case "OFFSET": {
            _stageAltitudes=[_altitude+70,(_altitude*0.7) max 60,_altitude+100];
            _stageSpeeds=[_speed,_speed+20,_speed+50];
            _captureRadii=[280,320,480];
            _attackMinimum=4;
        };
        case "HOOK": {
            _stageAltitudes=[_altitude+80,(_altitude*0.65) max 55,_altitude+110];
            _stageSpeeds=[_speed,_speed+15,_speed+60];
            _captureRadii=[280,320,500];
            _attackMinimum=5;
        };
        case "LATERAL": {
            _stageAltitudes=[_altitude+50,_altitude,_altitude+75];
            _stageSpeeds=[_speed,(_speed-15) max 70,_speed+45];
            _captureRadii=[350,400,550];
            _attackMinimum=4;
        };
        default {
            _stageAltitudes=[_altitude+70,(_altitude*0.7) max 55,_altitude+110];
            _stageSpeeds=[_speed,_speed+45,_speed+30];
            _captureRadii=[150,180,280];
            _attackMinimum=3;
        };
    };
};
// MOVE points and flyInHeight are terrain-relative, but natural fixed-wing flight can still lag a
// sharp ridge between distant waypoints. Sample each route leg once and compare the terrain with the
// straight absolute-height profile the three stage heights describe. Samples follow three parallel
// lines because native flight can cut either side of the nominal centreline on hills and during a
// turn. Spacing is approximately 300 metres and is capped per leg, so rough terrain is represented
// without creating a per-frame terrain controller or cost that scales with every AI unit.
private _terrainLift=0;
private _terrainRequiredLift=0;
private _terrainClearanceMinimum=0;
private _terrainSampleCount=0;
private _terrainCorridor=[75,200] select _isPlane;
private _terrainViable=true;
if (!_airToAir) then {
    _terrainClearanceMinimum=1e6;
    private _terrainClearanceSamples=[];
    private _minimumTerrainClearance=[45,300] select _isPlane;
    private _terrainLiftLimit=[300,1200] select _isPlane;
    // Include the live join to ingress. That leg starts at the aircraft's real ASL and only the
    // ingress end can be raised, so required lift is divided by progress along the leg. Unsafe
    // terrain in the first fifth is too late for a scripted altitude hint to solve and rejects the
    // plan. Later legs receive the same lift at both ends and retain their attack geometry.
    private _routePoints=[_airPos,_ingress,_attack,_egress];
    for "_legIndex" from 0 to 2 do {
        private _fromPoint=_routePoints select _legIndex;
        private _toPoint=_routePoints select (_legIndex+1);
        private _joinLeg=_legIndex == 0;
        private _fromTerrain=getTerrainHeightASL _fromPoint;
        private _toTerrain=getTerrainHeightASL _toPoint;
        private _fromFlightASL=if (_joinLeg) then {(getPosASL _aircraft) select 2}
            else {_fromTerrain+(_stageAltitudes select (_legIndex-1))};
        private _toFlightASL=_toTerrain+(_stageAltitudes select _legIndex);
        private _legVector=_toPoint vectorDiff _fromPoint;
        private _horizontalLeg=+_legVector;
        _horizontalLeg set [2,0];
        private _legLength=vectorMagnitude _horizontalLeg;
        private _sampleSteps=((ceil (_legLength/300)) max 6) min 36;
        private _legSide=if (_legLength > 1) then {
            private _legDirection=vectorNormalized _horizontalLeg;
            [-(_legDirection select 1),_legDirection select 0,0]
        } else {[0,0,0]};
        for "_sampleIndex" from ([1,0] select !_joinLeg) to _sampleSteps do {
            private _fraction=_sampleIndex/_sampleSteps;
            private _sampleCentre=_fromPoint vectorAdd (_legVector vectorMultiply _fraction);
            private _plannedASL=_fromFlightASL+((_toFlightASL-_fromFlightASL)*_fraction);
            {
                private _samplePoint=_sampleCentre vectorAdd (_legSide vectorMultiply _x);
                private _terrainASL=getTerrainHeightASL _samplePoint;
                private _clearance=_plannedASL-_terrainASL;
                _terrainClearanceMinimum=_terrainClearanceMinimum min _clearance;
                _terrainClearanceSamples pushBack [_clearance,[_fraction,1] select !_joinLeg];
                private _clearanceDeficit=_minimumTerrainClearance-_clearance;
                if (_clearanceDeficit > 0) then {
                    if (_joinLeg && {_fraction <= 0.2}) then {
                        _terrainViable=false;
                    } else {
                        private _requiredLift=if (_joinLeg) then {_clearanceDeficit/_fraction}
                            else {_clearanceDeficit};
                        _terrainLift=_terrainLift max _requiredLift;
                    };
                };
                _terrainSampleCount=_terrainSampleCount+1;
            } forEach [-_terrainCorridor,0,_terrainCorridor];
        };
    };
    _terrainRequiredLift=ceil (_terrainLift max 0);
    _terrainViable=_terrainViable && {_terrainRequiredLift <= _terrainLiftLimit};
    _terrainLift=_terrainRequiredLift min _terrainLiftLimit;
    if (_terrainViable && {_terrainLift > 0}) then {
        _stageAltitudes=_stageAltitudes apply {_x+_terrainLift};
        // The live aircraft end of the join leg cannot be lifted retroactively. Report the real
        // post-lift minimum using each sample's share of the climb rather than adding the full lift
        // to a near-aircraft sample and overstating clearance on rough ground.
        _terrainClearanceMinimum=selectMin (_terrainClearanceSamples apply {
            (_x select 0)+(_terrainLift*(_x select 1))
        });
    };
};
// The engine keeps its ordinary combat task when Cortex cannot form a safe bounded corridor. This
// is preferable to returning a route which the planner has already measured below clearance and
// relying on the emergency ground-proximity abort after committing the aircraft to the run.
if (!_terrainViable) exitWith {createHashMap};
{
    private _pointValue=_x;
    _pointValue set [2,_stageAltitudes select _forEachIndex];
} forEach [_ingress,_attack,_egress];
createHashMapFromArray [
    ["token",format ["%1:%2:%3",netId _aircraft,round serverTime,round random 1e6]],
    ["pattern",_pattern],["target",_target],["targetPosition",+_targetPos],
    ["aaPositions",_aaPositions],["standoff",_standoff],
    ["points",[_ingress,_attack,_egress]],["altitude",_altitude],["speed",_speed],
    ["stageAltitudes",_stageAltitudes],["stageSpeeds",_stageSpeeds],
    ["captureRadii",_captureRadii],["attackMinimum",_attackMinimum],
    ["terrainLift",_terrainLift],["terrainClearanceMinimum",_terrainClearanceMinimum],
    ["terrainRequiredLift",_terrainRequiredLift],["terrainViable",_terrainViable],
    ["terrainSampleCount",_terrainSampleCount],["terrainCorridor",_terrainCorridor],
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
