/*
 * Author: Waldo
 * Sends one client or headless-client runtime-state request to the server.
 * Arguments: None
 * Return Value: Boolean
 */

if (isServer || {remoteExecutedOwner > 0}) exitWith {false};
[] remoteExecCall ["Waldo_fnc_FeatureRuntimeRequestState", 2];
true
