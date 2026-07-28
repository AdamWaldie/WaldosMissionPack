/* Starts player-local rally interactions and keeps them across unit respawn. */
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {!(missionNamespace getVariable ["Waldo_Rally_Enable", false])}) exitWith {false};
[player] call Waldo_fnc_RallyPointSetupLocal;
if (missionNamespace getVariable ["Waldo_Rally_RespawnHandlerInstalled", false]) exitWith {true};
missionNamespace setVariable ["Waldo_Rally_RespawnHandlerInstalled", true];
missionNamespace addMissionEventHandler ["EntityRespawned", {
    params ["_newEntity"];
    if (local _newEntity && {_newEntity isKindOf "CAManBase"} && {missionNamespace getVariable ["Waldo_Rally_Enable", false]}) then {
        [_newEntity] call Waldo_fnc_RallyPointSetupLocal;
    };
}];
true
