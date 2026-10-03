/*
 * Author: WaldoTheWarfighter
 * Checks that a defence order chooses and physically reaches solid cover, with separate occupied spots.
 * Locality/authority: scheduled server QA using public Cortex defence; fixture groups are server-pinned.
 * Repeat/JIP: fresh units/walls, public destinations and traces; only fixture objects are cleaned up.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACover.sqf";
 */
params ["_check","_phase","_wait"];
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_CoverValidation_Enable",true]]] call Waldo_fnc_CortexTuning;
[{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
private _group=createGroup [east,true];
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_group setVariable ["acex_headless_blacklist",true,true];
private _units=[];
private _walls=[];
{
    private _u=_group createUnit ["O_Soldier_F",[_x,1100,0],[],0,"NONE"];
    _u setVariable ["acex_headless_blacklist",true,true];
    _u setVariable ["Waldo_CortexQA_Label",format ["COVER SOLDIER %1",_forEachIndex+1],true];
    _units pushBack _u;
    private _wall=createVehicle ["Land_CncWall4_F",[_x,1140,0],[],0,"CAN_COLLIDE"];
    _wall setDir 0;
    _walls pushBack _wall;
} forEach [2244,2256];
missionNamespace setVariable ["Waldo_CortexQA_Actors",_units,true];
["Solid cover selection","Both soldiers must walk to separate covered positions behind the concrete walls, facing north. Arrival alone is insufficient: a shot-height ray from the northern threat must hit a fixture wall before reaching each soldier.",[2250,1130,0]] call _phase;
["COVER-defend-accepted",[_group,[2250,1140,0],0,12] call Waldo_fnc_CortexDefend] call _check;
{private _slot=_x getVariable ["Waldo_AIPass_DefendPos",[]]; if (_slot isNotEqualTo []) then {_x setVariable ["Waldo_CortexQA_Target",_slot select 0,true]}} forEach _units;
private _arrived=[{
    _units findIf {private _slot=_x getVariable ["Waldo_AIPass_DefendPos",[]]; !alive _x || {_slot isEqualTo []} || {_x distance (_slot select 0) > 2.5} || {getPosATL _x select 1 < 1130}} < 0
},70] call _wait;
["COVER-physical-arrival",_arrived,str (_units apply {getPosATL _x})] call _check;
private _protected=true;
{
    private _end=(getPosASL _x) vectorAdd [0,0,1];
    private _rays=lineIntersectsSurfaces [(AGLToASL [2250,1200,0]) vectorAdd [0,0,1.6],_end,_x,objNull,true,-1,"FIRE","GEOM"];
    if (_rays findIf {(_x select 2) in _walls || {(_x select 3) in _walls}} < 0) then {_protected=false};
} forEach _units;
["COVER-solid-wall-between-threat-and-each-unit",_arrived && {_protected}] call _check;
["COVER-separate-occupied-positions",_arrived && {(_units select 0) distance2D (_units select 1) >= 2}] call _check;
sleep 8;
private _releaseOrigins = _units apply {getPosATL _x};
[_group] call Waldo_fnc_CortexDefendRelease;
private _destination = [2250,1050,0];
private _waypoint = _group addWaypoint [_destination,0];
_waypoint setWaypointType "MOVE";
_waypoint setWaypointBehaviour "AWARE";
_group setCurrentWaypoint _waypoint;
{_x setVariable ["Waldo_CortexQA_Target",_destination,true]} forEach _units;
["Leave cover for a new order","After defence is released, both soldiers must leave their covered positions and walk south to the replacement waypoint. A cleared defence flag alone does not pass.",_destination] call _phase;
private _leftCover = [{
    _units findIf {!alive _x || {_x distance2D (_releaseOrigins select (_units find _x)) < 30}
        || {_x distance2D _destination > 20}} < 0
},90] call _wait;
["COVER-release-physical-replacement",_arrived && {_leftCover},str (_units apply {getPosATL _x})] call _check;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_units+_walls); deleteGroup _group;
