/*
 * Author: WaldoTheWarfighter
 * Tests physical convoy yielding to a friendly pedestrian and resuming after clearance. VR keeps
 * fixed coordinates; terrain worlds rotate the complete vehicle/pedestrian route onto a measured
 * dry corridor and judge clearance and resumed movement on that corridor's axes.
 * Locality/authority: scheduled server QA; production convoy controller drives two live vehicles.
 * Repeat/JIP: fresh tagged actors and public observer state; original rosters are cleaned up.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAvoidance.sqf";
 */
params ["_check","_phase","_wait"];
private _saved=missionNamespace getVariable ["Waldo_Convoy_AvoidInfantry_Enable",false];
[createHashMapFromArray [["Waldo_Convoy_AvoidInfantry_Enable",true]]] call Waldo_fnc_CortexTuning;
private _terrainOrigin=[4200,2600,0];
private _terrainHeading=0;
private _terrainReady=worldName == "VR";
private _terrainRelief=0;
if (!_terrainReady) then {
    private _bestScore=-1;
    private _gridStep=(worldSize/9) max 900;
    for "_gridX" from 2 to 7 do {
        for "_gridY" from 2 to 7 do {
            private _candidateOrigin=[_gridX*_gridStep,_gridY*_gridStep,0];
            for "_heading" from 0 to 315 step 45 do {
                private _forward=[sin _heading,cos _heading,0];
                private _right=[cos _heading,-sin _heading,0];
                private _safe=true;
                private _heights=[];
                {
                    private _lane=_x;
                    private _previous=[];
                    private _previousHeight=0;
                    for "_along" from -110 to 650 step 25 do {
                        private _sample=_candidateOrigin vectorAdd (_right vectorMultiply _lane)
                            vectorAdd (_forward vectorMultiply _along);
                        private _height=getTerrainHeightASL _sample;
                        if (surfaceIsWater _sample || {((surfaceNormal _sample) select 2) < 0.65}) then {_safe=false};
                        if (_previous isNotEqualTo []) then {
                            private _grade=abs (_height-_previousHeight)/((_sample distance2D _previous) max 1);
                            if (_grade > 0.8) then {_safe=false};
                        };
                        _heights pushBack _height;
                        _previous=_sample;
                        _previousHeight=_height;
                    };
                } forEach [-20,0,20];
                private _relief=if (_heights isEqualTo []) then {0} else {(selectMax _heights)-(selectMin _heights)};
                if (_safe && {_relief >= 15} && {_relief <= 140} && {_relief > _bestScore}) then {
                    _bestScore=_relief;
                    _terrainOrigin=_candidateOrigin;
                    _terrainHeading=_heading;
                    _terrainRelief=_relief;
                    _terrainReady=true;
                };
            };
        };
    };
};
private _terrainForward=[sin _terrainHeading,cos _terrainHeading,0];
private _terrainRight=[cos _terrainHeading,-sin _terrainHeading,0];
private _terrainPosition={
    params ["_local"];
    _terrainOrigin vectorAdd (_terrainRight vectorMultiply ((_local select 0)-4200))
        vectorAdd (_terrainForward vectorMultiply ((_local select 1)-2600))
};
["CNV-AVOID-terrain-scenario",_terrainReady,
    format ["world=%1 origin=%2 heading=%3 relief=%4",worldName,_terrainOrigin,_terrainHeading,_terrainRelief]] call _check;
if (!_terrainReady) then {
    ["Convoy pedestrian avoidance: no evaluative terrain","No dry three-lane vehicle corridor provided 15-140 m relief without unsafe slope or grade. Avoidance cases are skipped rather than falling back to flat geometry.",_terrainOrigin] call _phase;
} else {
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
    private _v=createVehicle ["O_MRAP_02_F",[[4200,2600-_x*50,0]] call _terrainPosition,[],0,"NONE"];
    _v setDir _terrainHeading; createVehicleCrew _v;
    private _old=group driver _v;
    _crew append crew _v;
    (crew _v) joinSilent _group; deleteGroup _old;
    _vehicles pushBack _v;
} forEach [0,1];
private _lead=_vehicles select 0;
private _man=_pedestrians createUnit ["O_Soldier_F",[[4200,_pedestrianY,0]] call _terrainPosition,[],0,"NONE"];
_man setDir (_terrainHeading+180); _man disableAI "PATH";
_man setVariable ["Waldo_CortexQA_Label","PEDESTRIAN: MUST NOT BE HIT",true];
_group selectLeader driver _lead;
["Pedestrian in convoy corridor","The first case approaches a pedestrian from 40 m; the second begins with him 6 m ahead inside the stopped vehicle corridor. Watch actual speed and clearance on the measured terrain route: the lead must stop short without injuring him. The pedestrian then walks across the route, after which the convoy must continue.",[[4200,2630,0]] call _terrainPosition] call _phase;
private _wp=_group addWaypoint [[[4200,3200,0]] call _terrainPosition,0]; _wp setWaypointType "MOVE";
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
private _pedestrianOrigin=getPosATL _man;
private _clearTarget=[[4230,_pedestrianY,0]] call _terrainPosition;
_man doMove _clearTarget;
_man setVariable ["Waldo_CortexQA_Target",_clearTarget,true];
["Pedestrian clears convoy corridor","The soldier must physically walk at least 15 m across the measured route. The convoy must then travel beyond his former position without injury or a manual resume.",[[4200,_pedestrianY,0]] call _terrainPosition] call _phase;
[_prefix+"-pedestrian-physical-clearance",[{alive _man && {((getPosATL _man) vectorDiff _pedestrianOrigin) vectorDotProduct _terrainRight > 15}},40] call _wait] call _check;
private _pedestrianAlong=(_pedestrianOrigin vectorDiff _terrainOrigin) vectorDotProduct _terrainForward;
[_prefix+"-resume-physical-travel",[{_lead distance2D _origin > 50 && {((getPosATL _lead) vectorDiff _terrainOrigin) vectorDotProduct _terrainForward > _pedestrianAlong+30}},60] call _wait] call _check;
[_prefix+"-no-pedestrian-injury",alive _man && {damage _man == 0}] call _check;
[_group,0,50,true,true] call Waldo_fnc_SimpleAiConvoy;
{deleteVehicle _x} forEach (_crew+_vehicles+[_man]);
deleteGroup _group; deleteGroup _pedestrians;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",[],true];
} forEach [40,6];
};
[createHashMapFromArray [["Waldo_Convoy_AvoidInfantry_Enable",_saved]]] call Waldo_fnc_CortexTuning;
