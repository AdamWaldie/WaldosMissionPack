/*
 * Author: WaldoTheWarfighter
 * Validates curator requests and applies runtime feature configuration from ZEN.
 *
 * Arguments:
 * 0: action <STRING>
 * 1: settings <ARRAY>
 *
 * Return Value:
 * Boolean - true when the request was accepted
 *
 * Example:
 * ["FIELD_RESUPPLY_HUB", [objNull, west, -1, getPosATL player]]
 *     remoteExecCall ["Waldo_fnc_FeatureRuntimeApply", 2];
 *
 * Current caller: Waldo_fnc_FeatureRuntimeZen forwards validated ZEN runtime-control dialogs.
 */

params [
    ["_action", "", [""]],
    ["_settings", [], [[]]]
];
if !(isServer) exitWith {
    [_action, _settings] remoteExecCall ["Waldo_fnc_FeatureRuntimeApply", 2];
    true
};

private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _authorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_authorized) exitWith {false};
private _requestOwner = if (remoteExecutedOwner > 0) then {remoteExecutedOwner} else {2};

private _publish = {
    params ["_name", "_value"];
    missionNamespace setVariable [_name, _value, true];
};
private _publishAll = {
    private _updates = _this;
    {_x call _publish} forEach _updates;
    // One ordered payload is applied before any following remote initializer from this server.
    [_updates, false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
};

switch (toUpperANSI _action) do {
    case "PERSISTENCE_CONFIG": {
        _settings params ["_enable", "_playerInterval", "_objectInterval", "_loadout", "_medical", "_needs", "_position", "_radios", "_database"];
        [
            ["Waldo_Persistence_Enable", _enable],
            ["Waldo_Persistence_PlayerSaveInterval", _playerInterval max 10],
            ["Waldo_Persistence_ObjectSaveInterval", _objectInterval max 10],
            ["Waldo_Persistence_SaveLoadout", _loadout],
            ["Waldo_Persistence_SaveMedical", _medical],
            ["Waldo_Persistence_SaveFoodWater", _needs],
            ["Waldo_Persistence_SavePosition", _position],
            ["Waldo_Persistence_SaveRadios", _radios],
            ["Waldo_Persistence_DatabaseName", _database]
        ] call _publishAll;
        if (_enable) then {
            if (missionNamespace getVariable ["Waldo_Persistence_Active", false]) then {[] call Waldo_fnc_PersistenceStop};
            [] spawn {
                sleep 0.75;
                missionNamespace setVariable ["Waldo_Persistence_Enable", true, true];
                [] call Waldo_fnc_PersistenceInit;
                [] remoteExecCall ["Waldo_fnc_PersistenceInit", -2, "Waldo_Persistence_RuntimeInit"];
            };
        } else {
            [] call Waldo_fnc_PersistenceStop;
            [] remoteExecCall ["", "Waldo_Persistence_RuntimeInit"];
        };
    };
    case "PERSISTENCE_OBJECT": {
        _settings params ["_object", "_key", "_options"];
        if (isNull _object) exitWith {false};
        [_object, _key, _options] spawn Waldo_fnc_PersistenceRegisterObject;
    };
    case "PERSISTENCE_SAVE": {
        _settings params ["_savePlayers", "_saveObjects"];
        [_savePlayers, _saveObjects] call Waldo_fnc_PersistenceSaveNow;
    };
    case "TREATMENT_CONFIG": {
        _settings params ["_enable", "_showStart", "_showSuccess", "_showFailure", "_notifyPatient", "_notifyMedic", "_showMedic", "_showBodyPart"];
        [
            ["Waldo_TreatmentFeedback_Enable", _enable], ["Waldo_TreatmentFeedback_ShowStart", _showStart],
            ["Waldo_TreatmentFeedback_ShowSuccess", _showSuccess], ["Waldo_TreatmentFeedback_ShowFailure", _showFailure],
            ["Waldo_TreatmentFeedback_NotifyPatient", _notifyPatient], ["Waldo_TreatmentFeedback_NotifyMedic", _notifyMedic],
            ["Waldo_TreatmentFeedback_ShowMedicName", _showMedic], ["Waldo_TreatmentFeedback_ShowBodyPart", _showBodyPart]
        ] call _publishAll;
        [] remoteExecCall ["Waldo_fnc_TreatmentFeedbackStop", -2];
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_TreatmentFeedbackInit", -2, "Waldo_TreatmentFeedback_RuntimeInit"];
        } else {
            [] remoteExecCall ["", "Waldo_TreatmentFeedback_RuntimeInit"];
        };
    };
    case "FIELD_RESUPPLY_HUB": {
        _settings params ["_hub", "_side", "_stock", ["_modulePos", [], [[]]]];
        if (isNull _hub && {count _modulePos >= 2}) then {
            private _crateClass = missionNamespace getVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F"];
            if !(isClass (configFile >> "CfgVehicles" >> _crateClass)) then {_crateClass = "B_supplyCrate_F"};
            _hub = createVehicle [_crateClass, _modulePos, [], 0, "NONE"];
            clearWeaponCargoGlobal _hub;
            clearMagazineCargoGlobal _hub;
            clearItemCargoGlobal _hub;
            clearBackpackCargoGlobal _hub;
            [_hub, _requestOwner, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
        };
        if (isNull _hub) exitWith {false};
        [_hub, _side, _stock] call Waldo_fnc_FieldResupplyRegisterHub;
    };
    case "FIELD_RESUPPLY_CARRIER": {
        _settings params ["_unit", "_crates", "_maximum"];
        [_unit, _crates, _maximum] call Waldo_fnc_FieldResupplyAssignCarrier;
    };
    case "RECOVERY_WORKSHOP": {
        _settings params ["_object", "_key", "_radius", "_side", ["_notificationRadius", -1, [0]], ["_createMarkers", missionNamespace getVariable ["Waldo_Recovery_CreateWorkshopMarkers", true], [true]]];
        [_object, _key, _radius, _side, _notificationRadius, _createMarkers] call Waldo_fnc_RecoveryRegisterWorkshop;
    };
    case "RECOVERY_VEHICLE": {
        _settings params ["_object", "_key", "_damage", "_destroyed", "_engineer", "_package", "_cargo", "_fuel", ["_interaction", []]];
        [_object, _key, _damage, _destroyed, _engineer, _package, _cargo, _fuel, _interaction] call Waldo_fnc_RecoveryRegisterVehicle;
    };
    case "RECOVERY_CARRIER": {
        _settings params ["_object", "_range"];
        [_object, _range] call Waldo_fnc_RecoveryRegisterCarrier;
    };
    case "RALLY_CONFIG": {
        _settings params ["_enable", "_objectClass", "_duration", "_deploymentTime", "_cooldown", "_enemyRadius", "_minimumMembers", "_placement", "_slope", "_regroup"];
        if !(isClass (configFile >> "CfgVehicles" >> _objectClass)) exitWith {false};
        [
            ["Waldo_Rally_Enable", _enable], ["Waldo_Rally_ObjectClass", _objectClass],
            ["Waldo_Rally_Duration", _duration max 15], ["Waldo_Rally_DeploymentTime", _deploymentTime max 1], ["Waldo_Rally_Cooldown", _cooldown max 0],
            ["Waldo_Rally_EnemyExclusionRadius", _enemyRadius max 0], ["Waldo_Rally_MinimumGroupMembers", round (_minimumMembers max 1)],
            ["Waldo_Rally_PlacementDistance", (_placement max 1) min 10], ["Waldo_Rally_MaximumSlope", (_slope max 0) min 45],
            ["Waldo_Rally_AllowRegroup", _regroup]
        ] call _publishAll;
        [] remoteExecCall ["Waldo_fnc_RallyPointStop", -2];
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_RallyPointInit", -2, "Waldo_Rally_RuntimeInit"];
        } else {
            [] call Waldo_fnc_RallyPointRemoveAllServer;
            [] remoteExecCall ["", "Waldo_Rally_RuntimeInit"];
        };
    };
    case "TACTICAL_DISPLAY": {
        _settings params ["_object", "_side", "_radius", "_knownEnemies", ["_interaction", []]];
        [_object, _side, _radius, _knownEnemies, _interaction] call Waldo_fnc_TacticalDisplayRegister;
    };
    case "TREE_CONFIG": {
        _settings params ["_enable", "_range", "_baseHits", "_heightFactor", "_cooldown", "_clearBushes", "_bushRadius"];
        [
            ["Waldo_TreeFelling_Enable", _enable], ["Waldo_TreeFelling_Range", _range max 1],
            ["Waldo_TreeFelling_BaseHits", round (_baseHits max 1)], ["Waldo_TreeFelling_HeightFactor", _heightFactor max 0],
            ["Waldo_TreeFelling_HitCooldown", _cooldown max 0.1], ["Waldo_TreeFelling_ClearBushes", _clearBushes],
            ["Waldo_TreeFelling_BushRadius", _bushRadius max 0]
        ] call _publishAll;
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_TreeFellingInit", -2, "Waldo_TreeFelling_RuntimeInit"];
        } else {
            [] remoteExecCall ["Waldo_fnc_TreeFellingStop", -2];
            [] remoteExecCall ["", "Waldo_TreeFelling_RuntimeInit"];
        };
    };
    case "EMERGENCY_CONFIG": {
        _settings params ["_enable", "_overturn", "_destroyed", "_preserve", "_protect", "_seconds", "_clearRadius", "_requireClear", "_useEject", "_recover"];
        [
            ["Waldo_EmergencyDismount_Enable", _enable], ["Waldo_EmergencyDismount_OnOverturn", _overturn],
            ["Waldo_EmergencyDismount_OnDestroyed", _destroyed], ["Waldo_EmergencyDismount_PreserveVelocity", _preserve],
            ["Waldo_EmergencyDismount_ProtectDuringExit", _protect], ["Waldo_EmergencyDismount_ProtectionSeconds", _seconds max 0.5],
            ["Waldo_EmergencyDismount_ClearPositionRadius", _clearRadius max 0], ["Waldo_EmergencyDismount_RequireClearExit", _requireClear],
            ["Waldo_EmergencyDismount_UseEject", _useEject], ["Waldo_EmergencyDismount_RecoverUnconscious", _recover]
        ] call _publishAll;
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_EmergencyDismountInit", -2, "Waldo_EmergencyDismount_RuntimeInit"];
        } else {
            [] remoteExecCall ["Waldo_fnc_EmergencyDismountStop", -2];
            [] remoteExecCall ["", "Waldo_EmergencyDismount_RuntimeInit"];
        };
    };
    case "ACCESS_CONFIG": {
        _settings params ["_enable", "_iconRange", "_nameRange", "_lineOfSight", "_includeAI", "_allowToggle", "_visible"];
        [
            ["Waldo_AccessibilityPID_Enable", _enable], ["Waldo_AccessibilityPID_IconRange", _iconRange max 10],
            ["Waldo_AccessibilityPID_NameRange", _nameRange max 0], ["Waldo_AccessibilityPID_RequireLOS", _lineOfSight],
            ["Waldo_AccessibilityPID_IncludeAI", _includeAI], ["Waldo_AccessibilityPID_AllowToggle", _allowToggle],
            ["Waldo_AccessibilityPID_DefaultVisible", _visible]
        ] call _publishAll;
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_AccessibilityPIDStop", -2];
            [] remoteExecCall ["Waldo_fnc_AccessibilityPIDInit", -2, "Waldo_AccessibilityPID_RuntimeInit"];
        } else {
            [] remoteExecCall ["Waldo_fnc_AccessibilityPIDStop", -2];
            [] remoteExecCall ["", "Waldo_AccessibilityPID_RuntimeInit"];
        };
    };
    case "AI_CONFIG": {
        _settings params ["_enable", "_mode", "_profile"];
        [
            ["Waldo_AIRebalance_Enable", _enable],
            ["Waldo_AIRebalance_Mode", _mode],
            ["Waldo_AIRebalance_Profile", _profile]
        ] call _publishAll;
        if (_enable) then {
            [_mode, _profile] remoteExecCall ["Waldo_fnc_AIRebalanceInit", 0, "Waldo_AIRebalance_RuntimeInit"];
        } else {
            [] remoteExecCall ["Waldo_fnc_AIRebalanceStop", 0];
            [] remoteExecCall ["", "Waldo_AIRebalance_RuntimeInit"];
        };
    };
    case "HAZARD_SET": {
        _settings params ["_key", "_area", "_profile"];
        private _safeKey = [_key, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
        if (_safeKey == "" || {_safeKey != _key}) exitWith {false};
        [["Waldo_Hazard_Enable", true]] call _publishAll;
        [_key, _area, _profile] remoteExecCall ["Waldo_fnc_HazardRegisterZone", 0, format ["Waldo_Hazard_Zone_%1", _key]];
        [] remoteExecCall ["Waldo_fnc_HazardInit", -2, "Waldo_Hazard_RuntimeInit"];
    };
    case "HAZARD_REMOVE": {
        _settings params ["_key"];
        // Reconcile the authoritative registry synchronously before deriving the enabled state.
        [_key] call Waldo_fnc_HazardUnregisterZone;
        [_key] remoteExecCall ["Waldo_fnc_HazardUnregisterZone", -2];
        [] remoteExecCall ["", format ["Waldo_Hazard_Zone_%1", _key]];
        if ((missionNamespace getVariable ["Waldo_Hazard_Zones", []]) isEqualTo []) then {
            missionNamespace setVariable ["Waldo_Hazard_Enable", false, true];
            [[ ["Waldo_Hazard_Enable", false] ], false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
            [] remoteExecCall ["Waldo_fnc_HazardStop", -2];
            [] remoteExecCall ["", "Waldo_Hazard_RuntimeInit"];
        };
    };
    case "BREACH_SET": {
        _settings params ["_className", "_profile"];
        if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {false};
        private _profiles = missionNamespace getVariable ["Waldo_Breaching_Profiles", createHashMap];
        _profiles set [_className, _profile];
        // Profiles may contain mission-local Code callbacks, which cannot be safely transported in
        // the ordered settings payload. Publish the profile normally; init only needs the enable flag.
        ["Waldo_Breaching_Profiles", _profiles] call _publish;
        [["Waldo_Breaching_Enable", true]] call _publishAll;
        [] remoteExecCall ["Waldo_fnc_BreachingInit", 0, "Waldo_Breaching_RuntimeInit"];
    };
    case "BREACH_REMOVE": {
        _settings params ["_className"];
        private _profiles = missionNamespace getVariable ["Waldo_Breaching_Profiles", createHashMap];
        _profiles deleteAt _className;
        ["Waldo_Breaching_Profiles", _profiles] call _publish;
    };
    default {false};
};
true
