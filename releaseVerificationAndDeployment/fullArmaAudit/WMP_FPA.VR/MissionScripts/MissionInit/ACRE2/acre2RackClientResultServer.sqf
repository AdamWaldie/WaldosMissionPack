/*
 * Author: WaldoTheWarfighter
 * Accepts one ACRE rack application/read-back result from the exact interface client selected by
 * the server rack worker. The token, client owner and running vehicle request must all match.
 * Locality/authority: server only; remotely called by Waldo_fnc_ACRE2RackClientApply. The result is
 * transient server state consumed once by Waldo_fnc_ACRE2RackApply and is not JIP state.
 * Repeat behaviour: duplicate/stale/wrong-owner replies are rejected without changing rack state.
 *
 * Arguments:
 * 0: rack vehicle/object <OBJECT>
 * 1: request token <STRING>
 * 2: result <ARRAY> - [success, applied count, requested count, problems, diagnostic snapshot]
 * Return Value: BOOL - true only when this result was accepted.
 * Current caller: Waldo_fnc_ACRE2RackClientApply.
 * Example: [_vehicle, _token, [true, 1, 1, [], _snapshot]] remoteExecCall
 *          ["Waldo_fnc_ACRE2RackClientResultServer", 2];
 */
params [
    ["_vehicle", objNull, [objNull]],
    ["_token", "", [""]],
    ["_result", [], [[]]]
];
if (!isServer || {remoteExecutedOwner <= 2} || {isNull _vehicle}) exitWith {false};
if !(_vehicle getVariable ["Waldo_ACRE2_RackSetupRunning", false]) exitWith {false};
if ((_vehicle getVariable ["Waldo_ACRE2_RackClientOwner", -1]) != remoteExecutedOwner) exitWith {false};
if ((_vehicle getVariable ["Waldo_ACRE2_RackClientToken", ""]) != _token) exitWith {false};
if !(
    _result isEqualType [] && {count _result == 5}
    && {(_result select 0) isEqualType true}
    && {(_result select 1) isEqualType 0}
    && {(_result select 2) isEqualType 0}
    && {(_result select 3) isEqualType []}
    && {(_result select 4) isEqualType []}
) exitWith {false};
_vehicle setVariable ["Waldo_ACRE2_RackClientResult", _result];
true

