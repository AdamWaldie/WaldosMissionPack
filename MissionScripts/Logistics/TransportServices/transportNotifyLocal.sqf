/*
 * Author: WaldoTheWarfighter, Val
 * Shows a transport-service message through the shared WMP notification UI.
 * Locality and authority: interface-client presentation only; it changes no service state.
 *
 * Arguments: 0 type <STRING>; 1 message <STRING>; 2 state <STRING> (default INFO).
 * Return Value: Boolean from Waldo_fnc_FeatureNotifyLocal.
 * Example: ["HELICOPTER", "Raven One is inbound.", "INFO"] call Waldo_fnc_TransportNotifyLocal;
 * Current callers: authoritative request/report functions through owner-targeted remote execution.
 */
params [["_type", "GROUND", [""]], ["_message", "", [""]], ["_state", "INFO", [""]]];
private _heli = toUpperANSI _type == "HELICOPTER";
[["GROUND TRANSPORT", "HELICOPTER TRANSPORT"] select _heli, _message, _state, ["GROUND_TRANSPORT", "HELI_TRANSPORT"] select _heli, 7] call Waldo_fnc_FeatureNotifyLocal
