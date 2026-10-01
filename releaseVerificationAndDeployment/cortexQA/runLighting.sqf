/*
 * Author: WaldoTheWarfighter
 * Verifies automatic low-light skill clamping, configuration-based NVG capability, flashlight beam
 * behavior, actual night acquisition/fire and owner-local reapplication after an HC transfer.
 *
 * Locality/authority: the dedicated server owns the initial fixtures and authoritative date. Skill
 * application runs only where each AI is local. One observer is transferred through WMP's normal
 * headless migration path; its public skill snapshot/signature are inspected after adoption.
 * Repeat/JIP: fresh invulnerable actors are used, the date/settings are restored, public overlays are
 * cleared and all event handlers/objects are deleted. No detection knowledge is injected.
 *
 * Arguments:
 * 0: check <CODE> - records id, Boolean result and optional detail
 * 1: phase <CODE> - publishes the visible stage and observation instructions
 * 2: wait <CODE> - waits for a predicate with a timeout
 *
 * Return Value: Nothing.
 * Current caller: cortexQAServer.sqf through -CortexFocus lighting and the additive feature audit.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALighting.sqf";
 */
params ["_check","_phase","_wait"];

private _savedDate=date;
private _keys=["Waldo_AI_RebalanceActive","Waldo_AIRebalance_Profile","Waldo_AIRebalance_Mode","Waldo_AI_SkillVariance"];
private _saved=_keys apply {missionNamespace getVariable [_x,nil]};
missionNamespace setVariable ["Waldo_AI_RebalanceActive",true];
missionNamespace setVariable ["Waldo_AIRebalance_Profile","LINE"];
missionNamespace setVariable ["Waldo_AIRebalance_Mode","AUTO"];
missionNamespace setVariable ["Waldo_AI_SkillVariance",0];

private _night=+_savedDate;
_night set [3,0];
_night set [4,0];
setDate _night;
sleep 2;
["LIGHTING-dark-fixture",(getLighting select 1) <= (missionNamespace getVariable ["Waldo_AI_DarknessThreshold",5]),str getLighting] call _check;

private _observerGroup=createGroup [east,true];
_observerGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_observerGroup setVariable ["acex_headless_blacklist",true,true];
private _observer=_observerGroup createUnit ["O_Soldier_F",[3000,3000,0],[],0,"NONE"];
_observer setVariable ["acex_headless_blacklist",true,true];
_observer setVariable ["Waldo_CortexQA_Label","LIGHTING OBSERVER",true];
_observer unlinkItem hmd _observer;
[_observer] call Waldo_fnc_AIApplyProfile;
private _unaidedSpot=_observer skill "spotDistance";

private _hmdConfigs="getNumber (_x >> 'scope') == 2 && {getNumber (_x >> 'ItemInfo' >> 'type') == 616}" configClasses (configFile >> "CfgWeapons");
private _nvgConfigs=_hmdConfigs select {"NVG" in getArray (_x >> "visionMode")};
private _plainConfigs=_hmdConfigs select {!("NVG" in getArray (_x >> "visionMode"))};
private _vanillaNVGs=["NVGoggles","NVGoggles_OPFOR","NVGoggles_INDEP","O_NVGoggles_hex_F","O_NVGoggles_urb_F","O_NVGoggles_ghex_F"];
private _modNVGs=_nvgConfigs select {!(configName _x in _vanillaNVGs)};
private _nvgClass=if (_modNVGs isNotEqualTo []) then {configName (_modNVGs select 0)} else {if (_nvgConfigs isNotEqualTo []) then {configName (_nvgConfigs select 0)} else {""}};
private _plainClass=if (_plainConfigs isNotEqualTo []) then {configName (_plainConfigs select 0)} else {""};
["LIGHTING-nvg-capability-prerequisite",_nvgClass != "",_nvgClass] call _check;
["LIGHTING-modded-nvg-prerequisite",_modNVGs isNotEqualTo [],_nvgClass] call _check;
if (_nvgClass != "") then {
    _observer linkItem _nvgClass;
    [_observer] call Waldo_fnc_AIApplyProfile;
};
private _nvgSpot=_observer skill "spotDistance";
["LIGHTING-config-nvg-recovery",_nvgClass != "" && {hmd _observer == _nvgClass} && {_nvgSpot > _unaidedSpot},str [_nvgClass,hmd _observer,_unaidedSpot,_nvgSpot]] call _check;
if (_plainClass != "") then {
    _observer unlinkItem hmd _observer;
    _observer linkItem _plainClass;
    [_observer] call Waldo_fnc_AIApplyProfile;
};
private _plainSpot=_observer skill "spotDistance";
["LIGHTING-ordinary-hmd-no-recovery",_plainClass != "" && {hmd _observer == _plainClass}
    && {abs (_plainSpot-_unaidedSpot) < 0.001},str [_plainClass,hmd _observer,_unaidedSpot,_plainSpot]] call _check;

// Ownership migration must reapply from the original public snapshot instead of capturing already
// modified night skills as a new baseline.
private _hcOwners=((missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0}) select [0,1];
["LIGHTING-headless-prerequisite",count _hcOwners == 1,str _hcOwners] call _check;
if (count _hcOwners == 1) then {
    if (_nvgClass != "") then {_observer unlinkItem hmd _observer; _observer linkItem _nvgClass; [_observer] call Waldo_fnc_AIApplyProfile};
    private _beforeSkills=(_observer getVariable ["Waldo_AI_OriginalSkills",createHashMap]) getOrDefault ["spotDistance",-1];
    _observerGroup setVariable ["Waldo_Headless_ExcludeGroup",false,true];
    _observer setVariable ["acex_headless_blacklist",false,true];
    private _owner=_hcOwners select 0;
    private _requested=[_observerGroup,_owner] call Waldo_fnc_HeadlessMigrateGroup;
    private _adopted=[{groupOwner _observerGroup == _owner && {owner _observer == _owner}},30] call _wait;
    private _signature=_observer getVariable ["Waldo_Cortex_LightingSignature",[]];
    private _afterSkills=(_observer getVariable ["Waldo_AI_OriginalSkills",createHashMap]) getOrDefault ["spotDistance",-2];
    ["LIGHTING-owner-adoption-reapplies",_requested && {_adopted} && {count _signature == 3}
        && {_signature select 2 == _nvgClass} && {_beforeSkills == _afterSkills},str [groupOwner _observerGroup,owner _observer,_signature,_beforeSkills,_afterSkills]] call _check;
    [_observerGroup,2] call Waldo_fnc_HeadlessMigrateGroup;
    [{groupOwner _observerGroup == 2 && {owner _observer == 2}},30] call _wait;
    _observerGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _observer setVariable ["acex_headless_blacklist",true,true];
};

// Flashlights affect only the cone physically illuminated by the engine. Cortex deliberately does
// not raise global spotting skill when a light is on.
_observer unlinkItem hmd _observer;
_observer removePrimaryWeaponItem "acc_pointer_IR";
_observer addPrimaryWeaponItem "acc_flashlight";
[_observer] call Waldo_fnc_AIApplyProfile;
private _spotBeforeLight=_observer skill "spotDistance";
_observer setDir 0;
_observerGroup setBehaviourStrong "COMBAT";
_observerGroup setCombatMode "RED";
_observerGroup enableGunLights "forceOff";
private _frontGroup=createGroup [west,true];
private _rearGroup=createGroup [west,true];
private _front=_frontGroup createUnit ["B_Soldier_F",[3000,3080,0],[],0,"NONE"];
private _rear=_rearGroup createUnit ["B_Soldier_F",[3000,2920,0],[],0,"NONE"];
{_x setCombatMode "BLUE"; _x setBehaviourStrong "CARELESS"} forEach [_frontGroup,_rearGroup];
{_x allowDamage false; _x disableAI "MOVE"; _x disableAI "TARGET"; _x disableAI "AUTOTARGET"; _x setUnitPos "MIDDLE"} forEach [_front,_rear];
// Keep the shot counter on the actor so the visible observer and server assertion read the same state.
_observer setVariable ["Waldo_CortexQA_LightShots",0,true];
private _firedId=_observer addEventHandler ["FiredMan",{
    params ["_unit"];
    _unit setVariable ["Waldo_CortexQA_LightShots",(_unit getVariable ["Waldo_CortexQA_LightShots",0])+1,true];
}];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_observer,_front,_rear],true];
{_x setVariable ["Waldo_CortexQA_Target",getPosATL _front,true]} forEach [_observer];
["Lighting: real flashlight cone","The observer begins unaided with its flashlight forced off. It must not receive a global skill bonus. The light then turns on: watch for physical illumination, forward-target acquisition and real shots while the equally distant rear target stays outside the beam.",getPosATL _front] call _phase;
sleep 10;
private _offShots=_observer getVariable ["Waldo_CortexQA_LightShots",0];
private _offKnowledge=_observer knowsAbout _front;
["LIGHTING-light-off-control",_offShots == 0 && {_offKnowledge < 1.5},str [_offShots,_offKnowledge]] call _check;
_observerGroup enableGunLights "forceOn";
private _lightOn=[{isFlashlightOn _observer},15] call _wait;
private _spotWithLight=_observer skill "spotDistance";
private _forwardEngaged=[{(_observer getVariable ["Waldo_CortexQA_LightShots",0]) > _offShots && {_observer knowsAbout _front >= 1.5}},50] call _wait;
private _rearKnowledge=_observer knowsAbout _rear;
["LIGHTING-flashlight-physically-on",_lightOn] call _check;
["LIGHTING-flashlight-no-global-skill-boost",abs (_spotWithLight-_spotBeforeLight) < 0.001,str [_spotBeforeLight,_spotWithLight]] call _check;
["LIGHTING-forward-beam-acquisition-and-fire",_lightOn && {_forwardEngaged},str [_observer knowsAbout _front,_observer getVariable ["Waldo_CortexQA_LightShots",0],_offShots]] call _check;
["LIGHTING-rear-target-not-omnidirectional",_rearKnowledge < 1.5,str _rearKnowledge] call _check;

_observer removeEventHandler ["FiredMan",_firedId];
_observerGroup enableGunLights "forceOff";
{deleteVehicle _x} forEach [_front,_rear,_observer];
{deleteGroup _x} forEach [_frontGroup,_rearGroup,_observerGroup];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
setDate _savedDate;
{missionNamespace setVariable [_x,_saved select _forEachIndex]} forEach _keys;
