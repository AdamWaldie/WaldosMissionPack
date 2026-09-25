/*
 * Author: WaldoTheWarfighter
 * Starts the Smart AI Pass on this machine if it owns AI: the server or a headless client.
 *
 * Installs one CBA per-frame handler (0.25 s) that runs Waldo_fnc_AIPassSchedulerTick, and one
 * EntityKilled mission handler that passes kills in locally owned groups to the kill-driven
 * behaviours. Existing local groups have their peak strength recorded. Repeat calls are safe
 * because each handler is installed once. Player clients return immediately and pay nothing. Each
 * behaviour has its own Waldo_AIPass_<Behaviour>_Enable switch in MissionConfig\aiConfig.sqf, and
 * Waldo_fnc_AIPassIsEligible keeps player groups and other WMP features' units out.
 * Locality and authority: the server publishes Waldo_AIPass_Enable and replays this call to
 * headless clients through the JIP key Waldo_AIPass_RuntimeInit. Remote calls from anything other
 * than the server are refused. A headless client waits for the feature-runtime snapshot first.
 *
 * Arguments: None.
 *
 * Return Value:
 * Boolean - true when the pass is running on this machine
 *
 * Example:
 * [] call Waldo_fnc_AIPassInit;
 * Result: on the server, the pass starts and every connected or later headless client starts it too.
 *
 * Current callers: init.sqf when Waldo_AIPass_Enable is true, the AI Control ZEN module and JIP replay.
 */

if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (hasInterface && {!isServer}) exitWith {false};
if (!isServer && {!(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false])}) exitWith {
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
        };
        if (missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {[] call Waldo_fnc_AIPassInit};
    };
    true
};

missionNamespace setVariable ["Waldo_AIPass_Active", true];
if (isServer) then {
    missionNamespace setVariable ["Waldo_AIPass_Enable", true, true];
    if (remoteExecutedOwner == 0) then {
        [] remoteExecCall ["Waldo_fnc_AIPassInit", -2, "Waldo_AIPass_RuntimeInit"];
    };
};

if (isNil {missionNamespace getVariable "Waldo_AIPass_SchedulerHandle"}) then {
    missionNamespace setVariable ["Waldo_AIPass_SchedulerHandle", [{[] call Waldo_fnc_AIPassSchedulerTick}, 0.25] call CBA_fnc_addPerFrameHandler];
};
if (isNil {missionNamespace getVariable "Waldo_AIPass_KilledHandler"}) then {
    missionNamespace setVariable ["Waldo_AIPass_KilledHandler", addMissionEventHandler ["EntityKilled", {
        params ["_unit"];
        if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {};
        if !(_unit isKindOf "CAManBase") exitWith {};
        private _group = group _unit;
        if (isNull _group || {!local _group}) exitWith {};
        [_group, _unit] call Waldo_fnc_AIPassRegroupOnKill;
    }]];
};

{
    if (local _x) then {
        _x setVariable ["Waldo_AIPass_PeakSize", (_x getVariable ["Waldo_AIPass_PeakSize", 0]) max ({alive _x} count units _x)];
    };
} forEach allGroups;

diag_log format ["[WMP AI PASS] Started on %1 (regroup=%2).",
    ["headless client", "server"] select isServer,
    missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable", true]
];
true
