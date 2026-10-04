/*
 * Author: WaldoTheWarfighter
 * Exercises aircraft missile defence, surface gun, fixed-rocket, guided-missile and bomb delivery,
 * helicopter lateral fire and airborne interception using live armed aircraft, moving targets,
 * compatible weapon/operator selection, release alignment, actual damage, target destruction,
 * countermeasure events and physical flight. A Fired event or near miss cannot pass an attack case.
 * Locality/authority: scheduled server fixtures; defensive response runs through normal discovery.
 * Repeat/JIP: fresh actors, public trails/labels; removes actors and their event handlers on completion.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAircraft.sqf";
 */
params ["_recordCheck","_phase","_wait"];
private _results=[];
{
private _enabled=_x;
private _prefix=["AIR-NATIVE-","AIR-CORTEX-"] select _enabled;
private _check={params ["_id","_passed",["_detail",""]]; [_prefix+_id,_passed,_detail] call _recordCheck};
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],
    ["Waldo_AIPass_AircraftFlares_Enable",_enabled],
    ["Waldo_AIPass_AircraftBreak_Enable",_enabled],
    ["Waldo_Cortex_AttackRunFlares_Enable",false],
    ["Waldo_Cortex_AirAttack_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _aircraft=createVehicle ["O_Heli_Light_02_unarmed_F",[4500,4500,100],[],0,"FLY"];
_aircraft setDir 90; createVehicleCrew _aircraft; _aircraft allowDamage true;
private _aircrew=crew _aircraft;
private _airgroup=group driver _aircraft;
_airgroup setCombatMode "BLUE";
// Deliberately leave this ordinary aircraft without Gunship/Dynamic-AA provenance. The global
// setting must install defensive reactions on eligible AI aircraft directly.
_aircraft flyInHeight 100;
// Give both arms a real defensive window. The former 400 m launch was effectively point blank:
// even an immediate warning left too little missile time-of-flight for a physical break or flare
// rejection, so it measured launcher proximity rather than Cortex survivability.
private _launcher=createVehicle ["B_static_AA_F",[4500,3100,0],[],0,"NONE"];
_launcher setDir 0; createVehicleCrew _launcher;
private _shooters=crew _launcher;
private _shootgroup=group gunner _launcher;
_shootgroup setCombatMode "BLUE";
_shootgroup setVariable ["Waldo_AIPass_Exclude",true,true];
{
    _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _x setVariable ["acex_headless_blacklist",true,true];
    {_x setVariable ["acex_headless_blacklist",true,true]} forEach units _x;
} forEach [_airgroup,_shootgroup];
_aircraft setVariable ["Waldo_CortexQA_Label",_prefix+"HELICOPTER",true];
_launcher setVariable ["Waldo_CortexQA_Label","REAL AA MISSILE LAUNCHER",true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_aircraft,_launcher],true];
_aircraft setVariable ["Waldo_CortexQA_AALauncher",_launcher,true];
_aircraft setVariable ["Waldo_CortexQA_MissileWarnings",[],true];
_aircraft setVariable ["Waldo_CortexQA_Flares",0,true];
_aircraft setVariable ["Waldo_CortexQA_IncomingProjectile",objNull,true];
_launcher setVariable ["Waldo_CortexQA_Missiles",0,true];
_launcher addEventHandler ["Fired",{
    params ["_launcher","","","","_ammo"];
    if (toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") == "shotmissile") then {
        _launcher setVariable ["Waldo_CortexQA_Missiles",(_launcher getVariable ["Waldo_CortexQA_Missiles",0])+1,true];
        group gunner _launcher setCombatMode "BLUE";
    };
}];
_aircraft addEventHandler ["Fired",{
    params ["_aircraft","_weapon"];
    if (toLower getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") == "cmlauncher") then {
        _aircraft setVariable ["Waldo_CortexQA_Flares",(_aircraft getVariable ["Waldo_CortexQA_Flares",0])+1,true];
    };
}];
_aircraft addEventHandler ["IncomingMissile",{
    params ["_aircraft","","","",["_missile",objNull,[objNull]]];
    private _events=_aircraft getVariable ["Waldo_CortexQA_MissileWarnings",[]];
    private _sample=[serverTime,getPosATL _aircraft,velocity _aircraft];
    _events pushBack _sample;
    _aircraft setVariable ["Waldo_CortexQA_MissileWarnings",_events,true];
    _aircraft setVariable ["Waldo_CortexQA_IncomingProjectile",_missile,true];
    [_aircraft,_sample] spawn {
        params ["_aircraft","_sample"];
        private _departure=0;
        for "_i" from 1 to 60 do {
            sleep 0.1;
            if (isNull _aircraft) exitWith {};
            private _expected=(_sample select 1) vectorAdd ((_sample select 2) vectorMultiply (serverTime-(_sample select 0)));
            _departure=_departure max (_aircraft distance2D _expected);
        };
        if (!isNull _aircraft) then {_aircraft setVariable ["Waldo_CortexQA_EvasiveDeparture",_departure,true]};
    };
}];
// Start in genuine forward flight. A hovering target turns this into a countermeasure-ammunition
// check and cannot distinguish an energy-preserving break from a stationary flare dispenser.
_aircraft setVelocityModelSpace [0,35,0];
_aircraft limitSpeed 120;
private _approachWaypoint=_airgroup addWaypoint [[5700,4500,110],0];
_approachWaypoint setWaypointType "MOVE";
_approachWaypoint setWaypointBehaviour "AWARE";
private _returnWaypoint=_airgroup addWaypoint [[3600,4500,110],0];
_returnWaypoint setWaypointType "MOVE";
_returnWaypoint setWaypointBehaviour "AWARE";
private _cycleWaypoint=_airgroup addWaypoint [[4500,4500,110],0];
_cycleWaypoint setWaypointType "CYCLE";
private _moving=[{alive _aircraft && {speed _aircraft >= 45}},20] call _wait;
[_prefix+"missile acquisition","The moving helicopter is engaged by a real guided missile from tactical range. Enabled Cortex must preserve energy, break across guidance and dispense through the threat window. Firing flares alone does not pass.",[4500,4000,80]] call _phase;
private _installed=false;
if (_enabled) then {
    _installed=[{_aircraft getVariable ["Waldo_AIPass_FlaresInstalled",false]},30] call _wait;
    ["AIR-defence-installed",_installed] call _check;
} else {
    sleep 10;
    ["AIR-disabled-no-handler",!(_aircraft getVariable ["Waldo_AIPass_FlaresInstalled",false])] call _check;
};
["AIR-defence-owner-eligible",[_aircraft] call Waldo_fnc_CortexAircraftEligible] call _check;
["AIR-generic-aircraft-handler",isNil {_aircraft getVariable "Waldo_Gunship_Id"}
    && {isNil {_aircraft getVariable "Waldo_DynamicAA_SystemId"}}
    && {(!_enabled) || {_installed}}] call _check;
// Configuration refusal checks are kept separate from the live physical assertions.
_airgroup setVariable ["Waldo_AI_ExternalControl",true,true];
["AIR-external-owner-refused",!([_aircraft] call Waldo_fnc_CortexAircraftEligible)] call _check;
_airgroup setVariable ["Waldo_AI_ExternalControl",false,true];
private _detected=[{gunner _launcher knowsAbout _aircraft >= 1},60] call _wait;
diag_log format ["WMP CORTEX QA AIR DETECTION: mode=%1 natural=%2 knowsAbout=%3",
    _prefix,_detected,gunner _launcher knowsAbout _aircraft];
_shootgroup setCombatMode "RED";
(gunner _launcher) doTarget _aircraft;
private _solutionPeak=0;
private _fireDeadline=serverTime+30;
while {serverTime < _fireDeadline && {_launcher getVariable ["Waldo_CortexQA_Missiles",0] == 0}} do {
    _solutionPeak=_solutionPeak max (_launcher aimedAtTarget [_aircraft]);
    _launcher fireAtTarget [_aircraft];
    sleep 1;
};
private _fired=_launcher getVariable ["Waldo_CortexQA_Missiles",0] > 0;
["AIR-real-firing-solution",_fired,format ["peakAim=%1 finalAim=%2",_solutionPeak,_launcher aimedAtTarget [_aircraft]]] call _check;
["AIR-real-missile-fired",_fired] call _check;
private _warning=[{count (_aircraft getVariable ["Waldo_CortexQA_MissileWarnings",[]]) > 0},15] call _wait;
["AIR-real-missile-warning",_fired && {_warning}] call _check;
private _flared=[{_aircraft getVariable ["Waldo_CortexQA_Flares",0] > 0},10] call _wait;
if (_enabled) then {
    ["AIR-moving-threat-precondition",_moving,str [speed _aircraft,getPosATL _aircraft]] call _check;
    ["AIR-actual-countermeasure-release",_moving && {_fired} && {_warning} && {_flared},str (_aircraft getVariable ["Waldo_CortexQA_Flares",0])] call _check;
};
// The event-time sampler follows the bounded defensive window, not later ordinary flight drift.
// The sampler observes sixty 0.1-second intervals. Give its scheduled worker enough wall-clock
// allowance under dedicated-server load before reading the result.
private _sampled=[{!isNil {_aircraft getVariable "Waldo_CortexQA_EvasiveDeparture"}},8] call _wait;
private _departure=_aircraft getVariable ["Waldo_CortexQA_EvasiveDeparture",0];
if (_enabled) then {
    ["AIR-physical-evasive-departure",_warning && {_sampled} && {_departure >= 5},str _departure] call _check;
};
private _projectile=_aircraft getVariable ["Waldo_CortexQA_IncomingProjectile",objNull];
private _threatEnded=[{isNull _projectile || {!alive _projectile} || {!alive _aircraft}},18] call _wait;
private _survived=alive _aircraft && {_aircrew findIf {!alive _x || {vehicle _x != _aircraft}} < 0};
private _damage=if (isNull _aircraft) then {1} else {damage _aircraft};
_results pushBack [_fired && {_warning} && {_sampled},_departure,_aircraft getVariable ["Waldo_CortexQA_Flares",0],_survived,_damage,_threatEnded];
diag_log format ["WMP CORTEX QA AIR SAMPLE: mode=%1 departure=%2 countermeasures=%3 survived=%4 damage=%5 threatEnded=%6",_prefix,_departure,_aircraft getVariable ["Waldo_CortexQA_Flares",0],_survived,_damage,_threatEnded];
if (_enabled) then {
    ["AIR-guided-threat-defeated",_moving && {_fired} && {_warning} && {_threatEnded} && {_survived} && {_damage < 0.9},str [_survived,_damage,_threatEnded]] call _check;
    ["AIR-retains-operating-crew",_survived] call _check;
    ["AIR-clear-of-ground",alive _aircraft && {getPosATL _aircraft select 2 > 30}] call _check;
};
_shootgroup setCombatMode "BLUE";
{_x setUnitCombatMode "BLUE"; _x doTarget objNull} forEach _shooters;
if (_enabled && {_survived}) then {
    private _flightOrigin=getPosATL _aircraft;
    private _flightTarget=_flightOrigin vectorAdd [400,0,0];
    [_prefix+"flight after defence","After defeating the missile, the helicopter receives a normal flight waypoint. It must travel at least 100 m with its operating crew still aboard. Cortex may not leave a persistent defensive controller behind.",_flightTarget] call _phase;
    while {count waypoints _airgroup > 0} do {deleteWaypoint ((waypoints _airgroup) select 0)};
    private _flightWaypoint=_airgroup addWaypoint [_flightTarget,0];
    _flightWaypoint setWaypointType "MOVE";
    _flightWaypoint setWaypointBehaviour "AWARE";
    private _continued=[{
        alive _aircraft && {_aircraft distance2D _flightOrigin >= 100}
            && {_aircraft distance2D _flightTarget <= 300}
            && {_aircrew findIf {!alive _x || {vehicle _x != _aircraft}} < 0}
    },75] call _wait;
    ["AIR-post-defence-normal-flight",_continued,format ["travel=%1 remaining=%2",_aircraft distance2D _flightOrigin,_aircraft distance2D _flightTarget]] call _check;
};
sleep 8;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_aircrew+_shooters+[_aircraft,_launcher]);
deleteGroup _airgroup; deleteGroup _shootgroup;

} forEach [false,true];
private _native=_results select 0;
private _cortex=_results select 1;
["AIR-paired-real-threats",(_native select 0) && {_cortex select 0},str _results] call _recordCheck;
["AIR-break-exceeds-native-response",(_native select 0) && {_cortex select 0} && {(_cortex select 1) >= (_native select 1)+5},str _results] call _recordCheck;
["AIR-cortex-defeats-guided-threat",(_cortex select 0) && {(_cortex select 5)}
    && {(_cortex select 3)} && {(_cortex select 4) < 0.9}
    && {(!(_native select 3)) || {(_cortex select 4) <= (_native select 4)}},str _results] call _recordCheck;


// Additive attack-run cases. Normal target and flight commands provide the stimulus;
// the test never invokes the flare worker or assigns its approach/departure state.
{
    private _class=_x;
    {
        private _enabled=_x;
        private _id=format ["ATTACK-FLARE-%1-%2",_class,["OFF","ON"] select _enabled];
        [createHashMapFromArray [["Waldo_Cortex_AttackRunFlares_Enable",_enabled],
            ["Waldo_AIPass_AircraftFlares_Enable",false],["Waldo_AIPass_AircraftBreak_Enable",false],
            ["Waldo_Cortex_AirAttack_Enable",false]]] call Waldo_fnc_CortexTuning;
        private _plane=createVehicle [_class,[6500,5500,150],[],0,"FLY"];
        _plane setDir 0;
        createVehicleCrew _plane;
        _plane allowDamage false;
        private _crew=crew _plane;
        private _group=group driver _plane;
        _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _group setVariable ["acex_headless_blacklist",true,true];
        {_x allowDamage false} forEach _crew;
        // The flare feature must be observed on a credible attack pass. Fixed-wing aircraft need a
        // safe native baseline; 150 m allowed the unowned engine pass to dip to 50 m and obscured
        // the countermeasure result with an unrelated near-ground fixture failure.
        _plane flyInHeight ([150,400] select (_plane isKindOf "Plane"));
        private _launchSpeed=[45,90] select (_plane isKindOf "Plane");
        _plane setVelocityModelSpace [0,_launchSpeed,0];
        private _target=createVehicle ["B_Truck_01_transport_F",[6500,6700,0],[],0,"NONE"];
        createVehicleCrew _target;
        _target allowDamage false;
        private _targetCrew=crew _target;
        private _targetGroup=group driver _target;
        _targetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
        {_x allowDamage false; _x disableAI "PATH"} forEach _targetCrew;
        _group setCombatMode "RED";
        {_x doTarget _target} forEach _crew;
        private _waypoint=_group addWaypoint [[6500,7700,150],0];
        _waypoint setWaypointType "MOVE";
        _waypoint setWaypointBehaviour "AWARE";
        _plane setVariable ["Waldo_CortexQA_AttackFlares",[],true];
        _plane setVariable ["Waldo_CortexQA_Label",_id,true];
        _target setVariable ["Waldo_CortexQA_Label","ATTACK RUN TARGET",true];
        _plane addEventHandler ["Fired",{
            params ["_plane","_weapon","","","","_magazine"];
            if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") == "cmlauncher") then {
                private _events=_plane getVariable ["Waldo_CortexQA_AttackFlares",[]];
                _events pushBack [serverTime,_plane getVariable ["Waldo_Cortex_AttackFlarePhase","NATIVE"],getPosASL _plane,speed _plane,_magazine];
                _plane setVariable ["Waldo_CortexQA_AttackFlares",_events,true];
            };
        }];
        private _magazinesBefore=createHashMap;
        {_magazinesBefore set [_x select 0,(_magazinesBefore getOrDefault [_x select 0,0])+(_x select 2)]} forEach magazinesAllTurrets _plane;
        missionNamespace setVariable ["Waldo_CortexQA_Actors",[_plane,_target],true];
        [_id,"Watch a moving aircraft approach and pass the target. Enabled runs need actual flare release on both legs and ammunition consumption; phase labels alone cannot pass.",getPosATL _plane] call _phase;
        private _origin=getPosASL _plane;
        private _minimumSpeed=[80,200] select (_plane isKindOf "Plane");
        private _minimumAltitude=[30,100] select (_plane isKindOf "Plane");
        private _airborne=[{alive _plane && {speed _plane >= _minimumSpeed}
            && {(getPosATL _plane select 2) >= _minimumAltitude} && {_plane distance2D _origin >= 50}},30] call _wait;
        [_id+"-moving-airborne-precondition",_airborne,
            str [speed _plane,getPosATL _plane,_plane distance2D _origin]] call _recordCheck;
        private _passed=[{(_plane distance2D _origin > 1500) || {!alive _plane}},180] call _wait;
        // The scheduler samples once per second. Keep the completed physical pass alive long enough
        // for the production worker to observe that distance is increasing and release departure
        // countermeasures; deleting the aircraft on the same frame made fast jets race the audit.
        if (_enabled && {alive _plane}) then {
            [{(_plane getVariable ["Waldo_CortexQA_AttackFlares",[]]) findIf {(_x select 1) == "DEPARTURE"} >= 0},6] call _wait;
        };
        private _events=_plane getVariable ["Waldo_CortexQA_AttackFlares",[]];
        [_id+"-physical-flight",_airborne && {alive _plane} && {_plane distance2D _origin > 500}
            && {(getPosATL _plane select 2) >= 30},str [_plane distance2D _origin,speed _plane,getPosATL _plane]] call _recordCheck;
        if (_enabled) then {
            [_id+"-approach-release",_events findIf {(_x select 1) == "APPROACH" && {(_x select 3) >= 40}} >= 0,str _events] call _recordCheck;
            [_id+"-departure-release",_events findIf {(_x select 1) == "DEPARTURE" && {(_x select 3) >= 40}} >= 0,str _events] call _recordCheck;
            private _firedMagazines=[];
            {_firedMagazines pushBackUnique (_x select 4)} forEach _events;
            private _ammoBefore=0;
            {_ammoBefore=_ammoBefore+(_magazinesBefore getOrDefault [_x,0])} forEach _firedMagazines;
            private _ammoAfter=0;
            {if ((_x select 0) in _firedMagazines) then {_ammoAfter=_ammoAfter+(_x select 2)}} forEach magazinesAllTurrets _plane;
            [_id+"-ammunition-consumed",count _events > 0 && {_ammoAfter < _ammoBefore},str [_ammoBefore,_ammoAfter]] call _recordCheck;
        } else {
            [_id+"-no-cortex-release",_events findIf {(_x select 1) in ["APPROACH","DEPARTURE"]} < 0,str _events] call _recordCheck;
        };
        missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
        {deleteVehicle _x} forEach (_crew+_targetCrew+[_plane,_target]);
        deleteGroup _group; deleteGroup _targetGroup;
    } forEach [false,true];
} forEach ["O_Heli_Attack_02_dynamicLoadout_F","O_Plane_CAS_02_dynamicLoadout_F"];

// Paired native waypoint-replacement control. It uses the same aircraft class, airborne start,
// replacement-leg distance and physical threshold as the Cortex handover arm, but no Cortex flight
// controller or Zeus callback. This proves that the engine and audit geometry can fly a freshly
// selected group waypoint before attributing a Cortex handover failure to production logic.
[createHashMapFromArray [
    ["Waldo_Cortex_AirAttack_Enable",false],["Waldo_Cortex_AttackRunFlares_Enable",false],
    ["Waldo_AIPass_AircraftFlares_Enable",false],["Waldo_AIPass_AircraftBreak_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _nativeHandoverAircraft=createVehicle ["O_Heli_Attack_02_dynamicLoadout_F",[7400,5000,180],[],0,"FLY"];
_nativeHandoverAircraft setDir 0; createVehicleCrew _nativeHandoverAircraft; _nativeHandoverAircraft allowDamage false;
private _nativeHandoverCrew=crew _nativeHandoverAircraft;
private _nativeHandoverGroup=group driver _nativeHandoverAircraft;
_nativeHandoverGroup setVariable ["Waldo_AIPass_Exclude",true,true];
_nativeHandoverGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_nativeHandoverGroup setVariable ["acex_headless_blacklist",true,true];
{_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach _nativeHandoverCrew;
_nativeHandoverAircraft setVelocityModelSpace [0,55,0];
_nativeHandoverAircraft flyInHeight 180;
private _nativeInitial=[7400,6800,180];
private _nativeInitialWaypoint=_nativeHandoverGroup addWaypoint [_nativeInitial,0];
_nativeInitialWaypoint setWaypointType "MOVE";
_nativeInitialWaypoint setWaypointBehaviour "AWARE";
_nativeInitialWaypoint setWaypointSpeed "FULL";
_nativeHandoverAircraft setVariable ["Waldo_CortexQA_Label","AIR-HANDOVER-NATIVE-CONTROL",true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_nativeHandoverAircraft],true];
["AIR-HANDOVER-NATIVE-CONTROL","Native comparison: the airborne helicopter must accept a replacement AWARE/FULL/MOVE waypoint and physically fly it. This uses the same leg and threshold as the Cortex Zeus handover without starting any Cortex aircraft lease.",getPosATL _nativeHandoverAircraft] call _phase;
private _nativeOrigin=getPosATL _nativeHandoverAircraft;
private _nativeStarted=[{_nativeHandoverAircraft distance2D _nativeOrigin >= 100},60] call _wait;
["AIR-HANDOVER-NATIVE-CONTROL-started",_nativeStarted,str [getPosATL _nativeHandoverAircraft,speed _nativeHandoverAircraft]] call _recordCheck;
private _nativeReplacement=(getPosATL _nativeHandoverAircraft) vectorAdd [600,250,0];
private _nativeReplacementWaypoint=_nativeHandoverGroup addWaypoint [_nativeReplacement,0];
_nativeReplacementWaypoint setWaypointType "MOVE";
_nativeReplacementWaypoint setWaypointBehaviour "AWARE";
_nativeReplacementWaypoint setWaypointSpeed "FULL";
_nativeHandoverGroup setCurrentWaypoint _nativeReplacementWaypoint;
private _nativeTravelled=[{_nativeHandoverAircraft distance2D _nativeReplacement <= 350},90] call _wait;
["AIR-HANDOVER-NATIVE-CONTROL-replacement-travel",_nativeStarted && {_nativeTravelled},str [
    _nativeHandoverAircraft distance2D _nativeReplacement,getPosATL _nativeHandoverAircraft,
    currentCommand driver _nativeHandoverAircraft,expectedDestination driver _nativeHandoverAircraft,
    currentWaypoint _nativeHandoverGroup,waypoints _nativeHandoverGroup apply {waypointPosition _x},
    speed _nativeHandoverAircraft,velocityModelSpace _nativeHandoverAircraft
]] call _recordCheck;
["AIR-HANDOVER-NATIVE-CONTROL-no-cortex-owner",
    (_nativeHandoverAircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo []
        && {(_nativeHandoverAircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]]) isEqualTo []},
    str [_nativeHandoverAircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]],
        _nativeHandoverAircraft getVariable ["Waldo_Cortex_AirHandoverResult",[]]]] call _recordCheck;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_nativeHandoverCrew+[_nativeHandoverAircraft]);
deleteGroup _nativeHandoverGroup;

// Adaptive attacks remain separate from the flare-only comparison above. These cases never invoke
// the production planner/worker directly: ordinary targets, knowledge and flight orders provide the
// stimulus, and discovery must acquire the aircraft on its normal interval.
private _observedProfiles=createHashMap;
{
    _x params ["_id","_class","_withAA","_interrupt",["_patternOverride","AUTO"],
        ["_airTarget",false],["_expectedWeaponClass",""],["_mustDestroy",false],
        ["_targetClassOverride",""]];
    [createHashMapFromArray [
        ["Waldo_Cortex_AirAttack_Enable",true],["Waldo_Cortex_AttackRunFlares_Enable",true],
        ["Waldo_AIPass_AircraftFlares_Enable",false],["Waldo_AIPass_AircraftBreak_Enable",false]
    ]] call Waldo_fnc_CortexTuning;
    private _isPlaneClass=_class isKindOf ["Plane",configFile >> "CfgVehicles"];
    // Fixed-wing employment needs enough distance to establish a stable weapon axis before release.
    // Starting a jet inside two kilometres made discovery occur after overflight, so the fixture
    // measured emergency turns rather than the authored attack. Helicopters retain the compact lane.
    private _aircraft=createVehicle [_class,[8200,[5000,3000] select _isPlaneClass,[180,900] select _isPlaneClass],[],0,"FLY"];
    _aircraft setDir 0; createVehicleCrew _aircraft; _aircraft allowDamage false;
    // Give every weapon-specific case a deliberate, visible loadout. Dynamic-loadout defaults can
    // expose only one missile or bomb, which tests a depleted editor preset instead of the finite
    // multi-round attack contract. Use only magazines declared compatible by the aircraft's own
    // pylon config; modded aircraft are never assigned a guessed classname.
    private _auditPylonMagazine=switch _expectedWeaponClass do {
        case "ROCKET": {"PylonRack_20Rnd_Rocket_03_HE_F"};
        case "BOMB": {"PylonMissile_1Rnd_Bomb_03_F"};
        case "GUIDED": {
            ["PylonRack_1Rnd_Missile_AGM_01_F","PylonRack_1Rnd_Missile_AA_03_F"] select _airTarget
        };
        default {""};
    };
    private _auditPylonNeed=switch _expectedWeaponClass do {
        case "BOMB": {2};
        case "GUIDED": {3};
        case "ROCKET": {4};
        default {0};
    };
    private _auditPylonsConfigured=0;
    if (_auditPylonMagazine != "") then {
        {
            if (_auditPylonsConfigured < _auditPylonNeed
                && {_auditPylonMagazine in (_aircraft getCompatiblePylonMagazines (_x select 1))}) then {
                _aircraft setPylonLoadout [_x select 0,_auditPylonMagazine,true,_x select 2];
                _auditPylonsConfigured=_auditPylonsConfigured+1;
            };
        } forEach getAllPylonsInfo _aircraft;
    };
    private _pilot=driver _aircraft;
    // Observe the aircraft's normal crew exactly as createVehicleCrew supplies it. The fixture must
    // never manufacture extra turret operators to make an unsuitable airframe appear attack-ready.
    _aircraft setVariable ["Waldo_Cortex_AirAttackPattern",_patternOverride,true];
    private _crew=crew _aircraft;
    private _group=group driver _aircraft;
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    {_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach _crew;
    private _launchSpeed=[55,155] select (_aircraft isKindOf "Plane");
    _aircraft setVelocityModelSpace [0,_launchSpeed,0];
    _aircraft flyInHeight ([180,900] select (_aircraft isKindOf "Plane"));
    private _friendlySide=side _group;
    private _targetClass=if (_targetClassOverride != "") then {_targetClassOverride} else {if (_friendlySide == west) then {
        ["O_APC_Tracked_02_cannon_F","O_Plane_CAS_02_dynamicLoadout_F"] select _airTarget
    } else {
        ["B_APC_Tracked_01_rcws_F","B_Plane_CAS_01_dynamicLoadout_F"] select _airTarget
    }};
    private _targetPosition=if (_airTarget) then {[8500,9300,650]} else {
        [[8200,7600,0],[8200,12000,0]] select (_aircraft isKindOf "Plane")
    };
    private _target=createVehicle [_targetClass,_targetPosition,[],0,["NONE","FLY"] select _airTarget];
    createVehicleCrew _target; _target allowDamage _mustDestroy;
    private _targetCrew=crew _target;
    private _targetGroup=group driver _target;
    _targetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    {_x allowDamage false; if (!_airTarget) then {_x disableAI "PATH"}} forEach _targetCrew;
    if (!_airTarget) then {
        // A ground weapon audit requires an immutable aim point. Disabled crew pathfinding alone
        // still allowed the running vehicle to roll after the plan was sampled.
        _target engineOn false;
        _target setFuel 0;
        _target setVelocity [0,0,0];
        _target setPosATL _targetPosition;
        {doStop _x} forEach _targetCrew;
    };
    if (_airTarget) then {
        _target setDir 180;
        _target setVelocityModelSpace [0,145,0];
        _target flyInHeight 650;
        _targetGroup setCombatMode "BLUE";
        private _targetWaypoint=_targetGroup addWaypoint [[7600,4200,650],0];
        _targetWaypoint setWaypointType "MOVE";
        _targetWaypoint setWaypointBehaviour "AWARE";
        _targetWaypoint setWaypointSpeed "FULL";
    };
    private _aa=objNull;
    private _aaCrew=[];
    private _aaGroup=grpNull;
    if (_withAA) then {
        _aa=createVehicle ["B_static_AA_F",[[8750,6350,0],[8750,10750,0]] select _isPlaneClass,[],0,"NONE"];
        createVehicleCrew _aa; _aa allowDamage _mustDestroy;
        _aaCrew=crew _aa; _aaGroup=group gunner _aa;
        _aaGroup setVariable ["Waldo_AIPass_Exclude",true,true];
        {_x allowDamage false; _x disableAI "PATH"} forEach _aaCrew;
        // The case is explicitly observed-AA planning, so known threat is its declared stimulus.
        _group reveal [_aa,4];
        _aa setVariable ["Waldo_CortexQA_Label","OBSERVED AA THREAT",true];
    };
    _group setCombatMode "RED";
    // Declare a detected contact without pre-commanding every seat to attack it. The production
    // discovery path must turn normal group knowledge into the finite job; otherwise native fire
    // can make a controller that never reaches ATTACK appear successful.
    _group reveal [_target,4];
    private _authoredDestination=[8200,[12500,17000] select _isPlaneClass,[180,900] select _isPlaneClass];
    private _waypoint=_group addWaypoint [_authoredDestination,0];
    _waypoint setWaypointType "MOVE"; _waypoint setWaypointBehaviour "COMBAT";
    _aircraft setVariable ["Waldo_CortexQA_Label",_id,true];
    _target setVariable ["Waldo_CortexQA_Label",["LIVE ARMOURED ATTACK TARGET","LIVE AIR INTERCEPT TARGET"] select _airTarget,true];
    _aircraft setVariable ["Waldo_CortexQA_AdaptiveShots",0,true];
    _aircraft setVariable ["Waldo_CortexQA_AttackStageShots",[],true];
    _aircraft setVariable ["Waldo_CortexQA_AdaptiveFlares",0,true];
    _aircraft setVariable ["Waldo_CortexQA_AttackTarget",_target,true];
    _aircraft setVariable ["Waldo_CortexQA_ReleaseResults",[],true];
    _target setVariable ["Waldo_CortexQA_WeaponHits",0,true];
    _target addEventHandler ["Hit",{
        params ["_target","_source"];
        private _attackAircraft=_target getVariable ["Waldo_CortexQA_AttackAircraft",objNull];
        if (!isNull _attackAircraft && {_source == _attackAircraft || {_source in crew _attackAircraft}}) then {
            _target setVariable ["Waldo_CortexQA_WeaponHits",(_target getVariable ["Waldo_CortexQA_WeaponHits",0])+1,true];
        };
    }];
    _target setVariable ["Waldo_CortexQA_AttackAircraft",_aircraft,true];
    _aircraft setVariable ["Waldo_CortexQA_ReleaseSamplesStarted",0,true];
    _aircraft addEventHandler ["Fired",{
        params ["_aircraft","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
        if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") == "cmlauncher") then {
            _aircraft setVariable ["Waldo_CortexQA_AdaptiveFlares",(_aircraft getVariable ["Waldo_CortexQA_AdaptiveFlares",0])+1,true];
        } else {
            _aircraft setVariable ["Waldo_CortexQA_AdaptiveShots",(_aircraft getVariable ["Waldo_CortexQA_AdaptiveShots",0])+1,true];
            private _stages=_aircraft getVariable ["Waldo_CortexQA_AttackStageShots",[]];
            _stages pushBack ((_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) param [2,""]);
            _aircraft setVariable ["Waldo_CortexQA_AttackStageShots",_stages,true];
            private _target=_aircraft getVariable ["Waldo_CortexQA_AttackTarget",objNull];
            private _startedSamples=_aircraft getVariable ["Waldo_CortexQA_ReleaseSamplesStarted",0];
            if (!isNull _target && {_startedSamples < 12}) then {
                // Reserve the slot before the asynchronous closest-approach sampler starts. Counting
                // only completed samples allowed a fast cannon burst to create one job per round.
                _aircraft setVariable ["Waldo_CortexQA_ReleaseSamplesStarted",_startedSamples+1,true];
                private _velocity=velocity _projectile;
                private _bearing=(aimPos _target) vectorDiff (getPosASL _aircraft);
                private _alignment=if (vectorMagnitude _velocity > 0.1 && {vectorMagnitude _bearing > 0.1}) then {
                    (vectorNormalized _velocity) vectorDotProduct (vectorNormalized _bearing)
                } else {-1};
                [_aircraft,_target,_projectile,_weapon,_ammo,_alignment] spawn {
                    params ["_aircraft","_target","_projectile","_weapon","_ammo","_alignment"];
                    private _closest=if (isNull _projectile) then {1e9} else {_projectile distance _target};
                    // High releases can remain in flight well after the finite controller has
                    // begun egress. Keep the damageable target and sampler alive long enough to
                    // observe the real impact instead of deleting both two seconds after release.
                    private _deadline=serverTime+20;
                    while {!isNull _projectile && {alive _target} && {serverTime < _deadline}} do {
                        _closest=_closest min (_projectile distance _target);
                        sleep 0.05;
                    };
                    private _results=_aircraft getVariable ["Waldo_CortexQA_ReleaseResults",[]];
                    _results pushBack [serverTime,_weapon,_ammo,_alignment,_closest];
                    _aircraft setVariable ["Waldo_CortexQA_ReleaseResults",_results,true];
                };
            };
        };
    }];
    private _actors=[_aircraft,_target]; if (!isNull _aa) then {_actors pushBack _aa};
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors,true];
    [_id,"Watch the aircraft physically fly its labelled pattern, fire real weapons and exit safely. The cyan leg and red target line are live geometry; an assigned target or elapsed timer cannot pass.",getPosATL _aircraft] call _phase;
    private _origin=getPosATL _aircraft;
    private _started=[{(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []},35] call _wait;
    // Keep this case bound to the exact operation it started. A failed finite pass may otherwise be
    // rediscovered while the audit is still collecting its outcome, replacing the evidence with a
    // second plan and multiplying the case duration. This fixture-only cooldown does not interrupt
    // the active job and is discarded with the aircraft at case cleanup.
    if (_started) then {_aircraft setVariable ["Waldo_Cortex_AirAttackBlockedUntil",serverTime+300]};
    [_id+"-physical-plan-start",_started,str [
        _aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]],
        weapons _aircraft,_aircraft weaponsTurret [-1],magazinesAllTurrets _aircraft,
        getPylonMagazines _aircraft,[_auditPylonMagazine,_auditPylonNeed,_auditPylonsConfigured]
    ]] call _recordCheck;
    [_id+"-weapon-loadout-sufficient",_auditPylonNeed == 0 || {_auditPylonsConfigured >= _auditPylonNeed},
        str [_auditPylonMagazine,_auditPylonNeed,_auditPylonsConfigured,getAllPylonsInfo _aircraft]] call _recordCheck;
    _aircraft setVariable ["Waldo_CortexQA_ProfileSamples",[],true];
    [_aircraft] spawn {
        params ["_sampleAircraft"];
        while {alive _sampleAircraft && {(_sampleAircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []}} do {
            private _planSample=_sampleAircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
            private _samples=_sampleAircraft getVariable ["Waldo_CortexQA_ProfileSamples",[]];
            _samples pushBack [
                serverTime,_planSample param [2,""],speed _sampleAircraft,
                (getPosATL _sampleAircraft) select 2,_planSample param [4,[]],getPosATL _sampleAircraft,
                _sampleAircraft getVariable ["Waldo_Cortex_AirFireSolution",[]]
            ];
            _sampleAircraft setVariable ["Waldo_CortexQA_ProfileSamples",_samples,true];
            // QA-only quarter-second sampling catches the short terminal basket without changing
            // production cadence or manufacturing a release.
            sleep 0.25;
        };
    };
    [_id+"-dedicated-aircraft-owner",
        !(_group getVariable ["Waldo_AIPass_Managed",false])
            && {count (_group getVariable ["Waldo_AIPass_State",createHashMap]) == 0},
        str [_group getVariable ["Waldo_AIPass_Managed",false],
            _group getVariable ["Waldo_AIPass_PublicPhase",""],
            _group getVariable ["Waldo_AIPass_State",createHashMap]]] call _recordCheck;
    [_id+"-exclusive-flight-controller",!(_aircraft getVariable ["Waldo_HelicopterDeceleration_Active",false])
        && {!(_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active",false])},
        str [_aircraft getVariable ["Waldo_HelicopterDeceleration_LastResult",[]],
            _aircraft getVariable ["Waldo_ImprovedHelicopterLanding_LastResult",[]]]] call _recordCheck;
    private _initialPlan=_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
    // Observed-AA planning can legitimately replace the original armour contact with the known air
    // defence threat. From this point the audit must measure the production plan's accepted target;
    // comparing impacts and damage with the superseded fixture object creates false miss results.
    private _plannedTargetObject=_initialPlan param [3,_target];
    if (!isNull _plannedTargetObject && {_plannedTargetObject != _target}) then {
        _aircraft setVariable ["Waldo_CortexQA_AttackTarget",_plannedTargetObject,true];
        _plannedTargetObject setVariable ["Waldo_CortexQA_AttackAircraft",_aircraft,true];
        _plannedTargetObject setVariable ["Waldo_CortexQA_WeaponHits",0,true];
        _plannedTargetObject addEventHandler ["Hit",{
            params ["_target","_source"];
            private _attackAircraft=_target getVariable ["Waldo_CortexQA_AttackAircraft",objNull];
            if (!isNull _attackAircraft && {_source == _attackAircraft || {_source in crew _attackAircraft}}) then {
                _target setVariable ["Waldo_CortexQA_WeaponHits",
                    (_target getVariable ["Waldo_CortexQA_WeaponHits",0])+1,true];
            };
        }];
    };
    private _pattern=_initialPlan param [1,""];
    private _profileAltitudes=_initialPlan param [17,[]];
    private _profileSpeeds=_initialPlan param [18,[]];
    private _profileRadii=_initialPlan param [19,[]];
    private _profileDwell=_initialPlan param [20,0];
    private _profilePoints=_initialPlan param [21,[]];
    private _selectedWeapon=_initialPlan param [22,""];
    private _selectedSimulation=_initialPlan param [23,""];
    private _selectedTurret=_initialPlan param [24,[]];
    private _selectedWeaponClass=_initialPlan param [25,""];
    private _terrainLift=_initialPlan param [27,0];
    private _terrainClearanceMinimum=_initialPlan param [28,0];
    private _terrainSampleCount=_initialPlan param [29,0];
    private _terrainCorridor=_initialPlan param [30,0];
    private _plannedTargetPosition=_initialPlan param [31,getPosATL _target];
    private _terrainRequiredLift=_initialPlan param [32,0];
    private _terrainViable=_initialPlan param [33,false];
    private _selectedOperator=if (_selectedTurret isEqualTo [-1]) then {driver _aircraft}
        else {_aircraft turretUnit _selectedTurret};
    if (_pattern != "") then {_observedProfiles set [_pattern,[_profilePoints,_profileAltitudes,_profileSpeeds]]};
    [_id+"-pattern-specific-flight-profile",count _profileAltitudes == 3
        && {count _profileSpeeds == 3} && {count _profileRadii == 3}
        && {_profileDwell >= 2}
        && {count (_profileAltitudes arrayIntersect _profileAltitudes) > 1
            || {count (_profileSpeeds arrayIntersect _profileSpeeds) > 1}},
        str [_pattern,_profileAltitudes,_profileSpeeds,_profileRadii,_profileDwell,_profilePoints]] call _recordCheck;
    if (!_airTarget) then {
        private _requiredTerrainClearance=[45,300] select _isPlaneClass;
        [_id+"-terrain-envelope",_terrainLift >= 0
            && {_terrainLift <= ([300,1200] select _isPlaneClass)}
            && {_terrainRequiredLift == _terrainLift}
            && {_terrainViable}
            && {_terrainClearanceMinimum >= _requiredTerrainClearance}
            && {_terrainSampleCount >= 42}
            && {_terrainCorridor >= ([75,200] select _isPlaneClass)},
            str [_terrainLift,_terrainRequiredLift,_terrainViable,_terrainClearanceMinimum,_requiredTerrainClearance,_profileAltitudes,
                _terrainSampleCount,_terrainCorridor]] call _recordCheck;
        // VR is the fast flat regression arm. A checked Altis launch must prove that its route is
        // genuinely non-flat; otherwise a green terrain-envelope result would merely repeat VR in
        // a different world. Fourteen independent centreline samples provide a cheap scenario-relief
        // assertion; the production plan above separately proves its wider adaptive corridor.
        private _terrainSamples=[];
        if (count _profilePoints == 3) then {
            for "_terrainLeg" from 0 to 1 do {
                private _terrainStart=_profilePoints select _terrainLeg;
                private _terrainEnd=_profilePoints select (_terrainLeg+1);
                for "_terrainIndex" from 0 to 6 do {
                    private _fraction=_terrainIndex/6;
                    private _sample=(_terrainStart vectorMultiply (1-_fraction))
                        vectorAdd (_terrainEnd vectorMultiply _fraction);
                    _terrainSamples pushBack (getTerrainHeightASL _sample);
                };
            };
        };
        private _terrainRelief=if (_terrainSamples isEqualTo []) then {0}
            else {(selectMax _terrainSamples)-(selectMin _terrainSamples)};
        [_id+"-terrain-scenario-relief",worldName == "VR" || {_terrainRelief >= 30},
            str [worldName,_terrainRelief,_terrainSamples]] call _recordCheck;
    };
    if (_isPlaneClass && {!_airTarget} && {count _profilePoints == 3}) then {
        private _deliveryStart=+(_profilePoints select 0);
        private _deliveryEnd=+(_profilePoints select 1);
        private _deliveryVector=_deliveryEnd vectorDiff _deliveryStart;
        _deliveryVector set [2,0];
        private _deliveryLength=vectorMagnitude _deliveryVector;
        private _deliveryDirection=if (_deliveryLength > 1) then {vectorNormalized _deliveryVector} else {[0,0,0]};
        private _targetVector=_plannedTargetPosition vectorDiff _deliveryStart;
        _targetVector set [2,0];
        private _targetAlong=_targetVector vectorDotProduct _deliveryDirection;
        private _crossTrack=abs ((_targetVector select 0)*(_deliveryDirection select 1)
            -(_targetVector select 1)*(_deliveryDirection select 0));
        private _descentAngle=if (_deliveryLength > 1) then {
            atan (((_deliveryStart select 2)-(_deliveryEnd select 2))/_deliveryLength)
        } else {90};
        private _angleValid=switch _selectedWeaponClass do {
            case "GUN";
            case "ROCKET": {_descentAngle >= 3 && {_descentAngle <= 9}};
            case "BOMB": {abs _descentAngle <= 4};
            case "GUIDED": {abs _descentAngle <= 8};
            default {false};
        };
        [_id+"-delivery-axis-crosses-target",_deliveryLength >= 3000 && {_crossTrack <= 75}
            && {_targetAlong > 0} && {_targetAlong < _deliveryLength}
            && {_angleValid} && {(_deliveryEnd select 2) >= 220},
            str [_selectedWeaponClass,_descentAngle,_crossTrack,_targetAlong,_deliveryLength,
                _deliveryStart,_deliveryEnd,_plannedTargetPosition,getPosATL _target,
                _plannedTargetPosition distance2D _target]] call _recordCheck;
        [_id+"-ground-target-stationary",_plannedTargetPosition distance2D _plannedTargetObject <= 2,
            str [_plannedTargetPosition,getPosATL _plannedTargetObject,
                _plannedTargetPosition distance2D _plannedTargetObject,typeOf _plannedTargetObject]] call _recordCheck;
    };
    private _weaponMatchesPattern=switch _pattern do {
        case "STRAFE";
        case "LATERAL": {_selectedWeaponClass == "GUN"};
        case "STANDOFF": {_selectedWeaponClass == "GUIDED"};
        case "BOMB": {_selectedWeaponClass == "BOMB"};
        case "OFFSET";
        case "HOOK": {_selectedWeaponClass == "ROCKET"};
        case "INTERCEPT": {_selectedWeaponClass in ["GUN","GUIDED"]};
        default {false};
    };
    [_id+"-weapon-matches-manoeuvre",_selectedWeapon != "" && {_weaponMatchesPattern}
        && {_expectedWeaponClass == "" || {_selectedWeaponClass == _expectedWeaponClass}},
        str [_pattern,_selectedWeapon,_selectedSimulation,_selectedTurret,_selectedWeaponClass,
            _expectedWeaponClass]] call _recordCheck;
    [_id+"-armed-live-operator",_selectedWeapon != "" && {!isNull _selectedOperator}
        && {alive _selectedOperator},str [_class,_selectedWeapon,_selectedTurret,_selectedOperator,fullCrew _aircraft]] call _recordCheck;
    [_id+"-damageable-target-prerequisite",!_mustDestroy || {isDamageAllowed _plannedTargetObject},
        str [_mustDestroy,isDamageAllowed _plannedTargetObject,typeOf _plannedTargetObject]] call _recordCheck;
    if (_airTarget) then {
        [_id+"-air-contact-intercept-plan",_pattern == "INTERCEPT"
            && {_initialPlan param [3,objNull] == _target}
            && {speed _target >= 40},str [_initialPlan,speed _target,getPosATL _target]] call _recordCheck;
    };
    if (_withAA) then {
        [_id+"-aa-aware-pattern",_pattern in ["OFFSET","STANDOFF"] && {(_initialPlan param [7,0]) > 0},str _initialPlan] call _recordCheck;
    } else {
        if (!_interrupt && {!_airTarget}) then {
        [_id+"-low-threat-pattern",_pattern in ["STRAFE","OFFSET","HOOK","LATERAL","BOMB","STANDOFF"],str _initialPlan] call _recordCheck;
        if (_patternOverride == "LATERAL") then {
            [_id+"-lateral-capable-turret",_pattern == "LATERAL" && {_initialPlan param [13,false]},str _initialPlan] call _recordCheck;
        };
        };
    };
    if (_interrupt && {_started}) then {
        private _handoverPilot=driver _aircraft;
        private _handoverFeaturesBefore=["AUTOCOMBAT","TARGET","AUTOTARGET"] apply {
            _handoverPilot checkAIFeature _x
        };
        private _handoverCombatModeBefore=unitCombatMode _handoverPilot;
        private _handoverGroupCombatModeBefore=combatMode _group;
        private _moved=[{_aircraft distance2D _origin >= 100},60] call _wait;
        [_id+"-interrupt-physical-prerequisite",_moved,str (_aircraft distance2D _origin)] call _recordCheck;
        private _replacement=(getPosATL _aircraft) vectorAdd [600,250,0];
        // Model the waypoint Zeus actually creates and selects. Editing currentWaypoint while a
        // scripted aircraft attack is active can mutate an engine/Cortex destination rather than a
        // curator waypoint, producing a false handover failure against the old ingress position.
        private _replacementWaypoint=_group addWaypoint [_replacement,0];
        _replacementWaypoint setWaypointType "MOVE";
        _replacementWaypoint setWaypointBehaviour "AWARE";
        _replacementWaypoint setWaypointSpeed "FULL";
        _group setCurrentWaypoint _replacementWaypoint;
        private _handoverBehaviourExpected=waypointBehaviour _replacementWaypoint;
        // Curator waypoint events arrive after the engine has applied the edit. Keep this fixture in
        // that production order so cleanup can hand control to the selected replacement route.
        [_group,true,_replacementWaypoint select 1] call Waldo_fnc_CortexZeusMark;
        private _zeusSnapshot=_group getVariable ["Waldo_Cortex_ZeusOrderSnapshot",[]];
        [_id+"-zeus-snapshot-exact",_zeusSnapshot isNotEqualTo []
            && {(_zeusSnapshot param [1,[]]) distance2D _replacement < 1}
            && {_zeusSnapshot param [2,""] == "AWARE"}
            && {_zeusSnapshot param [3,""] == "FULL"},
            str [_replacement,_replacementWaypoint,_group getVariable ["Waldo_AIPass_ZeusHold",[]],_zeusSnapshot]] call _recordCheck;
        // Remove the fixture contact after Zeus takes over. The handover case measures whether
        // Cortex leaves the selected waypoint cleanly; retaining a known hostile instead measures
        // vanilla combat discretion and can make a correct release orbit away from the MOVE order.
        {deleteVehicle _x} forEach _targetCrew;
        deleteVehicle _target;
        private _released=[{(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo []},10] call _wait;
        private _handoverResult=_aircraft getVariable ["Waldo_Cortex_AirHandoverResult",[]];
        private _immediateHandover=(_aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]]) isEqualTo []
            && {(_aircraft getVariable ["Waldo_Cortex_AirHandoverRecovery",[]]) isEqualTo []}
            && {_handoverResult param [5,""] == "ZEUS_IMMEDIATE_HANDOVER"};
        private _travelled=[{_aircraft distance2D _replacement <= 350},90] call _wait;
        [_id+"-zeus-plan-retired",_released,str (_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]])] call _recordCheck;
        [_id+"-immediate-zeus-handover",_released && {_immediateHandover},str [
            _handoverResult,
            _aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]],
            _aircraft getVariable ["Waldo_Cortex_AirHandoverRecovery",[]]
        ]] call _recordCheck;
        [_id+"-zeus-replacement-travel",_released && {_travelled},str [
            _aircraft distance2D _replacement,getPosATL _aircraft,currentCommand (driver _aircraft),
            assignedTarget (driver _aircraft),expectedDestination (driver _aircraft),
            _group knowsAbout _target,combatMode _group,behaviour (driver _aircraft),
            combatBehaviour _group,combatBehaviour (driver _aircraft),
            attackEnabled _group,speedMode _group,speed _aircraft,
            getForcedSpeed _aircraft,vectorDir _aircraft,velocityModelSpace _aircraft,
            currentWaypoint _group,waypoints _group apply {waypointPosition _x},
            _replacement,_group getVariable ["Waldo_Cortex_ZeusOrderSnapshot",[]],
            _aircraft getVariable ["Waldo_Cortex_AirHandoverResult",[]],
            _aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]],
            _aircraft getVariable ["Waldo_Cortex_AirHandoverRecovery",[]],
            _aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active",false],
            _aircraft getVariable ["Waldo_ImprovedHelicopterLanding_LastResult",[]],
            _aircraft getVariable ["Waldo_HelicopterDeceleration_Active",false],
            _aircraft getVariable ["Waldo_HelicopterDeceleration_LastResult",[]],
            ["MOVE","PATH","FSM"] apply {_handoverPilot checkAIFeature _x},
            unitReady _handoverPilot,canMove _aircraft,isEngineOn _aircraft,fuel _aircraft,damage _aircraft,
            _group getVariable ["Waldo_AIPass_Managed",false],
            _group getVariable ["Waldo_AIPass_PublicPhase",""],
            _group getVariable ["Waldo_AIPass_State",createHashMap],
            _group getVariable ["Waldo_Cortex_DrillTransitions",[]],
            units _group apply {[_x,vehicle _x,currentCommand _x,assignedVehicleRole _x]}
        ]] call _recordCheck;
        private _transitions=_group getVariable ["Waldo_Cortex_DrillTransitions",[]];
        [_id+"-explicit-interruption-transition",_transitions findIf {(_x select 2) == "AIR_ATTACK" && {(_x select 4) == "ENDED"} && {(_x select 5) == "CONTROL_RELEASED"}} >= 0,str _transitions] call _recordCheck;
        private _handoverRestored=[{(_aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]]) isEqualTo []},35] call _wait;
        [_id+"-no-old-plan-resurrection",(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo [],str (_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]])] call _recordCheck;
        [_id+"-pilot-features-restored",
            (["AUTOCOMBAT","TARGET","AUTOTARGET"] apply {_handoverPilot checkAIFeature _x}) isEqualTo _handoverFeaturesBefore
                && {unitCombatMode _handoverPilot == _handoverCombatModeBefore}
                && {combatMode _group == _handoverGroupCombatModeBefore}
                && {_handoverRestored},
            str [_handoverFeaturesBefore,["AUTOCOMBAT","TARGET","AUTOTARGET"] apply {_handoverPilot checkAIFeature _x},
                [_handoverBehaviourExpected,behaviour _handoverPilot],[_handoverCombatModeBefore,unitCombatMode _handoverPilot],
                [_handoverGroupCombatModeBefore,combatMode _group],
                _aircraft getVariable ["Waldo_Cortex_AirHandoverResult",[]],
                _aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]]]] call _recordCheck;
    } else {
        // A rejected prerequisite already failed above. Do not spend another 210 seconds watching
        // native flight and then misattribute its fire to a Cortex run that never existed.
        private _ended=if (!_started) then {false} else {
            [{(_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]]) param [0,""] in [
                "COMPLETE","TARGET_DESTROYED","TARGET_LOST","STUCK","STAGE_TIMEOUT","GROUND_CLEARANCE",
                "INGRESS_NONPROGRESS","ATTACK_NONPROGRESS","EGRESS_NONPROGRESS","NO_FIRE_SOLUTION","NO_PLAN",
                "DELIVERY_MISSED"
            ]},210] call _wait
        };
        private _outcome=_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]];
        private _profileSamples=_aircraft getVariable ["Waldo_CortexQA_ProfileSamples",[]];
        private _sampleStages=_profileSamples apply {_x select 1};
        private _sampleSpeeds=_profileSamples apply {_x select 2};
        private _sampleAltitudes=_profileSamples apply {_x select 3};
        private _samplePositions=_profileSamples apply {_x select 5};
        private _sampleFireSolutions=_profileSamples apply {_x param [6,[]]};
        if (_isPlaneClass && {_selectedWeaponClass in ["GUN","ROCKET"]}) then {
            private _terrainAwareTerminal=_sampleFireSolutions findIf {
                count _x >= 23 && {_x param [21,false]}
                    && {(_x param [20,[]]) param [0,0] >= 8}
                    && {(_x param [20,[]]) param [3,false]}
                    && {_x param [22,false]}
            } >= 0;
            [_id+"-terrain-aware-terminal-delivery",_terrainAwareTerminal,
                str (_sampleFireSolutions select {count _x >= 23})] call _recordCheck;
        };
        private _pathTravel=0;
        for "_sampleIndex" from 1 to (count _samplePositions-1) do {
            _pathTravel=_pathTravel+((_samplePositions select (_sampleIndex-1)) distance2D (_samplePositions select _sampleIndex));
        };
        private _netTravel=if (count _samplePositions >= 2) then {
            (_samplePositions select 0) distance2D (_samplePositions select (count _samplePositions-1))
        } else {0};
        private _motionFloor=[20,80] select (_aircraft isKindOf "Plane");
        private _idleStreak=0;
        private _longestIdle=0;
        {
            if (abs _x < _motionFloor) then {
                _idleStreak=_idleStreak+1;
                _longestIdle=_longestIdle max _idleStreak;
            } else {_idleStreak=0};
        } forEach _sampleSpeeds;
        private _physicalTransitions=(_group getVariable ["Waldo_Cortex_DrillTransitions",[]]) select {
            (_x select 2) == "AIR_ATTACK" && {(_x select 4) in ["INGRESS","ATTACK","EGRESS"]}
        } apply {_x select 4};
        [_id+"-physical-profile-change",count (_physicalTransitions arrayIntersect _physicalTransitions) >= 2
            && {_sampleSpeeds isNotEqualTo []} && {_sampleAltitudes isNotEqualTo []}
            && {(selectMax _sampleSpeeds)-(selectMin _sampleSpeeds) >= 5
                || {(selectMax _sampleAltitudes)-(selectMin _sampleAltitudes) >= 5}},
            str [_sampleStages,_physicalTransitions,selectMin _sampleSpeeds,selectMax _sampleSpeeds,
                selectMin _sampleAltitudes,selectMax _sampleAltitudes]] call _recordCheck;
        // Pattern metadata cannot hide the behaviour reported by a human observer. Long stationary
        // pauses and a long trail with little net displacement are the measurable signature of the
        // tiny local circles that made the previous controller look worse than native flight.
        // A moving intercept is expected to turn and may end near its start. Retain the anti-circle
        // displacement ratio for ground runs while judging an intercept by sustained physical flight.
        [_id+"-continuous-useful-flight",_sampleSpeeds isNotEqualTo [] && {_longestIdle <= 5}
            && {_airTarget || {_pathTravel < 300 || {_netTravel/_pathTravel >= 0.35}}},
            str [_longestIdle,_motionFloor,_pathTravel,_netTravel,
                if (_pathTravel > 0) then {_netTravel/_pathTravel} else {1}]] call _recordCheck;
        // A failed fixed-wing delivery is still a failed weapon case, but it must be a finite pass.
        // Once the aircraft crosses the target, production should transition to EGRESS and continue
        // away from the objective. This separate contingency check prevents a no-fire result from
        // spending the rest of its time circling the attack endpoint and obscuring the root failure.
        if (_isPlaneClass && {!_airTarget} && {count _profilePoints == 3}) then {
            private _deliveryOrigin=+(_profilePoints select 0);
            private _deliveryAxis=_plannedTargetPosition vectorDiff _deliveryOrigin;
            _deliveryAxis set [2,0];
            private _postPassPositions=[];
            if (vectorMagnitude _deliveryAxis > 1) then {
                _deliveryAxis=vectorNormalized _deliveryAxis;
                private _crossed=false;
                {
                    private _relative=_x vectorDiff _plannedTargetPosition;
                    _relative set [2,0];
                    if (!_crossed && {_relative vectorDotProduct _deliveryAxis >= 350}) then {
                        _crossed=true;
                    };
                    if (_crossed) then {_postPassPositions pushBack _x};
                } forEach _samplePositions;
            };
            private _postPassTravel=0;
            for "_postIndex" from 1 to (count _postPassPositions-1) do {
                _postPassTravel=_postPassTravel+((_postPassPositions select (_postIndex-1))
                    distance2D (_postPassPositions select _postIndex));
            };
            private _postPassNet=if (count _postPassPositions >= 2) then {
                (_postPassPositions select 0) distance2D (_postPassPositions select (count _postPassPositions-1))
            } else {0};
            private _missed=_outcome param [0,""] == "DELIVERY_MISSED";
            [_id+"-missed-pass-egresses-without-circle",!_missed || {
                    count _postPassPositions >= 2
                    && {"EGRESS" in _physicalTransitions}
                    && {_postPassTravel < 300 || {_postPassNet/_postPassTravel >= 0.5}}
                },
                str [_outcome,count _postPassPositions,_postPassTravel,_postPassNet,
                    if (_postPassTravel > 0) then {_postPassNet/_postPassTravel} else {1},
                    _physicalTransitions]] call _recordCheck;
        };
        [_id+"-safe-flight-envelope",_sampleAltitudes isNotEqualTo []
            && {selectMin _sampleAltitudes >= ([25,200] select _isPlaneClass)},
            str [selectMin _sampleAltitudes,selectMax _sampleAltitudes,_sampleStages]] call _recordCheck;
        [_id+"-finite-completion",_ended && {_outcome param [0,""] in ["COMPLETE","TARGET_DESTROYED"]},str _outcome] call _recordCheck;
        // Rockets and high releases can remain live well after the finite controller starts egress.
        // Keep the damageable target until every bounded closest-approach sampler has completed;
        // deleting it after four seconds previously turned visible rocket misses into empty evidence.
        private _releaseWait=[4,20] select (_selectedWeaponClass in ["ROCKET","BOMB","GUIDED"]);
        [{
            !alive _plannedTargetObject || {
                count (_aircraft getVariable ["Waldo_CortexQA_ReleaseResults",[]])
                    >= (_aircraft getVariable ["Waldo_CortexQA_ReleaseSamplesStarted",0])
            }
        },_releaseWait] call _wait;
        private _releaseResults=_aircraft getVariable ["Waldo_CortexQA_ReleaseResults",[]];
        private _weaponHits=_plannedTargetObject getVariable ["Waldo_CortexQA_WeaponHits",0];
        private _attackStageShots=_aircraft getVariable ["Waldo_CortexQA_AttackStageShots",[]];
        // The real Fired event can arrive between the production stage transition and the public
        // diagnostic snapshot. Require an actual non-countermeasure release from this aircraft;
        // impact and destruction are asserted independently below, so accepting that event does
        // not turn an ingress miss into a passing attack.
        [_id+"-actual-weapon-fire",(_aircraft getVariable ["Waldo_CortexQA_AdaptiveShots",0]) > 0,
            str [_aircraft getVariable ["Waldo_CortexQA_AdaptiveShots",0],_attackStageShots,_releaseResults,
                _aircraft getVariable ["Waldo_CortexQA_ReleaseSamplesStarted",0]]] call _recordCheck;
        private _impactDistance=switch _selectedWeaponClass do {
            case "GUN": {8};
            case "GUIDED": {18};
            default {30};
        };
        private _physicalImpact=damage _plannedTargetObject > 0 || {!alive _plannedTargetObject}
            || {_releaseResults findIf {(_x param [4,1e9]) <= _impactDistance} >= 0};
        [_id+"-effective-release",_physicalImpact,
            str [_weaponHits,damage _plannedTargetObject,_impactDistance,_releaseResults,
                _aircraft getVariable ["Waldo_CortexQA_ReleaseSamplesStarted",0],
                _aircraft getVariable ["Waldo_Cortex_AirFireSolution",[]]]] call _recordCheck;
        [_id+"-target-destroyed",!_mustDestroy || {!alive _plannedTargetObject},
            str [_mustDestroy,alive _plannedTargetObject,damage _plannedTargetObject,
                getAllHitPointsDamage _plannedTargetObject,typeOf _plannedTargetObject,
                _weaponHits,_releaseResults]] call _recordCheck;
        [_id+"-visible-countermeasures",_aircraft getVariable ["Waldo_CortexQA_AdaptiveFlares",0] >= 2,
            str [_aircraft getVariable ["Waldo_CortexQA_AdaptiveFlares",0],_aircraft getVariable ["Waldo_Cortex_CountermeasureLastRequest",[]]]] call _recordCheck;
        private _transitions=_group getVariable ["Waldo_Cortex_DrillTransitions",[]];
        private _stages=_transitions select {(_x select 2) == "AIR_ATTACK"} apply {_x select 4};
        [_id+"-explicit-state-flow",["INGRESS","ATTACK","EGRESS","ENDED"] findIf {!(_x in _stages)} < 0,str _transitions] call _recordCheck;
        [_id+"-safe-crew-egress",alive _aircraft && {(getPosATL _aircraft select 2) >= 25}
            && {_crew findIf {!alive _x || {vehicle _x != _aircraft}} < 0},str [getPosATL _aircraft,_crew apply {vehicle _x == _aircraft}]] call _recordCheck;
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    {deleteVehicle _x} forEach (_crew+_targetCrew+_aaCrew+[_aircraft,_target,_aa]);
    deleteGroup _group; deleteGroup _targetGroup; if (!isNull _aaGroup) then {deleteGroup _aaGroup};
} forEach [
    // The quadbike died during ingress and the MRAP survived a geometrically effective 20 mm pass.
    // A full-size soft truck survives incidental acquisition fire but remains a credible one-pass
    // destruction target for the retained lateral turret.
    ["AIR-ATTACK-HELI-LATERAL","B_Heli_Attack_01_dynamicLoadout_F",false,false,"LATERAL",false,"GUN",true,"O_Truck_03_transport_F"],
    ["AIR-ATTACK-PLANE-STRAFE","O_Plane_CAS_02_dynamicLoadout_F",false,false,"STRAFE",false,"GUN",true,"B_MRAP_01_F"],
    ["AIR-ATTACK-PLANE-OFFSET","O_Plane_CAS_02_dynamicLoadout_F",false,false,"OFFSET",false,"ROCKET",true,"B_MRAP_01_F"],
    ["AIR-ATTACK-PLANE-HOOK","O_Plane_CAS_02_dynamicLoadout_F",false,false,"HOOK",false,"ROCKET",true,"B_MRAP_01_F"],
    ["AIR-ATTACK-PLANE-BOMB","O_Plane_CAS_02_dynamicLoadout_F",false,false,"BOMB",false,"BOMB",true,"B_APC_Tracked_01_rcws_F"],
    ["AIR-ATTACK-PLANE-GUIDED","O_Plane_CAS_02_dynamicLoadout_F",false,false,"STANDOFF",false,"GUIDED",true,"B_APC_Tracked_01_rcws_F"],
    ["AIR-ATTACK-PLANE-AA","O_Plane_CAS_02_dynamicLoadout_F",true,false,"AUTO",false,"GUIDED",true,"B_APC_Tracked_01_rcws_F"],
    ["AIR-ATTACK-PLANE-INTERCEPT","O_Plane_CAS_02_dynamicLoadout_F",false,false,"AUTO",true,"GUIDED",true],
    ["AIR-ATTACK-ZEUS-HANDOVER","O_Heli_Attack_02_dynamicLoadout_F",false,true,"AUTO",false,"",false]
];
private _strafeProfile=_observedProfiles getOrDefault ["STRAFE",[]];
private _offsetProfile=_observedProfiles getOrDefault ["OFFSET",[]];
private _hookProfile=_observedProfiles getOrDefault ["HOOK",[]];
["AIR-ATTACK-distinct-fixed-wing-profiles",
    _strafeProfile isNotEqualTo [] && {_offsetProfile isNotEqualTo []} && {_hookProfile isNotEqualTo []}
        && {(_strafeProfile select 0) isNotEqualTo (_offsetProfile select 0)}
        && {(_offsetProfile select 0) isNotEqualTo (_hookProfile select 0)}
        && {(_strafeProfile select 1) isNotEqualTo (_offsetProfile select 1)}
        && {(_offsetProfile select 2) isNotEqualTo (_hookProfile select 2)},
    str _observedProfiles] call _recordCheck;

// The adaptive controller's disabled boundary must preserve an ordinary authored flight. This is a
// physical comparison rather than an absence-only assertion: the aircraft must keep moving while no
// Cortex plan or AIR_ATTACK transition appears.
[createHashMapFromArray [
    ["Waldo_Cortex_AirAttack_Enable",false],["Waldo_Cortex_AttackRunFlares_Enable",false],
    ["Waldo_AIPass_AircraftFlares_Enable",false],["Waldo_AIPass_AircraftBreak_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _disabledAircraft=createVehicle ["O_Heli_Attack_02_dynamicLoadout_F",[9800,5000,140],[],0,"FLY"];
_disabledAircraft setDir 0; createVehicleCrew _disabledAircraft; _disabledAircraft allowDamage false;
private _disabledCrew=crew _disabledAircraft;
private _disabledGroup=group driver _disabledAircraft;
_disabledGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_disabledGroup setVariable ["acex_headless_blacklist",true,true];
{_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach _disabledCrew;
_disabledAircraft setVelocityModelSpace [0,55,0];
_disabledAircraft flyInHeight 140;
private _disabledTarget=createVehicle ["B_APC_Tracked_01_rcws_F",[9800,6200,0],[],0,"NONE"];
createVehicleCrew _disabledTarget; _disabledTarget allowDamage false;
private _disabledTargetCrew=crew _disabledTarget;
private _disabledTargetGroup=group driver _disabledTarget;
_disabledTargetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
{_x allowDamage false; _x disableAI "PATH"} forEach _disabledTargetCrew;
_disabledGroup setCombatMode "RED";
{_x doTarget _disabledTarget} forEach _disabledCrew;
private _disabledDestination=[9800,7200,140];
private _disabledWaypoint=_disabledGroup addWaypoint [_disabledDestination,0];
_disabledWaypoint setWaypointType "MOVE"; _disabledWaypoint setWaypointBehaviour "COMBAT";
_disabledAircraft setVariable ["Waldo_CortexQA_Label","AIR-ATTACK-DISABLED",true];
_disabledTarget setVariable ["Waldo_CortexQA_Label","DISABLED-BOUNDARY TARGET",true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_disabledAircraft,_disabledTarget],true];
["AIR-ATTACK-DISABLED","Adaptive attacks are disabled. The helicopter must continue its authored physical flight toward the live target without creating an AIR_ATTACK lease or transition.",getPosATL _disabledAircraft] call _phase;
private _disabledOrigin=getPosATL _disabledAircraft;
private _disabledTravel=[{alive _disabledAircraft && {_disabledAircraft distance2D _disabledOrigin >= 180}},45] call _wait;
private _disabledTransitions=_disabledGroup getVariable ["Waldo_Cortex_DrillTransitions",[]];
["AIR-ATTACK-DISABLED-authored-flight",_disabledTravel,
    str [_disabledAircraft distance2D _disabledOrigin,_disabledAircraft distance2D _disabledDestination]] call _recordCheck;
["AIR-ATTACK-DISABLED-no-controller",(_disabledAircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo []
    && {_disabledTransitions findIf {(_x select 2) == "AIR_ATTACK"} < 0},str _disabledTransitions] call _recordCheck;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_disabledCrew+_disabledTargetCrew+[_disabledAircraft,_disabledTarget]);
deleteGroup _disabledGroup; deleteGroup _disabledTargetGroup;
