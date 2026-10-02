/*
 * Author: WaldoTheWarfighter
 * Visually tests a contact-led combined-arms opportunity with infantry, an APC and an attack helicopter.
 * No rally, readiness flag, waypoint or scripted assembly is injected. The infantry must acquire the
 * hostile naturally; production communication then gives each nearby capable asset an independent role.
 * Locality/authority: scheduled dedicated-server fixture with server-owned groups and normal production calls.
 * Repeat/JIP: disposable actors are labelled publicly and deleted at completion; settings are restored by the parent runner.
 * Arguments: check <CODE>; phase <CODE>; wait <CODE>.
 * Return Value: Nothing.
 * Current callers: cortexQAServer.sqf for all/features/combinedarms focus.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombinedArms.sqf";
 */
params ["_check","_phase","_wait"];
private _groups=[];
private _objects=[];
private _savedDeceleration=missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable",false];
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable",false,true];
private _makeGroup={private _g=createGroup [_this,true]; _g setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _g setVariable ["acex_headless_blacklist",true,true]; _g allowFleeing 0; _groups pushBack _g; _g};
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
    ["Waldo_AIPass_ContactReports_Enable",true],["Waldo_AIPass_CoordinatedAssault_Enable",true],
    ["Waldo_AIPass_Vehicles_Enable",true],["Waldo_AIPass_VehicleGunnery_Enable",true],
    ["Waldo_Cortex_AirAttack_Enable",true],["Waldo_AIPass_Artillery_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_Flank_Enable",false],
    ["Waldo_AIPass_Advance_Enable",false],["Waldo_AIPass_Morale_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _infantry=east call _makeGroup;
for "_i" from 0 to 3 do {
    private _u=_infantry createUnit ["O_Soldier_F",[3600+_i*2,3600,0],[],0,"NONE"];
    _u setDir 0; _u setSkill ["spotDistance",1]; _u setSkill ["spotTime",1]; _u allowDamage false;
    _u setVariable ["Waldo_CortexQA_Label",format ["OBSERVER %1",_i+1],true]; _objects pushBack _u;
};
_infantry setCombatMode "RED";
private _enemyGroup=west call _makeGroup;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _enemy=_enemyGroup createUnit ["B_Soldier_F",[3600,3780,0],[],0,"NONE"];
_enemy setDir 180; _enemy disableAI "PATH"; _enemy allowDamage false; _enemy setVariable ["Waldo_CortexQA_Label","OBSERVED HOSTILE",true]; _objects pushBack _enemy;
private _apc=createVehicle ["O_APC_Tracked_02_cannon_F",[3520,3570,0],[],0,"NONE"];
_apc setDir 0; createVehicleCrew _apc; private _apcGroup=group driver _apc; _groups pushBackUnique _apcGroup;
_apcGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _apcGroup setCombatMode "RED"; _apc allowDamage false;
_apc setVariable ["Waldo_CortexQA_Label","APC / independent fire support",true]; _apc setVariable ["Waldo_CortexQA_Shots",[],true];
_apc addEventHandler ["Fired",{params ["_vehicle"]; private _shots=_vehicle getVariable ["Waldo_CortexQA_Shots",[]]; _shots pushBack serverTime; _vehicle setVariable ["Waldo_CortexQA_Shots",_shots,true]}]; _objects pushBack _apc; _objects append crew _apc;
private _heli=createVehicle ["O_Heli_Attack_02_dynamicLoadout_F",[3350,3400,140],[],0,"FLY"];
_heli setDir 0; _heli setVelocity [0,70,0]; createVehicleCrew _heli; private _heliGroup=group driver _heli; _groups pushBackUnique _heliGroup;
_heliGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _heliGroup setCombatMode "RED"; _heli allowDamage false;
_heli setVariable ["Waldo_CortexQA_Label","HELICOPTER / opportunity attack",true]; _objects pushBack _heli; _objects append crew _heli;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[leader _infantry,_enemy,_apc,_heli],true];
["Combined arms: contact creates independent roles","The infantry observes the hostile naturally. The APC and helicopter may engage immediately through their own controllers. No unit waits at a rally, and the infantry receives no assembly waypoint. Labels, target lines, shots and the air route show physical behaviour.",[3600,3650,0]] call _phase;
private _seen=[{(leader _infantry knowsAbout _enemy) >= 1},35] call _wait;
["COMBINED-natural-contact",_seen,str (leader _infantry targetKnowledge _enemy)] call _check;
private _opportunity=[{count (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) >= 5},25] call _wait;
["COMBINED-opportunity-created",_opportunity,str (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]])] call _check;
private _groundRole=[{((_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""]) == "GROUND_FIRE"},20] call _wait;
private _airRole=[{((_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""]) == "AIR_ATTACK"},20] call _wait;
["COMBINED-ground-role",_groundRole,str (_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]])] call _check;
["COMBINED-air-role",_airRole,str (_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]])] call _check;
["COMBINED-ground-applied",[{((_apcGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"},15] call _wait,str (_apcGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;
["COMBINED-air-applied",[{((_heliGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"},15] call _wait,str (_heliGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;
["COMBINED-no-infantry-assembly",(_infantry getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo [] && {(waypoints _infantry) findIf {waypointDescription _x == "WMP AI PASS"} < 0},str waypoints _infantry] call _check;
["COMBINED-ground-target-shared",[{_apcGroup knowsAbout _enemy >= 2 || {!isNull assignedTarget gunner _apc}},15] call _wait,format ["knowledge=%1 target=%2 shots=%3",_apcGroup knowsAbout _enemy,assignedTarget gunner _apc,count (_apc getVariable ["Waldo_CortexQA_Shots",[]])]] call _check;
["COMBINED-air-controller-started",[{_heli getVariable ["Waldo_Cortex_AirAttackJob",false] || {(_heli getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []}},20] call _wait,str (_heli getVariable ["Waldo_Cortex_AirAttackPlan",[]])] call _check;
sleep 5;
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable",_savedDeceleration,true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach _objects;
{deleteGroup _x} forEach _groups;
