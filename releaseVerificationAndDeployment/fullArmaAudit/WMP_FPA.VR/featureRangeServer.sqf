/*
 * Author: WaldoTheWarfighter
 * Builds the server-authoritative walkable full-pack feature range. Objects are real multiplayer
 * fixtures configured through the same public functions mission makers use. Curator assignment
 * follows the actual remote player owner, transfers after respawn and never selects server-owned
 * playable AI as the initial Zeus operator.
 *
 * Arguments: none (executed from auditInitServer.sqf).
 * Return Value: nothing.
 *
 * Example: [] execVM "featureRangeServer.sqf";
 * Current callers: the generated full-pack audit mission on dedicated or hosted authority.
 */
if (!isServer) exitWith {};
waitUntil {
    uiSleep 0.1;
    !isNil "Waldo_fnc_MiniGamesInit" &&
    {!isNil "Waldo_fnc_MiniGameInteractionSetup"} &&
    {!isNil "Waldo_fnc_EcoInit"}
};

missionNamespace setVariable ["Waldo_QA_FeatureObjects", [], true];
missionNamespace setVariable ["Waldo_QA_FeatureStations", [], true];
call compile preprocessFileLineNumbers "functionStations.sqf";

Waldo_QA_fnc_trackFeatureObjectServer = {
    params ["_object"];
    if (isNull _object) exitWith {objNull};
    private _objects = +(missionNamespace getVariable ["Waldo_QA_FeatureObjects", []]);
    _objects pushBackUnique _object;
    missionNamespace setVariable ["Waldo_QA_FeatureObjects", _objects, true];
    _object
};

Waldo_QA_fnc_spawnFeatureObjectServer = {
    params ["_class", "_position", ["_direction", 0], ["_simulation", true]];
    private _object = createVehicle [_class, _position, [], 0, "NONE"];
    // A physics fixture must be frozen before any correction. Enabling it at an
    // editor/default position for even one frame can collide or destroy vehicles.
    _object enableSimulationGlobal false;
    _object setVelocity [0, 0, 0];
    _object setPosATL _position;
    _object setDir _direction;
    if ((_position select 2) <= 1) then {_object setVectorUp (surfaceNormal _position)};
    _object allowDamage false;
    _object enableSimulationGlobal _simulation;
    [_object] call Waldo_QA_fnc_trackFeatureObjectServer
};

Waldo_QA_fnc_getFeatureObjectServer = {
    params ["_variableName", "_class", "_position", ["_direction", 0], ["_simulation", true]];
    private _object = missionNamespace getVariable [_variableName, objNull];
    if (isNull _object) then {
        _object = [_class, _position, _direction, _simulation] call Waldo_QA_fnc_spawnFeatureObjectServer;
        missionNamespace setVariable [_variableName, _object, true];
    } else {
        [_object] call Waldo_QA_fnc_trackFeatureObjectServer;
        _object enableSimulationGlobal false;
        _object setVelocity [0, 0, 0];
        _object setPosATL _position;
        _object setDir _direction;
        if ((_position select 2) <= 1) then {_object setVectorUp (surfaceNormal _position)};
        _object allowDamage false;
        _object enableSimulationGlobal _simulation;
    };
    _object
};

Waldo_QA_fnc_registerFeatureStationServer = {
    params ["_id", "_title", "_position", "_description"];
    private _stations = +(missionNamespace getVariable ["Waldo_QA_FeatureStations", []]);
    if ((_stations findIf {(_x select 0) isEqualTo _id}) >= 0) exitWith {false};
    _stations pushBack [_id, _title, _position, _description];
    missionNamespace setVariable ["Waldo_QA_FeatureStations", _stations, true];
    private _marker = createMarker [format ["Waldo_QA_Station_%1", _id], _position];
    _marker setMarkerType "mil_dot";
    _marker setMarkerColor "ColorBLUFOR";
    _marker setMarkerText _title;
    [format ["Waldo_QA_Station3D_%1", _id], _position, createHashMapFromArray [
        ["text", _title],
        ["offset", [0, 0, 2.4]],
        ["distance", 10],
        ["colour", [0.49, 0.78, 1, 0.95]]
    ]] call Waldo_fnc_Create3DMarker;
    true
};

Waldo_QA_fnc_resetPartyTablesServer = {
    if (!isServer) exitWith {};
    {
        private _table = _x;
        {
            if ((_x getVariable ["Waldo_MG_SeatedTable", objNull]) isEqualTo _table) then {
                [_x] call Waldo_MG_fnc_releaseUnitSeatServer;
            };
        } forEach allPlayers;
        {
            [_table] call _x;
        } forEach [
            Waldo_MG_fnc_battleshipClearServer,
            Waldo_MG_fnc_whosWhoClearServer,
            Waldo_MG_fnc_shotgunClearServer,
            Waldo_MG_fnc_checkersClearServer,
            Waldo_MG_fnc_rpsClearServer,
            Waldo_MG_fnc_blackjackClearServer,
            Waldo_MG_fnc_chessClearServer,
            Waldo_MG_fnc_pokerClearServer,
            Waldo_MG_fnc_drawPokerClearServer,
            Waldo_MG_fnc_liarsDiceClearServer,
            Waldo_MG_fnc_connectFourClearServer,
            Waldo_MG_fnc_unoClearServer
        ];
        _table setVariable ["Waldo_MG_TableSeats", [objNull, objNull, objNull, objNull], true];
        _table setVariable ["Waldo_MG_TableVotes", ["", "", "", ""], true];
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TableSelectedGame", "", true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
        [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
    } forEach (missionNamespace getVariable ["Waldo_QA_PartyTables", []]);
    ["Party tables reset to their empty lobbies."] remoteExec ["systemChat", 0];
};

Waldo_QA_fnc_resetInteractionsServer = {
    if (!isServer) exitWith {};
    {
        [_x, true, true] call Waldo_fnc_MiniGameInteractionReset;
    } forEach (missionNamespace getVariable ["Waldo_QA_InteractionObjects", []]);
    ["All interaction procedures returned to IDLE."] remoteExec ["systemChat", 0];
};

Waldo_QA_fnc_rearmBombServer = {
    if (!isServer) exitWith {};
    private _oldBomb = missionNamespace getVariable ["Waldo_QA_LiveBomb", objNull];
    if (!isNull _oldBomb) then {deleteVehicle _oldBomb;};
    private _bomb = ["qa_live_bomb", "Land_Device_assembled_F", [80, -94, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
    [_bomb, [["title", "Defuse Live Training Charge"], ["wireCount", 5], ["timeLimit", 30], ["detonateOnFailure", true], ["oneShot", false]]]
        call Waldo_fnc_BombDefuseSetup;
    missionNamespace setVariable ["Waldo_QA_LiveBomb", _bomb, true];
    if (missionNamespace getVariable ["Waldo_QA_FeatureRangeReady", false]) then {
        [_bomb] remoteExecCall ["Waldo_QA_fnc_setupBombLocal", 0];
    };
    ["Live EOD training charge rearmed."] remoteExec ["systemChat", 0];
};

Waldo_QA_fnc_refillEconomyServer = {
    if (!isServer || {isNil "Waldo_fnc_EcoResource_getResourceTypes"}) exitWith {};
    {
        private _capacity = ["WEST", _x] call Waldo_fnc_EcoResource_getSideResourceStorageCapacity;
        private _amount = if (_capacity < 0) then {500} else {0};
        ["WEST", _x, _amount, "QA RANGE"] call Waldo_fnc_EcoResource_setSideResourceAmount;
    } forEach (call Waldo_fnc_EcoResource_getResourceTypes);
    ["BLUFOR economy reset: unlimited stores replenished; capped stores emptied for collection tests."] remoteExec ["systemChat", 0];
};

Waldo_QA_fnc_configureEconomyServer = {
    if (!isServer) exitWith {false};
    private _requiredFunctions = [
        "Waldo_fnc_EcoResource_getResourceTypes",
        "Waldo_fnc_EcoResearch_getResearchCatalog",
        "Waldo_fnc_EcoBuild_getBuildCatalog",
        "Waldo_fnc_EcoBuy_getPurchaseCatalog"
    ];
    if (_requiredFunctions findIf {isNil _x} >= 0) exitWith {
        diag_log "[WMP QA] Economy fixture could not be configured because its public APIs are unavailable.";
        false
    };

    private _deadline = diag_tickTime + 30;
    waitUntil {
        uiSleep 0.1;
        missionNamespace getVariable ["WaldoEcoCore_MakerConfigApplied", false] || {diag_tickTime >= _deadline}
    };

    // Do not replace the bundled preset with a reduced QA-only economy. The full-pack audit must
    // exercise the same default data mission makers receive, including all selected side catalogues.
    private _resources = call Waldo_fnc_EcoResource_getResourceTypes;
    private _research = call Waldo_fnc_EcoResearch_getResearchCatalog;
    private _builds = call Waldo_fnc_EcoBuild_getBuildCatalog;
    private _purchases = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
    if ((count _resources) <= 0 || {(count _research) <= 0} || {(count _builds) <= 0} || {(count _purchases) <= 0}) exitWith {
        diag_log format ["[WMP QA] Bundled Economy preset was not applied: resources=%1 research=%2 builds=%3 purchases=%4.", count _resources, count _research, count _builds, count _purchases];
        false
    };

    missionNamespace setVariable ["Waldo_QA_EconomyConfigured", true, true];
    diag_log format ["[WMP QA] Economy fixture configured: resources=%1 research=%2 builds=%3 purchases=%4.",
        count (call Waldo_fnc_EcoResource_getResourceTypes),
        count (call Waldo_fnc_EcoResearch_getResearchCatalog),
        count (call Waldo_fnc_EcoBuild_getBuildCatalog),
        count (call Waldo_fnc_EcoBuy_getPurchaseCatalog)
    ];
    true
};

Waldo_QA_fnc_spawnResourceCrateServer = {
    private _crate = ["qa_economy_crate", "Land_PlasticCase_01_medium_F", [-61, -3, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
    private _resourceTypes = call Waldo_fnc_EcoResource_getResourceTypes;
    private _primaryType = _resourceTypes param [0, ""];
    private _secondaryType = _resourceTypes param [1, _primaryType];
    private _rows = [[_primaryType, 100]];
    if (_secondaryType isNotEqualTo _primaryType) then {_rows pushBack [_secondaryType, 5];};
    _crate setVariable ["WaldoEcoResource_IsResourceCrate", true, true];
    _crate setVariable ["WaldoEcoResource_Collected", false, true];
    _crate setVariable ["WaldoEcoResource_ResourceRows", _rows, true];
    _crate setVariable ["WaldoEcoResource_ResourceType", _primaryType, true];
    _crate setVariable ["WaldoEcoResource_ResourceValue", 100, true];
    [_crate, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;
    [_crate] call Waldo_fnc_EcoResource_trackCrateMarker;
    [_crate] remoteExec ["Waldo_fnc_EcoResource_ensureCrateActionLocal", 0];
    _crate
};

Waldo_QA_fnc_spawnConstructionVehicleServer = {
    private _vehicle = ["qa_economy_construction", "B_Truck_01_box_F", [-48, 16, 0], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
    [_vehicle] call Waldo_fnc_EcoBuild_registerConstructionVehicle;
    [_vehicle] remoteExec ["Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal", 0];
    _vehicle
};

Waldo_QA_fnc_startConvoyServer = {
    if (!isServer) exitWith {};

    private _oldGroup = missionNamespace getVariable ["Waldo_QA_ConvoyGroup", grpNull];
    if (!isNull _oldGroup) then {
        {
            if (!isPlayer _x) then {deleteVehicle _x;};
        } forEach (units _oldGroup);
        deleteGroup _oldGroup;
    };

    private _convoyGroup = createGroup west;
    {
        _x params ["_variableName", "_position"];
        private _vehicle = [_variableName, "B_MRAP_01_F", _position, 0, true] call Waldo_QA_fnc_getFeatureObjectServer;
        _vehicle setVelocity [0, 0, 0];
        _vehicle setVectorUp (surfaceNormal _position);
        private _driver = _convoyGroup createUnit ["B_Soldier_F", _position, [], 0, "NONE"];
        _driver moveInDriver _vehicle;
    } forEach [["qa_convoy_1", [28, 54, 0]], ["qa_convoy_2", [28, 70, 0]]];

    private _waypoint = _convoyGroup addWaypoint [[28, 100, 0], 0];
    _waypoint setWaypointType "MOVE";
    missionNamespace setVariable ["Waldo_QA_ConvoyGroup", _convoyGroup, true];
    [_convoyGroup, 15, 10, false] spawn Waldo_fnc_SimpleAiConvoy;
    diag_log "[WMP QA] Manual convoy test started.";
    ["Convoy test started. Both vehicles are now live and moving north."] remoteExec ["systemChat", 0];
};

Waldo_QA_fnc_resetEconomyFixturesServer = {
    if (!isServer) exitWith {};
    call Waldo_QA_fnc_refillEconomyServer;
    {
        private _old = missionNamespace getVariable [_x, objNull];
        if (!isNull _old) then {deleteVehicle _old;};
        missionNamespace setVariable [_x, objNull, true];
    } forEach ["qa_economy_crate", "qa_economy_construction"];
    call Waldo_QA_fnc_spawnResourceCrateServer;
    call Waldo_QA_fnc_spawnConstructionVehicleServer;
    ["Economy test fixtures restored: resources refilled, collection crate replaced and construction vehicle returned."] remoteExec ["systemChat", 0];
};

Waldo_QA_fnc_triggerEMPServer = {
    if (!isServer) exitWith {};
    [[0, -102, 0], 35, 12] call Waldo_fnc_EMP;
};

Waldo_QA_fnc_setSafeStartServer = {
    params [["_enabled", true]];
    if (!isServer) exitWith {};
    [_enabled] call Waldo_fnc_SafeStart;
};

Waldo_QA_fnc_startSafeStartTimerServer = {
    params [["_seconds", 60]];
    if (!isServer) exitWith {};
    [_seconds] call Waldo_fnc_SafeStartTimer;
};

Waldo_QA_fnc_endexServer = {
    if (!isServer) exitWith {};
    [] call Waldo_fnc_ENDEX;
};

Waldo_QA_fnc_resetEndexServer = {
    if (!isServer) exitWith {};
    [] call Waldo_fnc_ENDEXReset;
};

Waldo_QA_fnc_createObjectiveServer = {
    if (!isServer) exitWith {};
    ["qa_manual_objective", west, "Audit the feature range", "FULL-PACK PR AUDIT", [0, 0, 0], "ASSIGNED", true]
        call Waldo_fnc_CreateObjective;
};

Waldo_QA_fnc_spawnAARTargetServer = {
    params [["_actor", objNull, [objNull]]];
    if (!isServer) exitWith {};
    private _requestOwner = if (isNil "remoteExecutedOwner") then {2} else {remoteExecutedOwner};
    if (!isNull _actor && {_requestOwner != 2} && {_requestOwner != owner _actor}) exitWith {};
    private _oldTarget = missionNamespace getVariable ["Waldo_QA_AARTarget", objNull];
    if (!isNull _oldTarget) then {deleteVehicle _oldTarget;};
    private _oldGroup = missionNamespace getVariable ["Waldo_QA_AARTargetGroup", grpNull];
    if (!isNull _oldGroup) then {deleteGroup _oldGroup;};
    private _group = createGroup east;
    private _target = _group createUnit ["O_Soldier_F", [8, 67, 0], [], 0, "NONE"];
    _target disableAI "ALL";
    _target setCaptive true;
    _target allowDamage true;
    _target setVariable ["Waldo_QA_AARTarget", true, true];
    missionNamespace setVariable ["Waldo_QA_AARTargetGroup", _group];
    missionNamespace setVariable ["Waldo_QA_AARTarget", _target, true];
    ["qa_aar_live_target", _target, createHashMapFromArray [
        ["text", "AAR LIVE TARGET | SHOOT TO RECORD OPFOR KIA"],
        ["icon", "\a3\ui_f\data\map\markers\military\destroy_CA.paa"],
        ["colour", [1, 0.72, 0.25, 1]], ["offset", [0, 0, 2.2]], ["distance", 100]
    ]] call Waldo_fnc_Create3DMarker;
    if (!isNull _actor) then {
        ["AAR live target reset 19 metres north of this station. Shoot it, then run ENDEX + AAR to verify the recorded OPFOR KIA.", _actor] call Waldo_fnc_DynamicText;
    };
    diag_log format ["[WMP AAR QA] live target spawned target=%1 actor=%2 requestOwner=%3 position=%4", netId _target, if (isNull _actor) then {"SERVER"} else {name _actor}, _requestOwner, getPosATL _target];
};

// Central navigation and reset console.
private _consoleTable = ["qa_control_table", "Land_CampingTable_F", [0, 2, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _console = ["qa_control_console", "Land_Laptop_unfolded_F", [0, 2, 0.82], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_ControlConsole", _console, true];
["control", "AUDIT CONTROL", [0, 2, 0], "Navigation, resets, SafeStart, objectives and diagnostics."] call Waldo_QA_fnc_registerFeatureStationServer;

// Two genuine party tables allow two- and four-player sessions without rebuilding the mission.
private _partyOne = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
if (isNull _partyOne) then {
    _partyOne = ["qa_party_table_1", "Land_CampingTable_small_F", [-7, 28, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
    [_partyOne, "Feature Range A", "QA-PARTY-A"] call Waldo_MG_fnc_markTableServer;
    missionNamespace setVariable ["Waldo_QA_PartyTable", _partyOne, true];
};
private _partyTwo = ["qa_party_table_2", "Land_CampingTable_small_F", [7, 28, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
[_partyTwo, "Feature Range B", "QA-PARTY-B"] call Waldo_MG_fnc_markTableServer;
missionNamespace setVariable ["Waldo_QA_PartyTables", [_partyOne, _partyTwo], true];
["party", "PARTY TABLES", [0, 28, 0], "All twelve games, seating, voting, ready, spectators, leaving and rematches."] call Waldo_QA_fnc_registerFeatureStationServer;

// Ten procedures at every curated difficulty. Each object publishes authoritative state.
private _challengeRows = [
    ["wirecut", "EOD CONTROLLER", "Land_Device_assembled_F"],
    ["minesweeper", "TRIGGER ANALYSER", "Land_Laptop_unfolded_F"],
    ["keypad", "ACCESS TERMINAL", "Land_Laptop_03_sand_F"],
    ["lockpick", "LOCK CYLINDER", "Land_MetalCase_01_small_F"],
    ["circuit", "BREAKER CABINET", "Land_PortableServer_01_sand_F"],
    ["repair", "MAINTENANCE HATCH", "Land_ToolTrolley_02_F"],
    ["radiotune", "COMMUNICATIONS UNIT", "Land_PortableServer_01_sand_F"],
    ["pressure", "HYDRAULIC MANIFOLD", "Land_Pipes_small_F"],
    ["sequence", "CONTROL CONSOLE", "Land_Computer_01_sand_F"],
    ["commandinput", "TACTICAL UPLINK", "Land_Laptop_03_sand_F"]
];
private _difficulties = ["easy", "standard", "hard", "expert"];
private _interactionObjects = [];
{
    _x params ["_challengeId", "_equipmentTitle", "_class"];
    private _row = _forEachIndex;
    {
        private _difficulty = _x;
        private _position = [80 + (_forEachIndex * 14), 60 - (_row * 14), 0];
        private _variableName = format ["qa_interaction_%1_%2", _challengeId, _difficulty];
        private _object = [_variableName, _class, _position, 270, false] call Waldo_QA_fnc_getFeatureObjectServer;
        _object setVariable ["Waldo_QA_InteractionDefinition", [_challengeId, _difficulty, _equipmentTitle], true];
        _object setVariable ["Waldo_QA_InteractionLabel", format ["%1 / %2", _equipmentTitle, toUpper _difficulty], true];
        private _options = createHashMapFromArray [
            ["difficulty", _difficulty],
            ["repeatable", true],
            ["retryOnFailure", true],
            ["actionTitle", format ["Operate %1 (%2)", _equipmentTitle, toUpper _difficulty]],
            ["title", format ["%1 / %2", _equipmentTitle, toUpper _difficulty]],
            ["successVariable", format ["Waldo_QA_%1_%2_Success", _challengeId, _difficulty]],
            ["failureVariable", format ["Waldo_QA_%1_%2_Failure", _challengeId, _difficulty]]
        ];
        [_object, _challengeId, _options] call Waldo_fnc_MiniGameInteractionSetup;
        _interactionObjects pushBack _object;
        uiSleep 0.01;
    } forEach _difficulties;
} forEach _challengeRows;
missionNamespace setVariable ["Waldo_QA_InteractionObjects", _interactionObjects, true];
["interactions", "INTERACTION PROCEDURES", [72, 66, 0], "Ten equipment procedures at easy, standard, hard and expert."] call Waldo_QA_fnc_registerFeatureStationServer;

// A real destructive EOD example sits beyond the reusable training equipment.
call Waldo_QA_fnc_rearmBombServer;
["eod", "LIVE EOD", [80, -94, 0], "Wire-cut outcome drives a real server-side explosive consequence."] call Waldo_QA_fnc_registerFeatureStationServer;

// The audit pre-init selects the real MEDIUM preset before server-authoritative Economy startup.
// Validate it here, then build physical fixtures against its actual resource vocabulary.
if !(call Waldo_QA_fnc_configureEconomyServer) then {
    diag_log "[WMP QA] Economy fixtures skipped because the bundled preset is unavailable.";
};
private _qaEconomyResourceTypes = call Waldo_fnc_EcoResource_getResourceTypes;
private _qaZoneResource = _qaEconomyResourceTypes param [0, ""];
if (_qaZoneResource isNotEqualTo "") then {
    [[-55, 2, 0], "QA Supply Zone", 14, [[_qaZoneResource, 5, 5000]], "WEST", 15] call Waldo_fnc_EcoResource_createResourceZone;
};
private _resourceCrate = call Waldo_QA_fnc_spawnResourceCrateServer;
private _research = ["qa_economy_research", "Land_Research_HQ_F", [-63, 12, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
[_research] call Waldo_fnc_EcoResearch_registerCenter;
private _construction = call Waldo_QA_fnc_spawnConstructionVehicleServer;
private _terminal = ["qa_economy_terminal", "Land_Laptop_unfolded_F", [-48, -5, 0.82], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
[_terminal] call Waldo_fnc_EcoBuy_registerTerminal;
[[ -43, -5, 0], "Ground", 90, "WEST"] call Waldo_fnc_EcoBuy_createDropPoint;
call Waldo_QA_fnc_refillEconomyServer;
["economy", "ECONOMY SYSTEMS", [-55, 2, 0], "Deterministic Money/Parts fixture: collection, research, construction, purchase terminal and drop point."] call Waldo_QA_fnc_registerFeatureStationServer;

// Logistics: MHQ with synced deployment parts, VVD, and airborne paradrop transport.
private _mhq = ["qa_mhq", "B_Truck_01_covered_F", [-62, 45, 0], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _logicGroup = createGroup sideLogic;
private _mhqLogic = _logicGroup createUnit ["Logic", [-62, 45, 0], [], 0, "NONE"];
[_mhqLogic] call Waldo_QA_fnc_trackFeatureObjectServer;
private _mhqPartOne = ["qa_mhq_table", "Land_CampingTable_F", [-62, 33, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _mhqPartTwo = ["qa_mhq_chair", "Land_CampingChair_V2_F", [-56, 33, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _mhqTent = ["qa_mhq_tent", "Land_TentA_F", [-74, 33, 0], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _mhqCrate = ["qa_mhq_crate", "Box_NATO_Equip_F", [-68, 21, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _mhqAntenna = ["qa_mhq_antenna", "Land_TTowerSmall_1_F", [-80, 45, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _mhqLight = ["qa_mhq_light", "Land_PortableLight_double_F", [-50, 45, 0], 225, false] call Waldo_QA_fnc_getFeatureObjectServer;
_mhqLogic synchronizeObjectsAdd [_mhqPartOne, _mhqPartTwo, _mhqTent, _mhqCrate, _mhqAntenna, _mhqLight];
// Every optional path is enabled: modern audio, logistics quartermaster, rear placement.
[_mhq, true, true, 180, 5] call Waldo_fnc_MHQSetup;
missionNamespace setVariable ["Waldo_QA_MHQ", _mhq, true];

// Exact Logistics Spawner composition path: standalone info stand, immediately active without an
// MHQ deploy state. The object-keyed global call installs local/JIP interactions and server state.
private _standaloneQuartermaster = ["qa_standalone_quartermaster", "Land_InfoStand_V1_F", [-82, 60, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
[_standaloneQuartermaster, 0, 4, false] remoteExecCall ["Waldo_fnc_SetupQuarterMaster", 0, _standaloneQuartermaster];
missionNamespace setVariable ["Waldo_QA_StandaloneQuartermaster", _standaloneQuartermaster, true];

private _vvdPad = ["qa_vvd_pad", "Land_JumpTarget_F", [-105, 48, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _vvdTable = ["qa_vvd_table", "Land_CampingTable_F", [-105, 34, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _vvdLaptop = ["qa_vvd_laptop", "Land_Laptop_unfolded_F", [-105, 34, 0.82], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_VVD", [_vvdLaptop, _vvdPad], true];
[_vvdLaptop, _vvdPad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit;
private _vvdClearance = ((missionNamespace getVariable ["Waldo_QA_FeatureObjects", []]) select {
    !isNull _x && {_x isKindOf "AllVehicles"} && {_x distance2D _vvdPad < 25}
});
missionNamespace setVariable ["Waldo_QA_VVD_ClearanceObjects", _vvdClearance, true];

private _dropAircraft = ["qa_drop_aircraft", "B_Heli_Transport_01_F", [-30, 55, 55], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
_dropAircraft allowDamage false;
_dropAircraft enableSimulationGlobal false;
_dropAircraft flyInHeight 55;
private _dropFlag = ["qa_drop_flag", "FlagPole_F", [-35, 38, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_Paradrop", [_dropFlag, _dropAircraft], true];
["logistics", "LOGISTICS / PARADROP", [-73, 45, 0], "MHQ deployment, standalone info-stand quartermaster and airborne jump transport."] call Waldo_QA_fnc_registerFeatureStationServer;

Waldo_QA_fnc_activateDropAircraftServer = {
    if (!isServer) exitWith {};
    (missionNamespace getVariable ["Waldo_QA_Paradrop", []]) params [["_flag", objNull], ["_aircraft", objNull]];
    if (isNull _aircraft) exitWith {};
    _aircraft enableSimulationGlobal true;
    _aircraft engineOn true;
    _aircraft flyInHeight 55;
    diag_log format ["[WMP QA] paradrop aircraft activated netId=%1", netId _aircraft];
};
["vvd", "ISOLATED VEHICLE DEPOT", [-105, 38, 0], "Vehicle spawning and deletion lane, isolated from every other audit vehicle."] call Waldo_QA_fnc_registerFeatureStationServer;

// Core mission-flow fixtures: loadout save, SafeStart controls, objectives, AAR and an opt-in convoy.
private _loadoutCrate = ["qa_loadout_save", "Box_NATO_Equip_F", [2, 45, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_LoadoutSave", _loadoutCrate, true];
private _supplyCrate = ["qa_supply_crate", "B_supplyCrate_F", [-14, 48, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _medicalCrate = ["qa_medical_crate", "ACE_medicalSupplyCrate_advanced", [-26, 48, 0], 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_SupplyCrate", _supplyCrate, true];
missionNamespace setVariable ["Waldo_QA_MedicalCrate", _medicalCrate, true];
private _coreConsole = ["qa_core_console", "Land_Laptop_unfolded_F", [10, 45, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_CoreConsole", _coreConsole, true];
private _acreTable = ["qa_acre_table", "Land_CampingTable_small_F", [18, 34, 0], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
private _acreConsole = ["qa_acre_console", "Land_Laptop_unfolded_F", [18, 34, 0.82], 180, false] call Waldo_QA_fnc_getFeatureObjectServer;
missionNamespace setVariable ["Waldo_QA_ACREConsole", _acreConsole, true];
["acre", "ACRE2 COMMUNICATIONS", [18, 27, 0], "Preconfigured duplicate radios, named nets, listening ears, Babel, respawn and persistence."] call Waldo_QA_fnc_registerFeatureStationServer;
[] call Waldo_fnc_SideBaseLoadoutSetup;
[_supplyCrate, true, west, false] spawn Waldo_fnc_DoStarterCrate;
[_medicalCrate, true, 1] call Waldo_fnc_MedicalCratePopulate;
[] call Waldo_fnc_AARTrack;
[objNull] call Waldo_QA_fnc_spawnAARTargetServer;

{
    _x params ["_variableName", "_position"];
    [_variableName, "B_MRAP_01_F", _position, 0, false] call Waldo_QA_fnc_getFeatureObjectServer;
} forEach [["qa_convoy_1", [28, 54, 0]], ["qa_convoy_2", [28, 70, 0]]];
["core", "MISSION FLOW / CONVOY", [0, 39, 0], "Loadout save, diagnostics, objectives, AAR, SafeStart and a manually started AI convoy."] call Waldo_QA_fnc_registerFeatureStationServer;

// Electronic Warfare: live jammer, tracker target, immune vehicle and manual EMP control.
missionNamespace setVariable ["Waldo_Jamming_Enable", true, true];
[] call Waldo_fnc_JammingInit;
// Keep this manual-test fixture simulated so Zeus can reposition and terrain-snap it. The public
// jammer API itself remains neutral: mission makers may still register simulated or static objects.
private _jammer = ["qa_ew_jammer", "Land_TTowerSmall_1_F", [0, -102, 0], 0, true] call Waldo_QA_fnc_getFeatureObjectServer;
_jammer allowDamage true;
private _jammerInteraction = createHashMapFromArray [
    ["disableChallenge", true],
    ["challengeId", "circuit"],
    ["difficulty", "standard"],
    ["engineerOnly", false],
    ["resultMode", "DISABLE"],
    ["allowPlayerToggle", true]
];
[_jammer, 45, "WEST", "ALL", 15, 0.8, true, true, [], [], true, false, _jammerInteraction]
    call Waldo_fnc_Jammer;
missionNamespace setVariable ["Waldo_QA_Jammer", _jammer, true];
private _trackedVehicle = ["qa_ew_tracked", "O_MRAP_02_F", [-18, -102, 0], 90, false] call Waldo_QA_fnc_getFeatureObjectServer;
[_trackedVehicle, west, "QA TRACKED VEHICLE"] call Waldo_fnc_Tracker;
private _immuneVehicle = ["qa_ew_immune", "B_MRAP_01_F", [18, -102, 0], 270, false] call Waldo_QA_fnc_getFeatureObjectServer;
[_immuneVehicle] call Waldo_fnc_EMPImmune;
missionNamespace setVariable ["Waldo_QA_EWObjects", [_jammer, _trackedVehicle, _immuneVehicle], true];
["ew", "ELECTRONIC WARFARE", [-8, -102, 0], "Radio jammer, UAV jamming, tracker, EMP target and immune vehicle."] call Waldo_QA_fnc_registerFeatureStationServer;

// Transport services: real simulated vehicles, living AI crews, independent pools and enough
// clearance for physical departure/arrival. Player self-actions exercise pickup, destination and RTB.
private _transportHeli = ["qa_transport_heli", "B_Heli_Light_01_F", [270, 52, 0], 180, true] call Waldo_QA_fnc_getFeatureObjectServer;
private _transportGround = ["qa_transport_ground", "B_MRAP_01_F", [280, 52, 0], 180, true] call Waldo_QA_fnc_getFeatureObjectServer;
if (crew _transportHeli isEqualTo []) then {createVehicleCrew _transportHeli};
if (crew _transportGround isEqualTo []) then {createVehicleCrew _transportGround};
[_transportHeli, "HELICOPTER", "QA_RAVEN", "QA Raven", createHashMapFromArray [["showMarker", true], ["cruiseAltitude", 80], ["boardingSeconds", 180]]] call Waldo_fnc_TransportRegister;
[_transportGround, "GROUND", "QA_TAXI", "QA Taxi", createHashMapFromArray [["showMarker", true], ["boardingSeconds", 180]]] call Waldo_fnc_TransportRegister;
missionNamespace setVariable ["Waldo_QA_TransportVehicles", [_transportHeli, _transportGround], true];
["transport-services", "TRANSPORT SERVICES", [275, 40, 0], "Request each typed pool, select a destination, disembark and verify physical return-to-base."] call Waldo_QA_fnc_registerFeatureStationServer;

// Register the exhaustive function directory after the genuine feature fixtures.
// Each public API maps to exactly one physical subsystem station; internal helpers are
// documented there but are never invoked automatically during a manual session.
{
    _x params ["_id", "_title", "_position", "_description", "_functions"];
    [_id, _title, _position, format ["%1  %2 registered function(s).", _description, count _functions]]
        call Waldo_QA_fnc_registerFeatureStationServer;
    private _variableId = (_id splitString "-") joinString "_";
    // The subsystem information stand owns the manifest interaction. Real
    // feature objects remain the actual test targets; no duplicate laptop is
    // spawned merely to list function names.
    private _console = missionNamespace getVariable [format ["qa_sign_%1", _variableId], objNull];
    if (!isNull _console) then {
        [_console] call Waldo_QA_fnc_trackFeatureObjectServer;
        _console setVariable ["Waldo_QA_FunctionStation", _x, true];
    };
    uiSleep 0.01;
} forEach (missionNamespace getVariable ["Waldo_QA_FunctionStations", []]);

missionNamespace setVariable ["WALDO_INIT_COMPLETE", true, true];
private _curator = missionNamespace getVariable ["qa_curator", objNull];
if (isNull _curator) then {
    private _curatorGroup = createGroup sideLogic;
    _curator = _curatorGroup createUnit ["ModuleCurator_F", [0, 0, 0], [], 0, "NONE"];
    missionNamespace setVariable ["qa_curator", _curator, true];
};
Waldo_QA_fnc_assignCuratorServer = {
    params [
        ["_unit", objNull, [objNull]],
        ["_openInterface", false, [false]]
    ];
    if (!isServer || {isNull _unit} || {!(_unit in allPlayers)}) exitWith {false};
    if (remoteExecutedOwner > 2 && {remoteExecutedOwner != owner _unit}) exitWith {false};
    private _curator = missionNamespace getVariable ["Waldo_QA_Curator", objNull];
    if (isNull _curator) exitWith {false};
    private _assigned = getAssignedCuratorUnit _curator;
    if (
        !isNull _assigned
        && {_assigned in allPlayers}
        && {isPlayer _assigned}
        && {owner _assigned > 2}
        && {!(_assigned isEqualTo _unit)}
    ) exitWith {false};
    private _requestId = (missionNamespace getVariable ["Waldo_QA_CuratorRequestId", 0]) + 1;
    missionNamespace setVariable ["Waldo_QA_CuratorRequestId", _requestId];
    [_unit, _curator, _requestId, _openInterface] spawn {
        params ["_unit", "_curator", "_requestId", "_openInterface"];
        if !(getAssignedCuratorUnit _curator isEqualTo _unit) then {
            unassignCurator _curator;
            private _clearDeadline = diag_tickTime + 5;
            waitUntil {
                uiSleep 0.05;
                isNull (getAssignedCuratorUnit _curator)
                || {diag_tickTime >= _clearDeadline}
                || {_requestId != missionNamespace getVariable ["Waldo_QA_CuratorRequestId", -1]}
            };
            if (_requestId != missionNamespace getVariable ["Waldo_QA_CuratorRequestId", -1]) exitWith {};
            _unit assignCurator _curator;
        };
        private _assignDeadline = diag_tickTime + 10;
        waitUntil {
            uiSleep 0.05;
            getAssignedCuratorUnit _curator isEqualTo _unit
            || {diag_tickTime >= _assignDeadline}
            || {_requestId != missionNamespace getVariable ["Waldo_QA_CuratorRequestId", -1]}
        };
        if (_requestId != missionNamespace getVariable ["Waldo_QA_CuratorRequestId", -1]) exitWith {};
        if !(getAssignedCuratorUnit _curator isEqualTo _unit) exitWith {
            diag_log format ["WMP FULL AUDIT ZEUS SERVER FAIL: assignment not confirmed for %1 (%2)", name _unit, owner _unit];
            [objNull, false] remoteExecCall ["Waldo_QA_fnc_curatorAssignmentConfirmedClient", owner _unit];
        };
        missionNamespace setVariable ["Waldo_QA_CuratorAssignedUnit", _unit, true];
        diag_log format ["WMP FULL AUDIT ZEUS SERVER READY: assigned %1 (%2) curator=%3", name _unit, owner _unit, netId _curator];
        [_curator, _openInterface] remoteExecCall ["Waldo_QA_fnc_curatorAssignmentConfirmedClient", owner _unit];
    };
    true
};
addMissionEventHandler ["EntityRespawned", {
    params ["_newUnit", "_oldUnit"];
    if (!isServer || {!isPlayer _newUnit}) exitWith {};
    if !(_oldUnit isEqualTo (missionNamespace getVariable ["Waldo_QA_CuratorAssignedUnit", objNull])) exitWith {};
    [_newUnit] spawn {
        params ["_unit"];
        waitUntil {uiSleep 0.1; isNull _unit || {_unit in allPlayers}};
        if (!isNull _unit && {!isNil "Waldo_QA_fnc_assignCuratorServer"}) then {
            [_unit] call Waldo_QA_fnc_assignCuratorServer;
            diag_log format ["WMP FULL AUDIT ZEUS: transferred to respawned unit %1 (%2)", name _unit, owner _unit];
        };
    };
}];
if (isNull _curator) then {
    diag_log "WMP FULL AUDIT FAIL: Zeus curator could not be created";
} else {
    _curator setVariable ["showNotification", false];
    _curator addCuratorEditableObjects [missionNamespace getVariable ["Waldo_QA_FeatureObjects", []], true];
    missionNamespace setVariable ["Waldo_QA_Curator", _curator, true];
    [] spawn {
        waitUntil {
            uiSleep 0.2;
            (allPlayers findIf {isPlayer _x && {owner _x > 2}}) >= 0
        };
        private _curator = missionNamespace getVariable ["Waldo_QA_Curator", objNull];
        if (!isNull _curator) then {
            private _unit = allPlayers select (allPlayers findIf {isPlayer _x && {owner _x > 2}});
            [_unit] call Waldo_QA_fnc_assignCuratorServer;
        };
    };
};
missionNamespace setVariable ["Waldo_QA_FeatureRangeReady", true, true];
diag_log format ["WMP FULL AUDIT RANGE READY: %1 objects, %2 stations", count (missionNamespace getVariable ["Waldo_QA_FeatureObjects", []]), count (missionNamespace getVariable ["Waldo_QA_FeatureStations", []])];
