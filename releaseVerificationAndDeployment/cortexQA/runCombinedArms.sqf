/*
 * Author: WaldoTheWarfighter
 * Runs an additive, phase-visible contact-led combined-arms scenario with infantry, an APC and an attack helicopter.
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
private _publish={
    params ["_stage","_requester","_target","_assets",["_note",""]];
    missionNamespace setVariable ["Waldo_CortexQA_Combined",[
        "CONTACT-LED OPPORTUNITY",_stage,_requester,_target,_assets,serverTime,_note
    ],true];
};
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
_infantry setGroupIdGlobal ["Cortex QA observer"];
private _infantryWaypoints=count waypoints _infantry;
private _enemyGroup=west call _makeGroup;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _enemy=_enemyGroup createUnit ["B_Soldier_F",[3600,3780,0],[],0,"NONE"];
_enemy setDir 180; _enemy disableAI "PATH"; _enemy allowDamage false; _enemy setVariable ["Waldo_CortexQA_Label","OBSERVED HOSTILE",true]; _objects pushBack _enemy;
private _apc=createVehicle ["O_APC_Tracked_02_cannon_F",[3520,3570,0],[],0,"NONE"];
_apc setDir 0; createVehicleCrew _apc; private _apcGroup=group driver _apc; _groups pushBackUnique _apcGroup;
_apcGroup setGroupIdGlobal ["Cortex QA ground support"];
_apcGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _apcGroup setCombatMode "RED"; _apc allowDamage false;
_apc setVariable ["Waldo_CortexQA_Label","APC / independent fire support",true]; _apc setVariable ["Waldo_CortexQA_Shots",[],true];
_apc addEventHandler ["Fired",{params ["_vehicle"]; private _shots=_vehicle getVariable ["Waldo_CortexQA_Shots",[]]; _shots pushBack serverTime; _vehicle setVariable ["Waldo_CortexQA_Shots",_shots,true]}]; _objects pushBack _apc; _objects append crew _apc;
private _groundRouteTarget=[3520,3940,0];
private _groundRouteStart=_apc distance2D _groundRouteTarget;
(driver _apc) doMove _groundRouteTarget;
sleep 1;
private _heli=createVehicle ["O_Heli_Attack_02_dynamicLoadout_F",[3150,3600,140],[],0,"FLY"];
_heli setDir 90; _heli setVelocity [15,0,0]; createVehicleCrew _heli; private _heliGroup=group driver _heli; _groups pushBackUnique _heliGroup;
_heliGroup setGroupIdGlobal ["Cortex QA air support"];
_heliGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _heliGroup setCombatMode "RED"; _heli allowDamage false;
_heli limitSpeed 60; (driver _heli) doMove [4150,3600,140];
_heli setVariable ["Waldo_CortexQA_Label","HELICOPTER / opportunity attack",true]; _objects pushBack _heli; _objects append crew _heli;
private _assets=[[_apcGroup,_apc,"GROUND FIRE"],[_heliGroup,_heli,"AIR ATTACK"]];
missionNamespace setVariable ["Waldo_CortexQA_Actors",(units _infantry)+[_enemy,_apc,_heli],true];
["DETECT",_infantry,_enemy,_assets,"No Cortex support role exists yet. The infantry must see the hostile without injected knowledge."] call _publish;
["Combined arms / 1. Detect","The observer squad must acquire the live hostile through the engine. No readiness flag, rally point or support lease is created. Cyan trails show physical travel; blue links show communication candidates, not orders.",[3600,3650,0]] call _phase;
["COMBINED-air-fixture-moving",!isTouchingGround _heli && {speed _heli >= 40} && {(getPosATL _heli select 2) >= 80} && {alive driver _heli},
    format ["speed=%1km/h altitude=%2m command=%3 expected=%4",round speed _heli,round (getPosATL _heli select 2),currentCommand driver _heli,expectedDestination driver _heli]] call _check;
private _seen=[{(leader _infantry knowsAbout _enemy) >= 1},35] call _wait;
["COMBINED-natural-contact",_seen,str (leader _infantry targetKnowledge _enemy)] call _check;

["DISTRIBUTE",_infantry,_enemy,_assets,"Fresh contact may be shared immediately. Each arm accepts or refuses independently."] call _publish;
["Combined arms / 2. Distribute","The fresh contact should create one short-lived opportunity. The APC and flying helicopter may receive independent roles immediately; the infantry does not wait for either asset.",[3600,3650,0]] call _phase;
private _opportunity=[{count (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) >= 5},25] call _wait;
["COMBINED-opportunity-created",_opportunity,str (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]])] call _check;
private _groundRole=[{((_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""]) == "GROUND_FIRE"},20] call _wait;
private _airRole=[{((_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""]) == "AIR_ATTACK"},20] call _wait;
["COMBINED-ground-role",_groundRole,str (_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]])] call _check;
["COMBINED-air-role",_airRole,str (_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]])] call _check;
["COMBINED-ground-applied",[{((_apcGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"},15] call _wait,str (_apcGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;
["COMBINED-air-applied",[{((_heliGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"},15] call _wait,str (_heliGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;

["ACT",_infantry,_enemy,_assets,"Roles are finite. Watch real ground fire and the aircraft controller while the observer remains unblocked."] call _publish;
["Combined arms / 3. Act independently","The APC should physically engage without losing its authored route. The helicopter should enter its finite attack controller. A role or target assignment alone is insufficient for the physical-effect checks.",[3600,3650,0]] call _phase;
["COMBINED-no-infantry-assembly",
    (_infantry getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []
        && {count waypoints _infantry == _infantryWaypoints}
        && {(waypoints _infantry) findIf {waypointDescription _x == "WMP AI PASS"} < 0},
    format ["supportLease=%1 waypoints=%2",_infantry getVariable ["Waldo_AIPass_SupportLease",[]],waypoints _infantry]
] call _check;
private _groundRemaining=_apc distance2D _groundRouteTarget;
private _groundState=_apcGroup getVariable ["Waldo_AIPass_State",createHashMap];
private _groundLease=_groundState getOrDefault ["movementLease",[]];
private _groundWmpWaypoint=(waypoints _apcGroup) findIf {waypointDescription _x == "WMP AI PASS"};
["COMBINED-ground-route-preserved",_groundRemaining < _groundRouteStart-50 && {_groundLease isEqualTo []} && {_groundWmpWaypoint < 0},
    format ["target=%1 startRemaining=%2m nowRemaining=%3m lease=%4 current=%5 expected=%6",
        _groundRouteTarget,round _groundRouteStart,round _groundRemaining,_groundLease,currentCommand driver _apc,expectedDestination driver _apc]] call _check;
["COMBINED-ground-target-shared",[{_apcGroup knowsAbout _enemy >= 2 || {!isNull assignedTarget gunner _apc}},15] call _wait,
    format ["knowledge=%1 target=%2",_apcGroup knowsAbout _enemy,assignedTarget gunner _apc]] call _check;
["COMBINED-ground-actual-fire",[{count (_apc getVariable ["Waldo_CortexQA_Shots",[]]) > 0},20] call _wait,
    str (_apc getVariable ["Waldo_CortexQA_Shots",[]])] call _check;
["COMBINED-air-controller-started",[{_heli getVariable ["Waldo_Cortex_AirAttackJob",false] || {(_heli getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []}},20] call _wait,str (_heli getVariable ["Waldo_Cortex_AirAttackPlan",[]])] call _check;

["HANDOVER",_infantry,_enemy,_assets,"The opportunity expires by itself. No arm may leave an infantry movement lease or permanent role behind."] call _publish;
["Combined arms / 4. Handover","After the finite opportunity expires, role tokens must clear without a scheduled rally or shared completion barrier. Existing authored movement remains the owner of movement.",[3600,3650,0]] call _phase;
private _expired=[{
    (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) isEqualTo []
        && {(_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) isEqualTo []}
        && {(_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) isEqualTo []}
},45] call _wait;
["COMBINED-finite-cleanup",_expired,format ["requester=%1 ground=%2 air=%3",
    _infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]],
    _apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]],
    _heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]
]] call _check;
["COMBINED-no-blocking-state",
    (_infantry getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []
        && {(_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) isEqualTo []},
    format ["supportLease=%1 opportunity=%2",_infantry getVariable ["Waldo_AIPass_SupportLease",[]],_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]]
] call _check;

missionNamespace setVariable ["Waldo_CortexQA_Combined",["CONTACT-LED OPPORTUNITY","CLEANUP",grpNull,objNull,[],serverTime,"All fixture-owned roles and actors are being removed."],true];
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable",_savedDeceleration,true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{if (!isNull _x) then {deleteVehicle _x}} forEach _objects;
{if (!isNull _x) then {deleteGroup _x}} forEach _groups;
missionNamespace setVariable ["Waldo_CortexQA_Combined",[],true];
