/*
 * Author: WaldoTheWarfighter, Val
 * Starts the repeat-safe local hazardous-environment evaluator.
 *
 * The evaluator waits for the authoritative runtime snapshot before starting, then owns only the
 * local player's exposure, transition notifications and effects. It is called from
 * initPlayerLocal.sqf when enabled, from live ZEN activation for existing clients, and through JIP
 * replay. Repeated calls do not create duplicate loops.
 * Locality and authority: Interface-client only. It consumes the server snapshot but owns only
 * that player's local evaluator, exposure state, effects and UI.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when active or already running
 *
 * Example:
 * [] call Waldo_fnc_HazardInit;
 * Result: Starts one local evaluation loop, or returns true when it was already running.
 * Current callers: initPlayerLocal.sqf lifecycle, Waldo_fnc_HazardReceiveSnapshot and runtime activation.
 */

if !(hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_Hazard_Enable", false]) exitWith {false};
if ((missionNamespace getVariable ["Waldo_Hazard_Zones", []]) isEqualTo []) exitWith {
    diag_log "[WMP HAZARD] Evaluator start deferred: enabled but no authoritative zones are available.";
    false
};
if (missionNamespace getVariable ["Waldo_Hazard_ClientStarted", false]) exitWith {true};

missionNamespace setVariable ["Waldo_Hazard_ClientStarted", true];
[] call Waldo_fnc_HazardResetLocal;
if !(missionNamespace getVariable ["Waldo_Hazard_RespawnHandlerInstalled", false]) then {
    missionNamespace setVariable ["Waldo_Hazard_RespawnHandlerInstalled", true];
    private _respawnId = addMissionEventHandler ["EntityRespawned", {
        params ["_newEntity"];
        if (hasInterface && {local _newEntity} && {isPlayer _newEntity}) then {
            [] call Waldo_fnc_HazardResetLocal;
        };
    }];
    missionNamespace setVariable ["Waldo_Hazard_RespawnHandlerId", _respawnId];
};
// ACE's full-heal implementation raises this local extension event for every full heal, including
// the Zeus heal action. Reset the complete WMP hazard lifecycle on that same unit so accumulated
// dose, damage stage, attribution and pending presentation cannot survive an administrative heal.
if !(missionNamespace getVariable ["Waldo_Hazard_FullHealHandlerInstalled", false]) then {
    missionNamespace setVariable ["Waldo_Hazard_FullHealHandlerInstalled", true];
    ["ace_medical_treatment_fullHealLocalMod", {
        params ["_patient"];
        if (hasInterface && {_patient isEqualTo player} && {local _patient}) then {
            [] call Waldo_fnc_HazardResetLocal;
            diag_log format ["[WMP HAZARD] Full medical heal cleared hazard state object=%1 owner=%2.", netId _patient, clientOwner];
        };
    }] call CBA_fnc_addEventHandler;
};
[] call Waldo_fnc_HazardInteractionInit;
private _interval = (missionNamespace getVariable ["Waldo_Hazard_Interval", 1]) max 0.25;
private _handle = [_interval] spawn {
    params ["_interval"];
    while {missionNamespace getVariable ["Waldo_Hazard_ClientStarted", false]} do {
        [_interval] call Waldo_fnc_HazardTick;
        sleep _interval;
    };
};
missionNamespace setVariable ["Waldo_Hazard_ClientLoop", _handle];
diag_log format ["[WMP HAZARD] Local evaluator started with %1 zone(s).", count (missionNamespace getVariable ["Waldo_Hazard_Zones", []])];
true
