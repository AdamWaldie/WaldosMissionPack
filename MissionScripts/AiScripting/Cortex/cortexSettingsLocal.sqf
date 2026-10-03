/*
 * Author: WaldoTheWarfighter
 * Applies one validated AI settings revision before starting or stopping dependent local workers.
 * Locality and authority: server-only remote sender; each machine owns its local AI handlers.
 * Repeat/JIP: stale revisions are ignored; JIP uses the full settings handshake and normal startup.
 * Master, grenade and civilian-handler switches are re-applied only when their effective values change.
 * Arguments: 0: revision <NUMBER>, required; 1: validated named settings <ARRAY>, required.
 * Return Value: Nothing.
 * Current callers: AIPassTuning on the server.
 * Example: [_revision,_updates] remoteExecCall ["Waldo_fnc_CortexSettingsLocal",0];
 * Result: local workers see the complete accepted update before reacting to its switches.
 */
params ["_revision","_updates"];
if (remoteExecutedOwner != 2) exitWith {};
if (_revision < (missionNamespace getVariable ["Waldo_AIPass_SettingsRevision",0])
    || {_revision <= (missionNamespace getVariable ["Waldo_AIPass_SettingsApplied",-1])}) exitWith {};
{missionNamespace setVariable [_x select 0,_x select 1]} forEach _updates;
missionNamespace setVariable ["Waldo_AIPass_SettingsRevision",_revision];
missionNamespace setVariable ["Waldo_AIPass_SettingsApplied",_revision];
private _effects = [missionNamespace getVariable ["Waldo_AIRebalance_Enable",true],missionNamespace getVariable ["Waldo_AIRebalance_Mode","AUTO"],missionNamespace getVariable ["Waldo_AIRebalance_Profile","LINE"],missionNamespace getVariable ["Waldo_AIPass_Enable",false],missionNamespace getVariable ["Waldo_AIPass_GrenadeEvasion_Enable",true],missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Enable",true]];
private _previous = missionNamespace getVariable ["Waldo_AIPass_SettingsEffects",[]];
if (_previous isEqualTo [] || {(_previous select [0,3]) isNotEqualTo (_effects select [0,3])}) then {
    if (_effects select 0) then {[_effects select 1,_effects select 2] call Waldo_fnc_AIRebalanceInit} else {[] call Waldo_fnc_AIRebalanceStop};
};
if (_previous isEqualTo [] || {(_previous select [3,3]) isNotEqualTo (_effects select [3,3])}) then {
    if (_effects select 3) then {[] call Waldo_fnc_CortexInit} else {[] call Waldo_fnc_CortexStop};
};
missionNamespace setVariable ["Waldo_AIPass_SettingsEffects",_effects];
