/*
 * Author: WaldoTheWarfighter
 * Provides ZEN configuration and operation dialogs for optional WMP feature systems.
 *
 * This interface-only dispatcher is called by the registrations in Zen_initModules.sqf. Dialogs
 * collect friendly values while authoritative functions validate and apply world/state changes on
 * the server. It does not own persistent state and is safe to open repeatedly.
 * Locality and authority: ZEN invokes this on the curator interface client. Dialog submissions call
 * feature APIs that validate and route authoritative mutations to the server.
 *
 * Arguments:
 * 0: feature <STRING> - registered runtime operation identifier
 * 1: module position <ARRAY> - curator-selected world position
 * 2: object under the module <OBJECT> (default objNull) - optional preselected target
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["HAZARD_CREATE", _modulePos, objNull] call Waldo_fnc_FeatureRuntimeZen;
 *
 * Result:
 * Opens the matching friendly runtime dialog at the curator's selected position.
 *
 * Current callers:
 * ZEN registrations in MissionScripts\ZenModules\Zen_initModules.sqf.
 */

params [
    ["_feature", "", [""]],
    ["_modulePos", [], [[]]],
    ["_objectPos", objNull, [objNull]]
];
if !(hasInterface) exitWith {};
private _resolveTarget = {
    params ["_selected", "_position", ["_kinds", [], [[]]], ["_failureText", "Select a valid object.", [""]]];
    private _target = _selected;
    if (isNull _target) then {
        private _nearby = nearestObjects [_position, _kinds, 20, true];
        _target = _nearby param [0, objNull];
    };
    if (isNull _target) then {
        ["WMP ZEN", _failureText, "ERROR", "ZEN_TARGET"] call Waldo_fnc_FeatureNotifyLocal;
    };
    _target
};

switch (toUpperANSI _feature) do {
    case "GUNSHIP_REGISTER": {
        private _nearbyAircraft = nearestObjects [_modulePos, ["Air"], 40, true];
        private _aircraft = _nearbyAircraft param [0, objNull];
        private _resolveAssets = {
            params ["_nearbyAircraft"];
                private _assetValues = [];
                private _assetLabels = [];
                if (!isNull _nearbyAircraft && {_nearbyAircraft isKindOf "Air"} && {count (fullCrew [_nearbyAircraft, "gunner", true]) > 0}) then {
                    private _existingName = getText (configFile >> "CfgVehicles" >> typeOf _nearbyAircraft >> "displayName");
                    _assetValues pushBack ["EXISTING", _nearbyAircraft];
                    _assetLabels pushBack format ["Use nearby %1", _existingName];
                };
                private _sidePools = missionNamespace getVariable ["Waldo_Gunship_SideAircraftPools", createHashMap];
                private _classes = [];
                {{_classes pushBackUnique _x} forEach (_sidePools get _x)} forEach keys _sidePools;
                private _factionPools = missionNamespace getVariable ["Waldo_Gunship_FactionAircraftPools", createHashMap];
                {{_classes pushBackUnique _x} forEach (_factionPools get _x)} forEach keys _factionPools;
                _classes = _classes select {
                    isClass (configFile >> "CfgVehicles" >> _x)
                    && {_x isKindOf "Air"}
                    && {getNumber (configFile >> "CfgVehicles" >> _x >> "scope") >= 2}
                    && {count (configProperties [configFile >> "CfgVehicles" >> _x >> "Turrets", "isClass _x", true]) > 0}
                };
                {
                    private _displayName = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
                    _assetValues pushBack ["CLASS", _x];
                    _assetLabels pushBack format ["Spawn %1", if (_displayName == "") then {_x} else {_displayName}];
                } forEach (_classes call BIS_fnc_sortAlphabetically);
            [_assetValues, _assetLabels]
        };

        private _sideValues = [west, east, independent];
        private _sideLabels = ["BLUFOR", "OPFOR", "Independent"];
        private _initialAssets = [_aircraft] call _resolveAssets;
        if (count (_initialAssets select 0) == 0) exitWith {systemChat "[WMP] No compatible turret-equipped gunships are configured and no suitable aircraft is nearby."};
        private _id = ["gunship"] call Waldo_fnc_CreateRuntimeId;
        private _created = [
                    "Register or Spawn Airborne Gunship",
                    [
                        ["EDIT", ["Callsign", "Player-facing name used by controls, markers and notifications."], ["SPECTRE"]],
                        ["COMBO", ["Operational side", "Sets crew allegiance, access, ownership and targeting. It does not restrict the physical airframe."], [_sideValues, _sideLabels, 0]],
                        ["COMBO", ["Airframe", "Choose any configured compatible gunship. Airframe faction is independent from operational side."], [_initialAssets select 0, _initialAssets select 1, 0]],
                        ["SLIDER", ["Orbit altitude", "AI flight height in metres."], [100, 5000, missionNamespace getVariable ["Waldo_Gunship_DefaultAltitude", 700], 0]],
                        ["SLIDER", ["Orbit radius", "Distance from the selected orbit centre in metres."], [200, 10000, missionNamespace getVariable ["Waldo_Gunship_DefaultRadius", 1500], 0]],
                        ["SLIDER", ["Service duration", "Seconds spent servicing before returning to the last orbit."], [0, 3600, missionNamespace getVariable ["Waldo_Gunship_DefaultServiceDuration", 900], 0]],
                        ["CHECKBOX", ["Show friendly markers", "Show the aircraft and orbit to friendly clients."], true],
                        ["CHECKBOX", ["Copy setup script", "Copy an equivalent registration call for permanent mission setup."], false]
                    ],
                    {
                        params ["_values", "_arguments"];
                        _arguments params ["_modulePos", "_id"];
                        _values params ["_callsign", "_side", "_asset", "_altitude", "_radius", "_serviceDuration", "_markers", "_copy"];
                        _asset params ["_assetMode", "_assetValue"];
                        private _config = createHashMapFromArray [
                            ["id", _id], ["callsign", _callsign], ["side", _side], ["altitude", _altitude], ["radius", _radius],
                            ["serviceDuration", _serviceDuration], ["showMarkers", _markers], ["home", _modulePos], ["orbit", _modulePos]
                        ];
                        if (_assetMode == "EXISTING") then {
                            _config set ["aircraft", _assetValue];
                        } else {
                            _config set ["aircraftClass", _assetValue];
                            _config set ["spawnPosition", [_modulePos select 0, _modulePos select 1, _altitude]];
                        };
                        [_config] call Waldo_fnc_GunshipRegister;
                        if (_copy) then {
                            private _assetEntry = "";
                            if (_assetMode == "CLASS") then {
                                _assetEntry = format ["[%1,%2],[%3,%4]", str "aircraftClass", str _assetValue, str "spawnPosition", str [_modulePos select 0, _modulePos select 1, _altitude]];
                            } else {
                                private _variableName = vehicleVarName _assetValue;
                                if (_variableName != "") then {_assetEntry = format ["[%1,%2]", str "aircraft", _variableName]};
                            };
                            if (_assetEntry == "") then {
                                systemChat "[WMP] Give the existing aircraft an Eden variable name before exporting its setup.";
                            } else {
                                copyToClipboard format ["private _gunshipConfig = createHashMapFromArray [[%1,%2],[%3,%4],[%5,%6],%7,[%8,%9],[%10,%11],[%12,%13],[%14,%15],[%16,%17]]; [_gunshipConfig] call Waldo_fnc_GunshipRegister;", str "id", str _id, str "callsign", str _callsign, str "side", str _side, _assetEntry, str "home", str _modulePos, str "orbit", str _modulePos, str "altitude", _altitude, str "radius", _radius, str "serviceDuration", _serviceDuration];
                                systemChat "[WMP] Gunship registration call copied to clipboard.";
                            };
                        };
                    }, {}, [_modulePos, _id]
        ] call zen_dialog_fnc_create;

        _created;
    };
    case "GUNSHIP_ASSIGN": {
        private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
        if (count _systems == 0) exitWith {systemChat "[WMP] No airborne gunships are registered."};
        private _players = (nearestObjects [_modulePos, ["CAManBase"], 30, true]) select {isPlayer _x};
        private _target = _players param [0, objNull];
        if (isNull _target) exitWith {systemChat "[WMP] No player found within 30 metres."};
        private _ids = _systems apply {_x select 0};
        private _labels = _systems apply {format ["%1 - %2", _x param [7, _x select 0], toLowerANSI (_x param [3, "unavailable"])]};
        [
            "Assign Gunship Controller",
            [["COMBO", ["Gunship", format ["Assign %1 as controller.", name _target]], [_ids, _labels, 0]]],
            {params ["_values", "_target"]; [(_values select 0), "ASSIGN", [_target], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]},
            {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "GUNSHIP_ORBIT": {
        private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
        if (count _systems == 0) exitWith {systemChat "[WMP] No airborne gunships are registered."};
        private _ids = _systems apply {_x select 0};
        private _labels = _systems apply {format ["%1 - %2", _x param [7, _x select 0], toLowerANSI (_x param [3, "unavailable"])]};
        [
            "Set Gunship Orbit",
            [["COMBO", ["Gunship", "Move the selected system to this module position."], [_ids, _labels, 0]]],
            {params ["_values", "_modulePos"]; [(_values select 0), "SET_ORBIT", [_modulePos], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2]},
            {}, _modulePos
        ] call zen_dialog_fnc_create;
    };
    case "GUNSHIP_CONTROL": {
        private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
        if (count _systems == 0) exitWith {systemChat "[WMP] No airborne gunships are registered."};
        private _ids = _systems apply {_x select 0};
        private _labels = _systems apply {format ["%1 - %2", _x param [7, _x select 0], toLowerANSI (_x param [3, "unavailable"])]};
        [
            "Airborne Gunship Control",
            [
                ["COMBO", ["Gunship", "Callsign and current operational state."], [_ids, _labels, 0]],
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
                ["EDIT", ["Campaign save name", "Keeps this mission or campaign separate from other persistence saves."], [missionNamespace getVariable ["Waldo_Persistence_DatabaseName", "WaldosMissionPack"]]],
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
                ["CHECKBOX", ["Cargo", "Save inventory cargo."], true],
                ["CHECKBOX", ["Damage", "Save hit-point damage."], true],
                ["CHECKBOX", ["Fuel", "Save vehicle fuel."], true],
                ["CHECKBOX", ["Ammo and pylons", "Save vehicle ammunition."], true],
                ["CHECKBOX", ["Position", "Save position and orientation."], true]
            ],
            {
                params ["_values", "_arguments"];
                _arguments params ["_target", "_key"];
                _values params ["_cargo", "_damage", "_fuel", "_ammo", "_position"];
                ["PERSISTENCE_OBJECT", [_target, _key, [_cargo, _damage, _fuel, _ammo, _position]]] call Waldo_fnc_FeatureRuntimeApply;
            },
            {},
            [_target, format ["object_%1", _safeNetId]]
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
        private _target = _objectPos;
        if (isNull _target) then {_target = (nearestObjects [_modulePos, [], 5, true]) param [0, objNull]};
        [
            "Register Field Resupply Hub",
            [
                ["COMBO", ["Serviced side", "All permits every friendly side."], [[sideUnknown, west, east, independent], ["All", "BLUFOR", "OPFOR", "Independent"], 0]],
                ["SLIDER", ["Available refills", "0 means unlimited. Any other value is the number of portable crates the hub may issue."], [0, 100, 0, 0]]
            ],
            {
                params ["_values", "_arguments"];
                _arguments params ["_target", "_modulePos"];
                _values params ["_side", "_stockChoice"];
                private _stock = if (round _stockChoice == 0) then {-1} else {round _stockChoice};
                ["FIELD_RESUPPLY_HUB", [_target, _side, _stock, _modulePos]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, [_target, _modulePos]
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
    case "FIELD_RESUPPLY_GRANT": {
        private _units = nearestObjects [_modulePos, ["CAManBase"], 25, true];
        private _target = if (!isNull _objectPos && {_objectPos isKindOf "CAManBase"}) then {_objectPos} else {_units param [0, objNull]};
        if (isNull _target) exitWith {systemChat "[WMP] Place this module on an infantry carrier or within 25 metres of one."};
        if (_target getVariable ["Waldo_FieldResupply_MaxCrates", 0] <= 0) exitWith {
            systemChat "[WMP] That unit is not an assigned Field Resupply carrier.";
        };
        [
            "Grant Field Resupply Crates",
            [
                ["SLIDER", ["Crates to grant", "Added to this carrier, subject to their maximum capacity."], [1, 10, 1, 0]],
                ["CHECKBOX", ["Increase capacity if needed", "Raise this carrier's maximum so the complete grant fits."], false]
            ],
            {
                params ["_values", "_target"];
                _values params ["_amount", "_expandCapacity"];
                ["FIELD_RESUPPLY_GRANT", [_target, round _amount, _expandCapacity]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "RECOVERY_WORKSHOP": {
        // Prefer the object ZEN resolved underneath the module. An unfiltered nearestObjects query
        // can otherwise select a player, curator helper or vehicle standing beside the intended
        // workshop on a dedicated server.
        private _target = if (!isNull _objectPos && {!(_objectPos isKindOf "CAManBase")} && {!(_objectPos isKindOf "Logic")}) then {
            _objectPos
        } else {
            ((nearestObjects [_modulePos, [], 25, true]) select {
                !isNull _x && {!(_x isKindOf "CAManBase")} && {!(_x isKindOf "Logic")}
            }) param [0, objNull]
        };
        if (isNull _target) exitWith {systemChat "[WMP] No workshop object found within 25 metres."};
        [
            "Register Vehicle Recovery Workshop",
            [
                ["EDIT", ["Workshop name", "Short name used when assigning recoverable vehicles to this destination."], ["MAIN"]],
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
        private _nearVehicles = (nearestObjects [_modulePos, ["AllVehicles"], 25, true]) select {!(_x isKindOf "CAManBase")};
        private _target = if (!isNull _objectPos && {_objectPos isKindOf "AllVehicles"} && {!(_objectPos isKindOf "CAManBase")}) then {_objectPos} else {_nearVehicles param [0, objNull]};
        if (isNull _target) exitWith {systemChat "[WMP] No vehicle found within 25 metres."};
        private _workshops = (allMissionObjects "All") select {_x getVariable ["Waldo_Recovery_Workshop", false]};
        if (count _workshops == 0) exitWith {systemChat "[WMP] Create a vehicle recovery workshop before assigning recoverable vehicles."};
        private _workshopKeys = _workshops apply {_x getVariable ["Waldo_Recovery_WorkshopKey", "MAIN"]};
        private _workshopLabels = _workshops apply {
            format ["%1 (%2 m away)", _x getVariable ["Waldo_Recovery_WorkshopKey", "MAIN"], round (_x distance2D _target)]
        };
        private _packageClasses = +(missionNamespace getVariable ["Waldo_Recovery_PackageClasses", ["B_Slingload_01_Cargo_F", "Land_Pallet_MilBoxes_F"]]);
        _packageClasses = _packageClasses select {
            _x isEqualType ""
            && {isClass (configFile >> "CfgVehicles" >> _x)}
            && {!(_x isKindOf "CAManBase")}
        };
        if (_packageClasses isEqualTo []) then {_packageClasses = ["B_Slingload_01_Cargo_F"]};
        private _packageLabels = _packageClasses apply {
            private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
            if (_name == "") then {_x} else {_name}
        };
        private _preparationOptions = ["repair"] call Waldo_fnc_MiniGameInteractionOptions;
        [
            "Register Recoverable Vehicle",
            [
                ["COMBO", ["Destination workshop", "Choose from workshops already created in this mission."], [_workshopKeys, _workshopLabels, 0]],
                ["SLIDER", ["Minimum damage", "Living vehicle damage required before packaging."], [0, 1, 0.55, 2]],
                ["CHECKBOX", ["Allow destroyed", "Permit destroyed vehicles to be packaged."], true],
                ["CHECKBOX", ["Require engineer", "Restrict packaging to engineer-trait units."], false],
                ["COMBO", ["Recovery package", "Visible package class for this vehicle. Mission makers can extend Waldo_Recovery_PackageClasses."], [_packageClasses, _packageLabels, 0]],
                ["CHECKBOX", ["Preserve inventory", "Restore weapon, magazine, item and backpack cargo."], true],
                ["SLIDER", ["Restored fuel", "Fuel fraction after workshop restoration."], [0, 1, 1, 2]],
                ["CHECKBOX", ["Require Recovery Preparation", "Replace immediate packaging with a shared preparation procedure."], false],
                ["COMBO", ["Preparation Procedure", "Repair is the semantic default; every shared interaction procedure is available."], _preparationOptions],
                ["COMBO", ["Procedure Difficulty", "Shared interaction difficulty profile."], [["easy", "standard", "hard", "expert"], ["Easy", "Standard", "Hard", "Expert"], 1]]
            ],
            {
                params ["_values", "_target"];
                _values params ["_key", "_damage", "_destroyed", "_engineer", "_package", "_cargo", "_fuel", "_interactionEnabled", "_challengeId", "_difficulty"];
                private _interaction = createHashMapFromArray [["enabled", _interactionEnabled], ["challengeId", _challengeId], ["difficulty", _difficulty]];
                ["RECOVERY_VEHICLE", [_target, _key, _damage, _destroyed, _engineer, _package, _cargo, _fuel, _interaction]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "RECOVERY_CARRIER": {
        private _nearVehicles = (nearestObjects [_modulePos, ["AllVehicles"], 25, true]) select {!(_x isKindOf "CAManBase")};
        private _target = if (!isNull _objectPos && {_objectPos isKindOf "AllVehicles"} && {!(_objectPos isKindOf "CAManBase")}) then {_objectPos} else {_nearVehicles param [0, objNull]};
        if (isNull _target) exitWith {systemChat "[WMP] No carrier vehicle found within 25 metres."};
        [
            "Register Recovery Carrier",
            [
                ["SLIDER", ["Loading range", "Maximum package loading distance."], [3, 25, 10, 1]],
                ["COMBO", ["Cargo handling", "Automatic uses a real cargo bay when the package fits, otherwise virtualizes it. Virtual works with any vehicle. Physical requires an engine-configured vehicle cargo bay."], [["AUTO", "VIRTUAL", "PHYSICAL"], ["Automatic", "Virtual manifest", "Physical cargo bay"], 0]],
                ["SLIDER", ["Package capacity", "Combined number of physical and virtual recovery packages carried at once."], [1, 10, 1, 0]]
            ],
            {
                params ["_values", "_target"];
                _values params ["_range", "_mode", "_capacity"];
                ["RECOVERY_CARRIER", [_target, _range, _mode, round _capacity]] call Waldo_fnc_FeatureRuntimeApply;
            }, {}, _target
        ] call zen_dialog_fnc_create;
    };
    case "TRANSPORT_REGISTER": {
        private _target = [_objectPos, _modulePos, ["LandVehicle", "Helicopter"], "Select an AI-crewed helicopter or ground vehicle."] call _resolveTarget;
        if (isNull _target) exitWith {};
        private _isHelicopter = _target isKindOf "Helicopter";
        [
            "Register Transport Service",
            [
                ["COMBO", ["Service type", "Helicopter and ground transports use independent pools."], [["HELICOPTER", "GROUND"], ["Helicopter transport", "Ground transport"], if (_isHelicopter) then {0} else {1}]],
                ["EDIT", ["Service ID", "Unique setup key. Leave blank to generate one."], ""],
                ["EDIT", ["Display name", "Player-facing callsign. Leave blank to use the crew group callsign."], ""],
                ["CHECKBOX", ["Squad leaders only", "Only group leaders may request this service."], false],
                ["CHECKBOX", ["Show map marker", "Track the service vehicle on the map."], true],
                ["SLIDER", ["Boarding window", "Seconds at pickup before an unused service returns to base."], [30, 900, missionNamespace getVariable ["Waldo_Transport_DefaultBoardingSeconds", 300], 0]],
                ["SLIDER", ["Destination dwell", "Seconds allowed for disembarking before return to base."], [10, 300, missionNamespace getVariable ["Waldo_Transport_DefaultDestinationDwell", 45], 0]],
                ["SLIDER", ["Helicopter transit height", "Metres above terrain; ignored by ground transports."], [20, 300, missionNamespace getVariable ["Waldo_HeliTransport_DefaultAltitude", 80], 0]],
                ["CHECKBOX", ["Repair at base", "Fully repair the service after a completed return."], false],
                ["CHECKBOX", ["Refuel at base", "Fully refuel the service after a completed return."], true],
                ["CHECKBOX", ["Force late passengers out", "Move remaining passengers out when destination dwell expires."], false],
                ["CHECKBOX", ["Emergency position reset", "OFF by default. If physical RTB fails and no players are aboard, teleport the transport to base."], false]
            ],
            {
                params ["_values", "_target"];
                ["TRANSPORT_REGISTER", [_target] + _values] call Waldo_fnc_FeatureRuntimeApply;
            },
            {},
            _target
        ] call zen_dialog_fnc_create;
    };
    case "TRANSPORT_RTB": {
        private _target = [_objectPos, _modulePos, ["LandVehicle", "Helicopter"], "Select a registered transport-service vehicle."] call _resolveTarget;
        if (isNull _target) exitWith {};
        [
            "Return Transport to Base",
            [["CHECKBOX", ["Confirm", "Cancel the current task and physically return this service to its registered base."], false]],
            {
                params ["_values", "_target"];
                if (_values select 0) then {["TRANSPORT_RTB", [_target]] call Waldo_fnc_FeatureRuntimeApply};
            },
            {},
            _target
        ] call zen_dialog_fnc_create;
    };
    case "RALLY": {
        private _rallyClasses = ["Land_SatelliteAntenna_01_F", "Land_Radio_F", "Land_TentA_F", "Land_Sleeping_bag_blue_folded_F"];
        private _configuredRallyClass = missionNamespace getVariable ["Waldo_Rally_ObjectClass", "Land_SatelliteAntenna_01_F"];
        _rallyClasses pushBackUnique _configuredRallyClass;
        _rallyClasses = _rallyClasses select {isClass (configFile >> "CfgVehicles" >> _x)};
        private _rallyLabels = _rallyClasses apply {
            private _name = getText (configFile >> "CfgVehicles" >> _x >> "displayName");
            if (_name == "") then {_x} else {_name}
        };
        [
            "Squad Rally Point Control",
            [
                ["CHECKBOX", ["Enable", "Install squad-leader rally controls for all players."], missionNamespace getVariable ["Waldo_Rally_Enable", false]],
                ["COMBO", ["Rally object", "Choose the visible object created at a deployed squad rally."], [_rallyClasses, _rallyLabels, (_rallyClasses find _configuredRallyClass) max 0]],
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
        private _authenticationOptions = ["commandinput"] call Waldo_fnc_MiniGameInteractionOptions;
        [
            "Register Tactical Display",
            [
                ["COMBO", ["Displayed side", "All uses the accessing player's side."], [[sideUnknown, west, east, independent], ["Accessing player", "BLUFOR", "OPFOR", "Independent"], 0]],
                ["SLIDER", ["Map radius", "Friendly and known-contact display radius."], [100, 20000, 2000, 0]],
                ["CHECKBOX", ["Known enemies", "Show contacts known to the accessing player's group."], true],
                ["CHECKBOX", ["Require Display Authentication", "Keep the display locked until a player completes the selected procedure."], false],
                ["COMBO", ["Authentication Procedure", "Command authentication is the semantic default; every shared interaction procedure is available."], _authenticationOptions],
                ["COMBO", ["Procedure Difficulty", "Shared interaction difficulty profile."], [["easy", "standard", "hard", "expert"], ["Easy", "Standard", "Hard", "Expert"], 1]]
            ],
            {
                params ["_values", "_target"];
                _values params ["_side", "_radius", "_knownEnemies", "_interactionEnabled", "_challengeId", "_difficulty"];
                private _interaction = createHashMapFromArray [["enabled", _interactionEnabled], ["challengeId", _challengeId], ["difficulty", _difficulty]];
                ["TACTICAL_DISPLAY", [_target, _side, _radius, _knownEnemies, _interaction]] call Waldo_fnc_FeatureRuntimeApply;
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
    case "AI": {
        private _profileValues = ["LEGACY", "MILITIA", "LINE", "VETERAN", "ELITE"];
        private _configuredProfiles = missionNamespace getVariable ["Waldo_AI_Profiles", createHashMap];
        {
            if !(_x in ["PUBLIC", "STANDARD"]) then {_profileValues pushBackUnique _x};
        } forEach ((keys _configuredProfiles) call BIS_fnc_sortAlphabetically);
        private _profileNames = missionNamespace getVariable ["Waldo_AI_ProfileDisplayNames", createHashMap];
        private _profileLabels = _profileValues apply {_profileNames getOrDefault [_x, _x]};
        private _activeProfile = missionNamespace getVariable ["Waldo_AI_Profile", "LINE"];
        if (_activeProfile == "PUBLIC") then {_activeProfile = "MILITIA"};
        if (_activeProfile == "STANDARD") then {_activeProfile = "LINE"};
        [
            "AI Rebalance Control",
            [
                ["CHECKBOX", ["Enable", "Apply the selected profile to local AI on every machine."], missionNamespace getVariable ["Waldo_AIRebalance_Enable", true]],
                ["COMBO", ["Lighting conditions", "Low light reduces AI combat and sensing skills; assigned NVG/HMD equipment offsets the penalty."], [["DAY", "NIGHT"], ["Daylight", "Low light (NVG-aware)"], (["DAY", "NIGHT"] find (missionNamespace getVariable ["Waldo_AIRebalance_Mode", "DAY"])) max 0]],
                ["COMBO", ["WMP opposition profile", "These are WMP encounter presets, not Arma difficulty levels. Mission-defined profiles are included by display name."], [_profileValues, _profileLabels, (_profileValues find _activeProfile) max 0]]
            ],
            {
                params ["_values"];
                ["AI_CONFIG", _values] call Waldo_fnc_FeatureRuntimeApply;
            }
        ] call zen_dialog_fnc_create;
    };
    case "HAZARD_CREATE": {
        private _presets = missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap];
        private _presetKeys = (keys _presets) call BIS_fnc_sortAlphabetically;
        if (count _presetKeys == 0) exitWith {systemChat "[WMP] No hazardous-environment presets are configured."};
        private _presetLabels = _presetKeys apply {
            private _profile = _presets get _x;
            private _detectorGated =
                !((_profile getOrDefault ["detectorItems", []]) isEqualTo [])
                || !((_profile getOrDefault ["detectorObjects", []]) isEqualTo [])
                || ("awarenessCondition" in _profile);
            format ["%1 - %2%3", _x, _profile getOrDefault ["label", "Hazardous Area"], ["", " (detector-aware)"] select _detectorGated]
        };
        [
            "Hazardous Environment: Choose Type",
            [
                ["COMBO", ["Hazard type", "Mission-configured presets provide the behaviour, label and any protective-equipment list."], [_presetKeys, _presetLabels, 0]]
            ],
            {
                params ["_values", "_modulePos"];
                private _presetKey = _values select 0;
                private _presetMap = missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap];
                private _preset = _presetMap get _presetKey;
                private _thresholds = _preset getOrDefault ["damageThresholds", [[30, 0.01]]];
                private _firstThreshold = _thresholds param [0, [30, 0.01]];
                [
                    format ["Create %1", _preset getOrDefault ["label", _presetKey]],
                    [
                        ["EDIT", ["Hazard name", "Player-facing identity used in status and notifications; this can describe radiation, toxins, vacuum, heat or any mission-specific threat."], [_preset getOrDefault ["label", "Hazardous Area"]]],
                        ["EDIT", ["Entry message", "Roleplay-facing warning shown once when a player enters."], [_preset getOrDefault ["enterMessage", "You have entered a hazardous zone."]]],
                        ["EDIT", ["Exit message", "Roleplay-facing notice shown once when a player leaves."], [_preset getOrDefault ["exitMessage", "You have left the hazardous zone."]]],
                        ["SLIDER", ["Radius", "Circular zone radius in metres."], [5, 5000, 100, 0]],
                        ["COMBO", ["Intensity", "Linear falls toward the edge; constant applies full strength everywhere inside."], [["LINEAR", "CONSTANT"], ["Linear from centre", "Constant throughout"], ((["LINEAR", "CONSTANT"] find (toUpperANSI (_preset getOrDefault ["intensityMode", "LINEAR"]))) max 0)]],
                        ["SLIDER", ["Exposure rate", "Exposure gained per second at full intensity."], [0, 100, _preset getOrDefault ["rate", 1], 2]],
                        ["SLIDER", ["Recovery rate", "Exposure removed per second outside the zone."], [0, 100, _preset getOrDefault ["decay", 0.1], 2]],
                        ["SLIDER", ["Maximum exposure", "Caps accumulated exposure for this hazard channel."], [1, 10000, _preset getOrDefault ["maximumExposure", 1000], 0]],
                        ["SLIDER", ["Damage threshold", "Exposure before damage begins."], [0, 1000, _firstThreshold param [0, 30], 1]],
                        ["SLIDER", ["Damage per tick", "Damage applied each evaluator tick after the threshold. Zero creates a non-injuring roleplay zone."], [0, 1, _firstThreshold param [1, 0.01], 3]],
                        ["SLIDER", ["Fatal exposure", "Exposure that kills an unprotected player. Zero disables forced lethality."], [0, 10000, (_preset getOrDefault ["fatalExposure", 0]) max 0, 0]],
                        ["CHECKBOX", ["Vehicles protect", "Being inside a vehicle provides the configured protection factor."], _preset getOrDefault ["protectInVehicles", false]],
                        ["CHECKBOX", ["Interiors protect", "Being inside a building provides the configured protection factor."], _preset getOrDefault ["protectIndoors", false]],
                        ["SLIDER", ["Protected exposure factor", "0 is complete protection; 1 is none."], [0, 1, _preset getOrDefault ["equipmentFactor", 0.05], 2]],
                        ["CHECKBOX", ["Show continuous exposure panel", "Show one continuously updated lower-left panel. This does not create or queue repeated notification cards."], _preset getOrDefault ["showStatus", missionNamespace getVariable ["Waldo_Hazard_ShowStatus", true]]],
                        ["CHECKBOX", ["Notify on entry and exit", "Show each affected player one WMP notification when crossing the zone boundary."], _preset getOrDefault ["notifyTransitions", missionNamespace getVariable ["Waldo_Hazard_NotifyTransitions", true]]],
                        ["COMBO", ["Who can see hazard information", "Preset rules use any detector items, nearby detector objects or custom condition configured by the mission maker. Everyone ignores those information gates but does not change protection or damage."], [["PRESET", "EVERYONE"], ["Use preset detector rules", "Everyone"], 0]],
                        ["CHECKBOX", ["Copy setup script", "Copy an equivalent mission-maker call for permanent setup."], false]
                    ],
                    {
                        params ["_values", "_arguments"];
                        _arguments params ["_modulePos", "_presetKey", "_preset"];
                        _values params ["_label", "_enterMessage", "_exitMessage", "_radius", "_intensityMode", "_rate", "_decay", "_maximumExposure", "_threshold", "_damage", "_fatalExposure", "_vehicles", "_indoors", "_factor", "_showStatus", "_notifyTransitions", "_informationVisibility", "_copy"];
                        private _profile = createHashMap;
                        {_profile set [_x, _preset get _x]} forEach keys _preset;
                        _profile set ["label", _label];
                        _profile set ["enterMessage", _enterMessage];
                        _profile set ["exitMessage", _exitMessage];
                        _profile set ["intensityMode", _intensityMode];
                        _profile set ["rate", _rate];
                        _profile set ["decay", _decay];
                        _profile set ["maximumExposure", _maximumExposure];
                        _profile set ["damageThresholds", [[_threshold, _damage]]];
                        _profile set ["fatalExposure", if (_fatalExposure <= 0) then {-1} else {_fatalExposure}];
                        _profile set ["protectInVehicles", _vehicles];
                        _profile set ["vehicleFactor", _factor];
                        _profile set ["protectIndoors", _indoors];
                        _profile set ["indoorFactor", _factor];
                        _profile set ["equipmentFactor", _factor];
                        _profile set ["showStatus", _showStatus];
                        _profile set ["notifyTransitions", _notifyTransitions];
                        if (_informationVisibility isEqualTo "EVERYONE") then {
                            _profile set ["requireAwarenessForStatus", false];
                            _profile set ["requireAwarenessForNotifications", false];
                        };
                        private _key = ["hazard"] call Waldo_fnc_CreateRuntimeId;
                        ["HAZARD_SET", [_key, [_modulePos, _radius], _profile]] call Waldo_fnc_FeatureRuntimeApply;
                        if (_copy) then {
                            copyToClipboard format ["[%1, [%2, %3], %4] call Waldo_fnc_HazardRegisterZone;", str _key, str _modulePos, _radius, _profile];
                            systemChat "[WMP] Hazard setup call copied to clipboard.";
                        };
                    },
                    {},
                    [_modulePos, _presetKey, _preset]
                ] call zen_dialog_fnc_create;
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
