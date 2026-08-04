/*
 * Author: WaldoTheWarfighter
 * Builds the server-authoritative fixtures and control endpoints for the full-pack audit mission's
 * extended feature stations. State-changing actions are repeatable and are invoked by local station
 * controls through explicit server remote execution.
 *
 * Arguments: None.
 * Return Value: Nothing; publishes Waldo_QA_ExtendedFeatureStationsReady when setup completes.
 *
 * Example: [] execVM "extendedFeatureStationsServer.sqf";
 * Current caller: the audit mission's initServer.sqf.
 */
if (!isServer) exitWith {};
waitUntil {uiSleep 0.1; missionNamespace getVariable ["Waldo_QA_FeatureRangeReady", false]};

private _get = {
    params ["_name"];
    private _object = missionNamespace getVariable [_name, objNull];
    if (!isNull _object) then {[_object] call Waldo_QA_fnc_trackFeatureObjectServer};
    _object
};

Waldo_QA_fnc_notifyActorServer = {
    params ["_actor", "_title", "_message", ["_state", "INFO"], ["_channel", ""]];
    if (!isNull _actor) then {
        if (_channel isEqualTo "") then {_channel = format ["QA_%1", toUpperANSI _title]};
        [_title, _message, _state, _channel, 8] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _actor];
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

// Live exposure lane: protection makes it safe, while an unprotected player receives measurable
// ACE/vanilla damage quickly enough to validate that this is a real gameplay hazard.
private _hazardEmitter = ["qa_hazard_emitter"] call _get;
private _hazardProfile = createHashMapFromArray [
      ["type", "VACUUM"], ["label", "QA OXYGEN DEFICIENCY"], ["rate", 4],
      ["decay", 0.5], ["maximumExposure", 40], ["emitterRadius", 8],
      ["intensityMode", "CONSTANT"], ["damageThresholds", [[4, 0.1], [10, 0.2], [18, 0.35]]],
      ["damageStageMessages", ["Breathing is impaired; leave the area or equip protection.", "Severe oxygen deprivation is causing injury.", "Critical exposure: death is imminent."]],
      ["fatalExposure", 24], ["damageType", "stab"],
      ["protectiveItemsAnySlot", ["H_PilotHelmetFighter_B"]], ["equipmentFactor", 0]
];
// Exercise the real mid-mission authority path: ordered enable state, current
// and JIP zone registration, followed by the local evaluator start.
["HAZARD_SET", ["qa_hazard", _hazardEmitter, _hazardProfile]] call Waldo_fnc_FeatureRuntimeApply;

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

// Emergency dismount needs live vehicle physics. Test controls are installed
// on this vehicle locally rather than on the station sign.
private _dismountVehicle = ["qa_dismount_vehicle"] call _get;
_dismountVehicle enableSimulationGlobal true;
missionNamespace setVariable ["Waldo_QA_DismountVehicle", _dismountVehicle, true];
Waldo_QA_fnc_resetDismountServer = {
    params [["_actor", objNull, [objNull]]];
    private _vehicle = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
    private _recreated = isNull _vehicle;
    if (_recreated) then {
        _vehicle = ["qa_dismount_vehicle", "B_MRAP_01_F", [250, 88, 0.25], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
        missionNamespace setVariable ["Waldo_QA_DismountVehicle", _vehicle, true];
    };
    if (count crew _vehicle == 0 && {owner _vehicle != 2}) then {_vehicle setOwner 2};
    _vehicle enableSimulationGlobal true;
    _vehicle setVelocity [0, 0, 0];
    _vehicle setPosATL [250, 88, 2];
    [_vehicle, _actor] call Waldo_fnc_VehicleUpright;
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
    _vehicle enableSimulationGlobal true;
    if (local _vehicle) then {
        private _position = getPosATL _vehicle;
        _vehicle setVelocity [0, 0, 0];
        _vehicle setVectorDirAndUp [[1, 0, 0], [0, 0, -1]];
        _vehicle setPosATL [_position select 0, _position select 1, 1.8];
    } else {
        [_vehicle, "OVERTURN"] remoteExecCall ["Waldo_QA_fnc_setDismountOrientationLocal", owner _vehicle];
    };
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
    private _assignedHmd = hmd _unit;
    if (_assignedHmd != "") then {_unit unassignItem _assignedHmd; _unit removeItem _assignedHmd};
    if (_forEachIndex == 1) then {_unit linkItem "NVGoggles"};
    _unit setName (["QA AI Unaided A", "QA AI with NVG", "QA AI Unaided B"] select _forEachIndex);
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
        ["Land_City2_4m_F", [-4, 0, 0], 0, "CAN_COLLIDE"],
        ["Land_City2_4m_F", [4, 0, 0], 0, "CAN_COLLIDE"]
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
    params ["_profile", ["_mode", "DAY"]];
    [_profile, _mode] spawn {
        params ["_profile", "_mode"];
        uiSleep 0;
        missionNamespace setVariable ["Waldo_AI_DarknessThreshold", if (_mode == "NIGHT") then {1000000000} else {5}, true];
        ["AI_CONFIG", [true, _mode, _profile]] call Waldo_fnc_FeatureRuntimeApply;
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
    private _rows = _units apply {format ["%1 acc=%2/%3 spot=%4/%5 general=%6/%7", name _x, (_x skill "aimingAccuracy") toFixed 2, (_x skillFinal "aimingAccuracy") toFixed 2, (_x skill "spotDistance") toFixed 2, (_x skillFinal "spotDistance") toFixed 2, (_x skill "general") toFixed 2, (_x skillFinal "general") toFixed 2]};
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
private _tacticalConsole = ["qa_tactical_console"] call _get;
private _tacticalInteraction = createHashMapFromArray [["enabled", true], ["challengeId", "commandinput"], ["difficulty", "easy"]];
[_tacticalConsole, west, 500, true, _tacticalInteraction] call Waldo_fnc_TacticalDisplayRegister;
Waldo_QA_fnc_resetTacticalDisplayServer = {
    private _console = missionNamespace getVariable ["qa_tactical_console", objNull];
    if (isNull _console) exitWith {false};
    private _interaction = createHashMapFromArray [["enabled", true], ["challengeId", "commandinput"], ["difficulty", "easy"]];
    [_console, west, 500, true, _interaction] call Waldo_fnc_TacticalDisplayRegister;
};
Waldo_QA_fnc_revealTacticalHostileServer = {
    params ["_actor"];
    private _hostile = missionNamespace getVariable ["Waldo_QA_TacticalHostile", objNull];
    if (!isNull _hostile && {!isNull _actor}) then {(group _actor) reveal [_hostile, 4]};
    [_actor, "TACTICAL CONTACT", "The QA hostile is now known to your group and should appear on the tactical display.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};

// Dynamic AA is created only on request so no live weapons exist during ordinary range use.
Waldo_QA_fnc_createDynamicAAServer = {
    params [["_actor", objNull, [objNull]], ["_radarClass", "Land_Radar_F", [""]]];
    [_actor, _radarClass] spawn {
        params ["_actor", "_radarClass"];
        uiSleep 0;
        private _config = createHashMapFromArray [
            ["id", "QA_AA"], ["displayName", "QA Generated Air Defence"], ["centre", [175, -160, 0]],
            ["side", east], ["radius", 600], ["engagementRadius", 550],
            ["minimumAltitude", 60], ["maximumAltitude", 500], ["detectionDwell", 2],
            ["clearDelay", 5], ["faction", "BLU_F"], ["assetSelectionMode", "EXACT"],
            ["radarAssignments", [_radarClass]], ["staticAssignments", ["B_AAA_System_01_F"]], ["mobileAssignments", ["O_APC_Tracked_02_AA_F"]],
            ["radarCount", 1], ["staticCount", 1], ["mobileCount", 1],
            ["fighterCount", 0], ["createMarkers", true],
            ["shutdownInteraction", true], ["shutdownChallenge", "circuit"], ["shutdownDifficulty", "easy"]
        ];
        private _created = [_config] call Waldo_fnc_DynamicAACreate;
        private _state = (missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap]) getOrDefault ["QA_AA", createHashMap];
        private _objects = _state getOrDefault ["objects", []];
        private _hasRadar = _objects findIf {!isNull _x && {typeOf _x == _radarClass} && {!(_x isKindOf "AllVehicles") || {count crew _x > 0}}} >= 0;
        private _hasStaticAA = _objects findIf {!isNull _x && {_x isKindOf "B_AAA_System_01_F"} && {count crew _x > 0}} >= 0;
        private _hasMobileAA = _objects findIf {!isNull _x && {_x isKindOf "O_APC_Tracked_02_AA_F"} && {count crew _x > 0}} >= 0;
        private _separated = true;
        private _minimumMargin = 1e10;
        for "_left" from 0 to (count _objects - 2) do {
            for "_right" from (_left + 1) to (count _objects - 1) do {
                private _leftObject = _objects select _left;
                private _rightObject = _objects select _right;
                private _leftClearance = (((((sizeOf (typeOf _leftObject)) * 0.75) max 8) min 100) + 5);
                private _rightClearance = (((((sizeOf (typeOf _rightObject)) * 0.75) max 8) min 100) + 5);
                private _margin = (_leftObject distance2D _rightObject) - (_leftClearance + _rightClearance);
                _minimumMargin = _minimumMargin min _margin;
                if (_margin < 0) then {_separated = false};
            };
        };
        private _ready = _created && {_hasRadar} && {_hasStaticAA} && {_hasMobileAA} && {_separated};
        diag_log format ["WMP DYNAMIC AA QA SYSTEM: created=%1 requestedRadar=%2 radarReady=%3 staticReady=%4 mobileReady=%5 separated=%6 minimumMargin=%7 assets=%8", _created, _radarClass, _hasRadar, _hasStaticAA, _hasMobileAA, _separated, _minimumMargin, _objects apply {[typeOf _x, getPosATL _x]}];
        [_actor, "DYNAMIC AA QA", ["Generated placement failed or at least two final class footprints overlap. Inspect the runtime log for exact asset positions and the minimum margin.", format ["Created a collision-checked generated layout: %1 radar, BLUFOR Praetorian and OPFOR Tigris, all operated by the OPFOR operational side. Minimum clearance margin: %2m. Spawn the protected UAV to trigger both weapons.", _radarClass, _minimumMargin toFixed 1]] select _ready, ["ERROR", "SUCCESS"] select _ready] call Waldo_QA_fnc_notifyActorServer;
    };
};
Waldo_QA_fnc_destroyDynamicAAServer = {[] spawn {uiSleep 0; ["QA_AA", true] call Waldo_fnc_DynamicAADestroy}};
Waldo_QA_fnc_spawnDynamicAATargetServer = {
    params ["_actor"];
    private _old = missionNamespace getVariable ["Waldo_QA_AATarget", objNull];
    if (!isNull _old) then {deleteVehicle _old};
    private _target = createVehicle ["B_UAV_02_dynamicLoadout_F", [175, -160, 140], [], 0, "FLY"];
    _target setPosATL [175, -160, 140];
    _target setDir 180;
    _target allowDamage false;
    private _targetGroup = west createVehicleCrew _target;
    _target engineOn true;
    _target setVelocityModelSpace [0, 55, 0];
    _target flyInHeight 140;
    {if (local _x) then {_x action ["EngineOn", _target]}} forEach crew _target;
    if (!isNull _targetGroup) then {
        private _loiter = _targetGroup addWaypoint [[175, -160, 140], 0];
        _loiter setWaypointType "LOITER";
        _loiter setWaypointLoiterType "CIRCLE_L";
        _loiter setWaypointLoiterRadius 120;
        _loiter setWaypointSpeed "LIMITED";
    };
    missionNamespace setVariable ["Waldo_QA_AATarget", _target, true];
    private _crewSides = crew _target apply {side group _x};
    private _system = (missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap]) getOrDefault ["QA_AA", createHashMap];
    private _ready = count _system > 0 && {count crew _target > 0} && {west in _crewSides};
    diag_log format ["WMP DYNAMIC AA QA TARGET: object=%1 kindAir=%2 sim=%3 altitudeATL=%4 distance2D=%5 crew=%6 crewSides=%7 systemReady=%8", typeOf _target, _target isKindOf "Air", simulationEnabled _target, getPosATL _target select 2, _target distance2D [175, -160, 0], count crew _target, _crewSides, count _system > 0];
    [_actor, "DYNAMIC AA TARGET", if (_ready) then {"A protected, crewed WEST UAV is orbiting inside every detection gate. Detection should announce after the two-second dwell, then the Tigris should engage."} else {"The UAV spawned, but one or more detector prerequisites are missing. Inspect the runtime log."}, ["ERROR", "SUCCESS"] select _ready] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_removeDynamicAATargetServer = {
    private _target = missionNamespace getVariable ["Waldo_QA_AATarget", objNull];
    if (!isNull _target) then {{deleteVehicle _x} forEach crew _target; deleteVehicle _target};
    missionNamespace setVariable ["Waldo_QA_AATarget", objNull, true];
};

// Dynamic AO is created in an isolated southern test area only on request. VR has no buildings or
// roads, deliberately proving that garrison and roadblock requests cap cleanly instead of failing.
Waldo_QA_fnc_createDynamicAOServer = {
    params [["_actor", objNull, [objNull]]];
    ["QA_DYNAMIC_AO"] call Waldo_fnc_DynamicAODestroy;
    private _config = createHashMapFromArray [
        ["id", "QA_DYNAMIC_AO"], ["center", [350, -300, 0]], ["side", east], ["faction", "OPF_F"],
        ["radius", 250], ["patrolGroups", 2], ["garrisonGroups", 2],
        ["staticTurrets", 1], ["vehiclePatrols", 1], ["vehicleMix", [50, 35, 15]],
        ["airPatrols", 0], ["civilianFaction", "CIV_F"], ["civilianPatrols", 2],
        ["civilianGarrisons", 2], ["civilianCars", 1], ["minefields", 1],
        ["showMineMarkers", true], ["roadblocks", 1], ["showMarker", true]
    ];
    private _created = [_config] call Waldo_fnc_DynamicAOCreate;
    private _state = (missionNamespace getVariable ["Waldo_DynamicAO_Registry", createHashMap]) getOrDefault ["QA_DYNAMIC_AO", createHashMap];
    private _objects = _state getOrDefault ["objects", []];
    private _groups = _state getOrDefault ["groups", []];
    private _patrolGroups = _groups select {!isNull _x && {count waypoints _x >= 3}};
    private _routesActive = count _patrolGroups >= 3 && {_patrolGroups findIf {
        waypointType [_x, currentWaypoint _x] != "MOVE"
    } < 0};
    private _ready = _created && {count _objects > 1} && {count _groups >= 2} && {_routesActive};
    diag_log format ["WMP DYNAMIC AO QA: created=%1 objects=%2 groups=%3 patrolRoutes=%4 activeRoutes=%5 minefields=%6", _created, count _objects, count _groups, count _patrolGroups, _routesActive, count (_state getOrDefault ["minefields", []])];
    [_actor, "DYNAMIC AO QA", if (_ready) then {"Generated the isolated OPFOR AO south of this station with active infantry, vehicle and civilian patrol routes. Inspect their movement, faction assets, minefield anchor and global markers in Zeus."} else {"AO generation or patrol-route activation was incomplete. Inspect the current runtime log."}, ["ERROR", "SUCCESS"] select _ready] call Waldo_QA_fnc_notifyActorServer;
    if (_ready) then {
        private _starts = _patrolGroups apply {getPosATL leader _x};
        [_actor, _patrolGroups, _starts] spawn {
            params ["_actor", "_patrolGroups", "_starts"];
            sleep 15;
            private _moving = 0;
            {
                if (!isNull _x && {alive leader _x} && {(getPosATL leader _x) distance2D (_starts param [_forEachIndex, getPosATL leader _x]) > 2}) then {
                    _moving = _moving + 1;
                };
            } forEach _patrolGroups;
            private _passed = _moving > 0;
            diag_log format ["WMP DYNAMIC AO MOVEMENT QA: movingGroups=%1/%2 passed=%3", _moving, count _patrolGroups, _passed];
            [_actor, "DYNAMIC AO MOVEMENT", format ["%1 of %2 routed patrol groups moved within 15 seconds.", _moving, count _patrolGroups], ["ERROR", "SUCCESS"] select _passed] call Waldo_QA_fnc_notifyActorServer;
        };
    };
};
Waldo_QA_fnc_reportDynamicAOServer = {
    params [["_actor", objNull, [objNull]]];
    private _state = (missionNamespace getVariable ["Waldo_DynamicAO_Registry", createHashMap]) getOrDefault ["QA_DYNAMIC_AO", createHashMap];
    private _exists = count _state > 0;
    private _objects = _state getOrDefault ["objects", []];
    private _groups = _state getOrDefault ["groups", []];
    [_actor, "DYNAMIC AO STATE", if (_exists) then {format ["Registered with %1 tracked objects, %2 groups and %3 minefield(s). Delete its centre anchor in Zeus or use this station's cleanup action.", count _objects, count _groups, count (_state getOrDefault ["minefields", []])]} else {"QA Dynamic AO is not active."}, ["WARNING", "SUCCESS"] select _exists] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_destroyDynamicAOServer = {
    params [["_actor", objNull, [objNull]]];
    private _removed = ["QA_DYNAMIC_AO"] call Waldo_fnc_DynamicAODestroy;
    [_actor, "DYNAMIC AO QA", ["No QA Dynamic AO was active.", "The complete QA Dynamic AO was removed."] select _removed, ["WARNING", "SUCCESS"] select _removed] call Waldo_QA_fnc_notifyActorServer;
};

// Gunship spawn, assignment and teardown remain explicit because they create a live aircraft.
Waldo_QA_fnc_createGunshipServer = {
    params [["_actor", objNull, [objNull]]];
    [_actor] spawn {
        params ["_actor"];
        uiSleep 0;
        private _config = createHashMapFromArray [
            ["id", "QA_GUNSHIP"], ["callsign", "QA SPECTRE"], ["side", west],
            ["home", [200, -650, 300]], ["spawnPosition", [200, -650, 300]],
            ["orbit", [200, -150, 0]], ["altitude", 300], ["radius", 250],
            ["arrivalTolerance", 100], ["serviceDuration", 15], ["maximumRangeFromHome", 1200]
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
Waldo_QA_fnc_serviceGunshipServer = {
    params [["_actor", objNull, [objNull]]];
    private _accepted = ["QA_GUNSHIP", "SERVICE", [], _actor] call Waldo_fnc_GunshipServerHandle;
    [_actor, "AIRBORNE GUNSHIP QA", ["Service request rejected; spawn and assign the gunship first.", "Service accepted. Watch the map: it will RTB, service for 15 seconds, then return to its combat orbit."] select _accepted, ["ERROR", "SUCCESS"] select _accepted] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_reportGunshipServer = {
    params [["_actor", objNull, [objNull]]];
    private _registry = missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap];
    if !("QA_GUNSHIP" in keys _registry) exitWith {[_actor, "AIRBORNE GUNSHIP QA", "QA SPECTRE is not registered.", "ERROR"] call Waldo_QA_fnc_notifyActorServer};
    private _state = _registry get "QA_GUNSHIP";
    private _aircraft = _state getOrDefault ["aircraft", objNull];
    private _status = _state getOrDefault ["status", "UNKNOWN"];
    private _cycles = _state getOrDefault ["serviceCycles", 0];
    private _message = format ["State: %1 | service cycles: %2 | fuel: %3 | damage: %4 | position: %5", _status, _cycles, if (isNull _aircraft) then {"N/A"} else {(fuel _aircraft) toFixed 2}, if (isNull _aircraft) then {"N/A"} else {(damage _aircraft) toFixed 2}, if (isNull _aircraft) then {"N/A"} else {getPosATL _aircraft}];
    [_actor, "AIRBORNE GUNSHIP QA", _message, "INFO"] call Waldo_QA_fnc_notifyActorServer;
};

// Dynamic paradrop: player-focused looping route using the same authoritative production path.
Waldo_QA_fnc_createParadropServer = {
    params [["_actor", objNull, [objNull]]];
    ["QA_DZ", true, _actor, false] call Waldo_fnc_ParadropRemoveDropZone;
    private _config = createHashMapFromArray [
        ["id", "QA_DZ"], ["name", "QA DROP ZONE"], ["centre", [500, 500, 0]],
        ["direction", 90], ["side", west], ["aircraftClass", "B_Heli_Transport_01_F"],
        ["altitude", 180], ["maximumSpeed", 160], ["approachDistance", 1500],
        ["runLength", 1200], ["exitDistance", 1500], ["jumperCount", 0],
        ["jumpInterval", 2], ["staticJumpEnabled", true], ["staticMinimumAltitude", 120],
        ["staticMaximumAltitude", 350], ["staticMaximumSpeed", 250],
        ["staticChuteClass", "NonSteerable_Parachute_F"], ["haloJumpEnabled", false],
        ["requireOpenDoor", false], ["automaticJumpMode", "STATIC"],
        ["createJumpers", false], ["autoDropPlayers", false], ["createMarkers", true],
        ["lifecycle", "LOOP"], ["circuitDirection", "LEFT"], ["operationTimeout", 900], ["notifyRequester", false]
    ];
    private _created = [_config, _actor] call Waldo_fnc_ParadropCreateDropZone;
    [_actor, "DYNAMIC PARADROP QA", ["Creation failed; inspect the server RPT.", "Empty player transport created with one pilot and a repeating aligned circuit. Board through the station or spawn its boarding point."] select _created, ["ERROR", "SUCCESS"] select _created] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_embarkParadropServer = {
    params [["_actor", objNull, [objNull]], ["_createPoint", false, [false]]];
    private _mode = if (_createPoint) then {"POLE"} else {"SELECTION"};
    private _units = if (_createPoint || {isNull _actor}) then {[]} else {[_actor]};
    ["QA_DZ", _mode, _units, [300, 28, 0], "Land_InfoStand_V1_F", "Board QA Drop Aircraft", _actor]
        call Waldo_fnc_ParadropEmbark;
};
Waldo_QA_fnc_reportParadropServer = {
    params [["_actor", objNull, [objNull]]];
    private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
    private _registered = "QA_DZ" in keys _registry;
    private _message = if (_registered) then {
        private _state = _registry get "QA_DZ";
        private _aircraft = _state getOrDefault ["aircraft", objNull];
        format ["Registered: true<br/>Aircraft alive: %1<br/>Players aboard: %2<br/>Optional AI aboard: %3<br/>Lifecycle: %4<br/>Boarding points: %5<br/>Markers: %6", !isNull _aircraft && {alive _aircraft}, {isPlayer _x && {vehicle _x == _aircraft}} count allPlayers, {vehicle _x == _aircraft} count (_state getOrDefault ["jumpers", []]), _state getOrDefault ["lifecycle", "UNKNOWN"], count (_state getOrDefault ["boardingPoints", []]), count (_state getOrDefault ["markers", []])]
    } else {
        "No QA dynamic-paradrop operation is registered."
    };
    [_actor, "DYNAMIC PARADROP QA", _message, ["WARNING", "SUCCESS"] select _registered] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_removeParadropServer = {
    params [["_actor", objNull, [objNull]]];
    private _removed = ["QA_DZ", true, _actor, false] call Waldo_fnc_ParadropRemoveDropZone;
    [_actor, "DYNAMIC PARADROP QA", ["No QA operation was registered.", "Aircraft, embarked generated AI and all QA DZ markers removed. Already-deployed troops were preserved."] select _removed, ["WARNING", "SUCCESS"] select _removed] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_destroyGunshipServer = {[] spawn {uiSleep 0; ["QA_GUNSHIP", true] call Waldo_fnc_GunshipDestroy}};

// Vehicle recovery is live and repeatable; reset recreates any fixture consumed by packaging.
Waldo_QA_fnc_resetRecoveryLocalServer = {
    {
        if (!isNull _x) then {deleteVehicle _x};
    } forEach (missionNamespace getVariable ["Waldo_Recovery_Packages", []]);
    missionNamespace setVariable ["Waldo_Recovery_Packages", []];
    private _vehicle = ["qa_recovery_vehicle", "B_MRAP_01_F", [217, 7, 0], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
    private _carrier = ["qa_recovery_carrier", "B_MRAP_01_F", [225, -28, 0], 0, true] call Waldo_QA_fnc_getFeatureObjectServer;
    private _workshop = ["qa_recovery_workshop", "Land_RepairDepot_01_green_F", [225, 14, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
    _vehicle setDamage 0.8;
    [_workshop, "QA", 20, west] call Waldo_fnc_RecoveryRegisterWorkshop;
    private _recoveryInteraction = createHashMapFromArray [["enabled", true], ["challengeId", "repair"], ["difficulty", "easy"]];
    [_vehicle, "QA", 0.55, true, false, "B_Slingload_01_Cargo_F", true, 1, _recoveryInteraction] call Waldo_fnc_RecoveryRegisterVehicle;
    [_carrier, 12, "VIRTUAL", 2] call Waldo_fnc_RecoveryRegisterCarrier;
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
    [_actor, "SQUAD RALLY QA", "You are now group leader. Deploy with the production self-action, then use the station's respawn-selection test.", "SUCCESS"] call Waldo_QA_fnc_notifyActorServer;
};

// Improved landing QA creates only an AI-piloted helicopter. The production class-init and
// ownership handlers must discover it; the station never invokes the landing controller directly.
Waldo_QA_fnc_removeImprovedLandingServer = {
    private _helicopter = missionNamespace getVariable ["Waldo_QA_ImprovedLandingHelicopter", objNull];
    private _group = missionNamespace getVariable ["Waldo_QA_ImprovedLandingGroup", grpNull];
    if (!isNull _helicopter) then {
        {deleteVehicle _x} forEach crew _helicopter;
        deleteVehicle _helicopter;
    };
    if (!isNull _group) then {deleteGroup _group};
    missionNamespace setVariable ["Waldo_QA_ImprovedLandingHelicopter", objNull, true];
    missionNamespace setVariable ["Waldo_QA_ImprovedLandingGroup", grpNull, true];
    true
};
Waldo_QA_fnc_startImprovedLandingServer = {
    params [["_actor", objNull, [objNull]], ["_highApproach", false, [true]]];
    call Waldo_QA_fnc_removeImprovedLandingServer;
    private _landingPosition = [325, 70, 0];
    private _spawnAltitude = [30, 220] select _highApproach;
    private _spawnMode = "FLY";
    // The aircraft begins exactly 100 metres south of the marked helipad: twice the production
    // system's absolute 50 metre activation minimum. It is already established in forward flight,
    // so this tests the landing controller rather than Arma's ground-start waypoint completion.
    private _helicopter = createVehicle ["B_Heli_Light_01_F", [325, -30, _spawnAltitude], [], 0, _spawnMode];
    _helicopter setPosATL [325, -30, _spawnAltitude];
    _helicopter setDir 0;
    _helicopter enableSimulationGlobal true;
    createVehicleCrew _helicopter;
    {_x enableSimulationGlobal true} forEach crew _helicopter;
    _helicopter setVelocityModelSpace [0, [20, 32] select _highApproach, 0];
    private _pilot = currentPilot _helicopter;
    private _group = if (isNull _pilot) then {grpNull} else {group _pilot};
    if (!isNull _group) then {
        _group setBehaviourStrong "CARELESS";
        _group setCombatMode "BLUE";
        _group setSpeedMode "NORMAL";
        private _waypoint = _group addWaypoint [_landingPosition, 0];
        // Eden's vanilla Land waypoint is SCRIPTED and backed by fn_wpLand. The literal type
        // "LAND" resolves to UNDEF, which would leave the helicopter hovering without an order.
        _waypoint setWaypointType "SCRIPTED";
        _waypoint setWaypointScript "A3\functions_f\waypoints\fn_wpLand.sqf";
        _waypoint setWaypointBehaviour "CARELESS";
        _waypoint setWaypointCombatMode "BLUE";
        _waypoint setWaypointSpeed "NORMAL";
        _waypoint setWaypointCompletionRadius 2;
        // createVehicleCrew groups retain an engine-created waypoint at index zero. Explicitly
        // Select the landing leg so the aircraft cannot hover on the implicit crew waypoint. The
        // production tracker still discovers and controls it naturally; QA never calls it directly.
        _group setCurrentWaypoint _waypoint;
    };
    _helicopter engineOn true;
    missionNamespace setVariable ["Waldo_QA_ImprovedLandingHelicopter", _helicopter, true];
    missionNamespace setVariable ["Waldo_QA_ImprovedLandingGroup", _group, true];
    [_actor, "AI HELICOPTER LANDING", format ["AI-only %1 approach started. The production handler must acquire it without the QA station calling the controller.", ["normal", "excessively high go-around"] select _highApproach], "SUCCESS", "AI_LANDING_QA"] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_reportImprovedLandingServer = {
    params [["_actor", objNull, [objNull]]];
    private _helicopter = missionNamespace getVariable ["Waldo_QA_ImprovedLandingHelicopter", objNull];
    if (isNull _helicopter) exitWith {
        [_actor, "AI HELICOPTER LANDING", "No QA helicopter exists.", "WARNING", "AI_LANDING_QA"] call Waldo_QA_fnc_notifyActorServer;
    };
    private _pilot = currentPilot _helicopter;
    private _group = if (isNull _pilot) then {grpNull} else {group _pilot};
    private _index = if (isNull _group) then {-1} else {currentWaypoint _group};
    private _waypoints = if (isNull _group) then {[]} else {waypoints _group};
    private _type = if (_index >= 0 && {_index < count _waypoints}) then {waypointType [_group, _index]} else {"NONE"};
    private _message = format ["AI pilot: %1 | owner: %2 | simulation: %3 | engine: %4 | current WP: %5/%6 | tracker: %7 | active controller: %8 | result: %9 | distance: %10 m | altitude ATL: %11 m | grounded: %12", !isNull _pilot && {!isPlayer _pilot} && {isNull (remoteControlled _pilot)}, owner _helicopter, simulationEnabled _helicopter, isEngineOn _helicopter, _index, _type, _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_TrackedLocal", false], _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Active", false], _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_LastResult", []], round (_helicopter distance2D [325, 70, 0]), round ((getPosATL _helicopter) select 2), isTouchingGround _helicopter];
    [_actor, "AI HELICOPTER LANDING", _message, "INFO", "AI_LANDING_QA"] call Waldo_QA_fnc_notifyActorServer;
};
Waldo_QA_fnc_setUiThemeServer = {
    params [["_actor", objNull, [objNull]], ["_theme", "DEFAULT", [""]]];
    private _ok = [_theme, false] call Waldo_fnc_UiThemeSetServer;
    [_actor, "UI THEME QA", format ["%1 theme %2 globally. Open notifications, interaction challenges and service panels to compare the same controls with the new visual treatment.", _theme, ["was rejected", "is active"] select _ok], ["ERROR", "SUCCESS"] select _ok, "UI_THEME_QA"] call Waldo_QA_fnc_notifyActorServer;
};

missionNamespace setVariable ["Waldo_QA_ExtendedFeatureStationsReady", true, true];
diag_log "WMP EXTENDED FEATURE STATIONS READY: 18 station workflows configured.";
