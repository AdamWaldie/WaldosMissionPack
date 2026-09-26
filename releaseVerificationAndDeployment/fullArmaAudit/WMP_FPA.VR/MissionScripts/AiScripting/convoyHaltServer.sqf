/*
 * Author: WaldoTheWarfighter
 * Accepts an arrival, pinned-contact or mobility-failure halt from the current convoy owner.
 * Locality/authority: server only; stale revisions and former owners cannot stop a resumed convoy.
 * Repeat/JIP: transition is recorded in the ordered registry; a held convoy never automatically resumes.
 * Arguments: 0: group <GROUP>, grpNull; 1: expected revision <NUMBER>, -1; 2: reason <STRING>, ARRIVED; 3: believed threat ATL <ARRAY>, [].
 * Return Value: Boolean, transition accepted.
 * Current callers: ConvoyTick on the server/headless group owner.
 * Example: [convoyGroup, 3, "AMBUSH"] remoteExecCall ["Waldo_fnc_ConvoyHaltServer", 2];
 */
params [["_group", grpNull, [grpNull]], ["_expected", -1, [0]], ["_reason", "ARRIVED", [""]], ["_threat", [], [[]]]];
if (!isServer || {isNull _group} || {!(_reason in ["ARRIVED", "AMBUSH", "IMMOBILE"])}) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2} && {remoteExecutedOwner != groupOwner _group}) exitWith {false};
private _registry = missionNamespace getVariable ["Waldo_Convoy_Registry", []];
private _index = _registry findIf {(_x select 0) == _group};
if (_index < 0) exitWith {false};
private _configuration = (_registry select _index) select 1;
if ((_configuration select 0) != _expected || {(_configuration select 5) != "TRAVEL"}) exitWith {false};
if ([] call Waldo_fnc_AIPassIsPaused || {[_group] call Waldo_fnc_AIPassZeusHeld}) exitWith {false};
private _accepted = [_group, 0, 15, true, false, [["reason", _reason], ["threat", _threat]]] call Waldo_fnc_SimpleAiConvoy;
if (_accepted) then {diag_log format ["[WMP CONVOY] Hold and unload: group=%1 reason=%2 revision=%3", _group, _reason, _expected]};
_accepted
