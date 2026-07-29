/*
 * Author: Waldo
 * Provides ZEN configuration and operation dialogs for optional WMP feature systems.
 *
 * Arguments:
 * 0: feature <STRING>
 * 1: modulePosition <ARRAY>
 *
 * Return Value:
 * Nothing
 */

params [
    ["_feature", "", [""]],
    ["_modulePos", [], [[]]]
];
if !(hasInterface) exitWith {};

switch (toUpperANSI _feature) do {
    case "GUNSHIP_REGISTER": {
        private _nearbyAircraft = nearestObjects [_modulePos, ["Air"], 40, true];
        private _aircraft = _nearbyAircraft param [0, objNull];
        [
            "Register or Spawn Airborne Gunship",
            [
                ["EDIT", ["System ID", "Unique letters, numbers, underscores or hyphens."], [format ["gunship_%1", round (serverTime * 10)]]],
                ["EDIT", ["Callsign", "Name used by markers and notifications."], ["SPECTRE"]],
                ["COMBO", ["Side", "Crew and marker allegiance."], [[west, east, independent], ["BLUFOR", "OPFOR", "Independent"], 0]],
                ["EDIT", ["Aircraft class", "Leave blank to register the nearest aircraft within 40 metres."], [""]],
                ["SLIDER", ["Orbit altitude", "AI flyInHeight setting in metres."], [100, 5000, missionNamespace getVariable ["Waldo_Gunship_DefaultAltitude", 700], 0]],
                ["SLIDER", ["Orbit radius", "LOITER waypoint radius in metres."], [200, 10000, missionNamespace getVariable ["Waldo_Gunship_DefaultRadius", 1500], 0]],
                ["SLIDER", ["Service duration", "Seconds spent in the home orbit before return."], [0, 3600, missionNamespace getVariable ["Waldo_Gunship_DefaultServiceDuration", 900], 0]],
                ["CHECKBOX", ["Show friendly markers", "Show the aircraft and orbit to friendly clients."], true],
                ["CHECKBOX", ["Copy setup script", "Copy an equivalent registration call for permanent mission setup."], false]
            ],
            {
                params ["_values", "_arguments"];
                _arguments params ["_modulePos", "_aircraft"];
                _values params ["_id", "_callsign", "_side", "_class", "_altitude", "_radius", "_serviceDuration", "_markers", "_copy"];
                private _config = createHashMapFromArray [
                    ["id", _id], ["callsign", _callsign], ["side", _side], ["altitude", _altitude], ["radius", _radius],
                    ["serviceDuration", _serviceDuration], ["showMarkers", _markers], ["home", _modulePos], ["orbit", _modulePos]
                ];
                if (_class == "") then {
                    _config set ["aircraft", _aircraft];
                } else {
                    _config set ["aircraftClass", _class];
                    _config set ["spawnPosition", [_modulePos select 0, _modulePos select 1, _altitude]];
                };
                [_config] call Waldo_fnc_GunshipRegister;
                if (_copy) then {
                    private _assetEntry = "";
                    if (_class != "") then {
                        _assetEntry = format ["[%1,%2],[%3,%4]", str "aircraftClass", str _class, str "spawnPosition", str [_modulePos select 0, _modulePos select 1, _altitude]];
                    } else {
                        private _variableName = vehicleVarName _aircraft;
                        if (_variableName != "") then {_assetEntry = format ["[%1,%2]", str "aircraft", _variableName]};
                    };
                    if (_assetEntry == "") then {
                        systemChat "[WMP] Give the existing aircraft an Eden variable name before exporting its setup.";
                    } else {
                        copyToClipboard format ["private _gunshipConfig = createHashMapFromArray [[%1,%2],[%3,%4],[%5,%6],%7,[%8,%9],[%10,%11],[%12,%13],[%14,%15],[%16,%17]]; [_gunshipConfig] call Waldo_fnc_GunshipRegister;", str "id", str _id, str "callsign", str _callsign, str "side", str _side, _assetEntry, str "home", str _modulePos, str "orbit", str _modulePos, str "altitude", _altitude, str "radius", _radius, str "serviceDuration", _serviceDuration];
                        systemChat "[WMP] Gunship registration call copied to clipboard.";
                    };
                };
            }, {}, [_modulePos, _aircraft]
        ] call zen_dialog_fnc_create;
    };
    case "GUNSHIP_ASSIGN": {
        private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
        if (count _systems == 0) exitWith {systemChat "[WMP] No airborne gunships are registered."};
        private _players = (nearestObjects [_modulePos, ["CAManBase"], 30, true]) select {isPlayer _x};
        private _target = _players param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No player found within 30 metres."};
        private _ids = _systems apply {_x select 0};
        [
            "Assign Gunship Controller",
            [["COMBO", ["Gunship", format ["Assign %1 as controller.", name _target]], [_ids, _ids, 0]]],
            {params ["_values", "_target"]; [(_values select 0), "ASSIGN", [_target], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]},
            {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "GUNSHIP_ORBIT": {
        private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
        if (count _systems == 0) exitWith {systemChat "[WMP] No airborne gunships are registered."};
        private _ids = _systems apply {_x select 0};
        [
            "Set Gunship Orbit",
            [["COMBO", ["Gunship", "Move the selected system to this module position."], [_ids, _ids, 0]]],
            {params ["_values", "_modulePos"]; [(_values select 0), "SET_ORBIT", [_modulePos], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]},
            {}, _modulePos
        ] call zen_dialog_fnc_create;
    };
    case "GUNSHIP_CONTROL": {
        private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
        if (count _systems == 0) exitWith {systemChat "[WMP] No airborne gunships are registered."};
        private _ids = _systems apply {_x select 0};
        [
            "Airborne Gunship Control",
            [
                ["COMBO", ["Gunship", "Named registered system."], [_ids, _ids, 0]],
                ["COMBO", ["Operation", "Return uses the last assigned combat orbit."], [["RETURN", "SERVICE", "RELEASE_CONTROL", "REMOVE"], ["Return on station", "RTB and service", "Release operator", "Remove system"], 0]],
                ["CHECKBOX", ["Delete spawned aircraft", "Only applies when removing an aircraft created by this system."], false]
            ],
            {
                params ["_values"];
                _values params ["_id", "_operation", "_delete"];
                [_id, _operation, [_delete], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2];
            }
        ] call zen_dialog_fnc_create;
    };
    case "PERSISTENCE": {
        [
            "Persistence Control",
            [
                ["CHECKBOX", ["Enable", "Requires a compatible server runtime."], missionNamespace getVariable ["Waldo_Persistence_Enable", false]],
                ["SLIDER", ["Player save interval", "Seconds between player saves."], [10, 600, missionNamespace getVariable ["Waldo_Persistence_PlayerSaveInterval", 60], 0]],
                ["SLIDER", ["Object save interval", "Seconds between registered-object saves."], [10, 600, missionNamespace getVariable ["Waldo_Persistence_ObjectSaveInterval", 60], 0]],
                ["EDIT", ["Database prefix", "Letters, numbers, underscores and hyphens."], [missionNamespace getVariable ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"]]],
                ["CHECKBOX", ["Save loadout", "Persist player equipment."], missionNamespace getVariable ["Waldo_Persistence_SaveLoadout", true]],
                ["CHECKBOX", ["Save medical", "Persist supported ACE medical state."], missionNamespace getVariable ["Waldo_Persistence_SaveMedical", true]],
                ["CHECKBOX", ["Save food/water", "Persist supported field-ration state."], missionNamespace getVariable ["Waldo_Persistence_SaveFoodWater", false]],
                ["CHECKBOX", ["Save position", "Restore the player's previous position."], missionNamespace getVariable ["Waldo_Persistence_SavePosition", false]],
                ["CHECKBOX", ["Save radios", "Restore supported ACRE radio settings."], missionNamespace getVariable ["Waldo_Persistence_SaveRadios", false]]
            ],
            {
                params ["_values"];
                _values params ["_enable", "_playerInterval", "_objectInterval", "_database", "_loadout", "_medical", "_needs", "_position", "_radios"];
                ["PERSISTENCE_CONFIG", [_enable, _playerInterval, _objectInterval, _loadout, _medical, _needs, _position, _radios, _database]] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "PERSISTENCE_OBJECT": {
        private _target = (nearestObjects [_modulePos, [], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No object found within 25 metres."};
        private _safeNetId = [netId _target, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
        [
            "Register Persistent Object",
            [
                ["EDIT", ["Stable key", "Unique letters, numbers, underscores or hyphens."], [format ["object_%1", _safeNetId]]],
                ["CHECKBOX", ["Cargo", "Save inventory cargo."], true],
                ["CHECKBOX", ["Damage", "Save hit-point damage."], true],
                ["CHECKBOX", ["Fuel", "Save vehicle fuel."], true],
                ["CHECKBOX", ["Ammo and pylons", "Save vehicle ammunition."], true],
                ["CHECKBOX", ["Position", "Save position and orientation."], true]
            ],
            {
                params ["_values", "_target"];
                _values params ["_key", "_cargo", "_damage", "_fuel", "_ammo", "_position"];
                ["PERSISTENCE_OBJECT", [_target, _key, [_cargo, _damage, _fuel, _ammo, _position]]] call Waldo_fnc_FeatureRuntimeApply;
            },
            {},
            _target
        ] call zen_dialog_fnc_create;
    };
    case "PERSISTENCE_SAVE": {
        [
            "Persistence Save Now",
            [
                ["CHECKBOX", ["Save players", "Request an immediate local state capture from every connected player."], true],
                ["CHECKBOX", ["Save registered objects", "Immediately write every live registered object."], true]
            ],
            {
                params ["_values"];
                ["PERSISTENCE_SAVE", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "TREATMENT": {
        [
            "Patient Treatment Feedback",
            [
                ["CHECKBOX", ["Enable", "Use the pack notification UI for ACE treatment events."], missionNamespace getVariable ["Waldo_TreatmentFeedback_Enable", false]],
                ["CHECKBOX", ["Treatment started", "Notify when treatment begins."], missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowStart", true]],
                ["CHECKBOX", ["Treatment succeeded", "Notify when treatment completes successfully."], missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowSuccess", true]],
                ["CHECKBOX", ["Treatment failed", "Notify when treatment fails."], missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowFailure", true]],
                ["CHECKBOX", ["Notify patient", "Show feedback to the treated player."], missionNamespace getVariable ["Waldo_TreatmentFeedback_NotifyPatient", true]],
                ["CHECKBOX", ["Notify medic", "Also show feedback to the treating medic."], missionNamespace getVariable ["Waldo_TreatmentFeedback_NotifyMedic", false]],
                ["CHECKBOX", ["Show medic name", "Include the treating unit's name."], missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowMedicName", true]],
                ["CHECKBOX", ["Show body part", "Include the treated body region when available."], missionNamespace getVariable ["Waldo_TreatmentFeedback_ShowBodyPart", true]]
            ],
            {
                params ["_values"];
                ["TREATMENT_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "FIELD_RESUPPLY_HUB": {
        private _target = (nearestObjects [_modulePos, [], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No supply-hub object found within 25 metres."};
        [
            "Register Field Resupply Hub",
            [
                ["COMBO", ["Serviced side", "All permits every friendly side."], [[sideUnknown, west, east, independent], ["All", "BLUFOR", "OPFOR", "Independent"], 0]],
                ["EDIT", ["Refill stock", "-1 is unlimited; otherwise one stock is consumed per issued portable crate."], ["-1"]]
            ],
            {
                params ["_values", "_target"];
                _values params ["_side", "_stockText"];
                ["FIELD_RESUPPLY_HUB", [_target, _side, parseNumber _stockText]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "FIELD_RESUPPLY_CARRIER": {
        private _units = nearestObjects [_modulePos, ["CAManBase"], 25, true];
        private _target = _units param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No carrier unit found within 25 metres."};
        [
            "Assign Field Resupply Carrier",
            [
                ["SLIDER", ["Starting crates", "Portable crates immediately available."], [0, 10, 2, 0]],
                ["SLIDER", ["Maximum crates", "Carrier refill and salvage capacity."], [0, 10, 2, 0]]
            ],
            {
                params ["_values", "_target"];
                _values params ["_crates", "_maximum"];
                ["FIELD_RESUPPLY_CARRIER", [_target, round _crates, round _maximum]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "RECOVERY_WORKSHOP": {
        private _target = (nearestObjects [_modulePos, [], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No workshop object found within 25 metres."};
        [
            "Register Vehicle Recovery Workshop",
            [
                ["EDIT", ["Workshop key", "Recoverable vehicles with the same key are restored here."], ["MAIN"]],
                ["SLIDER", ["Delivery radius", "Grounded packages inside this radius are restored."], [5, 200, 50, 0]],
                ["COMBO", ["Serviced side", "All permits any side to use the workshop."], [[sideUnknown, west, east, independent], ["All", "BLUFOR", "OPFOR", "Independent"], 0]],
                ["SLIDER", ["Completion notice radius", "Only friendly players inside this distance are told that the restored vehicle is ready."], [0, 500, missionNamespace getVariable ["Waldo_Recovery_NotificationRadius", 100], 0]],
                ["CHECKBOX", ["Create map markers", "Create a global delivery-area marker and labelled exact-position marker."], missionNamespace getVariable ["Waldo_Recovery_CreateWorkshopMarkers", true]],
                ["CHECKBOX", ["Copy setup script", "Copy an equivalent mission setup call."], false]
            ],
            {
                params ["_values", "_target"];
                _values params ["_key", "_radius", "_side", "_notificationRadius", "_createMarkers", "_copy"];
                ["RECOVERY_WORKSHOP", [_target, _key, _radius, _side, _notificationRadius, _createMarkers]] call Waldo_fnc_FeatureRuntimeApply;
                if (_copy) then {
                    private _name = vehicleVarName _target;
                    if (_name == "") then {systemChat "[WMP] Give the workshop an Eden variable name before exporting."} else {
                        copyToClipboard format ["[%1, %2, %3, %4, %5, %6] call Waldo_fnc_RecoveryRegisterWorkshop;", _name, str _key, _radius, str _side, _notificationRadius, _createMarkers];
                        systemChat "[WMP] Recovery workshop setup copied.";
                    };
                };
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "RECOVERY_VEHICLE": {
        private _target = (nearestObjects [_modulePos, ["AllVehicles"], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No vehicle found within 25 metres."};
        [
            "Register Recoverable Vehicle",
            [
                ["EDIT", ["Workshop key", "Destination workshop key."], ["MAIN"]],
                ["SLIDER", ["Minimum damage", "Living vehicle damage required before packaging."], [0, 1, 0.55, 2]],
                ["CHECKBOX", ["Allow destroyed", "Permit destroyed vehicles to be packaged."], true],
                ["CHECKBOX", ["Require engineer", "Restrict packaging to engineer-trait units."], false],
                ["EDIT", ["Package class", "Cargo object used while transporting the vehicle."], ["B_Slingload_01_Cargo_F"]],
                ["CHECKBOX", ["Preserve inventory", "Restore weapon, magazine, item and backpack cargo."], true],
                ["SLIDER", ["Restored fuel", "Fuel fraction after workshop restoration."], [0, 1, 1, 2]]
            ],
            {
                params ["_values", "_target"];
                _values params ["_key", "_damage", "_destroyed", "_engineer", "_package", "_cargo", "_fuel"];
                ["RECOVERY_VEHICLE", [_target, _key, _damage, _destroyed, _engineer, _package, _cargo, _fuel]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "RECOVERY_CARRIER": {
        private _target = (nearestObjects [_modulePos, ["AllVehicles"], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No carrier vehicle found within 25 metres."};
        [
            "Register Recovery Carrier",
            [["SLIDER", ["Loading range", "Maximum package loading distance."], [3, 25, 10, 1]]],
            {params ["_values", "_target"]; ["RECOVERY_CARRIER", [_target, _values select 0]] call Waldo_fnc_FeatureRuntimeApply;}, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "RALLY": {
        [
            "Squad Rally Point Control",
            [
                ["CHECKBOX", ["Enable", "Install squad-leader rally controls for all players."], missionNamespace getVariable ["Waldo_Rally_Enable", false]],
                ["EDIT", ["Rally object class", "Object created at the rally position."], [missionNamespace getVariable ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"]]],
                ["SLIDER", ["Active duration", "Seconds before an active rally expires."], [15, 1800, missionNamespace getVariable ["Waldo_Rally_Duration", 180], 0]],
                ["SLIDER", ["Deployment time", "Seconds the leader must remain in place."], [1, 60, missionNamespace getVariable ["Waldo_Rally_DeploymentTime", 15], 0]],
                ["SLIDER", ["Deployment cooldown", "Group cooldown measured from deployment."], [0, 3600, missionNamespace getVariable ["Waldo_Rally_Cooldown", 300], 0]],
                ["SLIDER", ["Enemy exclusion", "Hostile-unit exclusion radius in metres."], [0, 500, missionNamespace getVariable ["Waldo_Rally_EnemyExclusionRadius", 100], 0]],
                ["SLIDER", ["Minimum group members", "Living members required to deploy."], [1, 12, missionNamespace getVariable ["Waldo_Rally_MinimumGroupMembers", 2], 0]],
                ["SLIDER", ["Placement distance", "Distance ahead of the leader."], [1, 10, missionNamespace getVariable ["Waldo_Rally_PlacementDistance", 2], 1]],
                ["SLIDER", ["Maximum slope", "Maximum permitted ground angle in degrees."], [0, 45, missionNamespace getVariable ["Waldo_Rally_MaximumSlope", 20], 0]],
                ["CHECKBOX", ["Allow direct regroup", "Allow living members to move directly to the rally. Disabled by default."], missionNamespace getVariable ["Waldo_Rally_AllowRegroup", false]]
            ],
            {params ["_values"]; ["RALLY_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;}
        ] call zen_dialog_fnc_create;
    };
    case "TACTICAL_DISPLAY": {
        private _target = (nearestObjects [_modulePos, [], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No tactical-display object found within 25 metres."};
        [
            "Register Tactical Display",
            [
                ["COMBO", ["Displayed side", "All uses the accessing player's side."], [[sideUnknown, west, east, independent], ["Accessing player", "BLUFOR", "OPFOR", "Independent"], 0]],
                ["SLIDER", ["Map radius", "Friendly and known-contact display radius."], [100, 20000, 2000, 0]],
                ["CHECKBOX", ["Known enemies", "Show contacts known to the accessing player's group."], true]
            ],
            {
                params ["_values", "_target"];
                _values params ["_side", "_radius", "_knownEnemies"];
                ["TACTICAL_DISPLAY", [_target, _side, _radius, _knownEnemies]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "TREE": {
        [
            "Tree Felling Control",
            [
                ["CHECKBOX", ["Enable", "Install the contextual action and melee hook."], missionNamespace getVariable ["Waldo_TreeFelling_Enable", false]],
                ["SLIDER", ["Interaction range", "Maximum range in metres."], [1, 8, missionNamespace getVariable ["Waldo_TreeFelling_Range", 3], 1]],
                ["SLIDER", ["Base hits", "Minimum swings before height scaling."], [1, 20, missionNamespace getVariable ["Waldo_TreeFelling_BaseHits", 3], 0]],
                ["SLIDER", ["Height factor", "Additional hits per metre of tree height."], [0, 2, missionNamespace getVariable ["Waldo_TreeFelling_HeightFactor", 0.25], 2]],
                ["SLIDER", ["Swing cooldown", "Minimum seconds between accepted hits."], [0.1, 3, missionNamespace getVariable ["Waldo_TreeFelling_HitCooldown", 0.7], 2]],
                ["CHECKBOX", ["Clear nearby bushes", "A valid swing also removes bushes in the configured radius."], missionNamespace getVariable ["Waldo_TreeFelling_ClearBushes", false]],
                ["SLIDER", ["Bush radius", "Bush-clearing radius in metres."], [0, 8, missionNamespace getVariable ["Waldo_TreeFelling_BushRadius", 4], 1]]
            ],
            {
                params ["_values"];
                ["TREE_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "EMERGENCY": {
        [
            "Emergency Dismount Control",
            [
                ["CHECKBOX", ["Enable", "Monitor occupants locally."], missionNamespace getVariable ["Waldo_EmergencyDismount_Enable", false]],
                ["CHECKBOX", ["On overturn", "Exit overturned vehicles."], missionNamespace getVariable ["Waldo_EmergencyDismount_OnOverturn", true]],
                ["CHECKBOX", ["On destruction", "Exit destroyed vehicles."], missionNamespace getVariable ["Waldo_EmergencyDismount_OnDestroyed", true]],
                ["CHECKBOX", ["Preserve velocity", "Carry vehicle momentum into the exit."], missionNamespace getVariable ["Waldo_EmergencyDismount_PreserveVelocity", true]],
                ["CHECKBOX", ["Protect during exit", "Temporarily disable damage while clearing the wreck."], missionNamespace getVariable ["Waldo_EmergencyDismount_ProtectDuringExit", true]],
                ["SLIDER", ["Protection duration", "Maximum protected seconds."], [0.5, 10, missionNamespace getVariable ["Waldo_EmergencyDismount_ProtectionSeconds", 2], 1]],
                ["SLIDER", ["Clear-position radius", "Nearby safe-position search radius."], [0, 15, missionNamespace getVariable ["Waldo_EmergencyDismount_ClearPositionRadius", 6], 1]],
                ["CHECKBOX", ["Require clear exit", "Only trigger overturn extraction when view geometry above the player is clear."], missionNamespace getVariable ["Waldo_EmergencyDismount_RequireClearExit", false]],
                ["CHECKBOX", ["Use eject", "Use the eject action instead of a normal move-out."], missionNamespace getVariable ["Waldo_EmergencyDismount_UseEject", false]],
                ["CHECKBOX", ["Recover unconscious", "Wake the player after a destroyed-vehicle extraction."], missionNamespace getVariable ["Waldo_EmergencyDismount_RecoverUnconscious", false]]
            ],
            {
                params ["_values"];
                ["EMERGENCY_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "ACCESSIBILITY": {
        [
            "Friendly Identification Aid",
            [
                ["CHECKBOX", ["Enable", "Enable for eligible players."], missionNamespace getVariable ["Waldo_AccessibilityPID_Enable", false]],
                ["SLIDER", ["Icon range", "Maximum friendly icon range."], [10, 1000, missionNamespace getVariable ["Waldo_AccessibilityPID_IconRange", 300], 0]],
                ["SLIDER", ["Name range", "Maximum friendly name range."], [0, 300, missionNamespace getVariable ["Waldo_AccessibilityPID_NameRange", 50], 0]],
                ["CHECKBOX", ["Require line of sight", "Hide identification through obstructing geometry."], missionNamespace getVariable ["Waldo_AccessibilityPID_RequireLOS", true]],
                ["CHECKBOX", ["Include AI", "Include friendly AI as well as players."], missionNamespace getVariable ["Waldo_AccessibilityPID_IncludeAI", false]],
                ["CHECKBOX", ["Player toggle", "Give players a local show/hide action."], missionNamespace getVariable ["Waldo_AccessibilityPID_AllowToggle", true]],
                ["CHECKBOX", ["Visible by default", "Initial local visibility state."], missionNamespace getVariable ["Waldo_AccessibilityPID_DefaultVisible", true]]
            ],
            {
                params ["_values"];
                ["ACCESS_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "AI": {
        [
            "AI Rebalance Control",
            [
                ["CHECKBOX", ["Enable", "Apply the selected profile to local AI on every machine."], missionNamespace getVariable ["Waldo_AIRebalance_Enable", true]],
                ["COMBO", ["Mode", "Night mode adds illumination and night-vision sensing rules."], [["DAY", "NIGHT"], ["Day", "Night"], (["DAY", "NIGHT"] find (missionNamespace getVariable ["Waldo_AI_Mode", "DAY"])) max 0]],
                ["COMBO", ["Profile", "LEGACY preserves established balance."], [["LEGACY", "PUBLIC", "STANDARD", "VETERAN"], ["Legacy", "Public", "Standard", "Veteran"], (["LEGACY", "PUBLIC", "STANDARD", "VETERAN"] find (missionNamespace getVariable ["Waldo_AI_Profile", "LEGACY"])) max 0]]
            ],
            {
                params ["_values"];
                ["AI_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "HAZARD_CREATE": {
        [
            "Create Hazardous Environment",
            [
                ["EDIT", ["Zone ID", "Unique letters, numbers, underscores or hyphens."], [format ["hazard_%1_%2", clientOwner, round (serverTime * 10)]]],
                ["EDIT", ["Hazard type", "Semantic type used by callbacks and exports."], ["TOXIC"]],
                ["EDIT", ["Display label", "Player-facing status label."], ["Hazardous Area"]],
                ["SLIDER", ["Radius", "Circular zone radius in metres."], [5, 5000, 100, 0]],
                ["SLIDER", ["Exposure rate", "Exposure gained per second at full intensity."], [0, 100, 1, 2]],
                ["SLIDER", ["Recovery rate", "Exposure removed per second outside the zone."], [0, 100, 0.1, 2]],
                ["SLIDER", ["Damage threshold", "Exposure before damage begins."], [0, 1000, 30, 1]],
                ["SLIDER", ["Damage per tick", "Damage applied after the threshold."], [0, 1, 0.01, 3]],
                ["CHECKBOX", ["Vehicles protect", "Being inside a vehicle provides configured protection."], false],
                ["CHECKBOX", ["Interiors protect", "Being inside a building provides configured protection."], false],
                ["EDIT", ["Protective equipment", "Comma-separated classnames accepted in any worn slot."], [""]],
                ["SLIDER", ["Protected exposure factor", "0 is complete protection; 1 is none."], [0, 1, 0.05, 2]],
                ["CHECKBOX", ["Copy setup script", "Copy an equivalent mission-maker call to the clipboard."], false]
            ],
            {
                params ["_values", "_modulePos"];
                _values params ["_key", "_type", "_label", "_radius", "_rate", "_decay", "_threshold", "_damage", "_vehicles", "_indoors", "_equipmentText", "_factor", "_copy"];
                private _equipment = (_equipmentText splitString ",") apply {[_x] call BIS_fnc_trimString};
                _equipment = _equipment select {_x != ""};
                private _profile = createHashMapFromArray [
                    ["type", toUpperANSI _type], ["label", _label], ["rate", _rate], ["decay", _decay],
                    ["damageThresholds", [[_threshold, _damage]]], ["protectInVehicles", _vehicles], ["vehicleFactor", _factor],
                    ["protectIndoors", _indoors], ["indoorFactor", _factor], ["protectiveItemsAnySlot", _equipment], ["equipmentFactor", _factor]
                ];
                ["HAZARD_SET", [_key, [_modulePos, _radius], _profile]] call Waldo_fnc_FeatureRuntimeApply;
                if (_copy) then {
                    copyToClipboard format ["[%1, [%2, %3], createHashMapFromArray [[%4,%5],[%6,%7],[%8,%9],[%10,%11],[%12,[[%13,%14]]]]]] call Waldo_fnc_HazardRegisterZone;", str _key, str _modulePos, _radius, str "type", str (toUpperANSI _type), str "label", str _label, str "rate", _rate, str "decay", _decay, str "damageThresholds", _threshold, _damage];
                    systemChat "[WMP] Hazard setup call copied to clipboard.";
                };
            },
            {},
            _modulePos
        ] call zen_dialog_fnc_create;
    };
    case "HAZARD_REMOVE": {
        private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
        if (count _zones == 0) exitWith {systemChat "[WMP] No hazardous-environment zones are registered."};
        private _nearest = _zones select 0;
        private _getCentre = {
            params ["_area"];
            if (_area isEqualType []) exitWith {_area select 0};
            if (_area isEqualType "") exitWith {getMarkerPos _area};
            getPosWorld _area
        };
        {
            if (((_x select 1) call _getCentre) distance2D _modulePos < (((_nearest select 1) call _getCentre) distance2D _modulePos)) then {_nearest = _x};
        } forEach _zones;
        private _key = _nearest select 0;
        [
            "Remove Hazardous Environment",
            [["CHECKBOX", [format ["Remove %1", _key], "Remove the nearest registered zone."], true]],
            {params ["_values", "_key"]; if (_values select 0) then {["HAZARD_REMOVE", [_key]] call Waldo_fnc_FeatureRuntimeApply}},
            {},
            _key
        ] call zen_dialog_fnc_create;
    };
    case "BREACH": {
        private _target = (nearestObjects [_modulePos, [], 25, true]) param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No breachable object found within 25 metres."};
        private _className = typeOf _target;
        [
            "Configure Breachable Class",
            [
                ["EDIT", ["Object class", "All objects of this class use the profile."], [_className]],
                ["SLIDER", ["Detection radius", "Maximum charge distance from the object."], [0.5, 25, 6, 1]],
                ["EDIT", ["Allowed explosives", "Comma-separated CfgAmmo classes; empty permits any explosive."], ["DemoCharge_Remote_Ammo"]],
                ["CHECKBOX", ["Destroy original", "Apply full damage to the original object."], true],
                ["CHECKBOX", ["Hide original", "Hide the original globally after breaching."], false],
                ["CHECKBOX", ["Delete original", "Delete the original after callbacks and replacements."], false],
                ["CHECKBOX", ["Remove profile", "Remove this class instead of adding/updating it."], false],
                ["CHECKBOX", ["Copy setup script", "Copy an equivalent profile call to the clipboard."], false]
            ],
            {
                params ["_values"];
                _values params ["_className", "_radius", "_explosiveText", "_destroy", "_hide", "_delete", "_remove", "_copy"];
                private _explosives = (_explosiveText splitString ",") apply {[_x] call BIS_fnc_trimString};
                _explosives = _explosives select {_x != ""};
                private _profile = createHashMapFromArray [["radius", _radius], ["explosives", _explosives], ["destroyOriginal", _destroy], ["hideOriginal", _hide], ["deleteOriginal", _delete], ["replacements", []]];
                if (_remove) then {
                    ["BREACH_REMOVE", [_className]] call Waldo_fnc_FeatureRuntimeApply;
                } else {
                    ["BREACH_SET", [_className, _profile]] call Waldo_fnc_FeatureRuntimeApply;
                };
                if (_copy) then {
                    copyToClipboard format ["Waldo_Breaching_Profiles set [%1, createHashMapFromArray [[%2,%3],[%4,%5],[%6,%7],[%8,%9],[%10,%11],[%12,[]]]];", str _className, str "radius", _radius, str "explosives", str _explosives, str "destroyOriginal", _destroy, str "hideOriginal", _hide, str "deleteOriginal", _delete, str "replacements"];
                    systemChat "[WMP] Breaching profile copied to clipboard.";
                };
            }
        ] call zen_dialog_fnc_create;
    };
};
