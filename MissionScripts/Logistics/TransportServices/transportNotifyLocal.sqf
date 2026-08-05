/*
 * Author: WaldoTheWarfighter, Val
 * Shows a transport-service message through the master WMP notification UI. Named services use
 * independent channels so concurrent vehicles stack/overflow normally, while repeat state from
 * one vehicle replaces its previous card instead of producing delayed notification after-play.
 * Locality and authority: interface-client presentation only; it changes no service state.
 *
 * Arguments: 0 type <STRING>; 1 message <STRING>; 2 state <STRING> (default INFO);
 * 3 service/channel key <STRING> (optional); 4 duration <NUMBER> (default 7 seconds).
 * Return Value: STRING token from Waldo_fnc_ShowUiNotification.
 * Example: ["HELICOPTER", "Raven One is inbound.", "INFO", "RAVEN_1"] call Waldo_fnc_TransportNotifyLocal;
 * Current callers: authoritative request/report functions through owner-targeted remote execution.
 */
params [
    ["_type", "GROUND", [""]], ["_message", "", [""]], ["_state", "INFO", [""]],
    ["_serviceKey", "", [""]], ["_duration", 7, [0]]
];
if (!hasInterface || {_message == ""}) exitWith {""};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {""};
private _heli = toUpperANSI _type == "HELICOPTER";
private _baseChannel = ["GROUND_TRANSPORT", "HELI_TRANSPORT"] select _heli;
private _safeKey = toUpperANSI ([_serviceKey, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString);
private _channel = if (_safeKey == "") then {_baseChannel} else {format ["%1_%2", _baseChannel, _safeKey]};
private _priority = switch (toUpperANSI _state) do {case "ERROR": {3}; case "WARNING": {2}; case "SUCCESS": {1}; default {0}};
[
    ["GROUND TRANSPORT", "HELICOPTER TRANSPORT"] select _heli,
    _message, _state, _duration, "TOP_RIGHT", _channel, "WMP TRANSPORT", "REPLACE", _priority
] call Waldo_fnc_ShowUiNotification
