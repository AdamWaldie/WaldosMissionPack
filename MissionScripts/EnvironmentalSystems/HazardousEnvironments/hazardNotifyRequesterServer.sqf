/*
 * Author: WaldoTheWarfighter, Val
 * Relays one client-owned dosimeter result to the player who requested it. Hazard exposure is
 * intentionally stored on the exposed player's machine, so the server authenticates that machine
 * before forwarding the result through the server-only WMP notification endpoint.
 *
 * Locality, repeat and JIP behaviour:
 * Runs only on the server. A remote caller must own the target player whose exposure was read.
 * Each accepted reading creates one transient notification for the requester and is not replayed
 * to JIP clients. Repeated dosimeter uses are independent and safe.
 *
 * Arguments:
 * 0: target <OBJECT> - player whose client supplied the exposure reading.
 * 1: requester <OBJECT> - player who should receive the result.
 * 2: message <STRING> - formatted dosimeter result, limited to 512 characters.
 * 3: state <STRING> - SUCCESS for a clear reading or WARNING for exposure (default SUCCESS).
 *
 * Return Value:
 * Boolean - true when an authenticated result was forwarded; false when rejected.
 *
 * Current callers:
 * Waldo_fnc_HazardReadExposureLocal when the requester is on another client.
 *
 * Example:
 * [player, remoteRequester, "Player has no measurable exposure.", "SUCCESS"]
 *     remoteExecCall ["Waldo_fnc_HazardNotifyRequesterServer", 2];
 */
params [
    ["_target", objNull, [objNull]],
    ["_requester", objNull, [objNull]],
    ["_message", "", [""]],
    ["_state", "SUCCESS", [""]]
];
if (!isServer || {isNull _target} || {isNull _requester} || {!isPlayer _target} || {!isPlayer _requester}) exitWith {false};
private _caller = remoteExecutedOwner;
if (_caller > 2 && {owner _target != _caller}) exitWith {false};
if (_message isEqualTo "") exitWith {false};
_state = toUpperANSI _state;
if !(_state in ["SUCCESS", "WARNING"]) then {_state = "WARNING"};
[
    "HAZARD DOSIMETER",
    _message select [0, 512],
    _state,
    "HAZARD_DOSIMETER",
    6
] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _requester];
true
