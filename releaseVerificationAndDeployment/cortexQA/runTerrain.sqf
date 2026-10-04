/*
 * Author: WaldoTheWarfighter
 * Finds a genuinely uneven, dry audit sector and exercises the shared Cortex avenue selector with
 * infantry, vehicle and defensive movement. This is a terrain prerequisite and cross-cutting
 * physical diagnostic; it does not turn a route calculation or accepted order into a feature pass.
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
