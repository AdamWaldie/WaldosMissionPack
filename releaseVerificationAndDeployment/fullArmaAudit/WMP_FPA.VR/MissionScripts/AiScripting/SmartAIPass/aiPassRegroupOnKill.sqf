/*
 * Author: WaldoTheWarfighter
 * Records a group's peak strength when one of its members dies and, if the group may now be a
 * remnant, queues one survivor-regroup evaluation on the machine that owns the group.
 *
 * Only kills trigger survivor regroup. Nothing polls living units, and no fired-near events are
 * added. The peak strength separates the survivors of a destroyed squad from deliberate small teams:
 * a sniper pair or lone sentry never reaches Waldo_AIPass_Regroup_MinimumPeakSize, so it is never
 * merged. Peak strength is stored only on the owning machine. Existing groups are seeded when the
 * pass starts, and the first kill on a new owner counts the members still listed in the group.
 * Locality and authority: called from the EntityKilled handler on the machine where the group is
 * local. Nothing is broadcast.
 *
 * Arguments:
 * 0: group <GROUP> - the dead unit's group
 * 1: unit <OBJECT> - the dead unit
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [group _unit, _unit] call Waldo_fnc_AIPassRegroupOnKill;
 * Result: a remnant evaluation runs after Waldo_AIPass_Regroup_SettleSeconds.
 *
 * Current caller: the EntityKilled handler installed by Waldo_fnc_AIPassInit.
 */

params [["_group", grpNull, [grpNull]], ["_unit", objNull, [objNull]]];
if (isNull _group || {!local _group}) exitWith {};
private _listed = count units _group;
if !(_unit in units _group) then {_listed = _listed + 1};
_group setVariable ["Waldo_AIPass_PeakSize", (_group getVariable ["Waldo_AIPass_PeakSize", 0]) max _listed];

if !(missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable", true]) exitWith {};
if (_group getVariable ["Waldo_AIPass_RegroupQueued", false]) exitWith {};
private _alive = {alive _x} count units _group;
if (_alive == 0 || {_alive > (missionNamespace getVariable ["Waldo_AIPass_Regroup_MaxRemnantSize", 2])}) exitWith {};

_group setVariable ["Waldo_AIPass_RegroupQueued", true];
[
    Waldo_fnc_AIPassRegroupStep,
    createHashMapFromArray [["group", _group], ["phase", "EVALUATE"], ["firstEvaluation", -1]],
    missionNamespace getVariable ["Waldo_AIPass_Regroup_SettleSeconds", 5]
] call Waldo_fnc_AIPassQueueJob;
