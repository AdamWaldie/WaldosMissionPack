/*
 * Author: WaldoTheWarfighter
 * Installs the event-driven WMP civilian danger response on one owner-local unarmed civilian.
 * Simple Civilian Behaviour is detected and left completely untouched. No per-frame or periodic
 * civilian scan is created; only FiredNear and Hit events can request a reaction.
 *
 * Locality / Authority: call where the unit is local. A Local handler repeats setup after migration.
 * Repeat/JIP: versioned handler IDs are removed before replacement; repeat calls are harmless.
 *
 * Arguments:
 * 0: civilian <OBJECT>, default objNull
 * 1: remove <BOOL>, default false
 *
 * Return Value:
 * Boolean - true when handlers are installed or removed, false when the unit is ineligible.
 *
 * Current callers: Cortex init, EntityCreated and the installed Local event handler.
 *
 * Example:
 * [_civilian] call Waldo_fnc_CortexCivilianSetup;
 * Result: gunfire near that owner-local civilian can trigger one bounded escape command.
 */

params [["_unit",objNull,[objNull]],["_remove",false,[true]]];
if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {false};
private _handlers=_unit getVariable ["Waldo_Cortex_CivilianHandlers",[]];
{_unit removeEventHandler _x} forEach _handlers;
_unit setVariable ["Waldo_Cortex_CivilianHandlers",nil];
if (_remove) exitWith {true};
if (!local _unit || {isPlayer _unit} || {side group _unit != civilian}
    || {primaryWeapon _unit != "" || {secondaryWeapon _unit != ""} || {handgunWeapon _unit != ""}}
    || {!(missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Enable",true])}
    || {[_unit] call Waldo_fnc_CortexExternalOwner != ""}) exitWith {false};
private _fired=_unit addEventHandler ["FiredNear",{
    params ["_unit","_firer","_distance"];
    if (_distance <= (missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Radius",45])) then {
        [_unit,_firer] call Waldo_fnc_CortexCivilianReact;
    };
}];
private _hit=_unit addEventHandler ["Hit",{
    params ["_unit","_source"];
    [_unit,_source] call Waldo_fnc_CortexCivilianReact;
}];
_unit setVariable ["Waldo_Cortex_CivilianHandlers",[["FiredNear",_fired],["Hit",_hit]]];
if (isNil {_unit getVariable "Waldo_Cortex_CivilianLocalHandler"}) then {
    private _local=_unit addEventHandler ["Local",{
        params ["_unit","_isLocal"];
        if (_isLocal) then {[_unit] call Waldo_fnc_CortexCivilianSetup};
    }];
    _unit setVariable ["Waldo_Cortex_CivilianLocalHandler",_local];
};
true
