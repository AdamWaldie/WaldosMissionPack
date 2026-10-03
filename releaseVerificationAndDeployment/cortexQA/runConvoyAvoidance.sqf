/*
 * Author: WaldoTheWarfighter
 * Tests physical convoy yielding to a friendly pedestrian and resuming after clearance.
 * Locality/authority: scheduled server QA; production convoy controller drives two live vehicles.
 * Repeat/JIP: fresh tagged actors and public observer state; original rosters are cleaned up.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAvoidance.sqf";
 */
params ["_check","_phase","_wait"];
private _saved=missionNamespace getVariable ["Waldo_Convoy_AvoidInfantry_Enable",false];
[createHashMapFromArray [["Waldo_Convoy_AvoidInfantry_Enable",true]]] call Waldo_fnc_CortexTuning;
{
private _offset=_x;
private _prefix=["AVOID","AVOID-CLOSE"] select (_offset < 10);
private _pedestrianY=2600+_offset;
private _group=createGroup [east,true];
private _pedestrians=createGroup [east,true];
{_x setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _x setVariable ["acex_headless_blacklist",true,true]} forEach [_group,_pedestrians];
_pedestrians setVariable ["Waldo_AIPass_Exclude",true,true];
private _vehicles=[];
private _crew=[];
{
    private _v=createVehicle ["O_MRAP_02_F",[4200,2600-_x*50,0],[],0,"NONE"];
    _v setDir 0; createVehicleCrew _v;
    private _old=group driver _v;
    _crew append crew _v;
    (crew _v) joinSilent _group; deleteGroup _old;
    _vehicles pushBack _v;
} forEach [0,1];
private _lead=_vehicles select 0;
private _man=_pedestrians createUnit ["O_Soldier_F",[4200,_pedestrianY,0],[],0,"NONE"];
_man setDir 180; _man disableAI "PATH";
_man setVariable ["Waldo_CortexQA_Label","PEDESTRIAN: MUST NOT BE HIT",true];
_group selectLeader driver _lead;
["Pedestrian in convoy corridor","The first case approaches a pedestrian from 40 m; the second begins with him 6 m ahead inside the stopped vehicle corridor. Watch actual speed and clearance: the lead must stop short without injuring him. The pedestrian then walks sideways, after which the convoy must continue.",[4200,2630,0]] call _phase;
private _wp=_group addWaypoint [[4200,3200,0],0]; _wp setWaypointType "MOVE";
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_man],true];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",_vehicles,true];
[_prefix+"-start",[_group,20,50,true] call Waldo_fnc_SimpleAiConvoy] call _check;
private _minimumDistance=1e9;
private _stopRequested=false;
private _yielded=[{
    _minimumDistance=_minimumDistance min (_lead distance2D _man);
    if (([_lead,20,_group] call Waldo_fnc_CortexInfantrySpeed) == 0) then {_stopRequested=true};
    alive _man && {_lead distance2D _man < 16} && {_lead distance2D _man > 3} && {abs speed _lead < 1}},60] call _wait;
private _held=_yielded;
for "_sample" from 1 to 5 do {sleep 1; if (!alive _man || {damage _man > 0} || {abs speed _lead > 2}) then {_held=false}};
[_prefix+"-physical-yield-and-hold",_held,format ["speed=%1 distance=%2 pedestrian damage=%3 closest=%4 corridorStop=%5",speed _lead,_lead distance2D _man,damage _man,_minimumDistance,_stopRequested]] call _check;
private _origin=getPosATL _lead;
_man enableAI "PATH";
_man doMove [4230,_pedestrianY,0];
_man setVariable ["Waldo_CortexQA_Target",[4230,_pedestrianY,0],true];
["Pedestrian clears convoy corridor","The soldier must physically walk at least 15 m sideways. The convoy must then travel beyond his former position without injury or a manual resume.",[4200,_pedestrianY,0]] call _phase;
[_prefix+"-pedestrian-physical-clearance",[{alive _man && {getPosATL _man select 0 > 4215}},40] call _wait] call _check;
[_prefix+"-resume-physical-travel",[{_lead distance2D _origin > 50 && {getPosATL _lead select 1 > _pedestrianY+30}},60] call _wait] call _check;
[_prefix+"-no-pedestrian-injury",alive _man && {damage _man == 0}] call _check;
[_group,0,50,true,true] call Waldo_fnc_SimpleAiConvoy;
{deleteVehicle _x} forEach (_crew+_vehicles+[_man]);
deleteGroup _group; deleteGroup _pedestrians;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",[],true];
} forEach [40,6];
[createHashMapFromArray [["Waldo_Convoy_AvoidInfantry_Enable",_saved]]] call Waldo_fnc_CortexTuning;
