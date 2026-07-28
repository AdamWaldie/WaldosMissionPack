/* Clears one group's active rally without touching its server-owned cooldown. */
params [["_group", grpNull, [grpNull]], ["_reason", "Rally point removed.", [""]], ["_state", "INFO", [""]]];
if (!isServer || {remoteExecutedOwner > 0} || {isNull _group}) exitWith {false};
if !(_group getVariable ["Waldo_Rally_Active", false]) exitWith {false};
private _respawn = _group getVariable ["Waldo_Rally_RespawnHandle", []];
if !(_respawn isEqualTo []) then {_respawn call BIS_fnc_removeRespawnPosition};
private _object = _group getVariable ["Waldo_Rally_Object", objNull];
if (!isNull _object) then {deleteVehicle _object};
_group setVariable ["Waldo_Rally_Active", false, true];
_group setVariable ["Waldo_Rally_Object", objNull, true];
_group setVariable ["Waldo_Rally_ExpiresAt", -1, true];
_group setVariable ["Waldo_Rally_RespawnHandle", []];
if (_reason != "") then {[_reason, _state] remoteExecCall ["Waldo_fnc_RallyPointNotifyLocal", units _group]};
true
