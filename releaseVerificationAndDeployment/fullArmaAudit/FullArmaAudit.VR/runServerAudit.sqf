/*
 * Author: WaldoTheWarfighter
 * Runs the server-authoritative full-pack audit cases against real mission fixtures and runtime state.
 *
 * Locality and authority: Executed once by the dedicated/host server after the real pack and audit
 * fixtures report ready. Individual cases deliberately exercise server authority and local AI state.
 * The assertion registry is published for connected clients and later log inspection.
 *
 * Arguments: None.
 * Return Value: Nothing; records assertions through Waldo_QA_fnc_assert and publishes server completion.
 * Result: Every selected case records a named pass/fail result; the final summary is written to RPT.
 *
 * Example: [] execVM "runServerAudit.sqf";
 * Current caller: auditInitServer.sqf when automated audit mode is enabled.
 */

private _suite = missionNamespace getVariable ["Waldo_QA_Suite", "all"];
if !(_suite in ["all", "core", "ew", "party", "interactions", "economy"]) exitWith {
    ["audit/suite", false, format ["Unknown suite %1", _suite]] call Waldo_QA_fnc_assert;
};

if (_suite in ["all", "core"]) then {
    ["core/functions/registered", {
        private _required = [
            "Waldo_fnc_SafeStart", "Waldo_fnc_AARTrack", "Waldo_fnc_CreateObjective",
            "Waldo_fnc_SetObjectiveState", "Waldo_fnc_RunDiagnostics",
            "Waldo_fnc_ZenLoadoutSaveModule", "Waldo_fnc_ZenAddLoadoutSaveAction"
        ];
        private _missing = _required select {isNil _x};
        ["core/functions/registered", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/dialogue/simple-archetypes", {
        private _archetypes = missionNamespace getVariable ["Waldo_Dialogue_Archetypes", createHashMap];
        private _required = ["DORNOW_CIVILIAN", "DORNOW_GUARD", "MODERN_CIVILIAN", "MODERN_CIVILIAN_FRIENDLY", "MODERN_CIVILIAN_WARY", "MODERN_CIVILIAN_DISPLACED", "MODERN_SHOPKEEPER", "MODERN_RURAL_RESIDENT", "MODERN_AID_WORKER", "MODERN_LOCAL_OFFICIAL"];
        private _missing = _required select {!(_x in _archetypes)};
        ["core/dialogue/simple-archetypes", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/dialogue/specific-callback", {
        private _units = missionNamespace getVariable ["Waldo_QA_DialogueUnits", []];
        private _speaker = _units param [2, objNull];
        private _registry = missionNamespace getVariable ["Waldo_Dialogue_Registry", createHashMap];
        private _entry = _registry getOrDefault [netId _speaker, createHashMap];
        private _lines = _entry getOrDefault ["lines", []];
        private _callback = _entry getOrDefault ["onComplete", nil];
        ["core/dialogue/specific-callback", !isNull _speaker && {count _lines == 2} && {!isNil "_callback"} && {_callback isEqualType {}}, [!isNull _speaker, count _lines, isNil "_callback"]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/dialogue/advanced-linear-branching", {
        private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
        private _linear = _definitions getOrDefault ["QA_LINEAR", createHashMap];
        private _branch = _definitions getOrDefault ["QA_BRANCH", createHashMap];
        private _branchNodes = _branch getOrDefault ["nodes", createHashMap];
        private _choices = (_branchNodes getOrDefault ["START", createHashMap]) getOrDefault ["choices", []];
        ["core/dialogue/advanced-linear-branching", count _linear > 0 && {count _branchNodes == 5} && {count _choices == 3}, [count _linear, count _branchNodes, count _choices]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/dialogue/config-safe-round-trip", {
        private _definitions = missionNamespace getVariable ["Waldo_Conversation_Definitions", createHashMap];
        private _configured = _definitions getOrDefault ["QA_CONFIG_SAFE", createHashMap];
        private _nodes = _configured getOrDefault ["nodes", createHashMap];
        private _startChoices = (_nodes getOrDefault ["START", createHashMap]) getOrDefault ["choices", []];
        private _ids = keys _definitions;
        ["core/dialogue/config-safe-round-trip", count _nodes == 2 && {count _startChoices == 1} && {"QA_CONFIG_SAFE" in _ids}, [count _nodes, count _startChoices, _ids]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/fixtures/zeus-mhq", {
        private _curator = missionNamespace getVariable ["Waldo_QA_Curator", objNull];
        private _deadline = diag_tickTime + 120;
        waitUntil {
            uiSleep 0.1;
            (!isNull _curator && {!isNull (getAssignedCuratorUnit _curator)})
            || {diag_tickTime >= _deadline}
        };
        private _mhq = missionNamespace getVariable ["Waldo_QA_MHQ", objNull];
        private _logic = if (isNull _mhq) then {objNull} else {nearestObject [_mhq, "Logic"]};
        private _parts = if (isNull _logic) then {[]} else {synchronizedObjects _logic};
        private _assigned = if (isNull _curator) then {objNull} else {getAssignedCuratorUnit _curator};
        ["core/fixtures/zeus-mhq", !isNull _curator && {!isNull _assigned} && {!isNull _mhq} && {(count _parts) >= 6}, [!isNull _curator, if (isNull _assigned) then {"NONE"} else {name _assigned}, !isNull _mhq, count _parts]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/fixtures/vvd-clearance", {
        private _vvd = missionNamespace getVariable ["Waldo_QA_VVD", []];
        private _pad = _vvd param [1, objNull];
        private _nearVehicles = missionNamespace getVariable ["Waldo_QA_VVD_ClearanceObjects", []];
        ["core/fixtures/vvd-clearance", !isNull _pad && {_nearVehicles isEqualTo []}, [_nearVehicles apply {typeOf _x}]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/ai-helicopter/land-touchdown", {
        [objNull, false] call Waldo_QA_fnc_startImprovedLandingServer;
        private _helicopter = missionNamespace getVariable ["Waldo_QA_ImprovedLandingHelicopter", objNull];
        private _deadline = diag_tickTime + 60;
        waitUntil {
            uiSleep 0.1;
            isNull _helicopter
            || {((_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_LastResult", []]) param [0, ""]) in ["LANDED", "ANCHORED", "ABORTED"]}
            || {diag_tickTime >= _deadline}
        };
        private _result = if (isNull _helicopter) then {[]} else {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_LastResult", []]};
        private _tracker = if (isNull _helicopter) then {[]} else {_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_TrackerState", []]};
        private _landed = (_result param [0, ""]) in ["LANDED", "ANCHORED"];
        private _trackerType = _tracker param [1, ""];
        private _trackerScript = _tracker param [3, ""];
        private _landTypeObserved = _trackerType == "SCRIPTED" && {_trackerScript find "fn_wpland.sqf" >= 0};
        private _exact = !isNull _helicopter && {(_helicopter distance2D [325, 70, 0]) <= 5} && {((getPosATL _helicopter) select 2) <= 1};
        ["core/ai-helicopter/land-touchdown", _landed && {_landTypeObserved} && {_exact}, [_result, _tracker, if (isNull _helicopter) then {-1} else {_helicopter distance2D [325, 70, 0]}, if (isNull _helicopter) then {-1} else {(getPosATL _helicopter) select 2}]] call Waldo_QA_fnc_assert;
        call Waldo_QA_fnc_removeImprovedLandingServer;
    }] call Waldo_QA_fnc_case;

    ["core/dynamic-aa/envelope-and-locality", {
        private _id = "QA_AA_AUTOMATED";
        private _centre = [800, -800, 0];
        private _config = createHashMapFromArray [
            ["id", _id], ["displayName", "Automated AA Envelope"], ["centre", _centre],
            ["side", east], ["radius", 1000], ["engagementRadius", 500],
            ["minimumAltitude", 100], ["maximumAltitude", 300], ["altitudeMode", "ATL"],
            ["detectionDwell", 0], ["clearDelay", 0], ["detectionInterval", 0.25],
            ["assetSelectionMode", "EXACT"], ["radarAssignments", ["Land_Radar_F"]],
            ["staticAssignments", ["B_AAA_System_01_F"]], ["radarCount", 1],
            ["staticCount", 1], ["mobileCount", 0], ["fighterCount", 0],
            ["createMarkers", false], ["announce", false]
        ];
        private _created = [_config] call Waldo_fnc_DynamicAACreate;
        private _target = createVehicle ["B_Heli_Light_01_F", [_centre select 0, _centre select 1, 50], [], 0, "FLY"];
        _target allowDamage false;
        private _targetGroup = west createVehicleCrew _target;
        _target enableSimulationGlobal false;
        private _ground = createVehicle ["B_MRAP_01_F", _centre, [], 0, "NONE"];
        _ground allowDamage false;
        private _groundGroup = west createVehicleCrew _ground;
        _ground enableSimulationGlobal false;
        private _readState = {
            (missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap])
                getOrDefault [_id, createHashMap]
        };

        uiSleep 0.8;
        private _belowFloor = call _readState;
        private _belowClosed = !(_belowFloor getOrDefault ["detected", false])
            && {!(_belowFloor getOrDefault ["engaged", false])};

        _target setPosATL [(_centre select 0) + 750, _centre select 1, 200];
        uiSleep 0.8;
        private _detectionOnlyState = call _readState;
        private _detectionOnly = _detectionOnlyState getOrDefault ["detected", false]
            && {!(_detectionOnlyState getOrDefault ["engaged", false])};

        _target setPosATL [_centre select 0, _centre select 1, 200];
        uiSleep 0.8;
        private _insideState = call _readState;
        private _insideEngaged = _insideState getOrDefault ["detected", false]
            && {_insideState getOrDefault ["engaged", false]};
        private _activeDefenceGroups = _insideState getOrDefault ["defenceGroups", []];
        private _groundNotEngaged = _activeDefenceGroups findIf {
            private _units = units _x;
            _units findIf {
                private _selectedTarget = assignedTarget _x;
                _selectedTarget == _ground
            } >= 0
        } < 0;
        private _autoTargetClosed = _activeDefenceGroups findIf {
            private _units = units _x;
            _units findIf {_x checkAIFeature "AUTOTARGET"} >= 0
        } < 0;

        _target setPosATL [_centre select 0, _centre select 1, 350];
        uiSleep 0.8;
        private _aboveState = call _readState;
        private _aboveClosed = !(_aboveState getOrDefault ["detected", false])
            && {!(_aboveState getOrDefault ["engaged", false])};
        private _defenceGroups = _aboveState getOrDefault ["defenceGroups", []];
        private _closedOnOwners = _defenceGroups findIf {
            private _units = units _x;
            _units findIf {
                private _unit = _x;
                !(vehicle _unit isKindOf "Air") && {_unit checkAIFeature "MOVE"}
            } >= 0
        } < 0;

        [
            "core/dynamic-aa/envelope-and-locality",
            _created && {_belowClosed} && {_detectionOnly} && {_insideEngaged}
                && {_groundNotEngaged} && {_autoTargetClosed} && {_aboveClosed} && {_closedOnOwners},
            [_created, _belowClosed, _detectionOnly, _insideEngaged, _groundNotEngaged, _autoTargetClosed, _aboveClosed, _closedOnOwners]
        ] call Waldo_QA_fnc_assert;

        [_id, true] call Waldo_fnc_DynamicAADestroy;
        {deleteVehicle _x} forEach crew _target;
        {deleteVehicle _x} forEach crew _ground;
        deleteVehicle _target;
        deleteVehicle _ground;
        if (!isNull _targetGroup) then {_targetGroup deleteGroupWhenEmpty true};
        if (!isNull _groundGroup) then {_groundGroup deleteGroupWhenEmpty true};
    }] call Waldo_QA_fnc_case;

    ["core/diagnostics/clean", {
        private _clientReadyDeadline = diag_tickTime + 60;
        waitUntil {
            uiSleep 0.1;
            (count allPlayers > 0 && {allPlayers findIf {!(_x getVariable ["Waldo_QA_FeatureRangeClientReady", false])} < 0})
            || {diag_tickTime >= _clientReadyDeadline}
        };
        private _previousDeadline = diag_tickTime + 15;
        waitUntil {
            uiSleep 0.1;
            !(missionNamespace getVariable ["Waldo_Diagnostics_Running", false])
            || {diag_tickTime >= _previousDeadline}
        };
        private _runAvailable = !(missionNamespace getVariable ["Waldo_Diagnostics_Running", false]);
        if (_runAvailable) then {[] call Waldo_fnc_RunDiagnostics;};
        private _result = missionNamespace getVariable ["Waldo_Diagnostics_LastReport", []];
        private _shapeValid = count _result >= 5;
        private _serverChecks = if (_shapeValid) then {_result select 2} else {[]};
        private _clientReports = if (_shapeValid) then {_result select 3} else {[]};
        private _runId = if (_shapeValid) then {_result select 4} else {""};
        private _serverErrors = {_x param [2, "ERROR"] == "ERROR"} count _serverChecks;
        private _clientErrors = 0;
        {
            _clientErrors = _clientErrors + ({_x param [2, "ERROR"] == "ERROR"} count (_x param [3, []]));
        } forEach _clientReports;
        private _clientCoverage = (count allPlayers == 0) || {count _clientReports > 0};
        [
            "core/diagnostics/clean",
            _runAvailable && {_shapeValid} && {_runId != ""} && {_serverErrors == 0} && {_clientErrors == 0} && {_clientCoverage},
            [_runAvailable, _shapeValid, _runId, count _serverChecks, count _clientReports, _serverErrors, _clientErrors]
        ] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/logistics/mhq-vvd-authority", {
        private _mhq = missionNamespace getVariable ["Waldo_QA_MHQ", objNull];
        (missionNamespace getVariable ["Waldo_QA_VVD", []]) params [["_terminal", objNull], ["_pad", objNull]];
        private _mhqReady = !isNull _mhq
            && {_mhq getVariable ["Waldo_MHQ_ServerConfigured", false]}
            && {!(_mhq getVariable ["Waldo_MHQ_Status", true])}
            && {(count (_mhq getVariable ["Waldo_MHQ_DeployParts", []])) >= 6};
        private _vvdReady = !isNull _terminal && {!isNull _pad}
            && {_pad getVariable ["Waldo_VVD_ServerConfigured", false]}
            && {(_pad getVariable ["Waldo_VVD_Key", ""]) != ""};
        ["core/logistics/mhq-vvd-authority", _mhqReady && _vvdReady, [_mhqReady, _vvdReady, if (isNull _mhq) then {-1} else {count (_mhq getVariable ["Waldo_MHQ_DeployParts", []])}]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/logistics/vvd-lock-token", {
        private _deadline = diag_tickTime + 120;
        waitUntil {uiSleep 0.1; count allPlayers > 0 || {diag_tickTime >= _deadline}};
        private _actor = allPlayers param [0, objNull];
        private _pad = createVehicle ["Land_JumpTarget_F", [8, 125, 0], [], 0, "CAN_COLLIDE"];
        private _token = format ["QA_VVD_%1", diag_tickTime];
        _pad setVariable ["Waldo_VVD_OpenActor", _actor, true];
        _pad setVariable ["Waldo_VVD_OpenToken", _token, true];
        _pad setVariable ["Waldo_VVD_OpenUntil", serverTime + 30, true];
        private _wrongRejected = !([_pad, _actor, _token + "_STALE", "QA_STALE"] call Waldo_fnc_VVDReleaseOpenServer);
        private _stillLocked = (_pad getVariable ["Waldo_VVD_OpenToken", ""]) == _token;
        private _released = [_pad, _actor, _token, "QA_COMPLETE"] call Waldo_fnc_VVDReleaseOpenServer;
        private _cleared = (_pad getVariable ["Waldo_VVD_OpenToken", "MISSING"]) == ""
            && {isNull (_pad getVariable ["Waldo_VVD_OpenActor", objNull])};
        ["core/logistics/vvd-lock-token", !isNull _actor && {_wrongRejected} && {_stillLocked} && {_released} && {_cleared}, [!isNull _actor, _wrongRejected, _stillLocked, _released, _cleared]] call Waldo_QA_fnc_assert;
        deleteVehicle _pad;
    }] call Waldo_QA_fnc_case;

    ["core/markers/custom-3d", {
        private _anchor = createVehicle ["Land_CampingTable_F", [40, 120, 0], [], 0, "CAN_COLLIDE"];
        private _exactId = ["qa_runtime_marker_exact", [38, 120, 0], createHashMapFromArray [["text", "QA EXACT"]]] call Waldo_fnc_Create3DMarker;
        private _anchorId = ["qa_runtime_marker_anchor", _anchor, createHashMapFromArray [["text", "QA ANCHOR"]]] call Waldo_fnc_Create3DMarker;
        private _positionId = ["qa_runtime_marker_position", [42, 120, 0], createHashMapFromArray [["text", "QA POSITION"]]] call Waldo_fnc_Create3DMarker;
        private _registry = missionNamespace getVariable ["Waldo_3DMarker_Registry", []];
        private _created = {_x in (_registry apply {_x select 0})} count [_exactId, _anchorId, _positionId] == 3;
        private _removedExact = [_exactId] call Waldo_fnc_Remove3DMarker;
        private _removedAnchor = [_anchor] call Waldo_fnc_Remove3DMarker;
        private _removedPosition = [[42, 120, 0], 5] call Waldo_fnc_Remove3DMarker;
        private _remainingIds = (missionNamespace getVariable ["Waldo_3DMarker_Registry", []]) apply {_x select 0};
        private _clean = {_x in _remainingIds} count [_exactId, _anchorId, _positionId] == 0;
        ["core/markers/custom-3d", _created && {_removedExact} && {_removedAnchor} && {_removedPosition} && {_clean}, [_created, _removedExact, _removedAnchor, _removedPosition, _clean]] call Waldo_QA_fnc_assert;
        deleteVehicle _anchor;
    }] call Waldo_QA_fnc_case;

    ["core/loadout/unique-array", {
        private _actual = [["A", "B", "A", "EMPTY", "B"]] call Waldo_fnc_UniqueLoadoutArray;
        ["core/loadout/unique-array", _actual isEqualTo ["A", "B", "EMPTY"], _actual] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/objective/create-update", {
        ["qa_objective", west, "QA Objective", "Audit", [10, 10, 0], "ASSIGNED", true] call Waldo_fnc_CreateObjective;
        private _created = (missionNamespace getVariable ["Waldo_AAR_Tasks", []]) findIf {(_x select 0) == "qa_objective" && {(_x select 2) == "ASSIGNED"}} >= 0;
        ["qa_objective", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
        private _updated = (missionNamespace getVariable ["Waldo_AAR_Tasks", []]) findIf {(_x select 0) == "qa_objective" && {(_x select 2) == "SUCCEEDED"}} >= 0;
        ["core/objective/create-update", _created && _updated && {markerType "Waldo_obj_qa_objective" == ""}, [_created, _updated]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/safestart/activate-lift", {
        [true] call Waldo_fnc_SafeStart;
        private _on = missionNamespace getVariable ["Waldo_SafeStart_Active", false];
        [false] call Waldo_fnc_SafeStart;
        private _off = !(missionNamespace getVariable ["Waldo_SafeStart_Active", true]);
        ["core/safestart/activate-lift", _on && _off, [_on, _off]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/safestart/countdown-auto-lift", {
        [2] call Waldo_fnc_SafeStartTimer;
        uiSleep 3;
        private _active = missionNamespace getVariable ["Waldo_SafeStart_Active", true];
        private _reason = missionNamespace getVariable ["Waldo_SafeStart_LastReason", ""];
        private _endTime = missionNamespace getVariable ["Waldo_SafeStart_EndTime", -1];
        ["core/safestart/countdown-auto-lift", !_active && {_reason == "TIMER"} && {_endTime == 0}, [_active, _reason, _endTime]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/paradrop/settings", {
        missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180];
        missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350];
        missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310];
        private _valid = (missionNamespace getVariable "WALDO_STATIC_MINALTITUDE") < (missionNamespace getVariable "WALDO_STATIC_MAXALTITUDE");
        ["core/paradrop/settings", _valid, "Static-line thresholds ordered"] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/paradrop/helicopter-flight-stability", {
        private _testRows = [
            ["QA_PARADROP_HURON", "B_Heli_Transport_03_unarmed_F", [1800, 1800, 0]],
            ["QA_PARADROP_MOHAWK", "I_Heli_Transport_02_F", [5600, 1800, 0]]
        ];
        private _aircraft = [];
        private _created = true;
        {
            _x params ["_id", "_class", "_centre"];
            private _config = createHashMapFromArray [
                ["id", _id], ["name", _id], ["centre", _centre], ["direction", 0],
                ["side", west], ["aircraftClass", _class], ["altitude", 300],
                ["maximumSpeed", 300], ["lifecycle", "RETAIN"], ["createJumpers", false],
                ["createMarkers", false], ["notifyRequester", false], ["staticJumpEnabled", true]
            ];
            private _ok = [_config] call Waldo_fnc_ParadropCreateDropZone;
            private _registry = missionNamespace getVariable ["Waldo_Paradrop_DropZones", createHashMap];
            private _state = _registry getOrDefault [_id, createHashMap];
            private _helicopter = _state getOrDefault ["aircraft", objNull];
            _created = _created && {_ok} && {!isNull _helicopter};
            _aircraft pushBack [_id, _helicopter];
        } forEach _testRows;
        // Allow the helicopter-only FULL route policy to accelerate naturally. Helicopters do not
        // receive the fixed-wing path's instantaneous velocity injection because that produces the
        // nose-up altitude excursion this case is intended to catch.
        uiSleep 45;
        private _samples = _aircraft apply {
            _x params ["_id", "_helicopter"];
            [_id, !isNull _helicopter, alive _helicopter, if (isNull _helicopter) then {-1} else {(getPosATL _helicopter) select 2}, if (isNull _helicopter) then {0} else {speed _helicopter}]
        };
        private _stable = _samples findIf {
            !(_x select 1) || {!(_x select 2)} || {(_x select 3) < 180} || {(_x select 3) > 420}
            || {(_x select 4) < 250} || {(_x select 4) > 330}
        } < 0;
        ["core/paradrop/helicopter-flight-stability", _created && {_stable}, [_created, _samples]] call Waldo_QA_fnc_assert;
        {[_x select 0, true, objNull, false] call Waldo_fnc_ParadropRemoveDropZone;} forEach _aircraft;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "party"]) then {
    ["party/fixture/registered-table", {
        private _table = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
        ["party/fixture/registered-table", !isNull _table && {_table getVariable ["Waldo_MG_IsPartyTable", false]} && {_table in (missionNamespace getVariable ["Waldo_MG_Tables", []])}, if (isNull _table) then {"NULL"} else {netId _table}] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
    ["party/catalogue/twelve-games", {
        private _fixture = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
        if (!isNull _fixture) then {[_fixture] call Waldo_fnc_MiniGamesRegisterTable;};
        private _ids = Waldo_MG_Games apply {_x select 0};
        private _expected = ["battleship", "whoswho", "shotgun", "blackjack", "poker", "drawpoker", "liarsdice", "chess", "checkers", "connectfour", "rps", "uno"];
        ["party/catalogue/twelve-games", count _ids == 12 && {{_x in _ids} count _expected == 12}, _ids] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["party/authority/leave-active-new-games", {
        private _outcomes = [];
        {
            private _gameId = _x;
            private _group = createGroup [west, true];
            // Keep the synthetic leave actor on server owner 2 even when an HC or locality mod is
            // present. Its acknowledgement is test evidence and must never reach the playable client.
            _group setGroupOwner 2;
            private _unit = _group createUnit ["B_Soldier_F", [0, 115 + (_forEachIndex * 4), 0], [], 0, "NONE"];
            private _table = createVehicle ["Land_CampingTable_F", [4, 115 + (_forEachIndex * 4), 0], [], 0, "CAN_COLLIDE"];
            [_table, createHashMapFromArray [["displayName", "QA leave route"], ["games", [_gameId]]]] call Waldo_fnc_MiniGamesRegisterTable;
            _table setVariable ["Waldo_MG_TableSeats", [_unit, objNull, objNull, objNull], true];
            _unit setVariable ["Waldo_MG_SeatedTable", _table, true];
            _unit setVariable ["Waldo_MG_SeatIndex", 0, true];
            _unit setVariable ["Waldo_MG_SeatToken", format ["QA_%1", _gameId], true];
            switch (_gameId) do {
                case "drawpoker": {
                    _table setVariable ["Waldo_MG_DrawPokerActive", true, true];
                    _table setVariable ["Waldo_MG_DrawPokerPlayers", [_unit], true];
                    _table setVariable ["Waldo_MG_DrawPokerSeatIndices", [0], true];
                    _table setVariable ["Waldo_MG_DrawPokerHandsServer", [[]]];
                };
                case "liarsdice": {
                    _table setVariable ["Waldo_MG_LiarsDiceActive", true, true];
                    _table setVariable ["Waldo_MG_LiarsDicePlayers", [_unit], true];
                    _table setVariable ["Waldo_MG_LiarsDiceSeatIndices", [0], true];
                };
                case "connectfour": {
                    _table setVariable ["Waldo_MG_ConnectFourActive", true, true];
                    _table setVariable ["Waldo_MG_ConnectFourPlayers", [_unit, objNull], true];
                    _table setVariable ["Waldo_MG_ConnectFourSeatIndices", [0, -1], true];
                };
            };
            private _token = format ["QA_LEAVE_%1_%2", _gameId, diag_tickTime];
            [_unit, [_token, netId _table]] call Waldo_MG_fnc_processLeaveRequestServer;
            private _seatCleared = isNull (_unit getVariable ["Waldo_MG_SeatedTable", objNull]);
            private _rosterCleared = isNull (((_table getVariable ["Waldo_MG_TableSeats", []]) param [0, objNull]));
            private _gameCleared = !([_table] call Waldo_MG_fnc_isTableGameActive);
            _outcomes pushBack [_gameId, _seatCleared, _rosterCleared, _gameCleared, owner _unit == 2];
            deleteVehicle _unit;
            deleteVehicle _table;
            deleteGroup _group;
        } forEach ["drawpoker", "liarsdice", "connectfour"];
        private _failed = _outcomes select {!((_x select 1) && {(_x select 2)} && {(_x select 3)} && {(_x select 4)})};
        ["party/authority/leave-active-new-games", _failed isEqualTo [], _outcomes] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "interactions"]) then {
    ["interactions/authority/server-condition-rejection", {
        private _actor = allPlayers param [0, objNull];
        private _equipment = createVehicle ["Land_Laptop_unfolded_F", [0, 125, 0], [], 0, "CAN_COLLIDE"];
        _equipment setVariable ["Waldo_MG_Int_Active", true, true];
        _equipment setVariable ["Waldo_MG_Int_Consumed", false, true];
        _equipment setVariable ["Waldo_MG_InteractionState", "IDLE", true];
        _equipment setVariable ["Waldo_MG_Int_ChallengeId", "circuit"];
        _equipment setVariable ["Waldo_MG_Int_Distance", 500];
        _equipment setVariable ["Waldo_MG_Int_Condition", {false}];
        private _accepted = if (isNull _actor) then {false} else {[_equipment, _actor] call Waldo_fnc_MiniGameInteractionAcquireServer};
        private _state = _equipment getVariable ["Waldo_MG_InteractionState", "MISSING"];
        private _attempt = _equipment getVariable ["Waldo_MG_Int_AttemptId", ""];
        [
            "interactions/authority/server-condition-rejection",
            !isNull _actor && {!_accepted} && {_state == "IDLE"} && {_attempt == ""},
            [!isNull _actor, _accepted, _state, _attempt]
        ] call Waldo_QA_fnc_assert;
        deleteVehicle _equipment;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "economy"]) then {
    ["economy/resource/full-crate-consumed", {
        // Use a server-owned QA actor so the production notification endpoint is still exercised
        // without presenting an automated transaction to the player as a mission-start event.
        private _actorGroup = createGroup [west, true];
        private _actor = _actorGroup createUnit ["B_Soldier_F", [0, 92, 0], [], 0, "NONE"];
        private _before = ["WEST", "Money"] call Waldo_fnc_EcoResource_getSideResourceAmount;
        private _crate = createVehicle ["Land_PlasticCase_01_medium_F", [0, 90, 0], [], 0, "CAN_COLLIDE"];
        _crate setVariable ["WaldoEcoResource_IsResourceCrate", true, true];
        _crate setVariable ["WaldoEcoResource_Collected", false, true];
        _crate setVariable ["WaldoEcoResource_ResourceRows", [["Money", 1]], true];
        [_crate, _actor] call Waldo_fnc_EcoResource_collectCrate;
        private _deleteDeadline = diag_tickTime + 2;
        waitUntil {uiSleep 0.05; isNull _crate || {diag_tickTime >= _deleteDeadline}};
        private _deleted = isNull _crate;
        ["WEST", "Money", _before, "QA RESTORE"] call Waldo_fnc_EcoResource_setSideResourceAmount;
        ["economy/resource/full-crate-consumed", !isNull _actor && {_deleted}, [!isNull _actor, _deleted]] call Waldo_QA_fnc_assert;
        if (!isNull _crate) then {deleteVehicle _crate;};
        deleteVehicle _actor;
        deleteGroup _actorGroup;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "ew"]) then {
    ["ew/registry/create-update-toggle-remove", {
        // Preserve the live range fixture. The test must not remove equipment the player audits.
        private _savedRegistry = +(missionNamespace getVariable ["Waldo_Jamming_Registry", []]);
        missionNamespace setVariable ["Waldo_Jamming_Registry", [], true];
        private _source = createVehicle ["Land_TTowerSmall_1_F", [30, 0, 0], [], 0, "NONE"];
        private _id = [_source, 300, "ALL"] call Waldo_fnc_Jammer;
        private _created = count (missionNamespace getVariable ["Waldo_Jamming_Registry", []]) == 1;
        [_id, false] call Waldo_fnc_JammerToggle;
        private _disabled = !(((missionNamespace getVariable ["Waldo_Jamming_Registry", []]) select 0) select 7);
        [_id] call Waldo_fnc_JammerRemove;
        private _removed = (missionNamespace getVariable ["Waldo_Jamming_Registry", []]) isEqualTo [];
        deleteVehicle _source;
        missionNamespace setVariable ["Waldo_Jamming_Registry", _savedRegistry, true];
        ["ew/registry/create-update-toggle-remove", _created && _disabled && _removed, [_created, _disabled, _removed, _id]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

private _passed = call Waldo_QA_fnc_complete;
missionNamespace setVariable ["Waldo_QA_ServerComplete", [_passed, missionNamespace getVariable ["Waldo_QA_LocalResults", []]], true];
if (!isMultiplayer) then {uiSleep 0.5; if (_passed) then {endMission "END1"} else {endMission "LOSER"};};
