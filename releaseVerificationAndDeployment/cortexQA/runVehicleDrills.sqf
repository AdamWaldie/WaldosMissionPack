/*
 * Author: WaldoTheWarfighter
 * Checks contact dismount, calm remount and damaged-armour withdrawal using live vehicles, including
 * an active withdrawal migrating from the server to a real headless owner before Zeus replacement.
 * Locality/authority: scheduled server creates disposable fixtures; production Cortex code commands
 * each current owner, and the migration case deliberately transfers its crew group and vehicle.
 * Repeat/JIP: fresh fixtures and public observer state; caller restores tuning, actors are deleted.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>, required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAVehicles.sqf";
 */
params ["_check","_phase","_wait"];
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_LambsMode","WMP"],
    ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_Flank_Enable",false],["Waldo_AIPass_Advance_Enable",false],
    ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_ContactReports_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_CoordinatedAssault_Enable",false],
    ["Waldo_AIPass_Artillery_Enable",false],["Waldo_AIPass_FireControl_Enable",false],
    ["Waldo_AIPass_Vehicles_Enable",true],["Waldo_AIPass_VehicleDismount_Enable",false],
    ["Waldo_AIPass_VehicleRemount_Enable",true],["Waldo_AIPass_VehicleWithdraw_Enable",false],
    ["Waldo_AIPass_VehicleGunnery_Enable",false],["Waldo_AIPass_PostContact_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _pin={params ["_group"]; _group setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _group setVariable ["acex_headless_blacklist",true,true]; {_x setVariable ["acex_headless_blacklist",true,true]} forEach units _group};
private _recordVehicleCheck = _check;
{
_x params ["_separate","_freshEnabled",["_nativeBaseline",false],["_stationary",false],["_replacementOrder",false]];
private _layout = ["shared crew/passenger group","separate passenger squad"] select _separate;
private _check = {params ["_id","_passed",["_detail",""]]; [(["","REPLACEMENT-"] select _replacementOrder)+(["","STATIONARY-"] select _stationary)+(["","NATIVE-"] select _nativeBaseline)+(["","FRESH-"] select _freshEnabled)+(["","SEPARATE-"] select _separate)+_id,_passed,_detail] call _recordVehicleCheck};
[createHashMapFromArray [["Waldo_AIPass_Enable",!_nativeBaseline],["Waldo_AIPass_VehicleDismount_Enable",false]]] call Waldo_fnc_CortexTuning;
private _truck=createVehicle ["O_Truck_03_transport_F",[1900,1100,0],[],0,"NONE"];
createVehicleCrew _truck;
// Additive safe-stop comparison; keep the original unrestricted fixtures intact.
// This isolated safe-exit fixture deliberately holds only the driver pathing.
// Passenger pathing and detection remain native. Unrestricted cases above/below
// still assess real driver decisions; this fixture cannot establish convoy behaviour.
if (_stationary) then {(driver _truck) disableAI "PATH"};
private _group=group driver _truck;
[_group] call _pin;
_group setCombatMode "BLUE";
_truck allowDamage false;
private _passengerGroup = if (_separate) then {createGroup [east,true]} else {_group};
[_passengerGroup] call _pin; _passengerGroup setCombatMode "BLUE";
private _passengers=[];
for "_i" from 0 to 1 do {
    private _unit=_passengerGroup createUnit ["O_Soldier_F",[1900+_i*3,1090,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["%1 | PASSENGER %2",_layout,_i+1],true];
    _unit allowDamage false;
    _unit assignAsCargo _truck; [_unit] orderGetIn true; _unit moveInCargo _truck;
    _passengers pushBack _unit;
};
private _crew=[driver _truck];
_truck addEventHandler ["GetOut",{
    params ["_vehicle","_role","_unit","_turret"];
    private _group=group _unit;
    private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
    private _records=_state getOrDefault ["dismounted",[]];
    private _issued=_records findIf {(_x select 0) == _unit && {(_x select 1) == _vehicle}} >= 0;
    diag_log format ["WMP CORTEX QA PASSENGER EXIT|unit=%1 role=%2 turret=%3 group=%4 phase=%5 cortexIssued=%6 dismountEnabled=%7 speed=%8 command=%9 assigned=%10",
        netId _unit,_role,_turret,_group,_state getOrDefault ["phase",""],_issued,
        [_group,"Waldo_AIPass_VehicleDismount_Enable",true] call Waldo_fnc_CortexFeatureEnabled,
        speed _vehicle,currentCommand _unit,assignedVehicle _unit];
    _unit setVariable ["Waldo_CortexQA_Label",format ["EXIT | %1 | Cortex order %2 | %3",_role,_issued,_state getOrDefault ["phase",""]],true];
}];
// Independent enabled runs start occupied before introducing contact. The original
// disabled-to-enabled sequence remains intact to expose unexpected native exits.
private _enabledStartedMounted=_passengers findIf {!alive _x || {vehicle _x != _truck}} < 0;
if (_freshEnabled) then {
    [createHashMapFromArray [["Waldo_AIPass_VehicleDismount_Enable",true]]] call Waldo_fnc_CortexTuning;
};
// Establish controller readiness before exposing the fresh fixture to enemies.
// No feature-state injection: wait for ordinary discovery to adopt both groups.
if (!_nativeBaseline) then {
    private _ready=[{
        missionNamespace getVariable ["Waldo_AIPass_Active",false]
            && {_group getVariable ["Waldo_AIPass_Managed",false]}
            && {_passengerGroup getVariable ["Waldo_AIPass_Managed",false]}
    },30] call _wait;
    ["DISMOUNT-fixture-controller-ready",_ready,"Both crew and passenger jobs must be adopted before contact"] call _check;
};
private _enemyGroup=createGroup [west,true]; [_enemyGroup] call _pin;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true]; _enemyGroup setCombatMode "BLUE";
private _enemy=_enemyGroup createUnit ["B_Soldier_F",[1900,1220,0],[],0,"NONE"];
_enemy setVariable ["acex_headless_blacklist",true,true]; _enemy allowDamage false; _enemy disableAI "PATH";
// Rear-facing cargo must have a real visible threat too; do not inject shared knowledge.
private _rearEnemy = _enemyGroup createUnit ["B_Soldier_F",[1900,980,0],[],0,"NONE"];
_rearEnemy setVariable ["acex_headless_blacklist",true,true]; _rearEnemy allowDamage false; _rearEnemy disableAI "PATH";
private _opponents = [_enemy,_rearEnemy];
missionNamespace setVariable ["Waldo_CortexQA_Actors",_passengers+_crew+_opponents,true];
[(["","Native AI baseline: "] select _nativeBaseline)+(["Vehicle dismount disabled: ","Fresh enabled dismount: "] select _freshEnabled)+_layout,(["Observe native seat retention while Cortex dismount is disabled; any engine exit must remain unattributed to Cortex.","A fresh occupied truck tests enabled contact dismount independently of earlier retention observations."] select _freshEnabled)+" Visible opponents are ahead and behind for driver and cargo sightlines.",[1900,1100,0]] call _phase;
private _passengerSamples=[];
private _nextPassengerSample=0;
private _driverDetected=false;
private _passengersDetected=false;
private _contactSeen=[{
    _driverDetected=_driverDetected || {(_opponents findIf {(_crew select 0) knowsAbout _x > 1}) >= 0};
    _passengersDetected=_passengersDetected || {(_opponents findIf {leader _passengerGroup knowsAbout _x > 1}) >= 0};
    if (diag_tickTime >= _nextPassengerSample && {count _passengerSamples < 20}) then {
        _nextPassengerSample=diag_tickTime+2;
        _passengerSamples pushBack [serverTime,speed _truck,
            _passengers apply {[netId _x,vehicle _x == _truck,currentCommand _x,[_x,_truck] call Waldo_fnc_CortexPassengerReady]},
            [_group,_passengerGroup] apply {private _sampleGroup=_x; [_sampleGroup,(_sampleGroup getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""],(_opponents apply {leader _sampleGroup knowsAbout _x})]}];
    };
private _crewSees=(_opponents findIf {(_crew select 0) knowsAbout _x > 1}) >= 0;
private _passengersSee=(_opponents findIf {leader _passengerGroup knowsAbout _x > 1}) >= 0;
_crewSees && {!_separate || {_passengersSee}}},30] call _wait;
{diag_log format ["WMP CORTEX QA PASSENGER SAMPLE %1 [time,speed,occupants,groupKnowledge]: %2",_forEachIndex,_x]} forEach _passengerSamples;
["DISMOUNT-fixture-natural-contact",_contactSeen,["Shared occupants must naturally detect an opponent","The crew must naturally detect an opponent; the separate passenger squad intentionally relies on the bounded crew report"] select _separate] call _check;
["DISMOUNT-driver-detected-contact",_driverDetected,"Measured separately: a crew report cannot originate without crew detection"] call _check;
diag_log format ["WMP CORTEX QA ONBOARD CONTACT: separate=%1 native=%2 driverDetected=%3 passengersDetected=%4 crewReport=%5",
    _separate,_nativeBaseline,_driverDetected,_passengersDetected,_truck getVariable ["Waldo_Cortex_OnboardReport",[]]];
if (!_freshEnabled) then {
    sleep 15;
    private _disabledRecords=([_passengerGroup] call Waldo_fnc_CortexGroupState) getOrDefault ["dismounted",[]];
    ["DISMOUNT-disabled-no-controller-order",_disabledRecords isEqualTo [],format ["mounted=%1; native Arma may independently order a shared crew/passenger group out",_passengers findIf {vehicle _x != _truck} < 0]] call _check;
    _enabledStartedMounted=_passengers findIf {!alive _x || {vehicle _x != _truck}} < 0;
};
if (_nativeBaseline) then {
    // Preserve the real engine-only retention result. Do not force occupants back in
    // or run enabled transitions on this fixture; compare with the Cortex cases.
    diag_log format ["WMP CORTEX QA NATIVE PASSENGERS|separate=%1 occupants=%2",_separate,_passengers apply {[netId _x,vehicle _x,currentCommand _x]}];
} else {
if (!_enabledStartedMounted) then {
    // This legacy disabled-to-enabled comparison remains additive, but a native exit has already
    // consumed its precondition. Do not mislabel that engine action as a Cortex failure; the fresh
    // enabled fixtures below remain the authoritative transition cases.
    private _unowned=([_passengerGroup] call Waldo_fnc_CortexGroupState) getOrDefault ["dismounted",[]];
    ["DISMOUNT-native-exit-not-misattributed",_unowned isEqualTo [],"Enabled transition skipped because occupants had already left under native control"] call _check;
} else {
["DISMOUNT-enabled-starts-mounted",_enabledStartedMounted,"Passengers already outside cannot prove an enabled dismount transition"] call _check;
[createHashMapFromArray [["Waldo_AIPass_VehicleDismount_Enable",true]]] call Waldo_fnc_CortexTuning;
["Vehicle contact dismount: "+_layout,"Both passengers must physically exit after the feature is enabled. The driver must remain in the truck.",[1900,1100,0]] call _phase;
private _peakExitSpeed=0;
private _safeStopObserved=false;
private _dismounted=[{
    _peakExitSpeed=_peakExitSpeed max abs speed _truck;
    _safeStopObserved=_safeStopObserved || {abs speed _truck < 1};
    _passengers findIf {!alive _x || {vehicle _x != _x}} < 0
},35] call _wait;
["DISMOUNT-fixture-safe-stop-observed",_safeStopObserved,format ["peakSpeed=%1 stationaryRequested=%2",_peakExitSpeed,_stationary]] call _check;
if (_stationary) then {["DISMOUNT-fixture-stationary-held",_peakExitSpeed < 1,format ["peakSpeed=%1; movement invalidates the stationary comparison",_peakExitSpeed]] call _check};
["DISMOUNT-contact-physical-exit",_contactSeen && {_enabledStartedMounted} && {_dismounted},format ["startedMounted=%1 endedDismounted=%2",_enabledStartedMounted,_dismounted]] call _check;
private _recorded=([_passengerGroup] call Waldo_fnc_CortexGroupState) getOrDefault ["dismounted",[]];
private _ownedExit=_passengers findIf {private _unit=_x; _recorded findIf {(_x select 0) == _unit && {(_x select 1) == _truck}} < 0} < 0;
["DISMOUNT-controller-attribution-valid",_ownedExit || {!_separate},["A shared group may execute its native exit first; Cortex does not claim or remount an unowned exit","The separate passenger case must record every exit before issuing it"] select _separate] call _check;
if (_separate) then {
    ["DISMOUNT-crew-report-physical-exit",_driverDetected && {_enabledStartedMounted} && {_dismounted} && {_ownedExit},
        format ["crewContact=%1 passengerContact=%2 physicalExit=%3 controllerOwned=%4 safeStop=%5",_driverDetected,_passengersDetected,_dismounted,_ownedExit,_safeStopObserved]] call _check;
};
["DISMOUNT-driver-retained",vehicle (_crew select 0) == _truck] call _check;
{deleteVehicle _x} forEach _opponents;
if (!_ownedExit) then {
    ["REMOUNT-unowned-native-exit-not-reclaimed",(_passengerGroup getVariable ["Waldo_Cortex_Remount",[]]) isEqualTo [],"Cortex must not overwrite an exit it did not initiate"] call _check;
} else {
if (_replacementOrder) then {
    private _replacement=createVehicle ["O_Truck_03_transport_F",_truck getPos [25,90],[],0,"NONE"];
    _replacement allowDamage false;
    // A genuine external boarding order: no seat teleport, state flag or cleanup call.
    {_x assignAsCargo _replacement; [_x] orderGetIn true} forEach _passengers;
    ["Replacement passenger order","After a Cortex dismount, another script orders the squad into the second truck. They must walk and board it; calm restoration must never send them back to the original truck.",getPosATL _replacement] call _phase;
    private _replacementPreserved=true;
    private _replacementBoarded=[{
        if (_passengers findIf {assignedVehicle _x != _replacement || {vehicle _x == _truck}} >= 0) then {_replacementPreserved=false};
        _passengers findIf {vehicle _x != _replacement} < 0
    },100] call _wait;
    // Observe beyond the normal contact-loss delay, including after successful boarding.
    for "_sample" from 1 to 40 do {
        sleep 1;
        if (_passengers findIf {assignedVehicle _x != _replacement || {vehicle _x == _truck}} >= 0) then {_replacementPreserved=false};
    };
    private _ownedExit=_passengers findIf {private _passenger=_x; _recorded findIf {(_x select 0) == _passenger && {(_x select 1) == _truck}} < 0} < 0;
    ["REMOUNT-replacement-assignment-preserved",_enabledStartedMounted && {_dismounted} && {_ownedExit} && {_replacementPreserved},str (_passengers apply {[assignedVehicle _x,vehicle _x,currentCommand _x]})] call _check;
    ["REMOUNT-replacement-physically-boarded",_ownedExit && {_replacementBoarded} && {_passengers findIf {vehicle _x != _replacement} < 0}] call _check;
    {deleteVehicle _x} forEach _passengers;
    deleteVehicle _replacement;
} else {
["Vehicle calm remount: "+_layout,"The enemy is removed. Once contact expires, both recorded passengers must physically board the same truck again. The test never moves them into seats.",[1900,1100,0]] call _phase;
private _remounted=[{_passengers findIf {!alive _x || {vehicle _x != _truck}} < 0},100] call _wait;
["REMOUNT-physical-seat-occupancy",_enabledStartedMounted && {_dismounted} && {_remounted},
    str ["previouslyDismounted",_dismounted,_passengerGroup getVariable ["Waldo_Cortex_Remount",[]],_passengers apply {[vehicle _x,assignedVehicle _x,currentCommand _x]}]] call _check;
["REMOUNT-group-membership-independent",_passengers findIf {group _x != _passengerGroup} < 0
    && {group (_crew select 0) == _group} && {(_passengerGroup != _group) isEqualTo _separate},
    "Membership is measured independently of seat occupancy; the original combined check follows"] call _check;
["REMOUNT-original-groups-retained",_enabledStartedMounted && {_remounted} && {_dismounted}
    && {_passengers findIf {group _x != _passengerGroup} < 0}
    && {group (_crew select 0) == _group}
    && {(_passengerGroup != _group) isEqualTo _separate},
    str [_separate,group (_crew select 0),_passengers apply {group _x}]] call _check;
};
};
};
};
{deleteVehicle _x} forEach (_passengers+_crew+_opponents+[_truck]); deleteGroup _group; if (_separate) then {deleteGroup _passengerGroup}; deleteGroup _enemyGroup;

} forEach [[false,false,true],[true,false,true],[false,false],[true,false],[false,true],[true,true],[false,true,false,true],[true,true,false,true],[true,true,false,true,true]];

[createHashMapFromArray [["Waldo_AIPass_VehicleDismount_Enable",false],["Waldo_AIPass_VehicleWithdraw_Enable",false]]] call Waldo_fnc_CortexTuning;
private _armour=createVehicle ["O_APC_Tracked_02_cannon_F",[1900,1100,0],[],0,"NONE"];
createVehicleCrew _armour;
private _group=group driver _armour; [_group] call _pin;
_group setCombatMode "BLUE";
private _crew=crew _armour;
{_x allowDamage false; _x setVariable ["Waldo_CortexQA_Label","WITHDRAWING CREW",true]} forEach _crew;
private _enemyGroup=createGroup [west,true]; [_enemyGroup] call _pin;
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true]; _enemyGroup setCombatMode "BLUE";
private _enemy=_enemyGroup createUnit ["B_Soldier_F",[1900,1250,0],[],0,"NONE"];
_enemy setVariable ["acex_headless_blacklist",true,true]; _enemy allowDamage false; _enemy disableAI "PATH";
// Compare independent engine/config views before attributing an empty inventory to the controller.
diag_log format ["WMP CORTEX QA ARMOUR IDENTITY: class=%1 config=%2 simulation=%3 simple=%4 crew=%5 allTurrets=%6 fullCrew=%7 magazines=%8",
    typeOf _armour,configName (configOf _armour),simulationEnabled _armour,isSimpleObject _armour,
    crew _armour,allTurrets _armour,fullCrew [_armour,"",true],magazinesAllTurrets _armour];
diag_log format ["WMP CORTEX QA ARMOUR CONFIG TURRETS: %1",("true" configClasses (configOf _armour >> "Turrets")) apply {
    [configName _x,getArray (_x >> "weapons"),getArray (_x >> "magazines")]
}];
private _smokeReady=[{
    ([[-1]]+allTurrets [_armour,true]) findIf {
        private _turret=_x;
        (_armour weaponsTurret _turret) findIf {toLowerANSI (getText (configFile >> "CfgWeapons" >> _x >> "simulation")) == "cmlauncher"} >= 0
            && {(_armour magazinesTurret _turret) isNotEqualTo []}
    } >= 0
},10] call _wait;
["WITHDRAW-smoke-inventory-prerequisite",_smokeReady,format ["class=%1 owner=%2 turrets=%3",typeOf _armour,owner _armour,allTurrets [_armour,true]]] call _check;
diag_log format ["WMP CORTEX QA COUNTERMEASURE CONFIG: %1",([[-1]]+allTurrets [_armour,true]) apply {
    private _turret=_x;
    [_turret,(_armour weaponsTurret _turret) apply {[_x,getText (configFile >> "CfgWeapons" >> _x >> "simulation")]},_armour magazinesTurret _turret]
}];
_armour addEventHandler ["Fired",{
    params ["_vehicle","_weapon","_muzzle","_mode","_ammo","_magazine"];
    diag_log format ["WMP CORTEX QA VEHICLE FIRED: weapon=%1 muzzle=%2 ammo=%3 magazine=%4",_weapon,_muzzle,_ammo,_magazine];
    if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") == "cmlauncher") then {_vehicle setVariable ["Waldo_CortexQA_SmokeShots",(_vehicle getVariable ["Waldo_CortexQA_SmokeShots",0])+1,true]};
}];
missionNamespace setVariable ["Waldo_CortexQA_Actors",_crew+[_enemy],true];
private _origin=getPosATL _armour;
_armour setDamage 0.55;
["WITHDRAW-mobile-damaged-fixture",alive _armour && {canMove _armour} && {damage _armour >= 0.5}] call _check;
["Damaged armour: withdrawal disabled","The damaged but mobile APC must hold while withdrawal is disabled. The crew must naturally detect the visible opponent before the enabled comparison begins.",[1900,1100,0]] call _phase;
private _withdrawContact = [{driver _armour knowsAbout _enemy > 1},30] call _wait;
["WITHDRAW-fixture-natural-contact",_withdrawContact] call _check;
private _disabledTravel = 0;
private _disabledCrewRetained = true;
for "_sample" from 1 to 15 do {
    sleep 1;
    _disabledTravel = _disabledTravel max (_armour distance2D _origin);
    if (_crew findIf {!alive _x || {vehicle _x != _armour}} >= 0) then {_disabledCrewRetained=false};
};
["WITHDRAW-disabled-holds",_withdrawContact && {_disabledTravel <= 5} && {_disabledCrewRetained},str _disabledTravel] call _check;
["WITHDRAW-disabled-no-smoke",(_armour getVariable ["Waldo_CortexQA_SmokeShots",0]) == 0] call _check;
_origin=getPosATL _armour;
[createHashMapFromArray [["Waldo_AIPass_VehicleWithdraw_Enable",true]]] call Waldo_fnc_CortexTuning;
["Damaged armour withdrawal","Withdrawal is now enabled on the same APC. It must fire actual defensive smoke and drive at least 40 m away from the visible threat, retaining all operating crew.",[1900,1100,0]] call _phase;
private _withdrawn=[{_armour distance2D _origin > 40 && {_armour distance2D _enemy > (_origin distance2D _enemy)+30}},100] call _wait;
["WITHDRAW-physical-distance",_withdrawContact && {_withdrawn},str getPosATL _armour] call _check;
["WITHDRAW-actual-smoke",(_armour getVariable ["Waldo_CortexQA_SmokeShots",0]) > 0] call _check;
["WITHDRAW-crew-retained",_crew findIf {!alive _x || {vehicle _x != _armour}} < 0] call _check;
sleep 12;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_crew+[_enemy,_armour]); deleteGroup _group; deleteGroup _enemyGroup;

// A separate fixture crosses the owner boundary while the production vehicle withdrawal is active.
// Keeping it independent preserves the original disabled/enabled comparison and prevents a failed
// migration precondition from consuming that result.
private _hcOwners=(missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0};
["WITHDRAW-MIGRATION-headless-prerequisite",_hcOwners isNotEqualTo [],str _hcOwners] call _check;
if (_hcOwners isNotEqualTo []) then {
    private _hcOwner=_hcOwners select 0;
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_Vehicles_Enable",true],["Waldo_AIPass_VehicleWithdraw_Enable",true],
        ["Waldo_AIPass_VehicleDismount_Enable",false],["Waldo_AIPass_VehicleGunnery_Enable",false],
        ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_PostContact_Enable",false],
        ["Waldo_AIPass_LambsMode","WMP"]
    ]] call Waldo_fnc_CortexTuning;
    private _migrateArmour=createVehicle ["O_APC_Tracked_02_cannon_F",[2300,1100,0],[],0,"NONE"];
    createVehicleCrew _migrateArmour;
    private _migrateGroup=group driver _migrateArmour;
    [_migrateGroup] call _pin;
    _migrateGroup setCombatMode "BLUE";
    private _migrateCrew=crew _migrateArmour;
    {
        _x allowDamage false;
        _x setVariable ["Waldo_CortexQA_Label",format ["VEHICLE WITHDRAW HANDOFF %1",_forEachIndex+1],true];
    } forEach _migrateCrew;
    private _migrateEnemyGroup=createGroup [west,true];
    [_migrateEnemyGroup] call _pin;
    _migrateEnemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    _migrateEnemyGroup setCombatMode "BLUE";
    private _migrateEnemy=_migrateEnemyGroup createUnit ["B_Soldier_LAT_F",[2300,1260,0],[],0,"NONE"];
    _migrateEnemy allowDamage false;
    _migrateEnemy disableAI "PATH";
    _migrateEnemy setVariable ["acex_headless_blacklist",true,true];
    _migrateEnemy setVariable ["Waldo_CortexQA_Label","WITHDRAW HANDOFF THREAT",true];
    _migrateArmour setDamage 0.55;
    _migrateArmour setVariable ["Waldo_CortexQA_SmokeShots",0,true];
    private _countermeasureAmmo={
        params ["_vehicle"];
        private _total=0;
        {
            _x params ["_magazine","_turret","_rounds"];
            private _ammo=getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
            if (toLowerANSI getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") in ["shotsmoke","shotsmokex"]) then {
                _total=_total+_rounds;
            };
        } forEach magazinesAllTurrets _vehicle;
        _total
    };
    _migrateArmour addEventHandler ["Fired",{
        params ["_vehicle","_weapon","_muzzle","_mode","_ammo","_magazine"];
        if (toLowerANSI getText (configFile >> "CfgWeapons" >> _weapon >> "simulation") == "cmlauncher") then {
            _vehicle setVariable ["Waldo_CortexQA_SmokeShots",(_vehicle getVariable ["Waldo_CortexQA_SmokeShots",0])+1,true];
        };
    }];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_migrateCrew+[_migrateEnemy],true];
    private _migrationOrigin=getPosATL _migrateArmour;
    ["Vehicle withdrawal: active owner handoff","The damaged APC must naturally detect the visible AT threat, start a real withdrawal on the server, then continue under a headless owner without replaying its initial smoke screen. Crew must remain aboard.",_migrationOrigin getPos [120,180]] call _phase;
    private _migrationContact=[{driver _migrateArmour knowsAbout _migrateEnemy > 1},35] call _wait;
    ["WITHDRAW-MIGRATION-natural-contact",_migrationContact,str (driver _migrateArmour knowsAbout _migrateEnemy)] call _check;
    private _migrationStarted=[{
        (_migrateGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "RETREAT"
            && {private _intent=_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]; count _intent == 7 && {(_intent select 0) == "VEHICLE"}}
            && {_migrateArmour distance2D _migrationOrigin >= 8}
    },45] call _wait;
    ["WITHDRAW-MIGRATION-production-start",_migrationContact && {_migrationStarted},str [_migrateGroup getVariable ["Waldo_AIPass_PublicPhase",""],_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]],getPosATL _migrateArmour]] call _check;
    private _initialSmoke=[{(_migrateArmour getVariable ["Waldo_CortexQA_SmokeShots",0]) > 0},12] call _wait;
    ["WITHDRAW-MIGRATION-initial-smoke",_initialSmoke,str (_migrateArmour getVariable ["Waldo_CortexQA_SmokeShots",0])] call _check;
    // Let the owner's initial launcher burst finish before taking the ammunition baseline. A Fired
    // handler installed on the old owner cannot observe a later HC-local replay, while live magazine
    // depletion remains authoritative across locality and therefore catches one.
    sleep 5;
    private _smokeBefore=_migrateArmour getVariable ["Waldo_CortexQA_SmokeShots",0];
    private _countermeasureAmmoBefore=[_migrateArmour] call _countermeasureAmmo;
    private _intentBefore=+(_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]);
    private _startedAt=_intentBefore param [4,-1];
    private _handoffPosition=getPosATL _migrateArmour;
    private _handoffThreatDistance=_migrateArmour distance2D _migrateEnemy;
    _migrateGroup setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    {_x setVariable ["acex_headless_blacklist",false,true]} forEach _migrateCrew;
    private _migrationRequested=[_migrateGroup,_hcOwner] call Waldo_fnc_HeadlessMigrateGroup;
    private _migrationAdopted=[{
        groupOwner _migrateGroup == _hcOwner
            && {owner _migrateArmour == _hcOwner}
            && {_migrateCrew findIf {owner _x != _hcOwner} < 0}
            && {(_migrateGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "RETREAT"}
            && {private _entry=_migrateGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]; count _entry == 5 && {(_entry select 3) == "VEHICLE_OWNERSHIP_RESUME"} && {(_entry select 4) == _hcOwner}}
    },40] call _wait;
    ["WITHDRAW-MIGRATION-owner-resume",_migrationRequested && {_migrationAdopted},str [groupOwner _migrateGroup,owner _migrateArmour,_migrateCrew apply {owner _x},_migrateGroup getVariable ["Waldo_Cortex_PhaseTransition",[]]]] call _check;
    private _intentAfter=+(_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]);
    ["WITHDRAW-MIGRATION-start-preserved",_migrationAdopted && {count _intentAfter == 7}
        && {abs ((_intentAfter select 4)-_startedAt) < 0.25},str [_startedAt,_intentAfter]] call _check;
    private _continued=[{
        _migrateArmour distance2D _handoffPosition >= 12
            && {_migrateArmour distance2D _migrateEnemy >= _handoffThreatDistance+8}
    },45] call _wait;
    ["WITHDRAW-MIGRATION-physical-continuation",_migrationAdopted && {_continued},str [_handoffPosition,getPosATL _migrateArmour,_handoffThreatDistance,_migrateArmour distance2D _migrateEnemy]] call _check;
    sleep 6;
    private _countermeasureAmmoAfter=[_migrateArmour] call _countermeasureAmmo;
    ["WITHDRAW-MIGRATION-no-smoke-replay",_initialSmoke && {_countermeasureAmmoAfter == _countermeasureAmmoBefore},str [_smokeBefore,_migrateArmour getVariable ["Waldo_CortexQA_SmokeShots",0],_countermeasureAmmoBefore,_countermeasureAmmoAfter]] call _check;
    ["WITHDRAW-MIGRATION-crew-retained",_migrateCrew findIf {!alive _x || {vehicle _x != _migrateArmour}} < 0,str (_migrateCrew apply {vehicle _x})] call _check;

    ["Vehicle withdrawal: Zeus replacement","Zeus now replaces the resumed withdrawal. The APC must release RETREAT, drive to the new marker under the replacement waypoint and remain there without reviving the old withdrawal.",[2420,1100,0]] call _phase;
    [_migrateGroup,true] call Waldo_fnc_CortexZeusMark;
    private _released=[{
        (_migrateGroup getVariable ["Waldo_AIPass_PublicPhase",""]) == "CALM"
            && {(_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]) isEqualTo []}
    },25] call _wait;
    ["WITHDRAW-MIGRATION-zeus-release",_released,str [_migrateGroup getVariable ["Waldo_AIPass_PublicPhase",""],_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]]] call _check;
    private _replacement=[2420,1100,0];
    private _replacementWP=_migrateGroup addWaypoint [_replacement,0];
    _replacementWP setWaypointType "MOVE";
    _replacementWP setWaypointCompletionRadius 8;
    _migrateGroup setCurrentWaypoint _replacementWP;
    {_x setVariable ["Waldo_CortexQA_Target",_replacement,true]} forEach _migrateCrew;
    private _replacementArrived=[{_migrateArmour distance2D _replacement <= 22},100] call _wait;
    ["WITHDRAW-MIGRATION-zeus-physical-replacement",_released && {_replacementArrived},str getPosATL _migrateArmour] call _check;
    private _stayedReleased=_replacementArrived;
    for "_sample" from 1 to 12 do {
        sleep 1;
        if ((_migrateGroup getVariable ["Waldo_AIPass_PublicPhase","CALM"]) == "RETREAT"
            || {(_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]]) isNotEqualTo []}
            || {_migrateArmour distance2D _replacement > 25}) then {_stayedReleased=false};
    };
    ["WITHDRAW-MIGRATION-zeus-no-resurrection",_stayedReleased,str [_migrateGroup getVariable ["Waldo_AIPass_PublicPhase",""],_migrateGroup getVariable ["Waldo_Cortex_WithdrawalIntent",[]],getPosATL _migrateArmour]] call _check;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    {deleteVehicle _x} forEach (_migrateCrew+[_migrateEnemy,_migrateArmour]);
    deleteGroup _migrateGroup;
    deleteGroup _migrateEnemyGroup;
};
