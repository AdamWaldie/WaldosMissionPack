/*
 * Author: WaldoTheWarfighter
 * Exercises infantry hold-fire, actual multi-target firing and naturally staggered multi-squad
 * suppression through the live Cortex scheduler.
 * Locality/authority: scheduled server with server-pinned fixtures; real fired events are observed.
 * Repeat/JIP: creates fresh actors and deletes them; public labels support joining observers.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>, required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAFire.sqf";
 */
params ["_check","_phase","_wait"];
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_LambsMode","WMP"],
    ["Waldo_AIPass_FireControl_Enable",true],["Waldo_AIPass_FireControl_MaxShootersPerTarget",1],
    ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_Flank_Enable",false],
    ["Waldo_AIPass_Advance_Enable",false],["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_Artillery_Enable",false],
    ["Waldo_AIPass_CoordinatedAssault_Enable",false],["Waldo_AIPass_AntiArmour_Enable",true]
]] call Waldo_fnc_CortexTuning;
["FIRE-requested-shooters-per-target",(missionNamespace getVariable ["Waldo_AIPass_FireControl_MaxShootersPerTarget",-1]) == 1,str (missionNamespace getVariable ["Waldo_AIPass_FireControl_MaxShootersPerTarget",-1])] call _check;
private _group=createGroup [east,true];
private _enemyGroup=createGroup [west,true];
{_x setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _x setVariable ["acex_headless_blacklist",true,true]} forEach [_group,_enemyGroup];
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
private _shooters=[];
for "_i" from 0 to 3 do {
    private _unit=_group createUnit ["O_Soldier_F",[2100+_i*4,1100,0],[],0,"NONE"];
    _unit allowDamage false; _unit disableAI "PATH";
    _unit setUnitCombatMode "BLUE";
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["FIRE CONTROL %1",_i+1],true];
    _unit addEventHandler ["FiredMan",{
        params ["_unit"];
        _unit setVariable ["Waldo_CortexQA_ActualShots",(_unit getVariable ["Waldo_CortexQA_ActualShots",0])+1,true];
    }];
    _shooters pushBack _unit;
};
private _targets=[];
for "_i" from 0 to 1 do {
    private _unit=_enemyGroup createUnit ["B_Soldier_F",[2100+_i*16,1115,0],[],0,"NONE"];
    _unit allowDamage false; _unit disableAI "PATH";
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["VISIBLE TARGET %1",_i+1],true];
    _unit allowDamage true;
    _unit setVariable ["Waldo_CortexQA_SourceGroup",_group];
    _unit addEventHandler ["HandleDamage",{
        params ["_unit","_selection","_damage","_source","_projectile","_hitIndex","_instigator"];
        private _shooter=if (isNull _instigator) then {_source} else {_instigator};
        if (_projectile != "" && {!isNull _shooter}
            && {group _shooter == (_unit getVariable ["Waldo_CortexQA_SourceGroup",grpNull])}) then {
            _unit setVariable ["Waldo_CortexQA_TargetHits",(_unit getVariable ["Waldo_CortexQA_TargetHits",0])+1,true];
        };
        0
    }];
    _targets pushBack _unit;
};
_group setCombatMode "BLUE"; _enemyGroup setCombatMode "BLUE";
missionNamespace setVariable ["Waldo_CortexQA_Actors",_shooters+_targets,true];
["Fire control: hold fire","Enemies are within 20 m. Cortex must respect BLUE hold-fire even when close-threat targeting would otherwise order a shot. Observe weapons and actual shots.",[2100,1100,0]] call _phase;
["FIRE-real-contact",[{((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT"},35] call _wait] call _check;
sleep 12;
["FIRE-hold-fire-no-shots",_shooters findIf {(_x getVariable ["Waldo_CortexQA_ActualShots",0]) > 0} < 0] call _check;
_group setCombatMode "RED";
["Fire control: weapons free","The same live targets remain. The squad must now fire real rounds at both targets. Labels show actual shots and target hit events; assignment alone does not establish effective fire.",[2100,1100,0]] call _phase;
private _engaged=[{
    (_shooters findIf {(_x getVariable ["Waldo_CortexQA_ActualShots",0]) > 0} >= 0)
        && {_targets findIf {(_x getVariable ["Waldo_CortexQA_TargetHits",0]) == 0} < 0}
},45] call _wait;
["FIRE-both-targets-actual-fire",_engaged,str [
    _shooters apply {_x getVariable ["Waldo_CortexQA_ActualShots",0]},
    _targets apply {_x getVariable ["Waldo_CortexQA_TargetHits",0]}
]] call _check;
private _bothHit=[{
    {
        _x setVariable ["Waldo_CortexQA_Label",format ["TARGET %1 | projectile hit events %2",_forEachIndex+1,_x getVariable ["Waldo_CortexQA_TargetHits",0]],true];
    } forEach _targets;
    {
        _x setVariable ["Waldo_CortexQA_Label",format ["SHOOTER %1 | actual shots %2",_forEachIndex+1,_x getVariable ["Waldo_CortexQA_ActualShots",0]],true];
    } forEach _shooters;
    _targets findIf {(_x getVariable ["Waldo_CortexQA_TargetHits",0]) == 0} < 0
},30] call _wait;
["FIRE-both-targets-projectile-hits",_bothHit,str (_targets apply {_x getVariable ["Waldo_CortexQA_TargetHits",0]})] call _check;
_group setCombatMode "BLUE";
{_x setUnitCombatMode "BLUE"; _x doTarget objNull} forEach _shooters;
sleep 3;
private _counts=_shooters apply {_x getVariable ["Waldo_CortexQA_ActualShots",0]};
sleep 12;
["FIRE-return-to-hold-no-new-shots",(_shooters apply {_x getVariable ["Waldo_CortexQA_ActualShots",0]}) isEqualTo _counts] call _check;
[_group] call Waldo_fnc_CortexReleaseGroup;
{deleteVehicle _x} forEach (_shooters+_targets);
deleteGroup _group; deleteGroup _enemyGroup;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];

// Two independent squads acquire the same visible enemy, then retain its last known position after
// it disappears. The production group ticks must choose and rotate suppressors without a test-injected
// order. This observer samples existing public state only; it adds no runtime scheduler or coordination.
private _suppressionGroups=[];
private _suppressionShooters=[];
for "_g" from 0 to 1 do {
    private _suppressionGroup=createGroup [east,true];
    _suppressionGroup setGroupIdGlobal [format ["Cortex QA TALK %1",_g+1]];
    _suppressionGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _suppressionGroup setVariable ["acex_headless_blacklist",true,true];
    _suppressionGroup setCombatMode "BLUE";
    private _origin=[2040+_g*60,1300,0];
    private _axis=_origin vectorFromTo [2100,1355,0];
    private _lateral=[-(_axis select 1),_axis select 0,0];
    for "_i" from 0 to 2 do {
        private _position=_origin vectorAdd (_lateral vectorMultiply ((_i-1)*4));
        private _unit=_suppressionGroup createUnit ["O_Soldier_F",_position,[],0,"NONE"];
        _unit allowDamage false;
        _unit disableAI "PATH";
        _unit setUnitCombatMode "BLUE";
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit setVariable ["Waldo_CortexQA_SuppressOrders",[]];
        _unit setVariable ["Waldo_CortexQA_SuppressShots",[]];
        _unit setVariable ["Waldo_CortexQA_Label",format ["SQUAD %1 / SHOOTER %2 | waiting",_g+1,_i+1],true];
        _unit addEventHandler ["FiredMan",{
            params ["_unit"];
            private _shots=_unit getVariable ["Waldo_CortexQA_SuppressShots",[]];
            _shots pushBack time;
            _unit setVariable ["Waldo_CortexQA_SuppressShots",_shots,true];
        }];
        _suppressionShooters pushBack _unit;
    };
    _suppressionGroups pushBack _suppressionGroup;
};
private _suppressionEnemyGroup=createGroup [west,true];
_suppressionEnemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
_suppressionEnemyGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_suppressionEnemyGroup setVariable ["acex_headless_blacklist",true,true];
_suppressionEnemyGroup setCombatMode "BLUE";
private _suppressionEnemy=_suppressionEnemyGroup createUnit ["B_Soldier_F",[2100,1355,0],[],0,"NONE"];
_suppressionEnemy allowDamage false;
_suppressionEnemy disableAI "PATH";
_suppressionEnemy setVariable ["acex_headless_blacklist",true,true];
_suppressionEnemy setVariable ["Waldo_CortexQA_Label","SHARED ENEMY / visible acquisition",true];
private _suppressionScreen=[];
for "_i" from -20 to 20 do {
    private _wall=createVehicle ["Land_CncWall4_F",[2100+_i*4,1415,0],[],0,"CAN_COLLIDE"];
    _wall setDir 0;
    _wall allowDamage false;
    _suppressionScreen pushBack _wall;
};
missionNamespace setVariable ["Waldo_CortexQA_Actors",_suppressionShooters+[_suppressionEnemy],true];
["Fire control: independent squad cadence","Two stationary squads first acquire the same visible enemy while holding fire. The enemy is then moved behind the concrete screen while their targets are cleared, leaving its old position unobstructed and known. Watch each squad rotate individual suppressors at its own lightly random cadence; cyan labels show Cortex-owned orders and actual shot times. Repeated synchronized squad volleys fail.",[2100,1375,0]] call _phase;
private _allContact=[{
    _suppressionGroups findIf {
        ((_x getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) != "CONTACT"
    } < 0
},40] call _wait;
["FIRE-multi-squad-natural-contact",_allContact,str (_suppressionGroups apply {(_x getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]})] call _check;
_suppressionEnemy setPosATL [2100,1460,0];
{_x doTarget objNull; _x doWatch objNull} forEach _suppressionShooters;
{_x setCombatMode "RED"} forEach _suppressionGroups;
private _deadline=time+35;
waitUntil {
    {
        private _unit=_x;
        private _last=_unit getVariable ["Waldo_AIPass_LastSuppress",-1];
        private _orders=_unit getVariable ["Waldo_CortexQA_SuppressOrders",[]];
        if (_last >= 0 && {_orders isEqualTo [] || {_last > (_orders select ((count _orders)-1))}}) then {
            _orders pushBack _last;
            _unit setVariable ["Waldo_CortexQA_SuppressOrders",_orders,true];
        };
        private _groupNumber=(_suppressionGroups find (group _unit))+1;
        _unit setVariable ["Waldo_CortexQA_Label",format ["SQUAD %1 | orders %2 | shots %3 | last %4",_groupNumber,count _orders,count (_unit getVariable ["Waldo_CortexQA_SuppressShots",[]]),if (_last < 0) then {"none"} else {_last toFixed 1}],true];
    } forEach _suppressionShooters;
    private _readyGroups={
        private _group=_x;
        count ((units _group) select {(_x getVariable ["Waldo_CortexQA_SuppressOrders",[]]) isNotEqualTo []}) >= 2
    } count _suppressionGroups;
    _readyGroups == 2 || {time >= _deadline}
};
private _orderedByGroup=_suppressionGroups apply {
    private _events=[];
    {_events append (_x getVariable ["Waldo_CortexQA_SuppressOrders",[]])} forEach units _x;
    _events sort true;
    _events
};
private _rotated=_orderedByGroup findIf {count _x < 2} < 0;
private _comparableRounds=selectMin (_orderedByGroup apply {count _x});
private _roundSpreads=[];
for "_round" from 0 to (_comparableRounds-1) do {
    private _times=_orderedByGroup apply {_x select _round};
    _roundSpreads pushBack ((selectMax _times)-(selectMin _times));
};
// A first reaction may legitimately share one frame. Repeated global lockstep is the defect.
private _staggered=_comparableRounds >= 2 && {_roundSpreads findIf {_x >= 0.15} >= 0};
private _actualSuppression=_suppressionGroups findIf {
    private _group=_x;
    (units _group) findIf {(_x getVariable ["Waldo_CortexQA_SuppressShots",[]]) isNotEqualTo []} < 0
} < 0;
["FIRE-talking-guns-rotated-suppressors",_rotated,str _orderedByGroup] call _check;
["FIRE-squads-not-global-volley",_staggered,str _roundSpreads] call _check;
["FIRE-multi-squad-actual-suppression",_actualSuppression,str (_suppressionShooters apply {count (_x getVariable ["Waldo_CortexQA_SuppressShots",[]])})] call _check;
{[_x] call Waldo_fnc_CortexReleaseGroup} forEach _suppressionGroups;
{deleteVehicle _x} forEach (_suppressionShooters+[_suppressionEnemy]+_suppressionScreen);
{deleteGroup _x} forEach (_suppressionGroups+[_suppressionEnemyGroup]);
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];

// Separate live AT fixture: real visible armour, clear rear arc and finite ammunition.
[createHashMapFromArray [["Waldo_AIPass_FireControl_Enable",false],["Waldo_AIPass_AntiArmour_Enable",true]]] call Waldo_fnc_CortexTuning;
_group=createGroup [east,true];
_group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_group setVariable ["acex_headless_blacklist",true,true];
private _gunner=_group createUnit ["O_Soldier_LAT_F",[2100,1100,0],[],0,"NONE"];
_gunner allowDamage false;
_gunner setVariable ["acex_headless_blacklist",true,true];
_gunner setVariable ["Waldo_CortexQA_Label","AT GUNNER - CLEAR REAR ARC",true];
private _armour=createVehicle ["B_APC_Tracked_01_rcws_F",[2100,1250,0],[],0,"NONE"];
createVehicleCrew _armour;
_enemyGroup=group driver _armour;
_enemyGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_enemyGroup setVariable ["acex_headless_blacklist",true,true];
_enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
_enemyGroup setCombatMode "BLUE";
{_x disableAI "PATH"; _x allowDamage false; _x setVariable ["acex_headless_blacklist",true,true]} forEach crew _armour;
_armour allowDamage false;
_gunner addEventHandler ["FiredMan",{
    params ["_unit","_weapon","","","_ammo"];
    if (_weapon == secondaryWeapon _unit) then {
        _unit setVariable ["Waldo_CortexQA_ATShots",(_unit getVariable ["Waldo_CortexQA_ATShots",0])+1,true];
        diag_log format ["WMP CORTEX QA AT SHOT: weapon=%1 ammo=%2 target=%3",_weapon,_ammo,assignedTarget _unit];
    };
}];
_group setCombatMode "BLUE";
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_gunner]+crew _armour,true];
["Anti-armour: hold fire","A real occupied APC is 150 m north. The launcher soldier must respect hold fire. Watch the weapon and target vehicle; the test does not reveal the target.",[2100,1175,0]] call _phase;
["AT-visible-contact",[{((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT"},35] call _wait] call _check;
sleep 10;
["AT-hold-fire-no-launch",(_gunner getVariable ["Waldo_CortexQA_ATShots",0]) == 0] call _check;
_group setCombatMode "RED";
["Anti-armour: actual launch","With a clear rear arc and weapons free, Cortex must select the armour and the soldier must fire a real launcher round. A target assignment alone does not pass.",[2100,1175,0]] call _phase;
private _orderedAT=false;
private _launched=[{
    _orderedAT=_orderedAT || {assignedTarget _gunner == _armour && {(_gunner getVariable ["Waldo_AIPass_TargetHold",-1]) > time}};
    (_gunner getVariable ["Waldo_CortexQA_ATShots",0]) > 0
},60] call _wait;
["AT-cortex-order-and-actual-launch",_orderedAT && {_launched},str [_orderedAT,_gunner getVariable ["Waldo_CortexQA_ATShots",0]]] call _check;
[_group] call Waldo_fnc_CortexReleaseGroup;
{deleteVehicle _x} forEach ([_gunner]+crew _armour);
deleteVehicle _armour; deleteGroup _group; deleteGroup _enemyGroup;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
