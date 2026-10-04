/*
 * Author: WaldoTheWarfighter
 * Runs an additive, phase-visible contact-led combined-arms scenario with infantry, two ground vehicles and an attack helicopter.
 * No rally, readiness flag, waypoint or scripted assembly is injected. The infantry must acquire the
 * hostile naturally; production communication then gives each nearby capable asset an independent role.
 * Locality/authority: scheduled dedicated-server fixture with server-owned groups and normal production calls.
 * Outside VR a bounded one-time scan rotates both vehicle routes and the contact geometry onto a
 * dry corridor with measurable relief, safe surface normals and vehicle-scale grades.
 * Repeat/JIP: disposable actors are labelled publicly and deleted at completion; settings are restored by the parent runner.
 * Arguments: check <CODE>; phase <CODE>; wait <CODE>.
 * Return Value: Nothing.
 * Current callers: cortexQAServer.sqf for all/features/combinedarms focus.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombinedArms.sqf";
 */
params ["_check","_phase","_wait"];
private _terrainOrigin=[3600,3600,0];
private _terrainHeading=0;
private _terrainRelief=0;
private _terrainMaximumGrade=0;
private _terrainMinimumNormal=1;
private _terrainScenarioReady=worldName == "VR";
private _terrainWorld={
    params ["_origin","_heading","_localX","_localY",["_localZ",0,[0]]];
    (_origin vectorAdd [
        _localX*cos _heading+_localY*sin _heading,
        -_localX*sin _heading+_localY*cos _heading,
        _localZ
    ])
};
if (!_terrainScenarioReady) then {
    private _found=[];
    private _margin=1200 min ((worldSize-1000)/2);
    private _scanStep=800 max ((worldSize-2*_margin)/5);
    for "_candidateX" from _margin to (worldSize-_margin) step _scanStep do {
        for "_candidateY" from _margin to (worldSize-_margin) step _scanStep do {
            for "_heading" from 0 to 315 step 45 do {
                if (_found isEqualTo []) then {
                    private _heights=[];
                    private _usable=true;
                    private _maximumGrade=0;
                    private _minimumNormal=1;
                    {
                        private _lateral=_x;
                        private _previousHeight=-1e9;
                        for "_along" from -400 to 400 step 40 do {
                            private _sample=[[_candidateX,_candidateY,0],_heading,_along,_lateral] call _terrainWorld;
                            private _normal=(surfaceNormal _sample) select 2;
                            if (surfaceIsWater _sample || {_normal < 0.68}) exitWith {_usable=false};
                            private _height=getTerrainHeightASL _sample;
                            if (_previousHeight > -1e8) then {
                                private _grade=abs (_height-_previousHeight)/40;
                                _maximumGrade=_maximumGrade max _grade;
                                if (_grade > 0.9) then {_usable=false};
                            };
                            _minimumNormal=_minimumNormal min _normal;
                            _previousHeight=_height;
                            _heights pushBack _height;
                        };
                    } forEach [-120,0,180];
                    if (_usable && {_heights isNotEqualTo []}) then {
                        private _relief=(selectMax _heights)-(selectMin _heights);
                        if (_relief >= 15 && {_relief <= 120}) then {
                            _found=[_candidateX,_candidateY,0];
                            _terrainHeading=_heading;
                            _terrainRelief=_relief;
                            _terrainMaximumGrade=_maximumGrade;
                            _terrainMinimumNormal=_minimumNormal;
                        };
                    };
                };
            };
        };
    };
    if (_found isNotEqualTo []) then {_terrainOrigin=_found; _terrainScenarioReady=true};
};
private _terrainPosition={
    params ["_x","_y",["_z",0,[0]]];
    [_terrainOrigin,_terrainHeading,_x-3600,_y-3600,_z] call _terrainWorld
};
["COMBINED-terrain-scenario",_terrainScenarioReady,
    str [worldName,_terrainOrigin,_terrainHeading,_terrainRelief,_terrainMaximumGrade,_terrainMinimumNormal]] call _check;
if (!_terrainScenarioReady) exitWith {};
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
    // This component case deliberately disables infantry coordinated assault. Armour and aircraft
    // contact support must remain governed by their own enabled features.
    ["Waldo_AIPass_ContactReports_Enable",true],["Waldo_AIPass_CoordinatedAssault_Enable",false],
    ["Waldo_AIPass_Vehicles_Enable",true],["Waldo_AIPass_VehicleGunnery_Enable",true],
    ["Waldo_Cortex_AirAttack_Enable",true],["Waldo_AIPass_Artillery_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_Flank_Enable",false],
    ["Waldo_AIPass_Advance_Enable",false],["Waldo_AIPass_Morale_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _infantry=east call _makeGroup;
for "_i" from 0 to 3 do {
    private _u=_infantry createUnit ["O_Soldier_F",[3600+_i*2,3600] call _terrainPosition,[],0,"NONE"];
    _u setDir _terrainHeading; _u setSkill ["spotDistance",1]; _u setSkill ["spotTime",1]; _u allowDamage false;
    _u setVariable ["Waldo_CortexQA_Label",format ["OBSERVER %1",_i+1],true]; _objects pushBack _u;
};
_infantry setCombatMode "RED";
_infantry setGroupIdGlobal ["Cortex QA observer"];
private _infantryWaypoints=count waypoints _infantry;
private _enemyGroup=west call _makeGroup;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _enemy=_enemyGroup createUnit ["B_Soldier_F",[3600,3780] call _terrainPosition,[],0,"NONE"];
_enemy setDir (_terrainHeading+180); _enemy disableAI "PATH"; _enemy allowDamage false; _enemy setVariable ["Waldo_CortexQA_Label","OBSERVED HOSTILE",true]; _objects pushBack _enemy;
private _apc=createVehicle ["O_APC_Tracked_02_cannon_F",[3200,3600] call _terrainPosition,[],0,"NONE"];
_apc setDir (_terrainHeading+90); createVehicleCrew _apc; private _apcGroup=group driver _apc; _groups pushBackUnique _apcGroup;
_apcGroup setGroupIdGlobal ["Cortex QA ground support"];
_apcGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _apcGroup setCombatMode "RED"; _apc allowDamage false;
_apc setVariable ["Waldo_CortexQA_Label","APC / independent fire support",true]; _apc setVariable ["Waldo_CortexQA_Shots",[],true];
_apc addEventHandler ["Fired",{params ["_vehicle"]; private _shots=_vehicle getVariable ["Waldo_CortexQA_Shots",[]]; _shots pushBack serverTime; _vehicle setVariable ["Waldo_CortexQA_Shots",_shots,true]}]; _objects pushBack _apc; _objects append crew _apc;
private _groundRouteTarget=[4000,3600] call _terrainPosition;
private _groundRouteStart=_apc distance2D _groundRouteTarget;
_apc limitSpeed 30;
(driver _apc) doMove _groundRouteTarget;
private _ifv=createVehicle ["O_APC_Wheeled_02_rcws_v2_F",[3200,3480] call _terrainPosition,[],0,"NONE"];
_ifv setDir (_terrainHeading+90); createVehicleCrew _ifv; private _ifvGroup=group driver _ifv; _groups pushBackUnique _ifvGroup;
_ifvGroup setGroupIdGlobal ["Cortex QA ground manoeuvre"];
_ifvGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _ifvGroup setCombatMode "RED"; _ifv allowDamage false;
_ifv setVariable ["Waldo_CortexQA_Label","IFV / safe-side manoeuvre",true]; _ifv setVariable ["Waldo_CortexQA_Shots",[],true];
_ifv addEventHandler ["Fired",{params ["_vehicle"]; private _shots=_vehicle getVariable ["Waldo_CortexQA_Shots",[]]; _shots pushBack serverTime; _vehicle setVariable ["Waldo_CortexQA_Shots",_shots,true]}];
private _ifvStart=getPosATL _ifv;
private _ifvRouteTarget=[4000,3480] call _terrainPosition;
private _ifvRouteStart=_ifv distance2D _ifvRouteTarget;
_ifv limitSpeed 30;
(driver _ifv) doMove _ifvRouteTarget;
_objects pushBack _ifv; _objects append crew _ifv;
sleep 1;
private _heli=createVehicle ["O_Heli_Attack_02_dynamicLoadout_F",[3300,3300,140] call _terrainPosition,[],0,"FLY"];
_heli setDir (_terrainHeading+45); _heli setVelocityModelSpace [0,55,0]; createVehicleCrew _heli; private _heliGroup=group driver _heli; _groups pushBackUnique _heliGroup;
_heliGroup setGroupIdGlobal ["Cortex QA air support"];
_heliGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _heliGroup setCombatMode "RED"; _heli allowDamage false;
_heli flyInHeight 140; _heli limitSpeed 170; (driver _heli) doMove ([3900,3900,140] call _terrainPosition);
_heli setVariable ["Waldo_CortexQA_Label","HELICOPTER / opportunity attack",true]; _objects pushBack _heli; _objects append crew _heli;
private _assets=[[_apcGroup,_apc,"GROUND FIRE"],[_ifvGroup,_ifv,"GROUND MANOEUVRE"],[_heliGroup,_heli,"AIR ATTACK"]];
missionNamespace setVariable ["Waldo_CortexQA_Actors",(units _infantry)+[_enemy,_apc,_ifv,_heli],true];
["DETECT",_infantry,_enemy,_assets,"No Cortex support role exists yet. The infantry must see the hostile without injected knowledge."] call _publish;
["Combined arms / 1. Detect","The observer squad must acquire the live hostile through the engine. No readiness flag, rally point or support lease is created. Cyan trails show physical travel; blue links show communication candidates, not orders.",[3600,3650] call _terrainPosition] call _phase;
["COMBINED-air-fixture-moving",!isTouchingGround _heli && {speed _heli >= 40} && {(getPosATL _heli select 2) >= 80} && {alive driver _heli},
    format ["speed=%1km/h altitude=%2m command=%3 expected=%4",round speed _heli,round (getPosATL _heli select 2),currentCommand driver _heli,expectedDestination driver _heli]] call _check;
private _seen=[{(leader _infantry knowsAbout _enemy) >= 1},35] call _wait;
["COMBINED-natural-contact",_seen,str (leader _infantry targetKnowledge _enemy)] call _check;

["DISTRIBUTE",_infantry,_enemy,_assets,"Fresh contact may be shared immediately. Each arm accepts or refuses independently."] call _publish;
["Combined arms / 2. Distribute","The fresh contact should create one short-lived opportunity. One ground vehicle provides fire, the other manoeuvres on a safe side, and the flying helicopter may attack independently; the infantry does not wait for any support asset.",[3600,3650] call _terrainPosition] call _phase;
private _opportunity=[{count (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) >= 5},25] call _wait;
["COMBINED-opportunity-created",_opportunity,str (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]])] call _check;
private _groundEntries=[
    [_apcGroup,_apc,_groundRouteTarget,_groundRouteStart,getPosATL _apc],
    [_ifvGroup,_ifv,_ifvRouteTarget,_ifvRouteStart,_ifvStart]
];
private _groundRoles=[{
    (_groundEntries findIf {((_x select 0) getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""] == "GROUND_FIRE"}) >= 0
        && {(_groundEntries findIf {((_x select 0) getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""] == "GROUND_MANOEUVRE"}) >= 0}
},20] call _wait;
private _fireIndex=_groundEntries findIf {((_x select 0) getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""] == "GROUND_FIRE"};
private _manoeuvreIndex=_groundEntries findIf {((_x select 0) getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""] == "GROUND_MANOEUVRE"};
// Keep later diagnostics safe when dispatch itself fails; the role assertions remain false and
// the fallback assets expose physical state without generating secondary null-object errors.
private _fireEntry=if (_fireIndex >= 0) then {_groundEntries select _fireIndex} else {_groundEntries select 0};
private _manoeuvreEntry=if (_manoeuvreIndex >= 0) then {_groundEntries select _manoeuvreIndex} else {_groundEntries select 1};
_fireEntry params ["_fireGroup","_fireAsset","_fireRouteTarget","_fireRouteStart","_fireStart"];
_manoeuvreEntry params ["_manoeuvreGroup","_manoeuvreAsset","_manoeuvreRouteTarget","_manoeuvreRouteStart","_manoeuvreStart"];
private _airRole=[{((_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) param [4,""]) == "AIR_ATTACK"},20] call _wait;
["COMBINED-ground-role",_groundRoles,str (_groundEntries apply {(_x select 0) getVariable ["Waldo_Cortex_CombinedRole",[]]})] call _check;
["COMBINED-ground-manoeuvre-role",_manoeuvreIndex >= 0,str (_groundEntries apply {(_x select 0) getVariable ["Waldo_Cortex_CombinedRole",[]]})] call _check;
["COMBINED-air-role",_airRole,str (_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]])] call _check;
["COMBINED-independent-feature-gates",_groundRoles && {_airRole}
    && {!(missionNamespace getVariable ["Waldo_AIPass_CoordinatedAssault_Enable",true])},
    str [_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]],_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]]] call _check;
["COMBINED-ground-applied",[{!isNull _fireGroup && {((_fireGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"}},15] call _wait,str (_fireGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;
["COMBINED-ground-manoeuvre-applied",[{!isNull _manoeuvreGroup && {((_manoeuvreGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"}},15] call _wait,str (_manoeuvreGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;
["COMBINED-air-applied",[{((_heliGroup getVariable ["Waldo_Cortex_CombinedResult",[]]) param [2,""]) == "APPLIED"},15] call _wait,str (_heliGroup getVariable ["Waldo_Cortex_CombinedResult",[]])] call _check;

["ACT",_infantry,_enemy,_assets,"Roles are finite. Watch real ground fire and the aircraft controller while the observer remains unblocked."] call _publish;
["Combined arms / 3. Act independently","The APC should physically engage without losing its authored route. The helicopter should enter its finite attack controller. A role or target assignment alone is insufficient for the physical-effect checks.",[3600,3650] call _terrainPosition] call _phase;
["COMBINED-no-infantry-assembly",
    (_infantry getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []
        && {count waypoints _infantry == _infantryWaypoints}
        && {(waypoints _infantry) findIf {waypointDescription _x == "WMP AI PASS"} < 0},
    format ["supportLease=%1 waypoints=%2",_infantry getVariable ["Waldo_AIPass_SupportLease",[]],waypoints _infantry]
] call _check;
private _groundRemaining=_fireAsset distance2D _fireRouteTarget;
private _groundState=_fireGroup getVariable ["Waldo_AIPass_State",createHashMap];
private _groundLease=_groundState getOrDefault ["movementLease",[]];
private _groundWmpWaypoint=(waypoints _fireGroup) findIf {waypointDescription _x == "WMP AI PASS"};
["COMBINED-ground-route-preserved",_groundRemaining < _fireRouteStart-50 && {_groundLease isEqualTo []} && {_groundWmpWaypoint < 0},
    format ["target=%1 startRemaining=%2m nowRemaining=%3m lease=%4 current=%5 expected=%6",
        _fireRouteTarget,round _fireRouteStart,round _groundRemaining,_groundLease,currentCommand driver _fireAsset,expectedDestination driver _fireAsset]] call _check;
["COMBINED-ground-target-shared",[{_fireGroup knowsAbout _enemy >= 2 || {!isNull assignedTarget gunner _fireAsset}},15] call _wait,
    format ["knowledge=%1 target=%2",_fireGroup knowsAbout _enemy,assignedTarget gunner _fireAsset]] call _check;
["COMBINED-ground-actual-fire",[{count (_fireAsset getVariable ["Waldo_CortexQA_Shots",[]]) > 0},20] call _wait,
    str (_fireAsset getVariable ["Waldo_CortexQA_Shots",[]])] call _check;
["COMBINED-ground-manoeuvre-physical-travel",[{_manoeuvreAsset distance2D _manoeuvreStart >= 60},35] call _wait,
    format ["travel=%1m result=%2 command=%3 expected=%4",round (_manoeuvreAsset distance2D _manoeuvreStart),
        _manoeuvreGroup getVariable ["Waldo_Cortex_CombinedResult",[]],currentCommand driver _manoeuvreAsset,expectedDestination driver _manoeuvreAsset]] call _check;
["COMBINED-air-controller-started",[{_heli getVariable ["Waldo_Cortex_AirAttackJob",false] || {(_heli getVariable ["Waldo_Cortex_AirAttackPlan",[]]) isNotEqualTo []}},20] call _wait,str (_heli getVariable ["Waldo_Cortex_AirAttackPlan",[]])] call _check;

["HANDOVER",_infantry,_enemy,_assets,"The opportunity expires by itself. No arm may leave an infantry movement lease or permanent role behind."] call _publish;
["Combined arms / 4. Handover","After the finite opportunity expires, role tokens must clear without a scheduled rally or shared completion barrier. Existing authored movement remains the owner of movement.",[3600,3650] call _terrainPosition] call _phase;
private _expired=[{
    (_infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]]) isEqualTo []
        && {(_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) isEqualTo []}
        && {(_ifvGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) isEqualTo []}
        && {(_heliGroup getVariable ["Waldo_Cortex_CombinedRole",[]]) isEqualTo []}
},45] call _wait;
["COMBINED-finite-cleanup",_expired,format ["requester=%1 ground=%2 air=%3",
    _infantry getVariable ["Waldo_Cortex_CombinedOpportunity",[]],
    [_apcGroup getVariable ["Waldo_Cortex_CombinedRole",[]],_ifvGroup getVariable ["Waldo_Cortex_CombinedRole",[]]],
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
