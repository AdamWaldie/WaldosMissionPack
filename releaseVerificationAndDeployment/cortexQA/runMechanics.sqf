/*
 * Author: WaldoTheWarfighter
 * Tests real inventory transfer, survivor travel/merge and skill application in the audit range.
 * Locality/authority: scheduled server with server-pinned disposable groups.
 * Repeat/JIP: fresh fixtures per run; caller restores settings, this script deletes its objects.
 * Arguments: check, phase, wait <CODE> callbacks; no defaults.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAMechanics.sqf";
 */
params ["_check","_phase","_wait"];
private _groups=[];
private _objects=[];
private _newGroup={
    params ["_side"];
    private _group=createGroup [_side,true];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _groups pushBack _group;
    _group
};
private _newUnit={
    params ["_group","_position","_label"];
    private _unit=_group createUnit [["O_Soldier_F","B_Soldier_F"] select (side _group == west),_position,[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",_label,true];
    _objects pushBack _unit;
    _unit
};
private _baseSettings=createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
    ["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Flank_Enable",false],
    ["Waldo_AIPass_Advance_Enable",false],["Waldo_AIPass_Reinforce_Enable",false],
    ["Waldo_AIPass_CoordinatedAssault_Enable",false],["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_FireControl_Enable",false],
    ["Waldo_AIPass_AmmoShare_Enable",false],["Waldo_AIPass_Artillery_Enable",false]
];
[_baseSettings] call Waldo_fnc_CortexTuning;
private _group=[east] call _newGroup;
private _donor=[_group,[1200,1100,0],"DONOR"] call _newUnit;
private _receiver=[_group,[1203,1100,0],"RECIPIENT"] call _newUnit;
private _enemyGroup=[west] call _newGroup;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _enemy=[_enemyGroup,[1200,1200,0],"VISIBLE CONTACT; HOLD FIRE"] call _newUnit;
{_x setCombatMode "BLUE"} forEach [_group,_enemyGroup];
{_x allowDamage false; _x disableAI "PATH"} forEach [_donor,_receiver,_enemy];
private _magazine=(primaryWeaponMagazine _donor) param [0,""];
private _compatible=compatibleMagazines primaryWeapon _donor;
{private _unit=_x; {_unit removeMagazines _x} forEach _compatible} forEach [_donor,_receiver];
{_donor addMagazine [_magazine,_x]} forEach [7,13,19,25,30];
_receiver addMagazines [_magazine,1];
private _inventory={
    params ["_unit"];
    private _spares=(magazinesAmmo _unit) select {(_x select 0) in _compatible};
    private _all=(magazinesAmmoFull _unit) select {(_x select 0) in _compatible};
    private _rounds=0;
    {_rounds=_rounds+(_x select 1)} forEach _all;
    [count _spares,_rounds]
};
private _before=[[_donor] call _inventory,[_receiver] call _inventory];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_donor,_receiver,_enemy],true];
["Ammo sharing disabled","Read the donor and recipient magazine counts above their heads. They have compatible ammunition and are within sharing distance; counts must stay unchanged while sharing is disabled.",[1200,1100,0]] call _phase;
sleep 22;
["AMMO-disabled-inventory",[[_donor] call _inventory,[_receiver] call _inventory] isEqualTo _before] call _check;
[createHashMapFromArray [["Waldo_AIPass_AmmoShare_Enable",true]]] call Waldo_fnc_CortexTuning;
["Ammo sharing enabled","The recipient must gain a real magazine from the donor. The donor carries partly used magazines. Total rounds, including loaded magazines, must remain unchanged. This checks actual inventory, not the transfer counter.",[1200,1100,0]] call _phase;
private _received=[{([_receiver] call _inventory select 0) > (_before select 1 select 0)},35] call _wait;
private _after=[[_donor] call _inventory,[_receiver] call _inventory];
["AMMO-recipient-gained",_received,str [_before,_after]] call _check;
["AMMO-rounds-conserved",(_before select 0 select 1)+(_before select 1 select 1) == (_after select 0 select 1)+(_after select 1 select 1),str [_before,_after]] call _check;
["AMMO-donor-funded-transfer",_received && {(_after select 0 select 1) < (_before select 0 select 1)} && {(_after select 1 select 1)-(_before select 1 select 1) == (_before select 0 select 1)-(_after select 0 select 1)},str [_before,_after]] call _check;
// Repeat through the scheduler after a real inventory change; never invoke the transfer helper.
[createHashMapFromArray [["Waldo_AIPass_AmmoShare_Enable",false]]] call Waldo_fnc_CortexTuning;
{_receiver removeMagazines _x} forEach _compatible;
_receiver addMagazines [_magazine,1];
private _disabledInventory=[[_donor] call _inventory,[_receiver] call _inventory];
["Ammo sharing: disable after transfer","The recipient now has one magazine again. Sharing is switched off after its first transfer; both actual inventories must remain unchanged. The next stage re-enables sharing and requires another donor-funded transfer.",[1200,1100,0]] call _phase;
sleep 22;
["AMMO-disable-after-transfer",[[_donor] call _inventory,[_receiver] call _inventory] isEqualTo _disabledInventory,str [_disabledInventory,[[_donor] call _inventory,[_receiver] call _inventory]]] call _check;
["AMMO-repeat-donor-prerequisite",(_disabledInventory select 0 select 0) >= 2,str _disabledInventory] call _check;
[createHashMapFromArray [["Waldo_AIPass_AmmoShare_Enable",true]]] call Waldo_fnc_CortexTuning;
["Ammo sharing: repeat after re-enable","Watch another real magazine move from donor to recipient. Neither a transfer flag nor a supplied replacement magazine passes: total ammunition must remain conserved.",[1200,1100,0]] call _phase;
private _repeatReceived=[{([_receiver] call _inventory select 0) > (_disabledInventory select 1 select 0)},90] call _wait;
private _repeatAfter=[[_donor] call _inventory,[_receiver] call _inventory];
["AMMO-reenable-real-transfer",_repeatReceived && {(_repeatAfter select 0 select 1) < (_disabledInventory select 0 select 1)},str [_disabledInventory,_repeatAfter]] call _check;
["AMMO-repeat-rounds-conserved",(_disabledInventory select 0 select 1)+(_disabledInventory select 1 select 1) == (_repeatAfter select 0 select 1)+(_repeatAfter select 1 select 1),str [_disabledInventory,_repeatAfter]] call _check;
sleep 15;
{deleteVehicle _x} forEach _objects; {deleteGroup _x} forEach _groups;
_objects=[]; _groups=[];

[createHashMapFromArray [["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Regroup_Enable",true]]] call Waldo_fnc_CortexTuning;
private _remnant=[east] call _newGroup;
private _host=[east] call _newGroup;
private _remnantUnits=[];
for "_i" from 0 to 3 do {_remnantUnits pushBack ([_remnant,[1200+_i*2,1100,0],format ["ORIGINAL SQUAD %1",_i+1]] call _newUnit)};
for "_i" from 0 to 3 do {private _unit=[_host,[1200+_i*2,1190,0],format ["HOST SQUAD %1",_i+1]] call _newUnit; _unit disableAI "PATH"};
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
["Survivor regroup","Two casualties will leave two survivors. The survivors must physically walk toward the host squad 90 m north, then join it. Joining from their starting position fails this case.",[1200,1140,0]] call _phase;
private _survivors=_remnantUnits select [2,2];
private _starts=_survivors apply {getPosATL _x};
{_x setDamage 1} forEach (_remnantUnits select [0,2]);
// Sample physical progress and order ownership without changing the movement being tested.
private _nextRegroupSample=0;
private _regroupClosest=_survivors apply {_x distance2D leader _host};
private _joined=[{
    {
        _regroupClosest set [_forEachIndex,(_regroupClosest select _forEachIndex) min (_x distance2D leader _host)];
    } forEach _survivors;
    if (time >= _nextRegroupSample) then {
        _nextRegroupSample=time+10;
        diag_log format ["WMP CORTEX REGROUP SAMPLE|leader=%1 alive=%2 queued=%3 host=%4 actors=%5",
            leader _remnant,alive leader _remnant,_remnant getVariable ["Waldo_AIPass_RegroupQueued",false],
            _remnant getVariable ["Waldo_AIPass_RegroupHost",grpNull],
            _survivors apply {[getPosATL _x,group _x,currentCommand _x,expectedDestination _x,
                _x checkAIFeature "PATH",behaviour _x,speed _x,_x distance2D leader _host]}];
    };
    _survivors findIf {group _x != _host} < 0
},140] call _wait;
private _walked=true;
{if (_x distance2D (_starts select _forEachIndex) < 45 || {_x distance2D leader _host > 35}) then {_walked=false}} forEach _survivors;
["REGROUP-physical-approach",_walked,format ["positions=%1 closestHostDistances=%2",_survivors apply {getPosATL _x},_regroupClosest]] call _check;
["REGROUP-membership-after-travel",_joined && {_walked}] call _check;
sleep 20;
{deleteVehicle _x} forEach _objects; {deleteGroup _x} forEach _groups;
_objects=[]; _groups=[];

// A fresh remnant tests interruption independently of the preceding arrival outcome.
private _interruptRemnant=[east] call _newGroup;
private _interruptHost=[east] call _newGroup;
private _interruptUnits=[];
for "_i" from 0 to 3 do {_interruptUnits pushBack ([_interruptRemnant,[1200+_i*2,1100,0],format ["HANDOVER REMNANT %1",_i+1]] call _newUnit)};
for "_i" from 0 to 3 do {private _unit=[_interruptHost,[1200+_i*2,1190,0],format ["FORMER HOST %1",_i+1]] call _newUnit; _unit disableAI "PATH"};
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
["Regroup interruption setup","A fresh remnant begins a real survivor-regroup job. The next stage replaces that job with an eastward order; this setup flag alone is not movement acceptance.",[1200,1140,0]] call _phase;
private _interruptSurvivors=_interruptUnits select [2,2];
{_x setDamage 1} forEach (_interruptUnits select [0,2]);
private _mergeStarted=[{(_interruptRemnant getVariable ["Waldo_AIPass_RegroupHost",grpNull]) == _interruptHost},25] call _wait;
["REGROUP-Zeus-active-job-prerequisite",_mergeStarted,str [
    _interruptRemnant getVariable ["Waldo_AIPass_Adopted",false],
    _interruptRemnant getVariable ["Waldo_AIPass_Epoch",0],
    _interruptRemnant getVariable ["Waldo_AIPass_RegroupQueued",false],
    _interruptRemnant getVariable ["Waldo_AIPass_RegroupHost",grpNull],
    _interruptRemnant getVariable ["Waldo_AIPass_PeakSize",0]]] call _check;
private _replacement=[1300,1100,0];
private _interruptOrigins=_interruptSurvivors apply {getPosATL _x};
private _replacementWaypoint=_interruptRemnant addWaypoint [_replacement,0];
_replacementWaypoint setWaypointType "MOVE";
_replacementWaypoint setWaypointCompletionRadius 5;
[_interruptRemnant,true] call Waldo_fnc_CortexZeusMark;
["Regroup replaced by Zeus order","Both survivors must travel east to the replacement destination, remain in their own group, and stop trying to join the northern host. This exercises the ownership handler; actual curator mouse input is a separate test.",_replacement] call _phase;
private _replacementArrived=[{
    _interruptSurvivors findIf {!alive _x || {group _x != _interruptRemnant} || {_x distance2D _replacement > 20}} < 0
},100] call _wait;
private _replacementTravel=true;
{if (_x distance2D (_interruptOrigins select _forEachIndex) < 50) then {_replacementTravel=false}} forEach _interruptSurvivors;
["REGROUP-Zeus-physical-replacement",_mergeStarted && {_replacementArrived} && {_replacementTravel},str (_interruptSurvivors apply {getPosATL _x})] call _check;
private _replacementStable=_replacementArrived;
for "_sample" from 1 to 10 do {
    sleep 1;
    if (_interruptRemnant getVariable ["Waldo_AIPass_RegroupQueued",false] || {
        _interruptSurvivors findIf {!alive _x || {group _x != _interruptRemnant} || {_x distance2D _replacement > 25}} >= 0
    }) then {_replacementStable=false};
};
["REGROUP-Zeus-no-merge-resurrection",_mergeStarted && {_replacementStable}] call _check;
{deleteVehicle _x} forEach _objects; {deleteGroup _x} forEach _groups;
_objects=[]; _groups=[];

// Real detection drives the post-contact state machine; no state or completion is injected.
[createHashMapFromArray [["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_PostContact_Enable",true]]] call Waldo_fnc_CortexTuning;
private _flowGroup=[east] call _newGroup;
private _flowLeader=[_flowGroup,[1200,1100,0],"CONSOLIDATION LEADER"] call _newUnit;
private _flowMembers=[_flowLeader];
{
    private _member=[_flowGroup,_x,format ["RETURNING MEMBER %1",_forEachIndex+1]] call _newUnit;
    doStop _member;
    _flowMembers pushBack _member;
} forEach [[1150,1100,0],[1250,1100,0],[1200,1050,0]];
private _flowEnemyGroup=[west] call _newGroup;
_flowEnemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _flowEnemy=[_flowEnemyGroup,[1200,1180,0],"CONTACT TO BE REMOVED"] call _newUnit;
{_x setCombatMode "BLUE"} forEach [_flowGroup,_flowEnemyGroup];
{_x allowDamage false} forEach (_flowMembers+[_flowEnemy]);
_flowEnemy disableAI "PATH";
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
["Post-contact detection","The spread squad must detect the visible opposing soldier. The enemy is then removed; watch security, search and consolidation. Lines show actual distance to the squad leader.",[1200,1100,0]] call _phase;
private _detected=[{((_flowGroup getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT"},40] call _wait;
["POST-real-contact",_detected] call _check;
deleteVehicle _flowEnemy;
["Post-contact consolidation","The squad must finish its search and physically gather within 20 m of its leader. A timeout or an INCOMPLETE status fails. Watch the member distances and cyan movement trails.",[1200,1100,0]] call _phase;
private _consolidated=[{
    private _flow=_flowGroup getVariable ["Waldo_Cortex_Consolidation",[]];
    _flow isNotEqualTo [] && {(_flow select 0) in ["COHESIVE","INCOMPLETE"]}
},150] call _wait;
private _together=_flowMembers findIf {!alive _x || {_x distance2D _flowLeader > 20}} < 0;
["POST-physical-consolidation",_detected && {_consolidated} && {_together},str (_flowMembers apply {
    [_x distance2D _flowLeader,currentCommand _x,expectedDestination _x,_x checkAIFeature "MOVE"]
})] call _check;
["POST-cohesion-outcome",((_flowGroup getVariable ["Waldo_Cortex_Consolidation",[]]) param [0,""]) == "COHESIVE"] call _check;
private _zeusTarget=[1200,1260,0];
private _zeusWaypoint=_flowGroup addWaypoint [_zeusTarget,0];
_zeusWaypoint setWaypointType "MOVE";
_zeusWaypoint setWaypointCompletionRadius 5;
[_flowGroup,true] call Waldo_fnc_CortexZeusMark;
["Zeus order handover","The same squad now receives a waypoint through the Zeus ownership marker. All four must travel north and remain together; Cortex must not pull them back to the previous engagement.",_zeusTarget] call _phase;
private _zeusArrived=[{_flowMembers findIf {!alive _x || {_x distance2D _zeusTarget > 25}} < 0},100] call _wait;
["FLOW-Zeus-physical-arrival",_zeusArrived,str (_flowMembers apply {getPosATL _x})] call _check;
private _replacementHeld=_zeusArrived;
private _maximumReturnDistance=0;
for "_sample" from 1 to 10 do {
    sleep 1;
    {
        _maximumReturnDistance=_maximumReturnDistance max (_x distance2D _zeusTarget);
        if (!alive _x || {_x distance2D _zeusTarget > 35}) then {_replacementHeld=false};
    } forEach _flowMembers;
};
["FLOW-Zeus-cohesion-held",_flowMembers findIf {!alive _x || {_x distance2D leader _flowGroup > 25}} < 0] call _check;
["FLOW-Zeus-replacement-destination-held",_replacementHeld,format ["initialArrival=%1 maximumDestinationDistance=%2",_zeusArrived,_maximumReturnDistance]] call _check;
{deleteVehicle _x} forEach _objects; {deleteGroup _x} forEach _groups;
_objects=[]; _groups=[];

[createHashMapFromArray [["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIRebalance_Enable",true],["Waldo_AIRebalance_Profile","MILITIA"]]] call Waldo_fnc_CortexTuning;
private _skillGroup=[east] call _newGroup;
private _skillUnit=[_skillGroup,[1200,1100,0],"SKILL PROFILE COMPARISON"] call _newUnit;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_skillUnit],true];
["Skill profile: militia","Read the actual engine aiming skill above the soldier. The next step applies Elite and must change that measured value.",[1200,1100,0]] call _phase;
sleep 5;
private _militia=_skillUnit skill "aimingAccuracy";
[createHashMapFromArray [["Waldo_AIRebalance_Profile","ELITE"]]] call Waldo_fnc_CortexTuning;
["Skill profile: elite","Actual aiming accuracy must differ from the recorded militia value. A profile name or applied flag alone does not pass.",[1200,1100,0]] call _phase;
private _skillChanged=[{abs ((_skillUnit skill "aimingAccuracy")-_militia) > 0.001},20] call _wait;
["SKILL-actual-value-changed",_skillChanged,format ["militia=%1 elite=%2",_militia,_skillUnit skill "aimingAccuracy"]] call _check;
private _crewVehicle=createVehicle ["O_APC_Tracked_02_cannon_F",[1240,1100,0],[],0,"NONE"];
private _crewGroup=east createVehicleCrew _crewVehicle;
_groups pushBack _crewGroup;
private _operatingCrew=crew _crewVehicle;
{_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]; _objects pushBack _x} forEach _operatingCrew;
_objects pushBack _crewVehicle;
private _cargoGroup=[east] call _newGroup;
private _cargo=[_cargoGroup,[1245,1100,0],"VEHICLE CARGO PROFILE"] call _newUnit;
_cargo moveInCargo _crewVehicle;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_skillUnit,_crewVehicle],true];
["Skill profile: operating crew and cargo","Vehicle operators must retain the selected Elite profile at lower precision. Cargo must keep the ordinary infantry profile. The label is backed by measured skills and aim coefficient, not vehicle occupancy alone.",getPosATL _crewVehicle] call _phase;
private _crewApplied=[{
    _operatingCrew findIf {
        toUpperANSI ((assignedVehicleRole _x) param [0,""]) != "CARGO"
            && {(_x skill "aimingAccuracy") >= (_skillUnit skill "aimingAccuracy")}
    } < 0 && {abs ((_cargo skill "aimingAccuracy")-(_skillUnit skill "aimingAccuracy")) < 0.02}
},20] call _wait;
["SKILL-vehicle-crew-profile",_crewApplied,format ["infantry=%1 crew=%2 cargo=%3",_skillUnit skill "aimingAccuracy",_operatingCrew apply {_x skill "aimingAccuracy"},_cargo skill "aimingAccuracy"]] call _check;
private _lambsTurrets=isClass (configFile >> "CfgPatches" >> "lambs_turrets");
private _dispersionApplied=_operatingCrew findIf {
    private _original=_x getVariable ["Waldo_AI_OriginalAimCoef",getCustomAimCoef _x];
    if (_lambsTurrets) then {abs (getCustomAimCoef _x-_original) > 0.01} else {getCustomAimCoef _x <= _original}
} < 0;
["SKILL-vehicle-dispersion-layer",_dispersionApplied,format ["lambsTurrets=%1 coefficients=%2",_lambsTurrets,_operatingCrew apply {[getCustomAimCoef _x,_x getVariable ["Waldo_AI_OriginalAimCoef",-1]]}]] call _check;
private _airVehicle=createVehicle ["O_Heli_Light_02_dynamicLoadout_F",[1260,1140,0],[],0,"NONE"];
private _airGroup=east createVehicleCrew _airVehicle;
_groups pushBack _airGroup;
private _airCrew=crew _airVehicle;
{_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]; _objects pushBack _x} forEach _airCrew;
_objects pushBack _airVehicle;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_skillUnit,_crewVehicle,_airVehicle],true];
["Skill profile: infantry, ground and air dispersion","Read the measured aim coefficients. Dismounted infantry and cargo receive the modest infantry layer; ground operators receive the wider vehicle layer; aircraft operators receive the widest ordinary layer. LAMBS Turrets replaces the two vehicle layers when loaded.",getPosATL _airVehicle] call _phase;
private _layeredDispersion=[{
    private _infantryOriginal=_skillUnit getVariable ["Waldo_AI_OriginalAimCoef",getCustomAimCoef _skillUnit];
    private _cargoOriginal=_cargo getVariable ["Waldo_AI_OriginalAimCoef",getCustomAimCoef _cargo];
    private _infantryOk=getCustomAimCoef _skillUnit > _infantryOriginal && {getCustomAimCoef _cargo > _cargoOriginal};
    private _vehicleOk=if (_lambsTurrets) then {true} else {
        (_operatingCrew findIf {getCustomAimCoef _x <= getCustomAimCoef _skillUnit}) < 0
    };
    private _airOk=if (_lambsTurrets) then {true} else {
        (_airCrew findIf {getCustomAimCoef _x <= getCustomAimCoef (_operatingCrew select 0)}) < 0
    };
    _infantryOk && {_vehicleOk} && {_airOk}
},20] call _wait;
["SKILL-layered-dispersion",_layeredDispersion,format ["infantry=%1 cargo=%2 ground=%3 air=%4 lambsTurrets=%5",getCustomAimCoef _skillUnit,getCustomAimCoef _cargo,_operatingCrew apply {getCustomAimCoef _x},_airCrew apply {getCustomAimCoef _x},_lambsTurrets]] call _check;
private _aaVehicle=createVehicle ["O_APC_Tracked_02_AA_F",[1280,1100,0],[],0,"NONE"];
_aaVehicle setVariable ["Waldo_DynamicAA_SystemId","CORTEX_QA_AA",true];
private _aaGroup=east createVehicleCrew _aaVehicle;
_groups pushBack _aaGroup;
private _aaCrew=crew _aaVehicle;
{_x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]; _objects pushBack _x} forEach _aaCrew;
_objects pushBack _aaVehicle;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_crewVehicle,_aaVehicle],true];
["Skill profile: Dynamic AA preservation","The ordinary APC shows the configured general crew reduction. The marked Dynamic AA vehicle must retain the selected profile and its original aim coefficient because its own network controls detection and fire.",getPosATL _aaVehicle] call _phase;
private _aaPreserved=[{
    _aaCrew findIf {
        private _original=_x getVariable ["Waldo_AI_OriginalAimCoef",-1];
        _original < 0 || {abs (getCustomAimCoef _x-_original) > 0.01}
            || {(_x skill "aimingAccuracy") <= (((_operatingCrew select 0) skill "aimingAccuracy")+0.02)}
    } < 0
},20] call _wait;
["SKILL-dynamic-aa-preserved",_aaPreserved,format ["ordinaryCrew=%1 dynamicAA=%2",_operatingCrew apply {[_x skill "aimingAccuracy",getCustomAimCoef _x]},_aaCrew apply {[_x skill "aimingAccuracy",getCustomAimCoef _x,_x getVariable ["Waldo_AI_OriginalAimCoef",-1]]}]] call _check;
sleep 15;
{deleteVehicle _x} forEach _objects; {deleteGroup _x} forEach _groups;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
