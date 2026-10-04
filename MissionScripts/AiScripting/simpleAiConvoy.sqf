/*
 * Author: WaldoTheWarfighter
 * Purpose: Keep an AI vehicle group in column formation with capped speed and spacing.
 * Locality/authority: server configures the group and pins its crew to server ownership.
 * Repeat/JIP: replacing a group controller terminates its previous worker; no client replay is needed.
 * Arguments: 0 group <GROUP>; 1 speed <NUMBER, default 30 km/h>; 2 separation <NUMBER, default 15 m>;
 * 3 push through <BOOL, default true>; 4 requesting curator <OBJECT, default objNull> for remote calls.
 * Return Value: SCRIPT handle on server, scriptNull when rejected.
 * Current callers: mission-maker server scripts and Waldo_fnc_ZenConvoyModule.
 * Example: [group driver truck1, 30, 15, true] call Waldo_fnc_SimpleAiConvoy;
 */
params ["_convoyGroup", ["_convoySpeed", 30], ["_convoySeparation", 15], ["_pushThrough", true], ["_requester", objNull]];
if (!isServer || {isClass (configFile >> "CfgPatches" >> "Waldo_AI_Tweaks_Main")}) exitWith {scriptNull};
if (isRemoteExecuted && {remoteExecutedOwner != 2} && {
    isNull _requester || {owner _requester != remoteExecutedOwner} || {isNull getAssignedCuratorLogic _requester}
}) exitWith {scriptNull};
if (!(_convoyGroup isEqualType grpNull) || {isNull _convoyGroup} || {!(_convoySpeed isEqualType 0)} || {!(_convoySeparation isEqualType 0)} || {!(_pushThrough isEqualType true)}) exitWith {scriptNull};
if (_convoySpeed < 5 || {_convoySpeed > 120} || {_convoySeparation < 5} || {_convoySeparation > 100}) exitWith {scriptNull};
private _vehicles = (units _convoyGroup apply {vehicle _x}) arrayIntersect (units _convoyGroup apply {vehicle _x});
_vehicles = _vehicles select {_x isKindOf "LandVehicle" && {alive _x} && {!isNull driver _x} && {driver _x in units _convoyGroup}};
if (_vehicles isEqualTo []) exitWith {scriptNull};
private _old = _convoyGroup getVariable ["Waldo_Convoy_Worker", scriptNull];
if (!isNull _old) then {terminate _old};
{[_x] call Waldo_fnc_HeadlessPinCrew} forEach _vehicles;
private _worker = [_convoyGroup, _convoySpeed, _convoySeparation, _pushThrough] spawn {
    params ["_group", "_speed", "_separation", "_push"];
    private _ownershipDeadline = diag_tickTime + 10;
    waitUntil {sleep 0.2; isNull _group || {local _group} || {diag_tickTime >= _ownershipDeadline} || {isClass (configFile >> "CfgPatches" >> "Waldo_AI_Tweaks_Main")}};
    if (isNull _group || {!local _group} || {isClass (configFile >> "CfgPatches" >> "Waldo_AI_Tweaks_Main")}) exitWith {};
    if (_push) then {_group enableAttack false};
    _group setFormation "COLUMN";
    while {!isNull _group && {local _group} && {!(isClass (configFile >> "CfgPatches" >> "Waldo_AI_Tweaks_Main"))}} do {
        private _members = units _group;
        private _vehicles = (_members apply {vehicle _x}) arrayIntersect (_members apply {vehicle _x});
        _vehicles = _vehicles select {_x isKindOf "LandVehicle" && {alive _x} && {local _x}};
        {
            _x limitSpeed (_speed * 1.15);
            _x setConvoySeparation _separation;
            if (_push) then {_x setUnloadInCombat [false, false]};
        } forEach _vehicles;
        private _lead = vehicle leader _group;
        if (_lead in _vehicles) then {_lead limitSpeed _speed};
        {
            if (_x != leader _group && {vehicle _x != _lead} && {speed vehicle _x < 5} && {_push || {behaviour _x != "COMBAT"}}) then {
                (vehicle _x) doFollow leader _group;
            };
        } forEach (_members - allPlayers);
        sleep 5;
    };
};
_convoyGroup setVariable ["Waldo_Convoy_Worker", _worker];
_worker
