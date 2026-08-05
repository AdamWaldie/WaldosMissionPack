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
private _caller = objNull;
if (remoteExecutedOwner > 0) then {
    private _callerIndex = allPlayers findIf {owner _x == remoteExecutedOwner};
    _caller = if (_callerIndex >= 0) then {allPlayers select _callerIndex} else {objNull};
    _authorized = !isNull _caller && {!isNull (getAssignedCuratorLogic _caller)};
};
if !(_authorized) exitWith {false};
private _requestOwner = if (remoteExecutedOwner > 0) then {remoteExecutedOwner} else {2};

private _reply = {
    params ["_title", "_message", "_state", "_key"];
    diag_log format ["[WMP ZEN SERVER] action=%1 owner=%2 result=%3 detail=%4", _action, _requestOwner, _state, _message];
    if (_requestOwner > 2) then {
        [_title, _message, _state, _key, 7] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _requestOwner];
    };
};

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
            [_hub, nil, nil, true, true] call Waldo_fnc_SetCargoAttributes;
            [_hub, _requestOwner, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
        };
        if (isNull _hub) exitWith {false};
        [_hub, _side, _stock] call Waldo_fnc_FieldResupplyRegisterHub;
    };
    case "FIELD_RESUPPLY_CARRIER": {
        _settings params ["_unit", "_crates", "_maximum"];
        [_unit, _crates, _maximum] call Waldo_fnc_FieldResupplyAssignCarrier;
    };
    case "FIELD_RESUPPLY_GRANT": {
        _settings params ["_unit", "_amount", "_expandCapacity"];
        [_unit, _amount, _expandCapacity] call Waldo_fnc_FieldResupplyGrantCrates;
    };
    case "RECOVERY_WORKSHOP": {
        _settings params ["_object", "_key", "_radius", "_side", ["_notificationRadius", -1, [0]], ["_createMarkers", missionNamespace getVariable ["Waldo_Recovery_CreateWorkshopMarkers", true], [true]]];
        private _ok = [_object, _key, _radius, _side, _notificationRadius, _createMarkers] call Waldo_fnc_RecoveryRegisterWorkshop;
        ["VEHICLE RECOVERY", if (_ok) then {format ["Workshop %1 registered.", toUpperANSI _key]} else {"Workshop registration was rejected. Check the selected object and server RPT."}, if (_ok) then {"SUCCESS"} else {"ERROR"}, "RECOVERY_ZEN"] call _reply;
        _ok
    };
    case "RECOVERY_VEHICLE": {
        _settings params ["_object", "_key", "_damage", "_destroyed", "_engineer", "_package", "_cargo", "_fuel", ["_interaction", []]];
        private _ok = [_object, _key, _damage, _destroyed, _engineer, _package, _cargo, _fuel, _interaction] call Waldo_fnc_RecoveryRegisterVehicle;
        ["VEHICLE RECOVERY", if (_ok) then {"Vehicle registered for recovery."} else {"Vehicle registration was rejected. Check the target and workshop key."}, if (_ok) then {"SUCCESS"} else {"ERROR"}, "RECOVERY_ZEN"] call _reply;
        _ok
    };
    case "RECOVERY_CARRIER": {
        _settings params ["_object", "_range", ["_mode", "AUTO"], ["_capacity", 1]];
        private _ok = [_object, _range, _mode, _capacity] call Waldo_fnc_RecoveryRegisterCarrier;
        ["VEHICLE RECOVERY", if (_ok) then {format ["Recovery carrier registered in %1 mode.", toUpperANSI _mode]} else {"Carrier registration was rejected. Check the selected vehicle."}, if (_ok) then {"SUCCESS"} else {"ERROR"}, "RECOVERY_ZEN"] call _reply;
        _ok
    };
    case "TRANSPORT_REGISTER": {
        _settings params ["_target", "_type", "_id", "_name", "_leadersOnly", "_showMarker", "_boarding", "_dwell", "_altitude", "_repair", "_refuel", "_forceOut", "_failSafe"];
        private _options = createHashMapFromArray [
            ["leadersOnly", _leadersOnly], ["showMarker", _showMarker],
            ["boardingSeconds", _boarding], ["destinationDwell", _dwell],
            ["cruiseAltitude", _altitude], ["repairAtBase", _repair],
            ["refuelAtBase", _refuel], ["forceDisembark", _forceOut], ["failSafeReset", _failSafe]
        ];
        private _ok = [_target, _type, _id, _name, _options] call Waldo_fnc_TransportRegister;
        ["TRANSPORT SERVICE", if (_ok) then {"Service registered."} else {"Registration rejected. Select a living AI-crewed vehicle matching the chosen type."}, if (_ok) then {"SUCCESS"} else {"ERROR"}, "TRANSPORT_ZEN"] call _reply;
    };
    case "TRANSPORT_RTB": {
        _settings params ["_target"];
        private _type = _target getVariable ["Waldo_TransportService_Type", ""];
        private _ok = _type in ["HELICOPTER", "GROUND"] && {["RTB", _type, _target, [], _caller] call Waldo_fnc_TransportRequestServer};
        ["TRANSPORT SERVICE", if (_ok) then {"Return-to-base ordered."} else {"The selected vehicle is not a registered transport service."}, if (_ok) then {"SUCCESS"} else {"ERROR"}, "TRANSPORT_ZEN"] call _reply;
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
        private _registered = [_key, _area, _profile, true] call Waldo_fnc_HazardRegisterZone;
        ["HAZARDOUS ENVIRONMENT", ["Zone registration was rejected by the server.", format ["Zone %1 is active and synchronised for connected and JIP players.", _key]] select _registered, ["ERROR", "SUCCESS"] select _registered, "HAZARD_RUNTIME"] call _reply;
    };
    case "HAZARD_REMOVE": {
        _settings params ["_key"];
        // Reconcile the authoritative registry synchronously before deriving the enabled state.
        private _removed = [_key, true] call Waldo_fnc_HazardUnregisterZone;
        ["HAZARDOUS ENVIRONMENT", ["The selected zone no longer existed on the server.", format ["Zone %1 was removed and the updated registry was synchronised.", _key]] select _removed, ["WARNING", "SUCCESS"] select _removed, "HAZARD_RUNTIME"] call _reply;
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
