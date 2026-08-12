/*
 * Author: WaldoTheWarfighter
 * Confirms a corpse's death for the Obituary system: the medic-facing "Pronounce Dead" ACE target
 * interaction's statement calls this. Server-authoritative and self-forwarding, matching
 * Waldo_fnc_Jammer/Waldo_fnc_Tracker - safe to call from any client, which is exactly how the ACE
 * action statement (running on the pronouncing medic's own machine) uses it. Reads only the plain
 * data Waldo_fnc_ObituaryRecordDeath cached at time of death (never a live name/object lookup, so a
 * victim who has since disconnected still gets a correct report), sets ACE triage level 4, creates
 * a server-owned global map marker for the grid-reference diary link, increments the per-victim
 * confirmed-death AAR tally (Waldo_AAR_Obituary, read by ENDEX.sqf), and appends the formatted
 * report to the broadcast Obituary document state so every client's diary render loop can update.
 * Idempotent per corpse: a second pronounce on an already-complete corpse is a no-op.
 * Locality and authority: forwards itself to the server via remoteExec [..., 2] when called from a
 * client; all state mutation (AAR tally, Obituary document, marker) happens only on the server.
 *
 * Arguments:
 * 0: Target <OBJECT> - the corpse being pronounced dead
 * 1: Player <OBJECT> - the medic performing the pronouncement
 *
 * Return Value:
 * Boolean - true when the pronouncement was recorded (false if already complete, forwarded, or null)
 *
 * Example:
 * [_target, _player] call Waldo_fnc_ObituaryPronounce;
 * Result: the corpse is marked complete, the AAR obituary tally and diary document both update.
 * Current caller: the "Pronounce Dead" ACE action statement installed by Waldo_fnc_ObituaryInit.
 */

params ["_target", "_player"];
if (isNull _target) exitWith {false};
if !(isServer) exitWith { [_target, _player] remoteExec ["Waldo_fnc_ObituaryPronounce", 2]; false };
if (_target getVariable ["Waldo_Obituary_Complete", true]) exitWith {false}; // idempotent

(_target getVariable ["Waldo_Obituary_DeathInfo", []]) params
    ["_tod", "_victimName", "_causeText", "_isFriendlyFire", "_instigatorName", "_direction", "_position", "_side"];

private _toDiscovery = format ["%1/%2/%3 %4:%5", date select 2, date select 1, date select 0,
    [date select 3] call Waldo_fnc_ObituaryPad2, [date select 4] call Waldo_fnc_ObituaryPad2];
private _toDeath = format ["%1/%2/%3 %4:%5", _tod select 2, _tod select 1, _tod select 0,
    [_tod select 3] call Waldo_fnc_ObituaryPad2, [_tod select 4] call Waldo_fnc_ObituaryPad2];

private _gridRef = mapGridPosition _position;
private _markerId = missionNamespace getVariable ["Waldo_Obituary_NextMarkerId", 0];
missionNamespace setVariable ["Waldo_Obituary_NextMarkerId", _markerId + 1, true];
private _markerName = format ["Waldo_Obituary_Death_%1", _markerId];
createMarker [_markerName, _position];
_markerName setMarkerType "Empty";
_markerName setMarkerAlpha 0;

private _ffSuffix = if (_isFriendlyFire) then {format [" - Friendly fire (%1)", _instigatorName]} else {""};
private _textBrief = format ["%1 was pronounced KIA by %2%3", _victimName, name _player, _ffSuffix];
private _textBlock = format [
    "MEDICAL REPORT<br/>KILLED IN ACTION<br/><br/>Time of Assessment: %1<br/>Patient Name: %2<br/>Assessment By: %3<br/>Time of Death: %4<br/>Cause of Death: %5<br/>Location: <marker name='%6'>GR%7</marker><br/>",
    _toDiscovery, _victimName, name _player, _toDeath, _causeText, _markerName, _gridRef
];

_target setVariable ["ace_medical_triageLevel", 4, true];
_target setVariable ["Waldo_Obituary_Complete", true, true];

// AAR accumulator: Waldo_AAR_Frags idiom, keyed by cached victim name (never re-derived).
private _obit = +(missionNamespace getVariable ["Waldo_AAR_Obituary", []]);
private _at = _obit findIf {(_x select 0) isEqualTo _victimName};
if (_at < 0) then {
    _obit pushBack [_victimName, 1];
} else {
    (_obit select _at) set [1, ((_obit select _at) select 1) + 1];
};
missionNamespace setVariable ["Waldo_AAR_Obituary", _obit, true];

// Obituary document state. Keep the fields as plain serialisable data so each client can group all
// of one player's deaths onto one page instead of consuming one diary record per body.
private _entries = +(missionNamespace getVariable ["Waldo_Obituary_Entries", []]);
_entries pushBack [_markerId, _victimName, _toDiscovery, name _player, _toDeath, _causeText, _markerName, _gridRef, _textBlock];
missionNamespace setVariable ["Waldo_Obituary_Entries", _entries, true];
// Compatibility mirror for scripts that only inspect whether obituary text exists. The diary
// renderer uses Waldo_Obituary_Entries and never presents this combined string.
missionNamespace setVariable ["Waldo_Obituary_Text", _textBlock, true];
missionNamespace setVariable ["Waldo_Obituary_Version", (missionNamespace getVariable ["Waldo_Obituary_Version", 0]) + 1, true];

if (missionNamespace getVariable ["Waldo_Obituary_ChatAnnounce", true]) then {
    [_textBrief] remoteExec ["systemChat", 0];
};
true
