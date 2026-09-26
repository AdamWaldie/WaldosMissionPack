/*
 * Author: WaldoTheWarfighter
 * Installs optional local FiredNear hearing on group leaders, recording uncertain areas rather than targets.
 * Locality/authority: each AI owner installs only on its current eligible leader; no remote reveal.
 * Repeat/JIP: tracked handlers are removed after transfer, disable, leader change or stop; reports expire.
 * Arguments: 0: group <GROUP>, grpNull; 1: force cleanup <BOOL>, false.
 * Return Value: Nothing.
 * Current callers: Discover, Stop and Locality.
 * Example: [_group] call Waldo_fnc_AIPassHearingLocal;
 */
params [["_group",grpNull,[grpNull]],["_cleanup",false,[true]]];
private _tracked = _group getVariable ["Waldo_AIPass_HearingHandler",[]];
private _leader = leader _group;
private _enabled = !_cleanup && {local _group} && {alive _leader} && {!isPlayer _leader}
    && {[_group] call Waldo_fnc_AIPassIsEligible} && {[_group,"Waldo_AIPass_Hearing_Enable",false] call Waldo_fnc_AIPassFeatureEnabled};
if (_tracked isNotEqualTo [] && {!_enabled || {(_tracked select 0) != _leader}}) then {
    (_tracked select 0) removeEventHandler ["FiredNear",_tracked select 1];
    _group setVariable ["Waldo_AIPass_HearingHandler",nil]; _tracked = [];
};
if (!_enabled || {_tracked isNotEqualTo []}) exitWith {};
private _handler = _leader addEventHandler ["FiredNear",{
    params ["_observer","_firer","_distance","_weapon","_muzzle","_mode","_ammo"];
    private _group = group _observer;
    if (!local _observer || {isNull _firer} || {!alive _observer} || {!(missionNamespace getVariable ["Waldo_AIPass_Active",false])}
        || {[] call Waldo_fnc_AIPassIsPaused} || {!([_group] call Waldo_fnc_AIPassIsEligible)}
        || {!([_group,"Waldo_AIPass_Hearing_Enable",false] call Waldo_fnc_AIPassFeatureEnabled)}
        || {(side _group) getFriend (side group _firer) >= 0.6}
        || {serverTime < (_group getVariable ["Waldo_AIPass_HearingDue",0])}) exitWith {};
    private _items = weaponsItems _firer;
    private _index = _items findIf {(_x select 0) == _weapon};
    private _suppressed = _index >= 0 && {((_items select _index) param [1,""]) != ""};
    private _audible = getNumber (configFile >> "CfgAmmo" >> _ammo >> "audibleFire");
    if ((_suppressed || {_audible > 0 && {_audible <= 3}}) && {_distance > 20}) exitWith {};
    _group setVariable ["Waldo_AIPass_HearingDue",serverTime+10];
    private _position = getPosATL _firer;
    // Deliberately quantize the report; never retain the firing object or follow later movement.
    _position = [50*round ((_position select 0)/50),50*round ((_position select 1)/50),0];
    private _old = _group getVariable ["Waldo_AIPass_AreaReport",[]];
    if (_old isEqualTo [] || {serverTime >= (_old select 2)} || {(_old select 3) == "SOUND"}) then {
        _group setVariable ["Waldo_AIPass_AreaReport",[_position,serverTime,serverTime+20,"SOUND"],true];
    };
}];
_group setVariable ["Waldo_AIPass_HearingHandler",[_leader,_handler]];
