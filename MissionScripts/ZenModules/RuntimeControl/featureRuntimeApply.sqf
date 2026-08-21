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
        // -2 ("all clients except owner 2") never reaches a listen server's own host client, since
        // the host shares owner 2 with the embedded server - so the direct hasInterface calls below
        // are required to actually apply this on a hosting player's own machine, not just remote
        // clients. Every target function here already guards on hasInterface, so these are safe
        // no-ops on a pure dedicated server.
        [] remoteExecCall ["Waldo_fnc_TreatmentFeedbackStop", -2];
        if (hasInterface) then {[] call Waldo_fnc_TreatmentFeedbackStop};
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_TreatmentFeedbackInit", -2, "Waldo_TreatmentFeedback_RuntimeInit"];
            if (hasInterface) then {[] call Waldo_fnc_TreatmentFeedbackInit};
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
    case "CREATE_3D_MARKER": {
        _settings params ["_id", "_anchor", "_text", "_icon", "_colour", "_sides", "_aboveObject", "_extraHeight", "_distance", "_size"];
        // The client ID is only a correlation hint. Generate the registry key on the server so a
        // curator cannot accidentally overwrite a marker created by a script or another curator.
        _id = format ["WMP3D_ZEUS_%1_%2", _requestOwner, floor (diag_tickTime * 1000)];
        private _icons = [
            "\a3\ui_f\data\map\markers\military\objective_CA.paa",
            "\a3\ui_f\data\map\markers\military\dot_CA.paa",
            "\a3\ui_f\data\map\markers\military\warning_CA.paa",
            "\a3\ui_f\data\map\markers\military\start_CA.paa",
            "\a3\ui_f\data\map\markers\military\end_CA.paa",
            "\a3\ui_f\data\map\vehicleicons\iconMan_ca.paa",
            "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa",
            "\a3\ui_f\data\map\vehicleicons\iconHelicopter_ca.paa",
            "\a3\ui_f\data\map\vehicleicons\iconPlane_ca.paa",
            "\a3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"
        ];
        private _allowedColours = [
            [0.49, 0.78, 1, 0.95], [1, 1, 1, 0.95], [0.25, 0.9, 0.45, 0.95],
            [1, 0.72, 0.18, 0.95], [0.95, 0.2, 0.2, 0.95], [0.75, 0.45, 1, 0.95]
        ];
        private _allowedSideSets = [["ALL"], [west], [east], [independent], [civilian]];
        if !(_anchor isEqualType objNull || {_anchor isEqualType [] && {count _anchor >= 2}}) exitWith {false};
        if (_anchor isEqualType objNull && {isNull _anchor}) exitWith {false};
        if !(_icon in _icons) then {_icon = _icons select 1};
        if !(_colour in _allowedColours) then {_colour = _allowedColours select 0};
        if !(_sides in _allowedSideSets) then {_sides = ["ALL"]};
        if !(_aboveObject isEqualType true) then {_aboveObject = false};
        if !(_extraHeight isEqualType 0) then {_extraHeight = 0};
        if !(_distance isEqualType 0) then {_distance = 150};
        if !(_size isEqualType 0) then {_size = 0.8};
        _text = [_text, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -_()/.:+"] call BIS_fnc_filterString;
        if (_text == "") then {_text = "POINT OF INTEREST"};
        _extraHeight = (_extraHeight max 0) min 20;
        _distance = (_distance max 10) min 2000;
        _size = (_size max 0.2) min 3;
        private _objectHeight = 0;
        if (_aboveObject && {_anchor isEqualType objNull} && {!isNull _anchor}) then {
            private _bounds = boundingBoxReal _anchor;
            if (count _bounds >= 2) then {
                private _lower = _bounds select 0;
                private _upper = _bounds select 1;
                _objectHeight = ((_upper select 2) max (_lower select 2)) max 0;
                _objectHeight = _objectHeight + 0.25;
            };
        };
        private _options = createHashMapFromArray [
            ["text", _text], ["icon", _icon], ["colour", _colour], ["sides", _sides],
            ["offset", [0, 0, _objectHeight + _extraHeight]], ["distance", _distance], ["width", _size], ["height", _size]
        ];
        private _result = [_id, _anchor, _options] call Waldo_fnc_Create3DMarker;
        ["3D MARKER", if (_result == "") then {"The marker request was rejected."} else {"The custom world marker is active."}, if (_result == "") then {"ERROR"} else {"SUCCESS"}, "ZEN_3D_MARKER"] call _reply;
        _result != ""
    };
    case "REMOVE_3D_MARKER": {
        _settings params [["_id", "", [""]]];
        private _registry = missionNamespace getVariable ["Waldo_3DMarker_Registry", []];
        private _exists = _id != "" && {_registry findIf {(_x param [0, ""]) isEqualTo _id} >= 0};
        private _ok = _exists && {[_id] call Waldo_fnc_Remove3DMarker};
        [
            "3D MARKER",
            if (_ok) then {"The selected custom world marker was removed."} else {"That marker no longer exists."},
            if (_ok) then {"SUCCESS"} else {"WARNING"},
            "ZEN_3D_MARKER_REMOVE"
        ] call _reply;
        _ok
    };
    case "FIELD_EQUIPMENT": {
        _settings params ["_object", "_mode", "_procedure", "_title", "_difficulty", "_successPreset", "_successCode", "_failurePreset", "_failureCode", "_repeat", "_retry", "_direct", "_detonate"];
        private _validProcedures = ["wirecut", "minesweeper", "keypad", "lockpick", "circuit", "repair", "radiotune", "pressure", "sequence", "commandinput"];
        private _validSuccessPresets = ["COMPLETE", "SHOW_ENABLE", "HIDE_DISABLE", "UNLOCK", "LOCK", "DESTROY", "DELETE", "NONE"];
        private _validFailurePresets = ["NONE", "SHOW_ENABLE", "HIDE_DISABLE", "UNLOCK", "LOCK", "DESTROY", "DELETE"];
        _mode = toUpperANSI _mode;
        _procedure = toLowerANSI _procedure;
        _difficulty = toLowerANSI _difficulty;
        _successPreset = toUpperANSI _successPreset;
        _failurePreset = toUpperANSI _failurePreset;
        if (isNull _object || {_object isKindOf "Logic"}) exitWith {false};
        if !(_mode in ["STANDARD", "EOD"]) then {_mode = "STANDARD"};
        if !(_procedure in _validProcedures) then {_procedure = if (_mode == "EOD") then {"wirecut"} else {"circuit"}};
        if !(_difficulty in ["easy", "standard", "hard", "expert"]) then {_difficulty = "standard"};
        if !(_successPreset in _validSuccessPresets) then {_successPreset = "COMPLETE"};
        if !(_failurePreset in _validFailurePresets) then {_failurePreset = "NONE"};
        if !(_successCode isEqualType "") then {_successCode = ""};
        if !(_failureCode isEqualType "") then {_failureCode = ""};
        _successCode = _successCode select [0, 4096];
        _failureCode = _failureCode select [0, 4096];
        _title = [_title, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 -_()/"] call BIS_fnc_filterString;
        if (_title == "") then {_title = if (_mode == "EOD") then {"Defuse Device"} else {"Operate Equipment"}};
        _object setVariable ["Waldo_FieldEquipment_SuccessPreset", _successPreset];
        _object setVariable ["Waldo_FieldEquipment_FailurePreset", _failurePreset];
        _object setVariable ["Waldo_FieldEquipment_SuccessCode", if (_successCode == "") then {{}} else {compile _successCode}];
        _object setVariable ["Waldo_FieldEquipment_FailureCode", if (_failureCode == "") then {{}} else {compile _failureCode}];
        _object setVariable ["Waldo_FieldEquipment_ZenConfigured", true, true];
        [_object, _mode, _procedure, _title, _difficulty, _repeat, _retry, _direct, _detonate]
            remoteExecCall ["Waldo_fnc_FieldEquipmentZenSetupLocal", 0, _object];
        ["FIELD EQUIPMENT", format ["%1 interaction added to the selected object.", if (_mode == "EOD") then {"EOD"} else {"Field Equipment"}], "SUCCESS", "FIELD_EQUIPMENT_ZEN"] call _reply;
        true
    };
    case "TRANSPORT_REGISTER": {
        _settings params ["_target", "_type", "_name", "_leadersOnly", "_showMarker", "_boarding", "_dwell", "_altitude", "_repair", "_refuel", "_invulnerable", "_forceOut", "_failSafe"];
        private _options = createHashMapFromArray [
            ["leadersOnly", _leadersOnly], ["showMarker", _showMarker],
            ["boardingSeconds", _boarding], ["destinationDwell", _dwell],
            ["cruiseAltitude", _altitude], ["repairAtBase", _repair],
            ["refuelAtBase", _refuel], ["invulnerable", _invulnerable],
            ["forceDisembark", _forceOut], ["failSafeReset", _failSafe]
        ];
        // ZEN always generates the internal registry ID; Zeus configures only the visible identity.
        private _ok = [_target, _type, "", _name, _options] call Waldo_fnc_TransportRegister;
        private _detail = if (_ok) then {
            format ["%1 registered as %2. Player controls and the optional map marker are now active.", _target getVariable ["Waldo_TransportService_Name", "Transport service"], _target getVariable ["Waldo_TransportService_Id", "generated service"]]
        } else {
            missionNamespace getVariable ["Waldo_Transport_LastRegistrationError", "Registration was rejected for an unknown reason. Check the server RPT."]
        };
        ["TRANSPORT SERVICE", _detail, if (_ok) then {"SUCCESS"} else {"ERROR"}, "TRANSPORT_ZEN"] call _reply;
        _ok
    };
    case "TRANSPORT_RTB": {
        _settings params ["_target"];
        private _type = _target getVariable ["Waldo_TransportService_Type", ""];
        private _ok = _type in ["HELICOPTER", "GROUND", "BOAT"] && {["RTB", _type, _target, [], _caller] call Waldo_fnc_TransportRequestServer};
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
        // See the listen-host note above TREATMENT_CONFIG's equivalent calls.
        [] remoteExecCall ["Waldo_fnc_RallyPointStop", -2];
        if (hasInterface) then {[] call Waldo_fnc_RallyPointStop};
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_RallyPointInit", -2, "Waldo_Rally_RuntimeInit"];
            if (hasInterface) then {[] call Waldo_fnc_RallyPointInit};
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
        // See the listen-host note above TREATMENT_CONFIG's equivalent calls.
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_TreeFellingInit", -2, "Waldo_TreeFelling_RuntimeInit"];
            if (hasInterface) then {[] call Waldo_fnc_TreeFellingInit};
        } else {
            [] remoteExecCall ["Waldo_fnc_TreeFellingStop", -2];
            if (hasInterface) then {[] call Waldo_fnc_TreeFellingStop};
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
        // See the listen-host note above TREATMENT_CONFIG's equivalent calls.
        if (_enable) then {
            [] remoteExecCall ["Waldo_fnc_EmergencyDismountInit", -2, "Waldo_EmergencyDismount_RuntimeInit"];
            if (hasInterface) then {[] call Waldo_fnc_EmergencyDismountInit};
        } else {
            [] remoteExecCall ["Waldo_fnc_EmergencyDismountStop", -2];
            if (hasInterface) then {[] call Waldo_fnc_EmergencyDismountStop};
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
