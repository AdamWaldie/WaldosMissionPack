/*
 * Author: WaldoTheWarfighter
 * Starts the Smart AI Pass on this machine if it owns AI: the server or a headless client.
 *
 * Installs, once per machine:
 * - one CBA per-frame handler (0.25 s) that runs Waldo_fnc_AIPassSchedulerTick;
 * - one EntityKilled mission handler that passes kills in locally owned groups to survivor regroup;
 * - the Waldo_fnc_AIPassDiscover sweep job, which brings local groups under the pass;
 * - a ProjectileCreated handler for grenade evasion, only while Waldo_AIPass_GrenadeEvasion_Enable is
 *   on (it would otherwise run for every projectile);
 * - an ArtilleryShellFired handler for counter-battery, only while Waldo_AIPass_CounterBattery_Enable
 *   is on.
 * Existing local groups have their peak strength recorded. Repeat calls are safe, and they add the
 * optional handlers when their switches have been turned on since the last call. Player clients return immediately and pay nothing. Each
 * behaviour has its own Waldo_AIPass_<Behaviour>_Enable switch in MissionConfig\aiConfig.sqf, and
 * Waldo_fnc_AIPassIsEligible keeps player groups and other WMP features' units out.
 * Locality and authority: the server publishes Waldo_AIPass_Enable and replays this call to
 * headless clients through the JIP key Waldo_AIPass_RuntimeInit. Remote calls from anything other
 * than the server are refused. A headless client waits for the feature-runtime snapshot first.
 *
 * Review contract: Repeated pre-snapshot calls share one waiter. Stop cancels it; a headless client starts only if the completed authoritative snapshot still enables the pass.
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
    if (missionNamespace getVariable ["Waldo_AIPass_InitPending", false]) exitWith {true};
    missionNamespace setVariable ["Waldo_AIPass_InitPending", true];
    [] spawn {
        waitUntil {
            missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
            || {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotFailed", false]}
            || {!(missionNamespace getVariable ["Waldo_AIPass_InitPending", false])}
        };
        private _requested = missionNamespace getVariable ["Waldo_AIPass_InitPending", false];
        missionNamespace setVariable ["Waldo_AIPass_InitPending", false];
        if (_requested && {missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]}
            && {missionNamespace getVariable ["Waldo_AIPass_Enable", false]}) then {[] call Waldo_fnc_AIPassInit};
    };
    true
};

if (!isServer && {!(missionNamespace getVariable ["Waldo_AIPass_Enable", false])}) exitWith {false};
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

if (isNil {missionNamespace getVariable "Waldo_AIPass_ProjectileHandler"} && {missionNamespace getVariable ["Waldo_AIPass_GrenadeEvasion_Enable", false]}) then {
    missionNamespace setVariable ["Waldo_AIPass_ProjectileHandler", addMissionEventHandler ["ProjectileCreated", {
        params ["_projectile"];
        if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {};
        private _type = typeOf _projectile;
        private _cache = missionNamespace getVariable ["Waldo_AIPass_GrenadeTypes", createHashMap];
        private _isGrenade = _cache getOrDefault [_type, -1];
        if (_isGrenade isEqualTo -1) then {
            _isGrenade = getText (configFile >> "CfgAmmo" >> _type >> "simulation") == "shotGrenade";
            _cache set [_type, _isGrenade];
            missionNamespace setVariable ["Waldo_AIPass_GrenadeTypes", _cache];
        };
        if (_isGrenade) then {
            [Waldo_fnc_AIPassGrenadeCheck, createHashMapFromArray [["projectile", _projectile]], 0.3 + random 0.4] call Waldo_fnc_AIPassQueueJob;
        };
    }]];
};
if (isNil {missionNamespace getVariable "Waldo_AIPass_ArtilleryHandler"} && {missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false]}) then {
    missionNamespace setVariable ["Waldo_AIPass_ArtilleryHandler", addMissionEventHandler ["ArtilleryShellFired", {
        params ["_vehicle", "", "", "_gunner"];
        if (missionNamespace getVariable ["Waldo_AIPass_Active", false]) then {[_vehicle, _gunner] call Waldo_fnc_AIPassCounterBattery};
    }]];
};
missionNamespace setVariable ["Waldo_AIPass_LambsDangerLoaded", isClass (configFile >> "CfgPatches" >> "lambs_danger")];
{
    if (local _x) then {
        _x setVariable ["Waldo_AIPass_PeakSize", (_x getVariable ["Waldo_AIPass_PeakSize", 0]) max ({alive _x} count units _x)];
    };
} forEach allGroups;
if !(missionNamespace getVariable ["Waldo_AIPass_DiscoveryQueued", false]) then {
    missionNamespace setVariable ["Waldo_AIPass_DiscoveryQueued", true];
    [Waldo_fnc_AIPassDiscover, createHashMap, 1] call Waldo_fnc_AIPassQueueJob;
};

diag_log format ["[WMP AI PASS] Started on %1 (contact=%2 flank=%3 regroup=%4 artillery=%5 airborne=%6 lambs=%7/%8).",
    ["headless client", "server"] select isServer,
    missionNamespace getVariable ["Waldo_AIPass_Contact_Enable", true],
    missionNamespace getVariable ["Waldo_AIPass_Flank_Enable", true],
    missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable", true],
    missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false],
    missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false],
    missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false],
    missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"]
];
true
