/*
 * Author: WaldoTheWarfighter
 * Finds a genuinely uneven, dry audit sector and exercises the shared Cortex avenue selector with
 * infantry, vehicle, defensive movement and live armed aircraft attacks. The air arm selects a
 * long dry corridor with measured relief, then requires a plane and helicopter to fly, release a
 * real compatible weapon, damage the target and leave the run clear of terrain. This is a terrain
 * prerequisite and cross-cutting physical diagnostic; it does not turn a route calculation or
 * accepted order into a feature pass.
 * Locality/authority: scheduled dedicated-server QA. Fresh groups and vehicles remain server-owned.
 * Repeat/JIP: each invocation creates and cleans fresh fixtures; public labels, targets and trails
 * are transient audit presentation state and are not replayed as production state.
 * Arguments: 0 check <CODE>; 1 phase <CODE>; 2 wait <CODE>. All callbacks are required.
 * Return Value: Nothing.
 * Current callers: cortexQAServer.sqf when Waldo_CortexQA_Focus is "terrain".
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQATerrain.sqf";
 */
params ["_check","_phase","_wait"];

private _auditTerrain=missionNamespace getVariable ["Waldo_CortexQA_AuditTerrain",worldName];
private _realWorld=toLower worldName != "vr" && {toLower _auditTerrain != "vr"};
["TERRAIN-real-world",_realWorld,format ["configured=%1 world=%2",_auditTerrain,worldName]] call _check;
if (!_realWorld) exitWith {
    ["Terrain prerequisite unavailable","Run this focused batch with -AuditTerrain Altis. A flat VR run cannot establish hill, incline or rough-ground behaviour.",[worldSize/2,worldSize/2,0]] call _phase;
    ["TERRAIN-meaningful-relief",false,"VR is deliberately rejected for terrain acceptance"] call _check;
};

private _best=[];
private _bestScore=-1;
private _spacing=(worldSize/10) max 900;
for "_gx" from 2 to 8 do {
    for "_gy" from 2 to 8 do {
        private _centre=[_gx*_spacing,_gy*_spacing,0];
        private _samples=[_centre];
        { _samples pushBack (_centre getPos [90,_x]); } forEach [0,45,90,135,180,225,270,315];
        if (_samples findIf {surfaceIsWater _x || {((surfaceNormal _x) select 2) < 0.72}} < 0) then {
            private _heights=_samples apply {getTerrainHeightASL _x};
            private _relief=(selectMax _heights)-(selectMin _heights);
            private _roughness=1-(selectMin (_samples apply {(surfaceNormal _x) select 2}));
            private _score=_relief+(_roughness*70);
            if (_relief >= 7 && {_roughness >= 0.025} && {_score > _bestScore}) then {
                _best=[_centre,_relief,_roughness,_samples];
                _bestScore=_score;
            };
        };
    };
};

private _found=_best isNotEqualTo [];
["TERRAIN-meaningful-relief",_found,if (_found) then {format ["centre=%1 relief=%2 roughness=%3",_best select 0,_best select 1,_best select 2]} else {"No dry 180 m sector met 7 m relief and roughness prerequisites"}] call _check;
if (!_found) exitWith {
    ["No evaluative terrain sector","This world or sampled area did not provide a dry, passable sector with enough relief. Movement results from this run must not be interpreted as terrain acceptance.",[worldSize/2,worldSize/2,0]] call _phase;
};

private _centre=_best select 0;
private _threat=_centre getPos [210,0];
private _start=_centre getPos [210,180];
private _left=_centre getPos [105,255];
private _right=_centre getPos [105,105];
private _candidates=[[_centre],[_left,_centre],[_right,_centre]];
private _infantryRoute=[_start,_candidates,_threat,[],objNull,"INFANTRY"] call Waldo_fnc_CortexSelectAvenue;
private _vehicleRoute=[_start,_candidates,_threat,[],objNull,"VEHICLE"] call Waldo_fnc_CortexSelectAvenue;
["TERRAIN-infantry-avenue",_infantryRoute isNotEqualTo [],str _infantryRoute] call _check;
["TERRAIN-vehicle-avenue",_vehicleRoute isNotEqualTo [],str _vehicleRoute] call _check;

private _routeUsable={
    params ["_origin","_route",["_minimumUp",0.5]];
    if (_route isEqualTo []) exitWith {false};
    private _usable=true;
    private _from=_origin;
    {
        private _to=_x;
        private _samples=((ceil ((_from distance2D _to)/20)) max 3) min 12;
        for "_index" from 1 to _samples do {
            private _fraction=_index/_samples;
            private _point=[
                (_from select 0)+((_to select 0)-(_from select 0))*_fraction,
                (_from select 1)+((_to select 1)-(_from select 1))*_fraction,
                0
            ];
            if (surfaceIsWater _point || {((surfaceNormal _point) select 2) < _minimumUp}) exitWith {_usable=false};
        };
        if (!_usable) exitWith {};
        _from=_to;
    } forEach _route;
    _usable
};
["TERRAIN-infantry-route-usable",[_start,_infantryRoute,0.5] call _routeUsable] call _check;
["TERRAIN-vehicle-route-usable",[_start,_vehicleRoute,0.68] call _routeUsable] call _check;

private _infantryGroup=createGroup [east,true];
_infantryGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
private _infantry=[];
for "_index" from 0 to 5 do {
    private _unit=_infantryGroup createUnit ["O_Soldier_F",_start getPos [3+_index,180],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["TERRAIN INF %1",_index+1],true];
    _infantry pushBack _unit;
};
private _infantryOrigin=getPosATL leader _infantryGroup;
{
    private _waypoint=_infantryGroup addWaypoint [_x,0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointBehaviour "AWARE";
    _waypoint setWaypointCompletionRadius 8;
} forEach _infantryRoute;

private _vehicle=createVehicle ["O_MRAP_02_F",_start getPos [12,210],[],0,"NONE"];
createVehicleCrew _vehicle;
private _vehicleGroup=group driver _vehicle;
(driver _vehicle) disableAI "PATH";
_vehicleGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
{_x setVariable ["acex_headless_blacklist",true,true]} forEach crew _vehicle;
private _vehicleOrigin=getPosATL _vehicle;
{
    private _waypoint=_vehicleGroup addWaypoint [_x,0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointBehaviour "SAFE";
    _waypoint setWaypointCompletionRadius 12;
} forEach _vehicleRoute;

missionNamespace setVariable ["Waldo_CortexQA_Actors",_infantry+(crew _vehicle),true];
{_x setVariable ["Waldo_CortexQA_Target",_centre,true]} forEach _infantry;
_vehicle setVariable ["Waldo_CortexQA_Label","TERRAIN VEHICLE",true];
_vehicle setVariable ["Waldo_CortexQA_Target",_centre,true];
["Uneven-ground route traversal","The infantry and wheeled vehicle must physically traverse the measured uneven sector. Cyan trails show actual travel; a selected avenue or waypoint alone cannot pass.",_centre] call _phase;
private _infantryMoved=[{alive leader _infantryGroup && {leader _infantryGroup distance2D _infantryOrigin >= 100}},100] call _wait;
(driver _vehicle) enableAI "PATH";
private _vehicleMoved=[{alive _vehicle && {canMove _vehicle} && {_vehicle distance2D _vehicleOrigin >= 90}},100] call _wait;
["TERRAIN-infantry-physical-progress",_infantryMoved,format ["travel=%1",leader _infantryGroup distance2D _infantryOrigin]] call _check;
["TERRAIN-vehicle-physical-progress",_vehicleMoved,format ["travel=%1 speed=%2",_vehicle distance2D _vehicleOrigin,speed _vehicle]] call _check;

private _defenceGroup=createGroup [east,true];
_defenceGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
private _defenders=[];
for "_index" from 0 to 5 do {
    private _unit=_defenceGroup createUnit ["O_Soldier_F",_centre getPos [55+_index*2,180],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["TERRAIN DEF %1",_index+1],true];
    _defenders pushBack _unit;
};
["TERRAIN-defence-accepted",[_defenceGroup,_centre,0,70] call Waldo_fnc_CortexDefend] call _check;
private _defenceArrived=[{
    _defenders findIf {
        private _slot=_x getVariable ["Waldo_AIPass_DefendPos",[]];
        !alive _x || {_slot isEqualTo []} || {_x distance2D (_slot select 0) > 4}
    } < 0
},100] call _wait;
["TERRAIN-defence-physical-arrival",_defenceArrived,str (_defenders apply {getPosATL _x})] call _check;
private _slots=_defenders apply {private _slot=_x getVariable ["Waldo_AIPass_DefendPos",[]]; if (_slot isEqualTo []) then {[0,0,0]} else {_slot select 0}};
["TERRAIN-defence-slots-dry-passable",_slots findIf {surfaceIsWater _x || {((surfaceNormal _x) select 2) < 0.5}} < 0,str _slots] call _check;

[_defenceGroup] call Waldo_fnc_CortexDefendRelease;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_infantry+_defenders+(crew _vehicle));
deleteVehicle _vehicle;
{deleteGroup _x} forEach [_infantryGroup,_vehicleGroup,_defenceGroup];

// Find one long inland air corridor instead of transplanting the flat VR coordinates. Its relief is
// measured along both the approach and departure, because a clear target area does not prove that a
// persistent aircraft can join, deliver and egress over the intervening hills.
private _airLane=[];
private _airLaneScore=-1;
private _airGrid=worldSize/10;
for "_airGridX" from 3 to 7 do {
    for "_airGridY" from 3 to 7 do {
        private _candidateTarget=[_airGridX*_airGrid,_airGridY*_airGrid,0];
        if (!surfaceIsWater _candidateTarget && {((surfaceNormal _candidateTarget) select 2) >= 0.72}) then {
            {
                private _bearing=_x;
                private _laneStart=_candidateTarget getPos [6500,_bearing+180];
                private _laneEnd=_candidateTarget getPos [4500,_bearing];
                private _inside={params ["_position"]; (_position select 0) > 300 && {(_position select 1) > 300}
                    && {(_position select 0) < worldSize-300} && {(_position select 1) < worldSize-300}};
                if ([_laneStart] call _inside && {[_laneEnd] call _inside}) then {
                    private _laneSamples=[];
                    private _dry=true;
                    private _laneVector=_laneEnd vectorDiff _laneStart;
                    for "_sampleIndex" from 0 to 44 do {
                        private _sample=_laneStart vectorAdd (_laneVector vectorMultiply (_sampleIndex/44));
                        if (surfaceIsWater _sample) then {_dry=false};
                        _laneSamples pushBack (getTerrainHeightASL _sample);
                    };
                    private _laneRelief=(selectMax _laneSamples)-(selectMin _laneSamples);
                    if (_dry && {_laneRelief >= 45} && {_laneRelief > _airLaneScore}) then {
                        _airLane=[_bearing,_laneStart,_candidateTarget,_laneEnd,_laneRelief,_laneSamples];
                        _airLaneScore=_laneRelief;
                    };
                };
            } forEach [0,45,90,135,180,225,270,315];
        };
    };
};

private _airLaneFound=_airLane isNotEqualTo [];
["TERRAIN-air-corridor-found",_airLaneFound,if (_airLaneFound) then {
    format ["bearing=%1 start=%2 target=%3 end=%4 relief=%5",_airLane select 0,_airLane select 1,
        _airLane select 2,_airLane select 3,_airLane select 4]
} else {"No sampled 11 km dry corridor provided at least 45 m relief"}] call _check;

if (_airLaneFound) then {
    _airLane params ["_airBearing","_airStart","_airTarget","_airEnd","_airRelief","_airTerrainSamples"];
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],
        ["Waldo_Cortex_AirAttack_Enable",true],
        ["Waldo_Cortex_AttackRunFlares_Enable",true],
        ["Waldo_AIPass_AircraftFlares_Enable",false],
        ["Waldo_AIPass_AircraftBreak_Enable",false]
    ]] call Waldo_fnc_CortexTuning;

    {
        _x params ["_id","_aircraftClass","_pattern","_height","_speed","_targetClass"];
        private _aircraft=createVehicle [_aircraftClass,[_airStart select 0,_airStart select 1,_height],[],0,"FLY"];
        _aircraft setDir _airBearing;
        createVehicleCrew _aircraft;
        _aircraft allowDamage false;
        _aircraft setVelocityModelSpace [0,_speed,0];
        _aircraft flyInHeight [_height,false];
        _aircraft setVariable ["Waldo_Cortex_AirAttackPattern",_pattern,true];
        _aircraft setVariable ["Waldo_CortexQA_Label",_id,true];
        _aircraft setVariable ["Waldo_CortexQA_TerrainShots",0,true];
        private _airCrew=crew _aircraft;
        private _airGroup=group driver _aircraft;
        _airGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _airGroup setVariable ["acex_headless_blacklist",true,true];
        {_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach _airCrew;

        private _target=createVehicle [_targetClass,_airTarget,[],0,"NONE"];
        createVehicleCrew _target;
        _target allowDamage true;
        _target setFuel 0;
        _target setVehicleAmmo 0;
        _target setVariable ["Waldo_CortexQA_Label",_id+" TERRAIN TARGET",true];
        private _targetCrew=crew _target;
        private _targetGroup=group driver _target;
        _targetGroup setVariable ["Waldo_AIPass_Exclude",true,true];
        {_x allowDamage false; _x disableAI "PATH"; doStop _x} forEach _targetCrew;

        _aircraft addEventHandler ["Fired",{
            params ["_aircraft","_weapon"];
            if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") != "cmlauncher") then {
                _aircraft setVariable ["Waldo_CortexQA_TerrainShots",
                    (_aircraft getVariable ["Waldo_CortexQA_TerrainShots",0])+1,true];
            };
        }];
        _airGroup setCombatMode "RED";
        _airGroup reveal [_target,4];
        private _routeWaypoint=_airGroup addWaypoint [_airEnd,0];
        _routeWaypoint setWaypointType "MOVE";
        _routeWaypoint setWaypointBehaviour "COMBAT";
        _routeWaypoint setWaypointSpeed "FULL";
        missionNamespace setVariable ["Waldo_CortexQA_Actors",[_aircraft,_target],true];
        [_id,format ["%1 must join and fly the measured %2 m-relief corridor, make a real %3 attack, damage the live target and egress without terrain contact. A plan or Fired event alone cannot pass.",_aircraftClass,round _airRelief,_pattern],_airTarget] call _phase;

        private _origin=getPosATL _aircraft;
        private _minimumHeight=1e6;
        private _maximumTravel=0;
        private _planStarted=[{(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []},45] call _wait;
        private _initialPlan=_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]];
        private _plannedClearance=_initialPlan param [28,0];
        private _plannedSamples=_initialPlan param [29,0];
        private _plannedViable=_initialPlan param [33,false];
        [_id+"-terrain-plan",_planStarted && {_plannedViable} && {_plannedSamples >= 42}
            && {_plannedClearance >= ([45,300] select (_aircraft isKindOf "Plane"))},
            str [_airRelief,_plannedClearance,_plannedSamples,_plannedViable,_initialPlan]] call _check;

        private _deadline=serverTime+240;
        waitUntil {
            sleep 0.25;
            if (!isNull _aircraft) then {
                _minimumHeight=_minimumHeight min ((getPosATL _aircraft) select 2);
                _maximumTravel=_maximumTravel max (_aircraft distance2D _origin);
            };
            serverTime >= _deadline || {!alive _aircraft}
                || {_planStarted && {(_aircraft getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isEqualTo []}}
        };
        private _shots=_aircraft getVariable ["Waldo_CortexQA_TerrainShots",0];
        private _outcome=_aircraft getVariable ["Waldo_Cortex_AirAttackOutcome",[]];
        private _clearance=[45,220] select (_aircraft isKindOf "Plane");
        [_id+"-physical-flight",alive _aircraft && {_maximumTravel >= 1500}
            && {_minimumHeight >= _clearance},str [_maximumTravel,_minimumHeight,_clearance,getPosATL _aircraft,_outcome]] call _check;
        [_id+"-real-weapon-release",_shots > 0,str [_shots,_outcome]] call _check;
        [_id+"-target-damaged",damage _target >= 0.2 || {!alive _target},
            str [damage _target,alive _target,_shots,_outcome]] call _check;
        [_id+"-finite-egress",_planStarted && {_outcome isNotEqualTo []}
            && {(_outcome param [0,""]) in ["COMPLETE","TARGET_DESTROYED"]},str _outcome] call _check;

        missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
        {deleteVehicle _x} forEach (_airCrew+_targetCrew+[_aircraft,_target]);
        deleteGroup _airGroup;
        deleteGroup _targetGroup;
    } forEach [
        ["TERRAIN-AIR-PLANE","O_Plane_CAS_02_dynamicLoadout_F","STRAFE",1100,155,"B_APC_Tracked_01_rcws_F"],
        ["TERRAIN-AIR-HELICOPTER","O_Heli_Attack_02_dynamicLoadout_F","LATERAL",220,55,"B_APC_Tracked_01_rcws_F"]
    ];
};
