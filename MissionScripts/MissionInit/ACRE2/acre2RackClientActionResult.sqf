/*
 * Author: WaldoTheWarfighter
 * Server-side receiver for Waldo_fnc_ACRE2RackClientAction: records the first successful result for a
 * given request ID, so Waldo_fnc_ACRE2RackApply's bounded wait can pick it up without needing to know
 * in advance which connected client actually holds the live ACRE2 rack state.
 *
 * Locality and authority:
 * Server-only. Only the first report for a given request ID is kept - a request that genuinely has
 * more than one valid answering client (e.g. a rack ACRE2 happens to have synced further than usual)
 * reports the same value from each, so keeping the first is deterministic and never mixes results from
 * two different requests.
 *
 * Arguments:
 * 0: RequestId <STRING> - matches the ID passed to Waldo_fnc_ACRE2RackClientAction.
 * 1: Value <ANY> - the action-specific result; see Waldo_fnc_ACRE2RackClientAction's header for shape.
 *
 * Return Value: Nothing.
 * Example: [_requestId, _value] remoteExecCall ["Waldo_fnc_ACRE2RackClientActionResult", 2];
 * Current caller: Waldo_fnc_ACRE2RackClientAction (remote clients reporting back to the server).
 */

params [["_requestId", "", [""]], "_value"];

if !(isServer) exitWith {};
if (_requestId == "") exitWith {};

if (isNil {missionNamespace getVariable _requestId}) then {
    missionNamespace setVariable [_requestId, _value];
};
