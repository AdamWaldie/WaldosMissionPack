/*
 * Author: WaldoTheWarfighter
 * Reconciles a complete server-authored dialogue descriptor snapshot on one interface client.
 * Locality/authority: client presentation only; accepts server remote execution only.
 * Repeat/JIP behaviour: removes stale local actions before applying current descriptors.
 * Arguments: 0 state version <NUMBER>; 1 descriptors <ARRAY>. Return Value: BOOL.
 * Current caller: DialoguePublishState. Example: server remote execution only.
 */
params [["_version", -1, [0]], ["_snapshot", [], [[]]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface) exitWith {false};
private _currentVersion = missionNamespace getVariable ["Waldo_Dialogue_LocalStateVersion", -1];
if (_version < _currentVersion) exitWith {false};
private _previous = missionNamespace getVariable ["Waldo_Dialogue_LocalSpeakers", []];
private _current = _snapshot apply {_x param [0, objNull]};
{if (!isNull _x && {!(_x in _current)}) then {[_x] call Waldo_fnc_DialogueRemoveActionLocal}} forEach _previous;
{_x call Waldo_fnc_DialogueApplyActionLocal} forEach _snapshot;
missionNamespace setVariable ["Waldo_Dialogue_LocalSpeakers", _current select {!isNull _x}];
missionNamespace setVariable ["Waldo_Dialogue_LocalStateVersion", _version];
missionNamespace setVariable ["Waldo_Dialogue_StateReady", true];
true
