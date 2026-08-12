/*
 * Author: WaldoTheWarfighter
 * Starts player-local rally interactions and restores them safely after player respawn.
 *
 * Interaction installation is local and repeat-safe. After respawn, a player who selected the
 * group's active rally is recognised by proximity to its stored spawn position; the client resolves
 * a fresh open point and moves locally only when necessary, preventing placement inside the rally
 * object or a newly introduced obstruction. Other respawn selections are not moved.
 *
 * Arguments: None.
 * Return Value: Boolean - true when initialized/already installed; otherwise false.
 * Example: [] call Waldo_fnc_RallyPointInit;
 * Current callers: initPlayerLocal.sqf and Rally ZEN runtime activation/JIP replay.
 */
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {!(missionNamespace getVariable ["Waldo_Rally_Enable", false])}) exitWith {false};
[player] call Waldo_fnc_RallyPointSetupLocal;
if (missionNamespace getVariable ["Waldo_Rally_RespawnHandlerInstalled", false]) exitWith {true};
missionNamespace setVariable ["Waldo_Rally_RespawnHandlerInstalled", true];
addMissionEventHandler ["EntityRespawned", {
    params ["_newEntity"];
    if (local _newEntity && {_newEntity isEqualTo player} && {missionNamespace getVariable ["Waldo_Rally_Enable", false]}) then {
        [_newEntity] call Waldo_fnc_RallyPointSetupLocal;
        private _group = group _newEntity;
        private _rally = _group getVariable ["Waldo_Rally_Object", objNull];
        private _registeredPosition = _group getVariable ["Waldo_Rally_RespawnPosition", []];
        if (!isNull _rally && {count _registeredPosition >= 2} && {_newEntity distance2D _registeredPosition <= 5}) then {
            private _safePosition = [_rally, typeOf _newEntity] call Waldo_fnc_RallyPointResolveSafePosition;
            if !(_safePosition isEqualTo []) then {[_newEntity, _safePosition] call Waldo_fnc_RallyPointMoveLocal};
        };
    };
}];
true
