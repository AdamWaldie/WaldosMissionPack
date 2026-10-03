/*
 * Author: WaldoTheWarfighter
 * Verifies artillery smoke gates and real finite smoke projectiles without HE substitution.
 * Locality/authority: scheduled server fixture using the production artillery request API.
 * Repeat/JIP: fresh battery, public shot/landing evidence; caller restores settings; deletes only fixtures.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAArtillerySmoke.sqf";
 */
params ["_check","_phase","_wait"];
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_Artillery_Enable",true],["Waldo_AIPass_ArtillerySmoke_Enable",true],["Waldo_AIPass_LambsMode","WMP"]]] call Waldo_fnc_CortexTuning;
private _gun=createVehicle ["O_Mortar_01_F",[1800,700,0],[],0,"NONE"];
createVehicleCrew _gun;
private _crew=crew _gun;
private _batteryGroup=group gunner _gun;
private _requester=createGroup [east,true];
private _caller=_requester createUnit ["O_Soldier_F",[1800,1100,0],[],0,"NONE"];
{
    _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _x setVariable ["acex_headless_blacklist",true,true];
    _x setCombatMode "YELLOW";
} forEach [_batteryGroup,_requester];
{_x setVariable ["acex_headless_blacklist",true,true]} forEach (_crew+[_caller]);
[_gun,"SUPPORT"] call Waldo_fnc_CortexSetArtilleryRole;
_gun setVariable ["Waldo_CortexQA_Label","SMOKE BATTERY: TWO ROUNDS ONLY",true];
_gun setVariable ["Waldo_CortexQA_SmokeShots",[],true];
_gun setVariable ["Waldo_CortexQA_SmokeGround",[],true];
_gun addEventHandler ["Fired",{
    params ["_gun","","","","_ammo","","_projectile"];
    private _shots=_gun getVariable ["Waldo_CortexQA_SmokeShots",[]];
    _shots pushBack _ammo;
    _gun setVariable ["Waldo_CortexQA_SmokeShots",_shots,true];
    private _shotIndex=count _shots-1;
    private _payloadKey=format ["Waldo_CortexQA_SmokePayload_%1",_shotIndex];
    _gun setVariable [_payloadKey,[_projectile]];
    _projectile setVariable ["Waldo_CortexQA_SmokeSource",[_gun,_payloadKey]];
    _projectile addEventHandler ["SubmunitionCreated",{
        params ["_carrier","_payload"];
        (_carrier getVariable ["Waldo_CortexQA_SmokeSource",[objNull,""]]) params ["_gun","_key"];
        if (isNull _gun) exitWith {};
        private _payloads=_gun getVariable [_key,[]];
        _payloads pushBack _payload;
        _gun setVariable [_key,_payloads];
        diag_log format ["WMP CORTEX QA SMOKE PAYLOAD: %1 at %2",typeOf _payload,getPosATL _payload];
    }];
    diag_log format ["WMP CORTEX QA SMOKE FIRED: %1 shot %2",_ammo,_shotIndex+1];
    [_gun,_payloadKey] spawn {
        params ["_gun","_payloadKey"];
        private _until=diag_tickTime+150;
        waitUntil {
            sleep 0.05;
            private _payloads=_gun getVariable [_payloadKey,[]];
            private _index=_payloads findIf {
                !isNull _x && {toLowerANSI getText (configFile >> "CfgAmmo" >> typeOf _x >> "simulation") in ["shotsmoke","shotsmokex"]}
                && {(getPosATL _x select 2) < 3} && {_x distance2D _gun > 100}
            };
            if (_index >= 0) exitWith {
                private _ground=_gun getVariable ["Waldo_CortexQA_SmokeGround",[]];
                _ground pushBack getPosATL (_payloads select _index);
                _gun setVariable ["Waldo_CortexQA_SmokeGround",_ground,true];
                true
            };
            isNull _gun || {diag_tickTime >= _until}
        };
    };
}];
private _target=[1800,1500,0];
missionNamespace setVariable ["Waldo_CortexQA_RedWarningEvents",[]];
private _warningHandler=addMissionEventHandler ["ProjectileCreated",{
    params ["_entity"];
    if (typeOf _entity == "SmokeShellRed") then {
        private _events=missionNamespace getVariable ["Waldo_CortexQA_RedWarningEvents",[]];
        _events pushBack [time,_entity];
        missionNamespace setVariable ["Waldo_CortexQA_RedWarningEvents",_events];
    };
}];
_gun setVariable ["Waldo_CortexQA_ShotTimes",[]];
private _timingHandler=_gun addEventHandler ["Fired",{
    params ["_gun"];
    private _times=_gun getVariable ["Waldo_CortexQA_ShotTimes",[]];
    _times pushBack time;
    _gun setVariable ["Waldo_CortexQA_ShotTimes",_times];
}];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_gun,_caller],true];
_caller setVariable ["Waldo_CortexQA_Label","SMOKE REQUESTER",true];
_caller setVariable ["Waldo_CortexQA_Target",_target,true];
["Artillery smoke gates","The battery must not fire when parent artillery or smoke support is disabled. Enabling both later must produce exactly two smoke shells, with no HE substitution. Watch the target marker for the smoke screen.",_target] call _phase;
[{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
private _request={[_gun,_target,0,"SMOKE",2,false,"SUPPORT",objNull,objNull,_requester] call Waldo_fnc_CortexArtilleryFire};
[createHashMapFromArray [["Waldo_AIPass_Artillery_Enable",false]]] call Waldo_fnc_CortexTuning;
["ART-SMOKE-parent-disabled-reject",!(call _request)] call _check;
[createHashMapFromArray [["Waldo_AIPass_Artillery_Enable",true],["Waldo_AIPass_ArtillerySmoke_Enable",false]]] call Waldo_fnc_CortexTuning;
["ART-SMOKE-child-disabled-reject",!(call _request)] call _check;
sleep 10;
["ART-SMOKE-disabled-no-shots",(_gun getVariable ["Waldo_CortexQA_SmokeShots",[]]) isEqualTo []] call _check;
[createHashMapFromArray [["Waldo_AIPass_ArtillerySmoke_Enable",true]]] call Waldo_fnc_CortexTuning;
diag_log format ["WMP CORTEX QA SMOKE INVENTORY: %1",magazinesAllTurrets [_gun,true]];
{
    private _ammo=getText (configFile >> "CfgMagazines" >> _x >> "ammo");
    private _cfg=configFile >> "CfgAmmo" >> _ammo;
    diag_log format ["WMP CORTEX QA AMMO PROFILE: %1",[_x,_ammo,getText (_cfg >> "simulation"),getNumber (_cfg >> "aiAmmoUsageFlags"),getArray (_cfg >> "smokeColor"),getText (_cfg >> "effectsSmoke"),getText (_cfg >> "explosionEffects"),getText (_cfg >> "submunitionAmmo"),getNumber (_cfg >> "hit"),getNumber (_cfg >> "indirectHit")]];
} forEach getArtilleryAmmo [_gun];
private _magazine=[_gun,true] call Waldo_fnc_CortexArtilleryAmmo;
private _smokeStores=(magazinesAllTurrets [_gun,true]) select {(_x select 0) == _magazine};
private _smokeTurret=if (_smokeStores isEqualTo []) then {[]} else {+(_smokeStores select 0 select 1)};
["ART-SMOKE-ammunition-prerequisite",_magazine != ""] call _check;
_batteryGroup setCombatMode "BLUE";
{_x setUnitCombatMode "BLUE"} forEach _crew;
["ART-SMOKE-never-fire-rejected",!(call _request)] call _check;
_batteryGroup setCombatMode "YELLOW";
{_x setUnitCombatMode "YELLOW"} forEach _crew;
["ART-SMOKE-request-accepted",call _request] call _check;
["Artillery smoke delivery","Observe two actual smoke shells reaching the marked area. No HE is permitted. The test measures fired ammunition and smoke payloads arriving below 3 m near the target, then checks that firing stops.",_target] call _phase;
private _delivered=[{count (_gun getVariable ["Waldo_CortexQA_SmokeGround",[]]) >= 2},150] call _wait;
private _positions=_gun getVariable ["Waldo_CortexQA_SmokeGround",[]];
["ART-SMOKE-physical-ground-delivery",_delivered && {_positions findIf {_x distance2D _target > 70} < 0},str _positions] call _check;
sleep 20;
private _shots=_gun getVariable ["Waldo_CortexQA_SmokeShots",[]];
private _expectedAmmo=getText (configFile >> "CfgMagazines" >> _magazine >> "ammo");
["ART-SMOKE-finite-two-smoke-only",count _shots == 2 && {_shots findIf {_x != _expectedAmmo} < 0},str _shots] call _check;
["ART-SMOKE-no-red-warning",(missionNamespace getVariable ["Waldo_CortexQA_RedWarningEvents",[]]) isEqualTo [],"Non-lethal smoke support must not create an HE warning spread"] call _check;
// A smoke-only battery must never have its smoke magazine selected for an HE mission.
if (_magazine != "") then {
    {
        _x params ["_class","_turret"];
        if (_class != _magazine) then {_gun removeMagazineTurret [_class,_turret]};
    } forEach magazinesAllTurrets [_gun,true];
};
["ART-SMOKE-no-HE-substitution",_magazine != "" && {([_gun,false] call Waldo_fnc_CortexArtilleryAmmo) == ""} && {([_gun,true] call Waldo_fnc_CortexArtilleryAmmo) == _magazine}] call _check;
["Artillery smoke: empty battery","The previous finite mission must release the battery. All remaining magazines are then removed: a new smoke request must be refused, with no extra projectile fired.",getPosATL _gun] call _phase;
private _released=[{!((netId _gun) in (missionNamespace getVariable ["Waldo_AIPass_FireMissions",createHashMap]))},60] call _wait;
["ART-SMOKE-completed-lock-released",_released] call _check;
{_gun removeMagazineTurret [_x select 0,_x select 1]} forEach magazinesAllTurrets [_gun,true];
["ART-SMOKE-empty-inventory",(magazinesAllTurrets [_gun,true]) findIf {(_x select 2) > 0} < 0] call _check;
["ART-SMOKE-empty-request-rejected",_released && {!(call _request)} && {([_gun,true] call Waldo_fnc_CortexArtilleryAmmo) == ""}] call _check;
private _beforeEmpty=count (_gun getVariable ["Waldo_CortexQA_SmokeShots",[]]);
sleep 8;
["ART-SMOKE-empty-no-projectile",count (_gun getVariable ["Waldo_CortexQA_SmokeShots",[]]) == _beforeEmpty] call _check;
// Resupply the same battery; repeat through the public request and real projectile path.
if (_magazine != "" && {_released}) then {
    ["Artillery smoke: resupply and repeat","The same exhausted mortar receives smoke ammunition. It must deliver another two-round screen and release its mission lock again. Earlier shells cannot satisfy this check.",_target] call _phase;
    _gun addMagazineTurret [_magazine,_smokeTurret];
    private _repeatShots=count (_gun getVariable ["Waldo_CortexQA_SmokeShots",[]]);
    private _repeatGround=count (_gun getVariable ["Waldo_CortexQA_SmokeGround",[]]);
    private _accepted=call _request;
    ["ART-SMOKE-resupplied-request",_accepted] call _check;
    private _repeatDelivered=[{count (_gun getVariable ["Waldo_CortexQA_SmokeGround",[]]) >= _repeatGround+2},150] call _wait;
    private _newPositions=(_gun getVariable ["Waldo_CortexQA_SmokeGround",[]]) select [_repeatGround];
    ["ART-SMOKE-repeat-ground-delivery",_accepted && {_repeatDelivered} && {_newPositions findIf {_x distance2D _target > 70} < 0},str _newPositions] call _check;
    sleep 20;
    ["ART-SMOKE-repeat-finite",count (_gun getVariable ["Waldo_CortexQA_SmokeShots",[]]) == _repeatShots+2] call _check;
    ["ART-SMOKE-repeat-no-red-warning",(missionNamespace getVariable ["Waldo_CortexQA_RedWarningEvents",[]]) isEqualTo []] call _check;
    ["ART-SMOKE-repeat-lock-released",[{!((netId _gun) in (missionNamespace getVariable ["Waldo_AIPass_FireMissions",createHashMap]))},60] call _wait] call _check;
} else {
    ["ART-SMOKE-resupplied-request",false,"Missing smoke ammunition class or previous mission did not release"] call _check;
};
removeMissionEventHandler ["ProjectileCreated",_warningHandler];
_gun removeEventHandler ["Fired",_timingHandler];
missionNamespace setVariable ["Waldo_CortexQA_RedWarningEvents",nil];
{deleteVehicle _x} forEach (_crew+[_gun,_caller]);
deleteGroup _batteryGroup; deleteGroup _requester;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
