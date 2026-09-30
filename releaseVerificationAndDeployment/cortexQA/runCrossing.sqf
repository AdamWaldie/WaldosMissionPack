/*
 * Author: WaldoTheWarfighter
 * Road-crossing acceptance using an engine road, natural enemy observation, carried
 * smoke and physical movement. No decorative road, injected drill or reveal command.
 * Locality/authority: scheduled server fixture; groups pinned to the server.
 * Repeat/JIP: fresh actors, public labels/destinations; deletes only its fixtures.
 * The parent audit restores settings. Missing terrain roads fail the prerequisite.
 * Arguments: 0 check <CODE>, 1 phase <CODE>, 2 wait <CODE>; required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACrossing.sqf";
 */
params ["_check","_phase","_wait"];
private _anchor=if (allPlayers isEqualTo []) then {[worldSize/2,worldSize/2,0]} else {getPosATL (allPlayers select 0)};
// One bounded fixture search, never a production or per-unit terrain scan.
private _roads=(_anchor nearRoads 2000) select {
    private _info=getRoadInfo _x;
    count _info >= 9 && {!(_info select 8)} && {(_info select 1) >= 4}
};
["CROSS-engine-road-prerequisite",_roads isNotEqualTo [],format ["world=%1; roads within 2 km=%2; VR needs a separate road-terrain run",worldName,count _roads]] call _check;
if (_roads isEqualTo []) exitWith {};
private _road=_roads select 0;
private _info=getRoadInfo _road;
private _centre=getPosATL _road;
private _direction=((_info select 6) getDir (_info select 7))+90;
private _start=_centre getPos [45,_direction+180];
private _goal=_centre getPos [110,_direction];
private _enemyPos=_centre getPos [190,_direction];
private _dry=!surfaceIsWater _start && {!surfaceIsWater _goal} && {!surfaceIsWater _enemyPos};
["CROSS-dry-approach-prerequisite",_dry] call _check;
if (!_dry) exitWith {};
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_LambsMode","WMP"],
    ["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_Advance_Enable",true],
    ["Waldo_AIPass_Flank_Enable",false],["Waldo_AIPass_Assault_Enable",false],
    ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_Artillery_Enable",false],
    ["Waldo_AIPass_StreetCrossing_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _group=createGroup [east,true];
private _opposition=createGroup [west,true];
{
    _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _x setVariable ["acex_headless_blacklist",true,true];
} forEach [_group,_opposition];
_opposition setVariable ["Waldo_AIPass_Exclude",true,true];
private _actors=[];
for "_i" from 0 to 5 do {
    private _u=_group createUnit ["O_Soldier_F",_start getPos [_i*3,_direction+90],[],0,"NONE"];
    _u setDir _direction; _u disableAI "PATH"; _u allowDamage false;
    _u addMagazine "SmokeShell"; _u addMagazine "SmokeShell";
    _u setVariable ["acex_headless_blacklist",true,true];
    _u setVariable ["Waldo_CortexQA_Label",format ["ROAD CROSSING %1",_i+1],true];
    _u setVariable ["Waldo_CortexQA_Target",_goal,true];
    _u setVariable ["Waldo_CortexQA_RoadSmoke",0];
    _u addEventHandler ["FiredMan",{
        params ["_unit","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
        if (!isNull _projectile && {toLowerANSI getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotsmoke","shotsmokex"]}) then {
            _unit setVariable ["Waldo_CortexQA_RoadSmoke",(_unit getVariable ["Waldo_CortexQA_RoadSmoke",0])+1];
        };
    }];
    _actors pushBack _u;
};
private _enemy=_opposition createUnit ["B_Soldier_F",_enemyPos,[],0,"NONE"];
_enemy allowDamage false; _enemy disableAI "PATH"; _opposition setCombatMode "BLUE";
_enemy setDir (_direction+180);
missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors+[_enemy],true];
["Road crossing: real terrain","The squad must naturally see the opponent, then use its ordinary advance to cross the road. Watch actual smoke and all six soldiers reaching the far side. Missing road or contact prerequisites cannot pass.",_centre] call _phase;
private _off=[_start,[_goal],"FINAL",_group] call Waldo_fnc_CortexPlanRoute;
["CROSS-disabled-no-crossing-stages",_off findIf {(_x select 1) in ["CROSS_NEAR","CROSS_FAR"]} < 0] call _check;
[createHashMapFromArray [["Waldo_AIPass_StreetCrossing_Enable",true]]] call Waldo_fnc_CortexTuning;
private _on=[_start,[_goal],"FINAL",_group] call Waldo_fnc_CortexPlanRoute;
private _planned=_on findIf {(_x select 1) == "CROSS_NEAR"} >= 0 && {_on findIf {(_x select 1) == "CROSS_FAR"} >= 0};
["CROSS-enabled-route-stages",_planned,str _on] call _check;
private _contact=[{(([ _group] call Waldo_fnc_CortexKnowledge) select 0) findIf {(_x select 0) == _enemy && {(_x select 2) <= 5}} >= 0},45] call _wait;
["CROSS-natural-contact-prerequisite",_contact] call _check;
private _wp=_group addWaypoint [_goal,0]; _wp setWaypointType "MOVE";
{_x enableAI "PATH"} forEach _actors;
private _axis=[sin _direction,cos _direction,0];
private _sawCrossing=false;
private _arrived=[{
    private _drill=(_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
    private _points=_drill getOrDefault ["points",[]];
    private _index=_drill getOrDefault ["index",-1];
    if (_index >= 0 && {_index < count _points} && {((_points select _index) select 1) == "CROSS_FAR"}) then {_sawCrossing=true};
    _actors findIf {!alive _x || {((getPosATL _x vectorDiff _centre) vectorDotProduct _axis) < 20}} < 0
},180] call _wait;
["CROSS-production-crossing-executed",_planned && {_contact} && {_sawCrossing}] call _check;
["CROSS-real-smoke-projectile",_sawCrossing && {_actors findIf {(_x getVariable ["Waldo_CortexQA_RoadSmoke",0]) > 0} >= 0}] call _check;
["CROSS-all-members-physical-far-side",_sawCrossing && {_arrived},str (_actors apply {getPosATL _x})] call _check;
[_group] call Waldo_fnc_CortexReleaseGroup;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_actors+[_enemy]);
deleteGroup _group; deleteGroup _opposition;
