/*
 * Author: WaldoTheWarfighter
 * Exercises aircraft missile defence, surface attack patterns and airborne interception using live
 * aircraft, moving targets, weapon fire, countermeasure events and physical flight.
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
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_AircraftFlares_Enable",_enabled],["Waldo_AIPass_AircraftBreak_Enable",_enabled]]] call Waldo_fnc_CortexTuning;
private _aircraft=createVehicle ["O_Heli_Light_02_unarmed_F",[4500,4500,100],[],0,"FLY"];
_aircraft setDir 0; createVehicleCrew _aircraft; _aircraft allowDamage false;
private _aircrew=crew _aircraft;
private _airgroup=group driver _aircraft;
_airgroup setCombatMode "BLUE";
// Deliberately leave this ordinary aircraft without Gunship/Dynamic-AA provenance. The global
// setting must install defensive reactions on eligible AI aircraft directly.
_aircraft flyInHeight 100;
private _launcher=createVehicle ["B_static_AA_F",[4500,4100,0],[],0,"NONE"];
_launcher setDir 0; createVehicleCrew _launcher;
private _shooters=crew _launcher;
private _shootgroup=group gunner _launcher;
_shootgroup setCombatMode "BLUE";
_shootgroup setVariable ["Waldo_AIPass_Exclude",true,true];
{
    _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _x setVariable ["acex_headless_blacklist",true,true];
    {_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach units _x;
} forEach [_airgroup,_shootgroup];
_aircraft setVariable ["Waldo_CortexQA_Label",_prefix+"HELICOPTER",true];
_launcher setVariable ["Waldo_CortexQA_Label","REAL AA MISSILE LAUNCHER",true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_aircraft,_launcher],true];
_aircraft setVariable ["Waldo_CortexQA_AALauncher",_launcher,true];
_aircraft setVariable ["Waldo_CortexQA_MissileWarnings",[],true];
_aircraft setVariable ["Waldo_CortexQA_Flares",0,true];
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
    params ["_aircraft"];
    private _events=_aircraft getVariable ["Waldo_CortexQA_MissileWarnings",[]];
    private _sample=[serverTime,getPosATL _aircraft,velocity _aircraft];
    _events pushBack _sample;
    _aircraft setVariable ["Waldo_CortexQA_MissileWarnings",_events,true];
    [_aircraft,_sample] spawn {
        params ["_aircraft","_sample"];
        private _departure=0;
        for "_i" from 1 to 20 do {
            sleep 0.1;
            if (isNull _aircraft) exitWith {};
            private _expected=(_sample select 1) vectorAdd ((_sample select 2) vectorMultiply (serverTime-(_sample select 0)));
            _departure=_departure max (_aircraft distance2D _expected);
        };
        if (!isNull _aircraft) then {_aircraft setVariable ["Waldo_CortexQA_EvasiveDeparture",_departure,true]};
    };
}];
[_prefix+"missile acquisition","The AA launcher faces the helicopter. It must acquire and fire a real missile. Watch the helicopter trail and actual countermeasures. A warning handler or accepted fire order alone is insufficient.",[4500,4400,80]] call _phase;
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
["AIR-natural-launcher-detection",_detected] call _check;
_shootgroup setCombatMode "RED";
(gunner _launcher) doTarget _aircraft; (gunner _launcher) doFire _aircraft;
private _fired=[{_launcher getVariable ["Waldo_CortexQA_Missiles",0] > 0},60] call _wait;
["AIR-real-missile-fired",_fired] call _check;
private _warning=[{count (_aircraft getVariable ["Waldo_CortexQA_MissileWarnings",[]]) > 0},15] call _wait;
["AIR-real-missile-warning",_fired && {_warning}] call _check;
private _flared=[{_aircraft getVariable ["Waldo_CortexQA_Flares",0] > 0},10] call _wait;
if (_enabled) then {
    ["AIR-actual-countermeasure-release",_fired && {_warning} && {_flared},str (_aircraft getVariable ["Waldo_CortexQA_Flares",0])] call _check;
};
// The event-time sampler observes only the first two seconds, not later ordinary flight drift.
private _sampled=[{!isNil {_aircraft getVariable "Waldo_CortexQA_EvasiveDeparture"}},5] call _wait;
private _departure=_aircraft getVariable ["Waldo_CortexQA_EvasiveDeparture",0];
if (_enabled) then {
    ["AIR-physical-evasive-departure",_warning && {_sampled} && {_departure >= 5},str _departure] call _check;
};
_results pushBack [_fired && {_warning} && {_sampled},_departure,_aircraft getVariable ["Waldo_CortexQA_Flares",0]];
diag_log format ["WMP CORTEX QA AIR SAMPLE: mode=%1 departure=%2 countermeasures=%3",_prefix,_departure,_aircraft getVariable ["Waldo_CortexQA_Flares",0]];
["AIR-retains-operating-crew",_aircrew findIf {!alive _x || {vehicle _x != _aircraft}} < 0] call _check;
["AIR-clear-of-ground",alive _aircraft && {getPosATL _aircraft select 2 > 30}] call _check;
_shootgroup setCombatMode "BLUE";
{_x setUnitCombatMode "BLUE"; _x doTarget objNull} forEach _shooters;
private _flightOrigin=getPosATL _aircraft;
private _flightTarget=_flightOrigin vectorAdd [400,0,0];
[_prefix+"flight after defence","After the missile response, the helicopter receives a normal flight waypoint. It must travel at least 100 m toward it with its operating crew still aboard. A defensive flag alone cannot pass.",_flightTarget] call _phase;
private _flightWaypoint=_airgroup addWaypoint [_flightTarget,0];
_flightWaypoint setWaypointType "MOVE";
_flightWaypoint setWaypointBehaviour "AWARE";
private _continued=[{
    alive _aircraft && {_aircraft distance2D _flightOrigin >= 100}
        && {_aircraft distance2D _flightTarget <= 300}
        && {_aircrew findIf {!alive _x || {vehicle _x != _aircraft}} < 0}
},75] call _wait;
["AIR-post-defence-normal-flight",_continued,format ["travel=%1 remaining=%2",_aircraft distance2D _flightOrigin,_aircraft distance2D _flightTarget]] call _check;
sleep 8;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_aircrew+_shooters+[_aircraft,_launcher]);
deleteGroup _airgroup; deleteGroup _shootgroup;

} forEach [false,true];
private _native=_results select 0;
private _cortex=_results select 1;
["AIR-paired-real-threats",(_native select 0) && {_cortex select 0},str _results] call _recordCheck;
["AIR-break-exceeds-native-response",(_native select 0) && {_cortex select 0} && {(_cortex select 1) >= (_native select 1)+5},str _results] call _recordCheck;


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
        _plane flyInHeight 150;
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
    _x params ["_id","_class","_withAA","_interrupt",["_patternOverride","AUTO"]];
    private _airTarget=_x param [5,false];
    [createHashMapFromArray [
        ["Waldo_Cortex_AirAttack_Enable",true],["Waldo_Cortex_AttackRunFlares_Enable",true],
        ["Waldo_AIPass_AircraftFlares_Enable",false],["Waldo_AIPass_AircraftBreak_Enable",false]
    ]] call Waldo_fnc_CortexTuning;
    private _aircraft=createVehicle [_class,[8200,5000,260],[],0,"FLY"];
    _aircraft setDir 0; createVehicleCrew _aircraft; _aircraft allowDamage false;
    _aircraft setVariable ["Waldo_Cortex_AirAttackPattern",_patternOverride,true];
    private _crew=crew _aircraft;
    private _group=group driver _aircraft;
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    {_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach _crew;
    private _launchSpeed=[55,105] select (_aircraft isKindOf "Plane");
    _aircraft setVelocityModelSpace [0,_launchSpeed,0];
    _aircraft flyInHeight ([120,260] select (_aircraft isKindOf "Plane"));
    private _targetClass=["B_APC_Tracked_01_rcws_F","B_Plane_CAS_01_dynamicLoadout_F"] select _airTarget;
    private _targetPosition=[[8200,6500,0],[8500,6400,320]] select _airTarget;
    private _target=createVehicle [_targetClass,_targetPosition,[],0,["NONE","FLY"] select _airTarget];
    createVehicleCrew _target; _target allowDamage false;
    private _targetCrew=crew _target;
    private _targetGroup=group driver _target;
    _targetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    {_x allowDamage false; if (!_airTarget) then {_x disableAI "PATH"}} forEach _targetCrew;
    if (_airTarget) then {
        _target setDir 180;
        _target setVelocityModelSpace [0,110,0];
        _target flyInHeight 320;
        _targetGroup setCombatMode "BLUE";
        private _targetWaypoint=_targetGroup addWaypoint [[7600,4200,320],0];
        _targetWaypoint setWaypointType "MOVE";
        _targetWaypoint setWaypointBehaviour "AWARE";
        _targetWaypoint setWaypointSpeed "FULL";
    };
    private _aa=objNull;
    private _aaCrew=[];
    private _aaGroup=grpNull;
    if (_withAA) then {
        _aa=createVehicle ["B_static_AA_F",[8750,6350,0],[],0,"NONE"];
        createVehicleCrew _aa; _aa allowDamage false;
        _aaCrew=crew _aa; _aaGroup=group gunner _aa;
        _aaGroup setVariable ["Waldo_AIPass_Exclude",true,true];
        {_x allowDamage false; _x disableAI "PATH"} forEach _aaCrew;
        // The case is explicitly observed-AA planning, so known threat is its declared stimulus.
        _group reveal [_aa,4];
        _aa setVariable ["Waldo_CortexQA_Label","OBSERVED AA THREAT",true];
    };
    _group setCombatMode "RED";
    {_x doTarget _target} forEach _crew;
    private _authoredDestination=[8200,7900,260];
    private _waypoint=_group addWaypoint [_authoredDestination,0];
    _waypoint setWaypointType "MOVE"; _waypoint setWaypointBehaviour "COMBAT";
    _aircraft setVariable ["Waldo_CortexQA_Label",_id,true];
    _target setVariable ["Waldo_CortexQA_Label",["LIVE ARMOURED ATTACK TARGET","LIVE AIR INTERCEPT TARGET"] select _airTarget,true];
    _aircraft setVariable ["Waldo_CortexQA_AdaptiveShots",0,true];
    _aircraft setVariable ["Waldo_CortexQA_AdaptiveFlares",0,true];
    _aircraft addEventHandler ["Fired",{
        params ["_aircraft","_weapon"];
        if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") == "cmlauncher") then {
            _aircraft setVariable ["Waldo_CortexQA_AdaptiveFlares",(_aircraft getVariable ["Waldo_CortexQA_AdaptiveFlares",0])+1,true];
        } else {
            _aircraft setVariable ["Waldo_CortexQA_AdaptiveShots",(_aircraft getVariable ["Waldo_CortexQA_AdaptiveShots",0])+1,true];
        };
    }];
    private _actors=[_aircraft,_target]; if (!isNull _aa) then {_actors pushBack _aa};
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors,true];
    [_id,"Watch the aircraft physically fly its labelled pattern, fire real weapons and exit safely. The cyan leg and red target line are live geometry; an assigned target or elapsed timer cannot pass.",getPosATL _aircraft] call _phase;
    private _origin=getPosATL _aircraft;
    private _started=[{(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []},35] call _wait;
    [_id+"-physical-plan-start",_started,str (_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]])] call _recordCheck;
    _aircraft setVariable ["Waldo_CortexQA_ProfileSamples",[],true];
    [_aircraft] spawn {
        params ["_sampleAircraft"];
        while {alive _sampleAircraft && {(_sampleAircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []}} do {
            private _planSample=_sampleAircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
            private _samples=_sampleAircraft getVariable ["Waldo_CortexQA_ProfileSamples",[]];
            _samples pushBack [
                serverTime,_planSample param [2,""],speed _sampleAircraft,
                (getPosATL _sampleAircraft) select 2,_planSample param [4,[]]
            ];
            _sampleAircraft setVariable ["Waldo_CortexQA_ProfileSamples",_samples,true];
            sleep 1;
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
    private _pattern=_initialPlan param [1,""];
    private _profileAltitudes=_initialPlan param [17,[]];
    private _profileSpeeds=_initialPlan param [18,[]];
    private _profileRadii=_initialPlan param [19,[]];
    private _profileDwell=_initialPlan param [20,0];
    private _profilePoints=_initialPlan param [21,[]];
    if (_pattern != "") then {_observedProfiles set [_pattern,[_profilePoints,_profileAltitudes,_profileSpeeds]]};
    [_id+"-pattern-specific-flight-profile",count _profileAltitudes == 3
        && {count _profileSpeeds == 3} && {count _profileRadii == 3}
        && {_profileDwell >= 2}
        && {count (_profileAltitudes arrayIntersect _profileAltitudes) > 1
            || {count (_profileSpeeds arrayIntersect _profileSpeeds) > 1}},
        str [_pattern,_profileAltitudes,_profileSpeeds,_profileRadii,_profileDwell,_profilePoints]] call _recordCheck;
    if (_airTarget) then {
        [_id+"-air-contact-intercept-plan",_pattern == "INTERCEPT"
            && {_initialPlan param [3,objNull] == _target}
            && {speed _target >= 40},str [_initialPlan,speed _target,getPosATL _target]] call _recordCheck;
    };
    if (_withAA) then {
        [_id+"-aa-aware-pattern",_pattern in ["OFFSET","STANDOFF"] && {(_initialPlan param [7,0]) > 0},str _initialPlan] call _recordCheck;
    } else {
        if (!_interrupt && {!_airTarget}) then {
        [_id+"-low-threat-pattern",_pattern in ["STRAFE","OFFSET","HOOK","LATERAL"],str _initialPlan] call _recordCheck;
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
        private _released=[{(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo []},10] call _wait;
        private _handoverGuard=_aircraft getVariable ["Waldo_Cortex_AirHandoverLease",[]];
        private _handoverResult=_aircraft getVariable ["Waldo_Cortex_AirHandoverResult",[]];
        // currentCommand and the first expectedDestination sample can remain ATTACK/the retired
        // internal leg while an aircraft replans. The unchanged 90-second physical gate below is
        // authoritative; this assertion verifies only that the bounded, interruptible guard exists.
        private _handoverGuardValid=count _handoverGuard == 2
            && {!(_handoverPilot checkAIFeature "AUTOTARGET")}
            && {(_aircraft getVariable ["Waldo_Cortex_AirHandoverRecovery",[]]) isEqualTo []}
            && {_handoverResult param [5,""] == "ZEUS_TRANSIT_GUARD"};
        private _travelled=[{_aircraft distance2D _replacement <= 350},90] call _wait;
        [_id+"-zeus-plan-retired",_released,str (_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]])] call _recordCheck;
        [_id+"-bounded-zeus-transit-guard",_released && {_handoverGuardValid},str [
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
        private _ended=[{(_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]]) param [0,""] in ["COMPLETE","TARGET_LOST","STUCK","STAGE_TIMEOUT","GROUND_CLEARANCE"]},210] call _wait;
        private _outcome=_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]];
        private _profileSamples=_aircraft getVariable ["Waldo_CortexQA_ProfileSamples",[]];
        private _sampleStages=_profileSamples apply {_x select 1};
        private _sampleSpeeds=_profileSamples apply {_x select 2};
        private _sampleAltitudes=_profileSamples apply {_x select 3};
        [_id+"-physical-profile-change",count (_sampleStages arrayIntersect _sampleStages) >= 2
            && {_sampleSpeeds isNotEqualTo []} && {_sampleAltitudes isNotEqualTo []}
            && {(selectMax _sampleSpeeds)-(selectMin _sampleSpeeds) >= 5
                || {(selectMax _sampleAltitudes)-(selectMin _sampleAltitudes) >= 5}},
            str [_sampleStages,selectMin _sampleSpeeds,selectMax _sampleSpeeds,
                selectMin _sampleAltitudes,selectMax _sampleAltitudes]] call _recordCheck;
        [_id+"-finite-completion",_ended && {_outcome param [0,""] == "COMPLETE"},str _outcome] call _recordCheck;
        [_id+"-actual-weapon-fire",_aircraft getVariable ["Waldo_CortexQA_AdaptiveShots",0] > 0,str (_aircraft getVariable ["Waldo_CortexQA_AdaptiveShots",0])] call _recordCheck;
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
    ["AIR-ATTACK-HELI-LATERAL","O_Heli_Attack_02_dynamicLoadout_F",false,false,"LATERAL"],
    ["AIR-ATTACK-PLANE-STRAFE","O_Plane_CAS_02_dynamicLoadout_F",false,false,"STRAFE"],
    ["AIR-ATTACK-PLANE-OFFSET","O_Plane_CAS_02_dynamicLoadout_F",false,false,"OFFSET"],
    ["AIR-ATTACK-PLANE-HOOK","O_Plane_CAS_02_dynamicLoadout_F",false,false,"HOOK"],
    ["AIR-ATTACK-PLANE-AA","O_Plane_CAS_02_dynamicLoadout_F",true,false,"AUTO"],
    ["AIR-ATTACK-PLANE-INTERCEPT","O_Plane_CAS_02_dynamicLoadout_F",false,false,"AUTO",true],
    ["AIR-ATTACK-ZEUS-HANDOVER","O_Heli_Attack_02_dynamicLoadout_F",false,true,"AUTO"]
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
