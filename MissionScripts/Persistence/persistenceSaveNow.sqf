/*
 * Author: WaldoTheWarfighter
 * Requests immediate player saves and saves all registered objects without stopping persistence.
 *
 * Arguments:
 * 0: save players <BOOLEAN>
 * 1: save registered objects <BOOLEAN>
 *
 * Return Value:
 * Boolean - true when the save request was accepted
 *
 * Example:
 * [true, true] call Waldo_fnc_PersistenceSaveNow;
 */

params [
    ["_savePlayers", true, [false]],
    ["_saveObjects", true, [false]]
];
if !(isServer) exitWith {
    [_savePlayers, _saveObjects] remoteExecCall ["Waldo_fnc_PersistenceSaveNow", 2];
    true
};

private _requestOwner = remoteExecutedOwner;
private _authorized = true;
if (_requestOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == _requestOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _authorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_authorized) exitWith {false};

if !(missionNamespace getVariable ["Waldo_Persistence_Active", false]) exitWith {
    if (_requestOwner > 0) then {
        ["PERSISTENCE", "Persistence is not active; nothing was saved.", "WARNING", "PERSISTENCE"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
    };
    false
};

private _objectCount = 0;
if (_saveObjects) then {
    {
        _x params ["_object", "_key", "_options"];
        if (!isNull _object && {[_object, _key, _options] call Waldo_fnc_PersistenceSaveObject}) then {
            _objectCount = _objectCount + 1;
        };
    } forEach +(missionNamespace getVariable ["Waldo_Persistence_ObjectRegistry", []]);
};

private _playerCount = if (_savePlayers) then {count allPlayers} else {0};
if (_savePlayers) then {
    [] remoteExecCall ["Waldo_fnc_PersistenceSavePlayerLocal", 0];
};

diag_log format ["[WMP PERSISTENCE] Manual save requested for %1 player(s); %2 registered object(s) saved.", _playerCount, _objectCount];
if (_requestOwner > 0) then {
    ["PERSISTENCE", format ["Save requested for %1 player(s); %2 object(s) saved.", _playerCount, _objectCount], "SUCCESS", "PERSISTENCE"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
};
true
