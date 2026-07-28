/* Physical, repeatable stations for the optional systems added after PR32. */
if (!isServer) exitWith {};
waitUntil {uiSleep 0.1; missionNamespace getVariable ["Waldo_QA_FeatureRangeReady", false]};

private _get = {
    params ["_name"];
    private _object = missionNamespace getVariable [_name, objNull];
    if (!isNull _object) then {[_object] call Waldo_QA_fnc_trackFeatureObjectServer};
    _object
};

Waldo_QA_fnc_notifyActorServer = {
    params ["_actor", "_title", "_message", ["_state", "INFO"]];
    if (!isNull _actor) then {
        [_title, _message, _state, "QA_FEATURE_STATION", 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _actor];
    };
};

// Persistence: demonstrate the dependency gate without weakening the default-off contract.
private _persistenceObject = ["qa_persistence_object"] call _get;
Waldo_QA_fnc_persistenceProbeServer = {
    params ["_actor"];
    private _available = [] call Waldo_fnc_PersistenceDependencyAvailable;
    private _message = if (_available) then {
        "Compatible INIDBI2 runtime detected. Use the Persistence ZEN controls to enable, register this crate and save."
    } else {
        "No compatible INIDBI2 server runtime detected. Persistence remains safely disabled."
    };
    [_actor, "PERSISTENCE DEPENDENCY", _message, ["WARNING", "SUCCESS"] select _available] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_persistenceSaveServer = {
    [] spawn {
        uiSleep 0;
        [true, true] call Waldo_fnc_PersistenceSaveNow;
    };
};
missionNamespace setVariable ["Waldo_QA_PersistenceObject", _persistenceObject, true];

// ACE patient fixture. It remains server-local and can be injured repeatedly.
private _patientGroup = createGroup west;
private _patient = _patientGroup createUnit ["B_medic_F", [175, 87, 0], [], 0, "NONE"];
_patient setName "QA Patient";
_patient disableAI "PATH";
_patient disableAI "AUTOCOMBAT";
_patient setUnitPos "UP";
[_patient] call Waldo_QA_fnc_trackFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_TreatmentPatient", _patient, true];
Waldo_QA_fnc_injurePatientServer = {
    params ["_actor"];
    private _patient = missionNamespace getVariable ["Waldo_QA_TreatmentPatient", objNull];
    if (isNull _patient) exitWith {false};
    if (isClass (configFile >> "CfgPatches" >> "ace_medical")) then {
        [_patient] call ace_medical_treatment_fnc_fullHealLocal;
        [_patient, 0.45, "LeftArm", "bullet"] call ace_medical_fnc_addDamageToUnit;
        [_actor, "PATIENT RESET", "QA Patient has a fresh left-arm wound. Treat it through ACE medical.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
    } else {
        _patient setDamage 0.45;
        [_actor, "PATIENT RESET", "ACE medical is unavailable; vanilla damage was applied.", "WARNING"] call Waldo_QA_fnc_notifyActorServer;
    };
    true
};

// Benign exposure lane: it exercises exposure/decay/status without injuring testers.
private _hazardEmitter = ["qa_hazard_emitter"] call _get;
private _hazardProfile = createHashMapFromArray [
    ["type", "VACUUM"], ["label", "QA OXYGEN DEFICIENCY"], ["rate", 0.35],
    ["decay", 0.5], ["maximumExposure", 5], ["emitterRadius", 8],
    ["intensityMode", "LINEAR"], ["damageThresholds", []]
];
["qa_hazard", _hazardEmitter, _hazardProfile] call Waldo_fnc_HazardRegisterZone;
["qa_hazard", _hazardEmitter, _hazardProfile] remoteExecCall ["Waldo_fnc_HazardRegisterZone", -2, "Waldo_QA_HazardZone"];
missionNamespace setVariable ["Waldo_Hazard_Enable", true, true];

private _tree = ["qa_tree"] call _get;
_tree allowDamage true;
_tree setVariable ["Waldo_TreeFelling_Hits", 0, true];
missionNamespace setVariable ["Waldo_QA_Tree", _tree, true];
Waldo_QA_fnc_resetTreeServer = {
    private _tree = missionNamespace getVariable ["Waldo_QA_Tree", objNull];
    if (isNull _tree) exitWith {false};
    {
        if (_x != _tree && {typeOf _x in ["Land_TreeTrunk_01_F", "Land_TreeTrunk_01_wood_F"]}) then {deleteVehicle _x};
    } forEach nearestObjects [_tree, [], 10, true];
    _tree hideObjectGlobal false;
    _tree setDamage 0;
    _tree setVariable ["Waldo_TreeFelling_Hits", 0, true];
    true
};

// Emergency dismount vehicle begins upright and inert; the station control overturns it on demand.
private _dismountVehicle = ["qa_dismount_vehicle"] call _get;
_dismountVehicle enableSimulationGlobal false;
missionNamespace setVariable ["Waldo_QA_DismountVehicle", _dismountVehicle, true];
Waldo_QA_fnc_resetDismountServer = {
    private _vehicle = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
    if (isNull _vehicle) exitWith {false};
    _vehicle setPosATL [250, 88, 0];
    _vehicle setVectorDirAndUp [[0, 1, 0], [0, 0, 1]];
    _vehicle setDamage 0;
    true
};
Waldo_QA_fnc_overturnDismountServer = {
    private _vehicle = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
    if (isNull _vehicle) exitWith {false};
    _vehicle setVectorDirAndUp [[0, 1, 0], [0, 0, -1]];
    true
};

// Friendly and hostile AI make PID, tactical-display and AI-profile behavior visible.
private _friendlyGroup = createGroup west;
private _friendlyUnits = [];
{
    private _unit = _friendlyGroup createUnit [_x, [150 + (_forEachIndex * 3), 47, 0], [], 0, "NONE"];
    _unit disableAI "PATH";
    _unit setName format ["QA Friendly %1", _forEachIndex + 1];
    _friendlyUnits pushBack _unit;
    [_unit] call Waldo_QA_fnc_trackFeatureObjectServer;
} forEach ["B_Soldier_F", "B_soldier_AR_F", "B_Soldier_M_F"];
private _hostileGroup = createGroup east;
private _hostile = _hostileGroup createUnit ["O_Soldier_F", [150, 15, 0], [], 0, "NONE"];
_hostile disableAI "PATH";
_hostile setName "QA Known Hostile";
west reveal [_hostile, 4];
[_hostile] call Waldo_QA_fnc_trackFeatureObjectServer;
private _profileGroup = createGroup west;
private _profileUnits = [];
{
    private _unit = _profileGroup createUnit [_x, [221 + (_forEachIndex * 4), 47, 0], [], 0, "NONE"];
    _unit disableAI "PATH";
    _unit setName format ["QA Profile AI %1", _forEachIndex + 1];
    _profileUnits pushBack _unit;
    [_unit] call Waldo_QA_fnc_trackFeatureObjectServer;
} forEach ["B_Soldier_F", "B_soldier_AR_F", "B_Soldier_M_F"];
missionNamespace setVariable ["Waldo_QA_ProfileUnits", _profileUnits, true];

// Breaching uses the documented 8 m wall and replacement segments.
private _breachWall = ["qa_breach_wall"] call _get;
_breachWall allowDamage true;
private _breachProfile = createHashMapFromArray [
    ["radius", 7], ["requiredStrength", 1], ["destroyOriginal", false],
    ["hideOriginal", true], ["explosives", ["DemoCharge_Remote_Ammo"]],
    ["replacements", [
        ["Land_City2_4m_F", [-2, 0, 0], 0, "CAN_COLLIDE"],
        ["Land_City2_4m_F", [2, 0, 0], 0, "CAN_COLLIDE"]
    ]]
];
private _breachProfiles = missionNamespace getVariable ["Waldo_Breaching_Profiles", createHashMap];
_breachProfiles set ["Land_City2_8m_F", _breachProfile];
missionNamespace setVariable ["Waldo_Breaching_Profiles", _breachProfiles, true];
missionNamespace setVariable ["Waldo_Breaching_Enable", true, true];
[] remoteExecCall ["Waldo_fnc_BreachingInit", 0, "Waldo_QA_BreachingInit"];
missionNamespace setVariable ["Waldo_QA_BreachWall", _breachWall, true];
Waldo_QA_fnc_testBreachServer = {
    params ["_actor"];
    [_actor, getPosWorld (missionNamespace getVariable ["Waldo_QA_BreachWall", objNull]), "DemoCharge_Remote_Ammo"] call Waldo_fnc_BreachingServerHandle;
};
Waldo_QA_fnc_resetBreachServer = {
    private _wall = missionNamespace getVariable ["Waldo_QA_BreachWall", objNull];
    if (isNull _wall) exitWith {false};
    {if (!isNull _x) then {deleteVehicle _x}} forEach (_wall getVariable ["Waldo_Breaching_Replacements", []]);
    _wall hideObjectGlobal false;
    _wall setDamage 0;
    _wall setVariable ["Waldo_Breaching_Processed", false, true];
    _wall setVariable ["Waldo_Breaching_AccumulatedStrength", 0, true];
    _wall setVariable ["Waldo_Breaching_Replacements", [], true];
    true
};

// Object-transform fixtures preserve one source and one target for copy testing.
{
    private _object = [_x] call _get;
    _object setVariable ["Waldo_ObjectScaleOriginal", 1, true];
} forEach ["qa_scale_small", "qa_scale_source", "qa_scale_target"];
Waldo_QA_fnc_scaleFixtureServer = {
    params ["_name", "_scale"];
    [_name, _scale] spawn {
        params ["_name", "_scale"];
        uiSleep 0;
        [missionNamespace getVariable [_name, objNull], _scale, false] call Waldo_fnc_ObjectScale;
    };
};
Waldo_QA_fnc_resetScaleFixturesServer = {
    [] spawn {
        uiSleep 0;
        { [missionNamespace getVariable [_x, objNull]] call Waldo_fnc_ObjectScaleReset } forEach ["qa_scale_small", "qa_scale_source", "qa_scale_target"];
    };
};

Waldo_QA_fnc_setAIProfileServer = {
    params ["_profile"];
    [_profile] spawn {
        params ["_profile"];
        uiSleep 0;
        ["AI_CONFIG", [true, "DAY", _profile]] call Waldo_fnc_FeatureRuntimeApply;
    };
};
Waldo_QA_fnc_stopAIRebalanceServer = {
    [] spawn {
        uiSleep 0;
        [] call Waldo_fnc_AIRebalanceStop;
    };
};

// Field resupply and tactical display use their production registration paths.
private _resupplyHub = ["qa_resupply_hub"] call _get;
[_resupplyHub, west, 8] call Waldo_fnc_FieldResupplyRegisterHub;
missionNamespace setVariable ["Waldo_QA_ResupplyHub", _resupplyHub, true];
Waldo_QA_fnc_assignResupplyCarrierServer = {
    params ["_actor"];
    [_actor] spawn {
        params ["_actor"];
        uiSleep 0;
        [_actor, 2, 2] call Waldo_fnc_FieldResupplyAssignCarrier;
    };
};
private _tacticalConsole = ["qa_sign_tactical_display"] call _get;
[_tacticalConsole, west, 500, true] call Waldo_fnc_TacticalDisplayRegister;

// Dynamic AA is created only on request so no live weapons exist during ordinary range use.
Waldo_QA_fnc_createDynamicAAServer = {
    [] spawn {
        uiSleep 0;
        private _config = createHashMapFromArray [
            ["id", "QA_AA"], ["centre", [175, -80, 0]], ["radarPosition", [175, -70, 0]],
            ["side", east], ["radius", 350], ["engagementRadius", 300],
            ["minimumAltitude", 60], ["maximumAltitude", 500], ["detectionDwell", 2],
            ["clearDelay", 5], ["staticPositions", [[165, -80, 0]]],
            ["mobilePositions", []], ["fighterCount", 0], ["createMarkers", true]
        ];
        [_config] call Waldo_fnc_DynamicAACreate;
    };
};
Waldo_QA_fnc_destroyDynamicAAServer = {[] spawn {uiSleep 0; ["QA_AA", true] call Waldo_fnc_DynamicAADestroy}};

// Gunship spawn, assignment and teardown remain explicit because they create a live aircraft.
Waldo_QA_fnc_createGunshipServer = {
    [] spawn {
        uiSleep 0;
        private _config = createHashMapFromArray [
            ["id", "QA_GUNSHIP"], ["callsign", "QA SPECTRE"], ["side", west],
            ["home", [200, -550, 300]], ["spawnPosition", [200, -550, 300]],
            ["orbit", [200, -350, 0]], ["altitude", 300], ["radius", 400],
            ["serviceDuration", 30], ["maximumRangeFromHome", 1200]
        ];
        [_config] call Waldo_fnc_GunshipRegister;
    };
};
Waldo_QA_fnc_assignGunshipServer = {
    params ["_actor"];
    [_actor] spawn {
        params ["_actor"];
        uiSleep 0;
        ["QA_GUNSHIP", "ASSIGN", [_actor], _actor] call Waldo_fnc_GunshipServerHandle;
    };
};
Waldo_QA_fnc_destroyGunshipServer = {[] spawn {uiSleep 0; ["QA_GUNSHIP", true] call Waldo_fnc_GunshipDestroy}};

// Vehicle recovery is live and repeatable; reset recreates any fixture consumed by packaging.
Waldo_QA_fnc_resetRecoveryLocalServer = {
    {
        if (!isNull _x) then {deleteVehicle _x};
    } forEach (missionNamespace getVariable ["Waldo_Recovery_Packages", []]);
    missionNamespace setVariable ["Waldo_Recovery_Packages", []];
    private _vehicle = ["qa_recovery_vehicle", "B_MRAP_01_F", [217, 7, 0], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
    private _carrier = ["qa_recovery_carrier", "B_Truck_01_transport_F", [233, 7, 0], 270, true] call Waldo_QA_fnc_getFeatureObjectServer;
    private _workshop = ["qa_recovery_workshop", "Land_RepairDepot_01_green_F", [225, 14, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
    _vehicle setDamage 0.8;
    [_workshop, "QA", 20, west] call Waldo_fnc_RecoveryRegisterWorkshop;
    [_vehicle, "QA", 0.55, true, false, "B_Slingload_01_Cargo_F", true, 1] call Waldo_fnc_RecoveryRegisterVehicle;
    [_carrier, 12] call Waldo_fnc_RecoveryRegisterCarrier;
    missionNamespace setVariable ["Waldo_QA_RecoveryObjects", [_vehicle, _carrier, _workshop], true];
    true
};
Waldo_QA_fnc_resetRecoveryServer = {[] spawn {uiSleep 0; call Waldo_QA_fnc_resetRecoveryLocalServer}};
call Waldo_QA_fnc_resetRecoveryServer;

// The physical crate uses the real nested-folder-derived pool.
private _loadoutArsenal = ["qa_loadout_arsenal"] call _get;
[_loadoutArsenal, west, false] spawn Waldo_fnc_CreateLimitedArsenal;
missionNamespace setVariable ["Waldo_QA_LoadoutArsenal", _loadoutArsenal, true];
Waldo_QA_fnc_reportLoadoutPoolServer = {
    params ["_actor"];
    private _pool = ["West"] call Waldo_fnc_MissionSQMLookup;
    private _counts = _pool apply {if (_x isEqualTo ["EMPTY"]) then {0} else {count _x}};
    private _message = format ["Nested playable-role pool categories: weapons %1, magazines %2, launchers %3, launcher ammo %4, gear %5, items %6, backpacks %7, attachments %8.", _counts select 0, _counts select 1, _counts select 2, _counts select 3, _counts select 4, _counts select 5, _counts select 6, _counts select 7];
    [_actor, "NESTED LOADOUT SCRAPE", _message, "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_resetRalliesServer = {
    [] spawn {
        uiSleep 0;
        [] call Waldo_fnc_RallyPointRemoveAllServer;
    };
};

missionNamespace setVariable ["Waldo_QA_ExtendedFeatureStationsReady", true, true];
diag_log "WMP EXTENDED FEATURE STATIONS READY: 16 station workflows configured.";
