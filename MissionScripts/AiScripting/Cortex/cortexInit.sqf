/*
 * Author: WaldoTheWarfighter
 * Starts the Smart AI Pass on this machine if it owns AI: the server or a headless client.
 *
 * Installs, once per machine:
 * - one CBA per-frame handler that runs Waldo_fnc_CortexSchedulerTick. The due-time cache makes
 *   idle frames constant-time; due work gets one budgeted opportunity per rendered/simulated frame
 *   instead of being capped at four heavy jobs per second;
 * - one EntityKilled mission handler that passes kills in locally owned groups to survivor regroup;
 * - the Waldo_fnc_CortexDiscover sweep job, which brings local groups under the pass;
 * - a ProjectileCreated handler for grenade evasion, only while Waldo_AIPass_GrenadeEvasion_Enable is
 *   on (it would otherwise run for every projectile);
 * - an ArtilleryShellFired handler for counter-battery, only while Waldo_AIPass_CounterBattery_Enable
 *   is on.
 * - event-driven civilian FiredNear/Hit reactions when enabled. Existing and newly created owner-local
 *   civilians are versioned once; no civilian polling loop is installed.
 * Existing local groups have their peak strength recorded. Repeat calls are safe, and they add the
 * optional handlers when their switches have been turned on since the last call. Player clients return immediately and pay nothing. Each
 * behaviour has its own Waldo_AIPass_<Behaviour>_Enable switch in MissionConfig\aiConfig.sqf, and
 * Waldo_fnc_CortexIsEligible keeps player groups and other WMP features' units out.
 * LAMBS_Danger, Waypoints, Turrets, Suppression and RPG are detected without becoming hard
 * dependencies. Only Danger participates in movement ownership; the config-only companions remain active.
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
 * [] call Waldo_fnc_CortexInit;
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
            && {missionNamespace getVariable ["Waldo_AIPass_Enable", false]}) then {[] call Waldo_fnc_CortexInit};
    };
    true
};

if (!isServer && {!(missionNamespace getVariable ["Waldo_AIPass_Enable", false])}) exitWith {false};
missionNamespace setVariable ["Waldo_AIPass_Active", true];
if (isServer) then {
    missionNamespace setVariable ["Waldo_AIPass_Enable", true, true];
    if (remoteExecutedOwner == 0) then {
        [] remoteExecCall ["Waldo_fnc_CortexInit", -2, "Waldo_AIPass_RuntimeInit"];
    };
};

if (isNil {missionNamespace getVariable "Waldo_AIPass_SchedulerHandle"}) then {
    missionNamespace setVariable ["Waldo_AIPass_SchedulerHandle", [{[] call Waldo_fnc_CortexSchedulerTick}, 0] call CBA_fnc_addPerFrameHandler];
};
if (isNil {missionNamespace getVariable "Waldo_AIPass_KilledHandler"}) then {
    missionNamespace setVariable ["Waldo_AIPass_KilledHandler", addMissionEventHandler ["EntityKilled", {
        params ["_unit"];
        if !(missionNamespace getVariable ["Waldo_AIPass_Active", false]) exitWith {};
        if !(_unit isKindOf "CAManBase") exitWith {};
        private _group = group _unit;
        if (isNull _group || {!local _group}) exitWith {};
        [_group, _unit] call Waldo_fnc_CortexRegroupOnKill;
    }]];
};

if (!(missionNamespace getVariable ["Waldo_AIPass_GrenadeEvasion_Enable", true]) && {!isNil {missionNamespace getVariable "Waldo_AIPass_ProjectileHandler"}}) then {
    removeMissionEventHandler ["ProjectileCreated", missionNamespace getVariable "Waldo_AIPass_ProjectileHandler"];
    missionNamespace setVariable ["Waldo_AIPass_ProjectileHandler", nil];
};
if (isNil {missionNamespace getVariable "Waldo_AIPass_ProjectileHandler"} && {missionNamespace getVariable ["Waldo_AIPass_GrenadeEvasion_Enable", true]}) then {
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
            [Waldo_fnc_CortexGrenadeCheck, createHashMapFromArray [["projectile", _projectile]], 0.3 + random 0.4] call Waldo_fnc_CortexQueueJob;
        };
    }]];
};
if (isNil {missionNamespace getVariable "Waldo_AIPass_ArtilleryHandler"}) then {
    missionNamespace setVariable ["Waldo_AIPass_ArtilleryHandler", addMissionEventHandler ["ArtilleryShellFired", {
        _this call Waldo_fnc_CortexArtilleryFired;
        params ["_vehicle", "", "", "_gunner"];
        if (missionNamespace getVariable ["Waldo_AIPass_Active", false]) then {[_vehicle, _gunner] call Waldo_fnc_CortexCounterBattery};
    }]];
};
missionNamespace setVariable ["Waldo_AIPass_LambsDangerLoaded", isClass (configFile >> "CfgPatches" >> "lambs_danger")];
missionNamespace setVariable ["Waldo_AIPass_VcomLoaded",
    isClass (configFile >> "CfgPatches" >> "VCOM_AI") || {!isNil "VCM_fnc_SQUADBEH"}];
missionNamespace setVariable ["Waldo_AIPass_ProtocolNavyLoaded",
    isClass (configFile >> "CfgPatches" >> "PROTOCOL_AI_NAVY_SEAL")];
missionNamespace setVariable ["Waldo_AIPass_IMSLoaded",
    !isNil "IMS_Melee_Weapons" || {isClass (configFile >> "CfgPatches" >> "WBK_IMS")}
        || {isClass (configFile >> "CfgPatches" >> "WBK_IMS2")}];
missionNamespace setVariable ["Waldo_AIPass_WBKLoaded",
    !isNil "WBK_LoadAIThroughEden" || {!isNil "WBK_Droid_B1_Load"}];
missionNamespace setVariable ["Waldo_AIPass_WBKCivilianLoaded",!isNil "WBK_CivilianFlee"];
// The companion packages are config layers. Record them for diagnostics, but never disable them
// when Cortex takes movement ownership from LAMBS_Danger.
missionNamespace setVariable ["Waldo_Cortex_LambsTurretsLoaded", isClass (configFile >> "CfgPatches" >> "lambs_turrets")];
missionNamespace setVariable ["Waldo_Cortex_LambsSuppressionLoaded", isClass (configFile >> "CfgPatches" >> "lambs_suppression")];
missionNamespace setVariable ["Waldo_Cortex_LambsRpgLoaded", isClass (configFile >> "CfgPatches" >> "lambs_rpg")];
if (missionNamespace getVariable ["Waldo_AIPass_CivilianReaction_Enable",true]) then {
    {if (local _x) then {[_x] call Waldo_fnc_CortexCivilianSetup}} forEach (allUnits select {side group _x == civilian});
    if (isNil {missionNamespace getVariable "Waldo_Cortex_CivilianCreatedHandler"}) then {
        missionNamespace setVariable ["Waldo_Cortex_CivilianCreatedHandler",addMissionEventHandler ["EntityCreated",{
            params ["_entity"];
            if (_entity isKindOf "CAManBase" && {local _entity}) then {[_entity] call Waldo_fnc_CortexCivilianSetup};
        }]];
    };
} else {
    private _civilianCreated=missionNamespace getVariable "Waldo_Cortex_CivilianCreatedHandler";
    if (!isNil "_civilianCreated") then {
        removeMissionEventHandler ["EntityCreated",_civilianCreated];
        missionNamespace setVariable ["Waldo_Cortex_CivilianCreatedHandler",nil];
    };
    {if (local _x) then {[_x,true] call Waldo_fnc_CortexCivilianSetup}} forEach (allUnits select {side group _x == civilian});
};
{
    if (local _x) then {
        _x setVariable ["Waldo_AIPass_PeakSize", (_x getVariable ["Waldo_AIPass_PeakSize", 0]) max ({alive _x} count units _x)];
    };
} forEach allGroups;
if !(missionNamespace getVariable ["Waldo_AIPass_DiscoveryQueued", false]) then {
    missionNamespace setVariable ["Waldo_AIPass_DiscoveryQueued", true];
    [Waldo_fnc_CortexDiscover, createHashMap, 1] call Waldo_fnc_CortexQueueJob;
};

diag_log format ["[WMP CORTEX] Started on %1 (contact=%2 flank=%3 regroup=%4 artillery=%5 airborne=%6 lambs=%7/%8 vcom=%9 ims=%10 wbk=%11).",
    ["headless client", "server"] select isServer,
    missionNamespace getVariable ["Waldo_AIPass_Contact_Enable", true],
    missionNamespace getVariable ["Waldo_AIPass_Flank_Enable", true],
    missionNamespace getVariable ["Waldo_AIPass_Regroup_Enable", true],
    missionNamespace getVariable ["Waldo_AIPass_Artillery_Enable", false],
    missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false],
    missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded", false],
    missionNamespace getVariable ["Waldo_AIPass_LambsMode", "SPLIT"],
    missionNamespace getVariable ["Waldo_AIPass_VcomLoaded",false],
    missionNamespace getVariable ["Waldo_AIPass_IMSLoaded",false],
    missionNamespace getVariable ["Waldo_AIPass_WBKLoaded",false]
];
true
