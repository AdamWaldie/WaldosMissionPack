/*
 * Author: WaldoTheWarfighter
 * Creates a collision-resistant identifier containing only characters accepted by WMP's
 * server-authoritative runtime registries. It deliberately avoids formatting serverTime,
 * diag_tickTime or large random numbers because Arma may render them in scientific notation;
 * the resulting decimal point and plus sign caused long-running dedicated servers to reject
 * otherwise valid ZEN-created gunships, AA systems, hazards and paradrop operations.
 *
 * Locality and authority:
 * Pure local helper. It may run on a curator client, server, headless client or normal client.
 * The local client owner, UTC wall-clock fields and a bounded local counter make repeated calls
 * distinct without requiring network state. The receiving authority still validates uniqueness.
 *
 * Arguments:
 * 0: prefix <STRING> - human-readable identifier prefix (default "WMP")
 *
 * Return Value:
 * STRING - safe identifier containing only letters, numbers, underscore and hyphen.
 *
 * Example:
 * private _id = ["AA"] call Waldo_fnc_CreateRuntimeId;
 *
 * Result:
 * A value similar to AA_11_2026_8_3_21_45_12_418_1, never scientific notation.
 *
 * Current callers:
 * Dynamic AA, Dynamic AO, airborne gunship, hazardous-environment and paradrop ZEN dialogs.
 */

params [["_prefix", "WMP", [""]]];

private _safePrefix = [_prefix, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_safePrefix == "") then {_safePrefix = "WMP"};

private _counter = ((missionNamespace getVariable ["Waldo_RuntimeIdCounter", 0]) + 1) mod 100000;
missionNamespace setVariable ["Waldo_RuntimeIdCounter", _counter];

private _clock = systemTimeUTC apply {str (floor _x)};
format [
    "%1_%2_%3_%4",
    _safePrefix,
    clientOwner,
    _clock joinString "_",
    _counter
]
