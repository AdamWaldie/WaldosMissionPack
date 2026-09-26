/*
 * Author: WaldoTheWarfighter
 * Accepts a reservation only after checking local eligibility, actual capability and existing orders.
 * Locality/authority: server owns reservations; current group owners validate and execute orders.
 * Repeat/JIP: unique tokens, shared deadlines and owner acknowledgements retire stale assignments.
 * Arguments: 0: helper <GROUP>, grpNull; 1: server lease <ARRAY>, [].
 * Return Value: Nothing.
 * Current callers: SupportStep.
 * Example: [_group, _lease] remoteExecCall ["Waldo_fnc_AIPassSupportLocal", groupOwner _group];
 */
params [["_group",grpNull,[grpNull]],["_lease",[],[[]]]];
if (remoteExecutedOwner != 2 || {isNull _group} || {!local _group} || {count _lease != 6}) exitWith {};
[Waldo_fnc_AIPassSupportApply,createHashMapFromArray [["group",_group],["lease",_lease],["waitUntil",serverTime+5]],0] call Waldo_fnc_AIPassQueueJob;
