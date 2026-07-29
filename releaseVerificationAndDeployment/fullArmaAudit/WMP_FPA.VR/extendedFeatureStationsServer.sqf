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

// Persistence: the audit opts in explicitly and exercises the full object lifecycle.
private _persistenceObject = ["qa_persistence_object"] call _get;
Waldo_QA_fnc_persistenceProbeServer = {
    params ["_actor"];
    private _available = [] call Waldo_fnc_PersistenceDependencyAvailable;
    private _message = if (_available) then {
        "Compatible INIDBI2 runtime detected. This station can enable, register, save, mutate and reload its crate."
    } else {
        "No compatible INIDBI2 server runtime detected. Persistence remains safely disabled."
    };
    [_actor, "PERSISTENCE DEPENDENCY", _message, ["WARNING", "SUCCESS"] select _available] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_persistenceEnableServer = {
    params ["_actor"];
    missionNamespace setVariable ["Waldo_Persistence_Enable", true, true];
    private _started = [] call Waldo_fnc_PersistenceInit;
    private _object = missionNamespace getVariable ["Waldo_QA_PersistenceObject", objNull];
    private _registered = false;
    if (_started && {missionNamespace getVariable ["Waldo_Persistence_Active", false]} && {!isNull _object}) then {
        _object allowDamage true;
        _registered = [_object, "qa_station_crate", [true, true, false, false, true, []]] call Waldo_fnc_PersistenceRegisterObject;
    };
    private _ok = _started && {_registered};
    [_actor, "PERSISTENCE SETUP", ["Dependency unavailable; persistence stayed disabled.", "Persistence is active and the QA crate is registered."] select _ok, ["WARNING", "SUCCESS"] select _ok] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_persistenceSaveServer = {
    params ["_actor"];
    [_actor] spawn {
        params ["_actor"];
        uiSleep 0;
        private _ok = [false, true] call Waldo_fnc_PersistenceSaveNow;
        [_actor, "PERSISTENCE SAVE", ["Save was rejected; enable and register the crate first.", "Registered QA crate state saved."] select _ok, ["WARNING", "SUCCESS"] select _ok] call Waldo_QA_fnc_notifyActorServer;
    };
};
Waldo_QA_fnc_persistenceMutateServer = {
    params ["_actor"];
    private _object = missionNamespace getVariable ["Waldo_QA_PersistenceObject", objNull];
    if (isNull _object) exitWith {};
    clearItemCargoGlobal _object;
    _object setDamage 0.65;
    _object setPosATL [158, 87, 0];
    [_actor, "PERSISTENCE MUTATION", "QA crate cargo, damage and position changed. Reload should restore the saved state.", "INFO"] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_persistenceReloadServer = {
    params ["_actor"];
    private _object = missionNamespace getVariable ["Waldo_QA_PersistenceObject", objNull];
    private _ok = !isNull _object && {[_object, "qa_station_crate", [true, true, false, false, true, []]] call Waldo_fnc_PersistenceLoadObject};
    [_actor, "PERSISTENCE RELOAD", ["No compatible saved QA crate state was restored.", "Saved QA crate state restored."] select _ok, ["WARNING", "SUCCESS"] select _ok] call Waldo_QA_fnc_notifyActorServer;
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
private _medicalSupplies = ["qa_treatment_supplies", "B_supplyCrate_F", [182, 87, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
clearItemCargoGlobal _medicalSupplies;
{_medicalSupplies addItemCargoGlobal [_x, 20]} forEach ["ACE_fieldDressing", "ACE_packingBandage", "ACE_elasticBandage", "ACE_tourniquet", "ACE_morphine", "ACE_epinephrine"];
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
    ["intensityMode", "LINEAR"], ["damageThresholds", []],
    ["protectiveItemsAnySlot", ["H_HelmetB"]], ["equipmentFactor", 0]
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
        if (_x != _tree && {typeOf _x in ["Land_WoodenLog_F"]}) then {deleteVehicle _x};
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
    params [["_actor", objNull, [objNull]]];
    private _vehicle = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
    private _recreated = isNull _vehicle;
    if (_recreated) then {
        _vehicle = ["qa_dismount_vehicle", "B_MRAP_01_F", [250, 88, 0.25], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
        missionNamespace setVariable ["Waldo_QA_DismountVehicle", _vehicle, true];
    };
    _vehicle enableSimulationGlobal false;
    _vehicle setVelocity [0, 0, 0];
    _vehicle setVectorDirAndUp [[1, 0, 0], [0, 0, 1]];
    _vehicle setPosATL [250, 88, 0.25];
    _vehicle setDamage 0;
    if (!isNull _actor) then {
        [_actor, "EMERGENCY DISMOUNT QA", ["Vehicle reset upright on its pad.", "Vehicle was recreated and reset upright on its pad."] select _recreated, "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
    };
    true
};
Waldo_QA_fnc_overturnDismountServer = {
    params [["_actor", objNull, [objNull]]];
    private _vehicle = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
    if (isNull _vehicle) exitWith {false};
    _vehicle setVelocity [0, 0, 0];
    _vehicle setVectorDirAndUp [[1, 0, 0], [0, 0, -1]];
    _vehicle setPosATL [250, 88, 0.25];
    if (!isNull _actor) then {
        [_actor, "EMERGENCY DISMOUNT QA", "Vehicle overturned in place. Board it first to exercise the automatic extraction path.", "INFO"] call Waldo_QA_fnc_notifyActorServer;
    };
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
{(group _x) reveal [_hostile, 4]} forEach allPlayers;
[_hostile] call Waldo_QA_fnc_trackFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_TacticalHostile", _hostile, true];
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
        private _scaled = [missionNamespace getVariable [_name, objNull], _scale, true] call Waldo_fnc_ObjectScale;
        if (!isNull _scaled) then {missionNamespace setVariable [_name, _scaled, true]};
    };
};
Waldo_QA_fnc_resetScaleFixturesServer = {
    [] spawn {
        uiSleep 0;
        { [missionNamespace getVariable [_x, objNull]] call Waldo_fnc_ObjectScaleReset } forEach ["qa_scale_small", "qa_scale_source", "qa_scale_target"];
    };
};
Waldo_QA_fnc_copyScaleFixtureServer = {
    private _source = missionNamespace getVariable ["qa_scale_source", objNull];
    private _target = missionNamespace getVariable ["qa_scale_target", objNull];
    [_source, _target] call Waldo_fnc_ObjectScaleCopy;
};
Waldo_QA_fnc_multiplyScaleFixtureServer = {
    [missionNamespace getVariable ["qa_scale_target", objNull], 1.5] call Waldo_fnc_ObjectScaleMultiply;
};
Waldo_QA_fnc_transformFixtureServer = {
    private _target = missionNamespace getVariable ["qa_scale_target", objNull];
    [_target, [207, 49, 1], [15, 10, 45], "ATL", 1.25] call Waldo_fnc_ObjectTransformSet;
};
Waldo_QA_fnc_reportScaleFixturesServer = {
    params ["_actor"];
    private _rows = ["qa_scale_small", "qa_scale_source", "qa_scale_target"] apply {
        private _object = missionNamespace getVariable [_x, objNull];
        format ["%1 scale=%2 pos=%3", _x, _object getVariable ["Waldo_ObjectScale", 1], getPosATL _object]
    };
    [_actor, "OBJECT TRANSFORM STATE", _rows joinString " | ", "INFO"] call Waldo_QA_fnc_notifyActorServer;
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
Waldo_QA_fnc_reportAIProfileServer = {
    params ["_actor"];
    private _units = missionNamespace getVariable ["Waldo_QA_ProfileUnits", []];
    private _rows = _units apply {format ["%1 acc=%2 spot=%3 general=%4", name _x, (_x skill "aimingAccuracy") toFixed 2, (_x skill "spotDistance") toFixed 2, (_x skill "general") toFixed 2]};
    [_actor, "AI PROFILE STATE", _rows joinString " | ", "INFO"] call Waldo_QA_fnc_notifyActorServer;
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
Waldo_QA_fnc_revealTacticalHostileServer = {
    params ["_actor"];
    private _hostile = missionNamespace getVariable ["Waldo_QA_TacticalHostile", objNull];
    if (!isNull _hostile && {!isNull _actor}) then {(group _actor) reveal [_hostile, 4]};
    [_actor, "TACTICAL CONTACT", "The QA hostile is now known to your group and should appear on the tactical display.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};

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
Waldo_QA_fnc_spawnDynamicAATargetServer = {
    params ["_actor"];
    private _old = missionNamespace getVariable ["Waldo_QA_AATarget", objNull];
    if (!isNull _old) then {deleteVehicle _old};
    private _target = createVehicle ["B_UAV_02_dynamicLoadout_F", [175, -20, 140], [], 0, "FLY"];
    _target setPosATL [175, -20, 140];
    _target setDir 180;
    _target flyInHeight 140;
    _target allowDamage false;
    createVehicleCrew _target;
    missionNamespace setVariable ["Waldo_QA_AATarget", _target, true];
    [_actor, "DYNAMIC AA TARGET", "A protected WEST UAV is above the configured altitude inside the detection zone.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_removeDynamicAATargetServer = {
    private _target = missionNamespace getVariable ["Waldo_QA_AATarget", objNull];
    if (!isNull _target) then {{deleteVehicle _x} forEach crew _target; deleteVehicle _target};
    missionNamespace setVariable ["Waldo_QA_AATarget", objNull, true];
};

// Gunship spawn, assignment and teardown remain explicit because they create a live aircraft.
Waldo_QA_fnc_createGunshipServer = {
    params [["_actor", objNull, [objNull]]];
    [_actor] spawn {
        params ["_actor"];
        uiSleep 0;
        private _config = createHashMapFromArray [
            ["id", "QA_GUNSHIP"], ["callsign", "QA SPECTRE"], ["side", west],
            ["home", [200, -550, 300]], ["spawnPosition", [200, -550, 300]],
            ["orbit", [200, -350, 0]], ["altitude", 300], ["radius", 400],
            ["serviceDuration", 30], ["maximumRangeFromHome", 1200]
        ];
        private _created = [_config] call Waldo_fnc_GunshipRegister;
        if (!isNull _actor) then {
            [_actor, "AIRBORNE GUNSHIP QA", ["Gunship creation failed. Check the runtime log and aircraft pool.", "QA SPECTRE spawned. Assign it to yourself, then use the Gunship ACE self-interaction."] select _created, ["ERROR", "SUCCESS"] select _created] call Waldo_QA_fnc_notifyActorServer;
        };
    };
};
Waldo_QA_fnc_assignGunshipServer = {
    params ["_actor"];
    [_actor] spawn {
        params ["_actor"];
        uiSleep 0;
        private _assigned = ["QA_GUNSHIP", "ASSIGN", [_actor], _actor] call Waldo_fnc_GunshipServerHandle;
        if (_assigned) then {[] remoteExecCall ["Waldo_fnc_GunshipSetupLocal", owner _actor]};
        [_actor, "AIRBORNE GUNSHIP QA", ["Assignment failed. Spawn QA SPECTRE first.", "Assigned. Open ACE Self Interactions > Gunship: QA SPECTRE for orbit and turret controls."] select _assigned, ["ERROR", "SUCCESS"] select _assigned] call Waldo_QA_fnc_notifyActorServer;
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
    private _carrier = ["qa_recovery_carrier", "B_T_VTOL_01_vehicle_F", [225, -28, 0], 0, true] call Waldo_QA_fnc_getFeatureObjectServer;
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
clearWeaponCargoGlobal _loadoutArsenal;
clearMagazineCargoGlobal _loadoutArsenal;
clearItemCargoGlobal _loadoutArsenal;
clearBackpackCargoGlobal _loadoutArsenal;
[_loadoutArsenal, west, false] spawn Waldo_fnc_CreateLimitedArsenal;
missionNamespace setVariable ["Waldo_QA_LoadoutArsenal", _loadoutArsenal, true];
private _expectedPrimaryWeapons = ["arifle_MX_GL_Hamr_pointer_F", "arifle_MXC_Black_F", "arifle_MX_Black_F", "arifle_MX_SW_Black_F", "srifle_DMR_03_F"];
private _loadoutPool = ["West"] call Waldo_fnc_MissionSQMLookup;
private _scrapedWeaponCategory = _loadoutPool param [0, []];
private _missingPrimaryWeapons = _expectedPrimaryWeapons - _scrapedWeaponCategory;
diag_log format ["WMP NESTED LOADOUT PRIMARY AUDIT: expected=%1 missing=%2 scrapedWeaponCategory=%3", _expectedPrimaryWeapons, _missingPrimaryWeapons, _scrapedWeaponCategory];
Waldo_QA_fnc_reportLoadoutPoolServer = {
    params ["_actor"];
    private _pool = ["West"] call Waldo_fnc_MissionSQMLookup;
    private _counts = _pool apply {if (_x isEqualTo ["EMPTY"]) then {0} else {count _x}};
    private _expected = ["arifle_MX_GL_Hamr_pointer_F", "arifle_MXC_Black_F", "arifle_MX_Black_F", "arifle_MX_SW_Black_F", "srifle_DMR_03_F"];
    private _missing = _expected - (_pool param [0, []]);
    private _message = format ["Primary fixtures: %1. Missing from scraped weapon category: %2. Category counts: weapons %3, magazines %4, launchers %5, launcher ammo %6, gear %7, items %8, backpacks %9, attachments %10.", _expected joinString ", ", if (_missing isEqualTo []) then {"NONE"} else {_missing joinString ", "}, _counts select 0, _counts select 1, _counts select 2, _counts select 3, _counts select 4, _counts select 5, _counts select 6, _counts select 7];
    [_actor, "NESTED LOADOUT SCRAPE", _message, "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_resetRalliesServer = {
    [] spawn {
        uiSleep 0;
        [] call Waldo_fnc_RallyPointRemoveAllServer;
    };
};
Waldo_QA_fnc_prepareRallyTesterServer = {
    params ["_actor"];
    if (isNull _actor) exitWith {};
    (group _actor) selectLeader _actor;
    [_actor, "SQUAD RALLY QA", "You are now group leader. Use the production self-action to deploy, regroup and pack the rally.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};

missionNamespace setVariable ["Waldo_QA_ExtendedFeatureStationsReady", true, true];
diag_log "WMP EXTENDED FEATURE STATIONS READY: 16 station workflows configured.";
