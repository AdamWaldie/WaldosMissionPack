/*
 * Author: WaldoTheWarfighter
 * Sends one client or headless-client runtime-state request to the server.
 * Locality and authority: Runs only on a client or headless client and rejects a remote call;
 * the server validates the requester when it receives the request.
 * Repeat/JIP: One-shot send with no persistent handler. FeatureRuntimeRequestState handles
 * bounded retries and readiness for a joining machine.
 * Arguments: None
 * Return Value: Boolean
 * Current caller: Waldo_fnc_FeatureRuntimeRequestState retry loop.
 * Example: [] call Waldo_fnc_FeatureRuntimeSendStateRequest;
 * Result: One state request is sent to the server for a complete runtime snapshot.
 */

if (isServer || {remoteExecutedOwner > 0}) exitWith {false};
[] remoteExecCall ["Waldo_fnc_FeatureRuntimeRequestState", 2];
true
