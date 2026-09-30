/*
 * Author: WaldoTheWarfighter
 * Exercises aircraft missile defence using a live AA launcher and real projectile events.
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
_aircraft setVariable ["Waldo_Gunship_Id","CORTEX_QA_DEFENSIVE_FIXTURE",true];
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
            ["Waldo_AIPass_AircraftFlares_Enable",false],["Waldo_AIPass_AircraftBreak_Enable",false]]] call Waldo_fnc_CortexTuning;
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
        private _target=createVehicle ["B_Truck_01_transport_F",[6500,6700,0],[],0,"NONE"];
        createVehicleCrew _target;
        _target allowDamage false;
        private _targetCrew=crew _target;
        private _targetGroup=group driver _target;
        _targetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
        {_x allowDamage false; _x disableAI "PATH"} forEach _targetCrew;
        _group setCombatMode "RED";
        (driver _plane) doTarget _target;
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
        private _passed=[{(_plane distance2D _origin > 1500) || {!alive _plane}},180] call _wait;
        private _events=_plane getVariable ["Waldo_CortexQA_AttackFlares",[]];
        [_id+"-physical-flight",alive _plane && {_plane distance2D _origin > 500},str (_plane distance2D _origin)] call _recordCheck;
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
