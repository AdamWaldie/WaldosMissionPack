/*
 * Author: WaldoTheWarfighter
 * Installs local controls, labels and player-facing fixtures for the ongoing full-pack audit.
 * The client explicitly requests its dedicated curator assignment after server readiness so a
 * playable slot transferred from server AI to a human does not retain the server-owned assignment.
 * Repeat guards prevent duplicate actions during JIP or local script restarts.
 *
 * Arguments: none (executed from auditInitPlayerLocal.sqf).
 * Return Value: nothing.
 *
 * Example: [] execVM "featureRangeClient.sqf";
 * Current callers: the generated full-pack audit mission on every player client and JIP.
 */
if (!hasInterface) exitWith {};
Waldo_QA_fnc_curatorAssignmentConfirmedClient = {
    params [
        ["_curator", objNull, [objNull]],
        ["_openInterface", false, [false]]
    ];
    if (!hasInterface) exitWith {};
    [_curator, _openInterface] spawn {
        params ["_curator", "_openInterface"];
        private _deadline = diag_tickTime + 10;
        waitUntil {
            uiSleep 0.1;
            isNull player
            || {(!isNull _curator && {getAssignedCuratorLogic player isEqualTo _curator})}
            || {diag_tickTime >= _deadline}
        };
        if (isNull player || {isNull _curator} || {!(getAssignedCuratorLogic player isEqualTo _curator)}) exitWith {
            diag_log format ["WMP FULL AUDIT ZEUS CLIENT FAIL: no curator received by %1 (%2)", profileName, clientOwner];
        };
        diag_log format ["WMP FULL AUDIT ZEUS CLIENT READY: %1 (%2) curator=%3", profileName, clientOwner, netId _curator];
        if (_openInterface) then {openCuratorInterface};
    };
};
waitUntil {uiSleep 0.1; !isNull player && {missionNamespace getVariable ["Waldo_QA_FeatureRangeReady", false]}};
// The slot may have existed as server-local playable AI when the range became ready. Requesting
// from the owning interface after transfer is the authoritative point at which Zeus can be bound.
[player, false] remoteExecCall ["Waldo_QA_fnc_assignCuratorServer", 2];
if (missionNamespace getVariable ["Waldo_QA_FeatureRangeClientReady", false]) exitWith {};
if (missionNamespace getVariable ["Waldo_QA_FeatureRangeClientStarting", false]) exitWith {};
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientStarting", true];

// MiniGames, Economy, jamming and core ZEN modules were installed by the real
// release init.sqf. The range must never start them a second time.

// Exhaustive public-function directory. The mission provides real fixtures for public
// player workflows and assigns lower-level helpers to the same physical subsystem station.
// Opening the diary is opt-in and creates no persistent HUD.
if !(player diarySubjectExists "WMP_FUNCTIONS") then {
    player createDiarySubject ["WMP_FUNCTIONS", "WMP Function Stations"];
    {
        _x params ["_id", "_title", "_position", "_description", "_functions"];
        private _functionText = if (_functions isEqualTo []) then {
            "No registered public functions."
        } else {
            (_functions apply {format ["<br/>%1", _x]}) joinString ""
        };
        player createDiaryRecord [
            "WMP_FUNCTIONS",
            [_title, format ["<font size='16'>%1</font><br/><br/>Station: %2<br/>Coverage: %3 function(s).%4", _description, mapGridPosition _position, count _functions, _functionText]]
        ];

        private _variableId = (_id splitString "-") joinString "_";
        private _stationConsole = missionNamespace getVariable [format ["qa_sign_%1", _variableId], objNull];
        if (!isNull _stationConsole) then {
            private _aceAvailable = isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
                && {!(isNil "ace_interact_menu_fnc_createAction")};
            if (_aceAvailable) then {
                private _action = [
                    format ["Waldo_QA_FunctionStation_%1", _variableId],
                    format ["Review %1 Functions (%2)", _title, count _functions],
                    "",
                    {openMap true;},
                    {true}
                ] call ace_interact_menu_fnc_createAction;
                [_stationConsole, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
            } else {
                _stationConsole addAction [
                    format ["Review %1 Functions (%2)", _title, count _functions],
                    {openMap true;}, [], 1.5, true, true, "", "true", 4
                ];
            };
        };
        uiSleep 0.01;
    } forEach (missionNamespace getVariable ["Waldo_QA_FunctionStations", []]);
};

// Dynamic interaction equipment must install its local ACE action (or vanilla fallback)
// on every joining client, while authoritative state/callbacks remain on the server.
{
    private _object = _x;
    if (!isNull _object && {!(_object getVariable ["Waldo_QA_InteractionLocalReady", false])}) then {
        _object setVariable ["Waldo_QA_InteractionLocalReady", true];
        (_object getVariable ["Waldo_QA_InteractionDefinition", []]) params [
            ["_challengeId", "wirecut"],
            ["_difficulty", "standard"],
            ["_equipmentTitle", "FIELD EQUIPMENT"]
        ];
        private _options = createHashMapFromArray [
            ["difficulty", _difficulty],
            ["repeatable", true],
            ["retryOnFailure", true],
            ["actionTitle", format ["Operate %1 (%2)", _equipmentTitle, toUpper _difficulty]],
            ["title", format ["%1 / %2", _equipmentTitle, toUpper _difficulty]]
        ];
        [_object, _challengeId, _options] call Waldo_fnc_MiniGameInteractionSetup;

        // These follow-up actions prove a mission can gate subsequent interactions on the
        // authoritative outcome. Both discoverability surfaces read the same published state.
        private _aceAvailable = isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
            && {!(isNil "ace_interact_menu_fnc_createAction")};
        if (_aceAvailable && {!(_object getVariable ["Waldo_QA_ResultACEInstalled", false])}) then {
            private _resultAction = [
                format ["Waldo_QA_Result_%1", _challengeId],
                "Read Procedure Result",
                "",
                {
                    private _result = [(_this select 0)] call Waldo_fnc_MiniGameInteractionGetResult;
                    [format ["%1: %2 - %3", _result get "state", _result get "outcomeCode", _result get "reason"], if ((_result get "state") == "SUCCESS") then {"OK"} else {"ERROR"}, 6] call Waldo_fnc_MiniGameInteractionNotifyClient;
                },
                {
                    params ["_target"];
                    private _state = [_target] call Waldo_fnc_MiniGameInteractionGetState;
                    _state in ["SUCCESS", "FAILURE"]
                }
            ] call ace_interact_menu_fnc_createAction;
            [_object, 0, ["ACE_MainActions"], _resultAction] call ace_interact_menu_fnc_addActionToObject;
            _object setVariable ["Waldo_QA_ResultACEInstalled", true];
        };
        if !(_object getVariable ["Waldo_QA_ResultVanillaInstalled", false]) then {
            private _resultActionId = _object addAction [
                "Read Procedure Result",
                {
                    private _result = [(_this select 0)] call Waldo_fnc_MiniGameInteractionGetResult;
                    [format ["%1: %2 - %3", _result get "state", _result get "outcomeCode", _result get "reason"], if ((_result get "state") == "SUCCESS") then {"OK"} else {"ERROR"}, 6] call Waldo_fnc_MiniGameInteractionNotifyClient;
                },
                [], 1.4, true, true, "",
                "([_target] call Waldo_fnc_MiniGameInteractionGetState) in ['SUCCESS','FAILURE']",
                4
            ];
            _object setVariable ["Waldo_QA_ResultVanillaInstalled", _resultActionId >= 0];
        };
        uiSleep 0.01;
    };
} forEach (missionNamespace getVariable ["Waldo_QA_InteractionObjects", []]);

// The live bomb uses its purpose-built wrapper on every client and can be rearmed.
Waldo_QA_fnc_setupBombLocal = {
    params [["_bomb", objNull]];
    if (isNull _bomb || {_bomb getVariable ["Waldo_QA_BombLocalReady", false]}) exitWith {};
    _bomb setVariable ["Waldo_QA_BombLocalReady", true];
    [_bomb, [["title", "Defuse Live Training Charge"], ["wireCount", 5], ["timeLimit", 30], ["detonateOnFailure", true], ["oneShot", false]]]
        call Waldo_fnc_BombDefuseSetup;
};
private _bomb = missionNamespace getVariable ["Waldo_QA_LiveBomb", objNull];
[_bomb] call Waldo_QA_fnc_setupBombLocal;

// Party table B also exposes all equipment procedures without entering party-game state.
{
    [_x] call Waldo_fnc_MiniGameInteractionTableSetup;
} forEach (missionNamespace getVariable ["Waldo_QA_PartyTables", []]);

// Production local setup paths for earlier PR features.
private _savePoint = missionNamespace getVariable ["Waldo_QA_LoadoutSave", objNull];
if (!isNull _savePoint) then {[_savePoint] call Waldo_fnc_ZenAddLoadoutSaveAction;};

private _mhq = missionNamespace getVariable ["Waldo_QA_MHQ", objNull];
if (!isNull _mhq) then {[_mhq, true, true, 180, 5] call Waldo_fnc_MHQSetup;};

(missionNamespace getVariable ["Waldo_QA_VVD", []]) params [["_vvdLaptop", objNull], ["_vvdPad", objNull]];
if (!isNull _vvdLaptop && {!isNull _vvdPad}) then {
    [_vvdLaptop, _vvdPad, ["All"], ["ALL"], false, false, false, 10, ""] call Waldo_fnc_VVDInit;
};

(missionNamespace getVariable ["Waldo_QA_Paradrop", []]) params [["_dropFlag", objNull], ["_dropAircraft", objNull]];
if (!isNull _dropAircraft) then {[_dropAircraft] call Waldo_fnc_VehicleJumpSetup;};
if (!isNull _dropFlag && {!isNull _dropAircraft}) then {
    [_dropFlag, _dropAircraft, "QA DROP AIRCRAFT"] call Waldo_fnc_MoveInCargoPlane;
};

// Audit controls follow the same ACE-first contract as production interactions.
Waldo_QA_fnc_addAuditActionLocal = {
    params ["_target", "_id", "_title", "_statement", ["_arguments", []], ["_forceVanilla", false]];
    _forceVanilla = _forceVanilla || {
        _target in [
            missionNamespace getVariable ["Waldo_QA_ControlConsole", objNull],
            missionNamespace getVariable ["Waldo_QA_CoreConsole", objNull],
            missionNamespace getVariable ["Waldo_QA_ACREConsole", objNull]
        ]
    };
    private _aceAvailable = isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
        && {!(isNil "ace_interact_menu_fnc_createAction")};
    if (_aceAvailable && {!_forceVanilla}) exitWith {
        private _action = [
            _id,
            _title,
            "",
            {
                params ["_target", "_actor", "_params"];
                _params params ["_statement", "_arguments"];
                [_target, _actor, _arguments] call _statement;
            },
            {true},
            {},
            [_statement, _arguments]
        ] call ace_interact_menu_fnc_createAction;
        [_target, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
        diag_log format ["WMP QA CONTROL INSTALLED: id=%1 mode=ACE target=%2", _id, netId _target];
        true
    };
    private _actionId = _target addAction [
        _title,
        {
            params ["_target", "_actor", "_actionId", "_params"];
            _params params ["_statement", "_arguments"];
            [_target, _actor, _arguments] call _statement;
        },
        [_statement, _arguments],
        1.5,
        false,
        true,
        "",
        "true",
        4
    ];
    diag_log format ["WMP QA CONTROL INSTALLED: id=%1 mode=ADD_ACTION target=%2 action=%3", _id, netId _target, _actionId];
    _actionId >= 0
};

// Central control console: navigation is local; state changes are sent to server authority.
private _console = missionNamespace getVariable ["Waldo_QA_ControlConsole", objNull];
if (!isNull _console) then {
    {
        _x params ["_id", "_title", "_position", "_description"];
        [_console, format ["Waldo_QA_GoTo_%1", _id], format ["GO TO: %1", _title], {
            params ["_target", "_actor", "_position"];
            _actor setPosATL (_position vectorAdd [0, -3, 0]);
        }, _position, true] call Waldo_QA_fnc_addAuditActionLocal;
    } forEach (missionNamespace getVariable ["Waldo_QA_FeatureStations", []]);
    [_console, "Waldo_QA_ResetParty", "RESET PARTY TABLES", {[] remoteExecCall ["Waldo_QA_fnc_resetPartyTablesServer", 2];}, [], true] call Waldo_QA_fnc_addAuditActionLocal;
    [_console, "Waldo_QA_ResetInteractions", "RESET ALL INTERACTIONS", {[] remoteExecCall ["Waldo_QA_fnc_resetInteractionsServer", 2];}, [], true] call Waldo_QA_fnc_addAuditActionLocal;
    [_console, "Waldo_QA_RearmEOD", "REARM LIVE EOD CHARGE", {[] remoteExecCall ["Waldo_QA_fnc_rearmBombServer", 2];}, [], true] call Waldo_QA_fnc_addAuditActionLocal;
    [_console, "Waldo_QA_ResetEconomy", "RESET ECONOMY FIXTURES + RESOURCES", {[] remoteExecCall ["Waldo_QA_fnc_resetEconomyFixturesServer", 2];}, [], true] call Waldo_QA_fnc_addAuditActionLocal;
    [_console, "Waldo_QA_TriggerEMP", "TRIGGER EW EMP TEST", {[] remoteExecCall ["Waldo_QA_fnc_triggerEMPServer", 2];}, [], true] call Waldo_QA_fnc_addAuditActionLocal;
};

private _coreConsole = missionNamespace getVariable ["Waldo_QA_CoreConsole", objNull];
if (!isNull _coreConsole) then {
    [_coreConsole, "Waldo_QA_AssignZeus", "ASSIGN / OPEN ZEUS", {
        params ["_target", "_actor"];
        [_actor, true] remoteExecCall ["Waldo_QA_fnc_assignCuratorServer", 2];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_ModStatus", "SHOW REQUIRED MOD STATUS", {
        private _checks = [
            ["CBA", "cba_main"],
            ["ACE", "ace_main"],
            ["ZEN", "zen_main"],
            ["ZEN ADVANCED WAYPOINTS", "zen_ai"],
            ["ACRE2", "acre_main"]
        ];
        private _missing = [];
        private _loaded = [];
        {
            if (isClass (configFile >> "CfgPatches" >> (_x select 1))) then {
                _loaded pushBack (_x select 0);
            } else {
                _missing pushBack (_x select 0);
            };
        } forEach _checks;
        private _wmpZenCount = missionNamespace getVariable ["Waldo_ZenModuleCount", 0];
        private _wmpZenReady = missionNamespace getVariable ["Waldo_ZenModulesReady", false] && {_wmpZenCount == 42};
        if (_wmpZenReady) then {
            _loaded pushBack format ["WMP ZEN MODULES (%1)", _wmpZenCount];
        } else {
            _missing pushBack format ["WMP ZEN MODULE REGISTRATION (%1/42)", _wmpZenCount];
        };
        private _message = if (_missing isEqualTo []) then {
            format ["REQUIRED MODS LOADED: %1", _loaded joinString ", "]
        } else {
            format ["MISSING REQUIRED MODS: %1", _missing joinString ", "]
        };
        [_message, if (_missing isEqualTo []) then {"OK"} else {"ERROR"}, 8] call Waldo_fnc_MiniGameInteractionNotifyClient;
        diag_log format ["[WMP QA] %1", _message];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    private _acreConsole = missionNamespace getVariable ["Waldo_QA_ACREConsole", objNull];
    if (isNull _acreConsole) then {_acreConsole = _coreConsole};
    [_acreConsole, "Waldo_QA_ACREStatus", "ACRE2: SHOW PLAN / RADIO STATUS", {
        if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {
            ["ACRE2 is not loaded on this client.", "ERROR", 8] call Waldo_fnc_MiniGameInteractionNotifyClient;
        };
        private _plan = missionNamespace getVariable ["Waldo_ACRE2_Plan", []];
        private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
        private _application = uiNamespace getVariable ["Waldo_ACRE2_LastApplication", []];
        private _message = format ["Plan revision %1 | group %2 | ordered radios %3 | application %4", if (count _plan > 1) then {_plan select 1} else {-1}, groupId group player, _radios, _application];
        [_message, "OK", 10] call Waldo_fnc_MiniGameInteractionNotifyClient;
        diag_log format ["[WMP QA ACRE] %1 plan=%2", _message, _plan];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACRESquadMatrix", "ACRE2: SHOW SQUAD RADIO PAIRS", {
        private _matrix = [
            "Commander + Medic: 2x PRC-343, 2x PRC-152, 1x PRC-148",
            "Anti-Tank + Engineer: PRC-117F, BF-888S, SEM52SL, PRC-77, SEM70",
            "Marksman: PRC-343 + PRC-117F (bridges both pairs)"
        ];
        [format ["%1 | %2 | %3", _matrix select 0, _matrix select 1, _matrix select 2], "INFO", 18] call Waldo_fnc_MiniGameInteractionNotifyClient;
        diag_log format ["[WMP QA ACRE SQUAD MATRIX] player=%1 role=%2 distribution=%3", name player, roleDescription player, _matrix];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREApply", "ACRE2: REAPPLY PLAN + BABEL + CEOI", {
        private _radioResult = [true, "QA"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
        private _babelResult = [] call Waldo_fnc_ACRE2ApplyBabel;
        private _ceoiResult = [] call Waldo_fnc_ACRE2BuildCEOI;
        [format ["Radio %1 | Babel %2 | CEOI %3", _radioResult, _babelResult, _ceoiResult], if (_radioResult && {_ceoiResult}) then {"OK"} else {"ERROR"}, 10] call Waldo_fnc_MiniGameInteractionNotifyClient;
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREProvision", "ACRE2: PROVISION CARRIED TEST RADIOS", {
        if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {
            ["ACRE2 is not loaded on this client.", "ERROR", 8] call Waldo_fnc_MiniGameInteractionNotifyClient;
        };
        {
            _x params ["_radioClass", "_required"];
            private _present = {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _radioClass} count ([] call Waldo_fnc_ACRE2GetOrderedRadios);
            if (_present < _required) then {
                for "_index" from (_present + 1) to _required do {player addItem _radioClass};
            };
        } forEach [["ACRE_PRC343", 2], ["ACRE_PRC152", 2], ["ACRE_PRC148", 1]];
        [] spawn {
            uiSleep 2;
            [true, "QA_PROVISION"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
            [] call Waldo_fnc_ACRE2BuildCEOI;
            ["Two PRC-343s and two PRC-152s were requested. Inspect both ears and channels, then run duplicate verification.", "OK", 12] call Waldo_fnc_MiniGameInteractionNotifyClient;
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREDuplicates", "ACRE2: VERIFY DUPLICATE RADIO ASSIGNMENTS", {
        private _ordered = [] call Waldo_fnc_ACRE2GetOrderedRadios;
        private _checks = [
            ["ACRE_PRC343", 1, 109, "LEFT"],
            ["ACRE_PRC343", 2, 182, "RIGHT"],
            ["ACRE_PRC152", 1, 8, "RIGHT"],
            ["ACRE_PRC152", 2, 11, "LEFT"],
            ["ACRE_PRC148", 1, 9, "CENTER"]
        ];
        private _failures = [];
        {
            _x params ["_base", "_occurrence", "_channel", "_spatial"];
            private _matching = _ordered select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
            if (count _matching < _occurrence) then {
                _failures pushBack format ["missing %1 #%2", _base, _occurrence];
            } else {
                private _id = _matching select (_occurrence - 1);
                if (([_id] call acre_api_fnc_getRadioChannel) != _channel || {([_id] call acre_api_fnc_getRadioSpatial) != _spatial}) then {
                    _failures pushBack format ["%1 #%2 expected channel %3/%4", _base, _occurrence, _channel, _spatial];
                };
            };
        } forEach _checks;
        private _ok = count _failures == 0;
        [if (_ok) then {"Radios verified: 343 B7/C13 LEFT, 343 B12/C6 RIGHT, 152 C8 RIGHT, 152 C11 LEFT and 148 C9 BOTH."} else {_failures joinString "; "}, if (_ok) then {"OK"} else {"ERROR"}, 12] call Waldo_fnc_MiniGameInteractionNotifyClient;
        diag_log format ["[WMP QA ACRE DUPLICATES] success=%1 failures=%2 radios=%3", _ok, _failures, _ordered];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREAdditionalChannels", "ACRE2: TEST 117F / BF-888S / SEM52SL", {
        if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {
            ["ACRE2 is not loaded on this client.", "ERROR", 8] call Waldo_fnc_MiniGameInteractionNotifyClient;
        };
        {
            private _base = _x;
            private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
            if (count _matching == 0) then {player addItemToBackpack _base};
        } forEach ["ACRE_PRC117F", "ACRE_BF888S", "ACRE_SEM52SL"];
        [] spawn {
            uiSleep 2;
            private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
            private _savedOverrides = +(_config getOrDefault ["radioOverrides", []]);
            _config set ["radioOverrides", [[["VARIABLE", vehicleVarName player], [
                ["ACRE_PRC117F", 1, 7, "BOTH"],
                ["ACRE_BF888S", 1, 14, "RIGHT"],
                ["ACRE_SEM52SL", 1, 12, "LEFT"]
            ]]]];
            private _result = [true, "QA_ADDITIONAL_CHANNEL_PROFILES"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
            _config set ["radioOverrides", _savedOverrides];
            private _ordered = [] call Waldo_fnc_ACRE2GetOrderedRadios;
            private _failures = [];
            {
                _x params ["_base", "_channel", "_ear"];
                private _matching = _ordered select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == _base};
                if (count _matching == 0) then {
                    _failures pushBack format ["missing %1", _base];
                } else {
                    private _id = _matching select 0;
                    if (([_id] call acre_api_fnc_getRadioChannel) != _channel || {([_id] call acre_api_fnc_getRadioSpatial) != _ear}) then {
                        _failures pushBack format ["%1 expected C%2/%3", _base, _channel, _ear];
                    };
                };
            } forEach [["ACRE_PRC117F", 7, "CENTER"], ["ACRE_BF888S", 14, "RIGHT"], ["ACRE_SEM52SL", 12, "LEFT"]];
            private _ok = _result && {count _failures == 0};
            [if (_ok) then {"PRC-117F C7 BOTH, BF-888S C14 RIGHT and SEM52SL C12 LEFT verified."} else {_failures joinString "; "}, if (_ok) then {"OK"} else {"ERROR"}, 12] call Waldo_fnc_MiniGameInteractionNotifyClient;
            diag_log format ["[WMP QA ACRE ADDITIONAL CHANNELS] success=%1 failures=%2 radios=%3", _ok, _failures, _ordered];
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACRERoundTrip", "ACRE2: EXERCISE PERSISTED RADIO STATE", {
        private _state = [] call Waldo_fnc_ACRE2CaptureRadioState;
        private _ordered = [] call Waldo_fnc_ACRE2GetOrderedRadios;
        {
            [_x, 1] call acre_api_fnc_setRadioChannel;
            [_x, "CENTER"] call acre_api_fnc_setRadioSpatial;
            [_x, 0.35] call acre_api_fnc_setRadioVolume;
        } forEach _ordered;
        private _generation = (missionNamespace getVariable ["Waldo_ACRE2_LoadoutGeneration", 0]) + 1;
        missionNamespace setVariable ["Waldo_ACRE2_LoadoutGeneration", _generation];
        [_state, _generation] spawn {
            params ["_saved", "_generation"];
            private _restored = [_saved, _generation] call Waldo_fnc_ACRE2ApplyRadioState;
            [format ["Persisted radio state round trip: %1. Alternate PTT was deliberately untouched.", _restored], if (_restored) then {"OK"} else {"ERROR"}, 12] call Waldo_fnc_MiniGameInteractionNotifyClient;
            diag_log format ["[WMP QA ACRE PERSISTENCE] success=%1 state=%2", _restored, _saved];
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREPreserveExtra", "ACRE2: VERIFY EXTRA RADIO PRESERVATION", {
        private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == "ACRE_PRC343"};
        if (count _matching < 3) then {player addItem "ACRE_PRC343"};
        [] spawn {
            uiSleep 2;
            private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == "ACRE_PRC343"};
            if (count _matching < 3) exitWith {["A third PRC-343 could not be added to the inventory.", "ERROR", 10] call Waldo_fnc_MiniGameInteractionNotifyClient};
            private _extra = _matching select 2;
            [_extra, 10] call acre_api_fnc_setRadioChannel;
            [_extra, "CENTER"] call acre_api_fnc_setRadioSpatial;
            [true, "QA_EXTRA_PRESERVATION"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
            private _preserved = ([_extra] call acre_api_fnc_getRadioChannel) == 10 && {([_extra] call acre_api_fnc_getRadioSpatial) == "CENTER"};
            [format ["Unlisted third PRC-343 preserved: %1.", _preserved], if (_preserved) then {"OK"} else {"ERROR"}, 10] call Waldo_fnc_MiniGameInteractionNotifyClient;
            diag_log format ["[WMP QA ACRE EXTRA] success=%1 radio=%2", _preserved, _extra];
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREFrequency", "ACRE2: TEST PRC-77 FREQUENCY PROFILE", {
        private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == "ACRE_PRC77"};
        if (count _matching == 0) then {player addItemToBackpack "ACRE_PRC77"};
        [] spawn {
            uiSleep 2;
            private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == "ACRE_PRC77"};
            if (count _matching == 0) exitWith {["The PRC-77 requires free backpack capacity; no radio was added.", "ERROR", 10] call Waldo_fnc_MiniGameInteractionNotifyClient};
            private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
            private _savedOverrides = +(_config getOrDefault ["radioOverrides", []]);
            _config set ["radioOverrides", [[["VARIABLE", vehicleVarName player], [["ACRE_PRC77", 1, 31.15, "BOTH"]]]]];
            private _result = [true, "QA_FREQUENCY"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
            _config set ["radioOverrides", _savedOverrides];
            [format ["PRC-77 31.15 MHz setup accepted: %1. Confirm 31.15 and both-ear audio on the physical interface.", _result], if (_result) then {"OK"} else {"ERROR"}, 14] call Waldo_fnc_MiniGameInteractionNotifyClient;
            diag_log format ["[WMP QA ACRE FREQUENCY] success=%1 radio=%2", _result, _matching select 0];
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACREFrequencySem70", "ACRE2: TEST SEM70 FREQUENCY PROFILE", {
        private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == "ACRE_SEM70"};
        if (count _matching == 0) then {player addItemToBackpack "ACRE_SEM70"};
        [] spawn {
            uiSleep 2;
            private _matching = ([] call Waldo_fnc_ACRE2GetOrderedRadios) select {toUpper ([_x] call acre_api_fnc_getBaseRadio) == "ACRE_SEM70"};
            if (count _matching == 0) exitWith {["The SEM70 requires free backpack capacity; remove the PRC-77 or another manpack first.", "ERROR", 12] call Waldo_fnc_MiniGameInteractionNotifyClient};
            private _config = missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap];
            private _savedOverrides = +(_config getOrDefault ["radioOverrides", []]);
            _config set ["radioOverrides", [[["VARIABLE", vehicleVarName player], [["ACRE_SEM70", 1, 34.075, "BOTH"]]]]];
            private _result = [true, "QA_FREQUENCY_SEM70"] call Waldo_fnc_ACRE2ApplyPlayerPlan;
            _config set ["radioOverrides", _savedOverrides];
            [format ["SEM70 34.075 MHz setup accepted: %1. Confirm 34.075 and both-ear audio on the physical interface.", _result], if (_result) then {"OK"} else {"ERROR"}, 14] call Waldo_fnc_MiniGameInteractionNotifyClient;
            diag_log format ["[WMP QA ACRE FREQUENCY SEM70] success=%1 radio=%2", _result, _matching select 0];
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_acreConsole, "Waldo_QA_ACRESave", "ACRE2: SAVE FILTERED RESPAWN LOADOUT", {
        [true] call Waldo_fnc_SaveLoadout;
        private _saved = missionNamespace getVariable ["Waldo_Player_Inventory", []];
        diag_log format ["[WMP QA ACRE] Filtered respawn loadout=%1", _saved];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_SafeStartOn", "ENABLE SAFESTART", {[true] remoteExecCall ["Waldo_QA_fnc_setSafeStartServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_SafeStartOff", "DISABLE SAFESTART", {[false] remoteExecCall ["Waldo_QA_fnc_setSafeStartServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_SafeStart30", "SAFESTART TIMER: 30 SECONDS", {[30] remoteExecCall ["Waldo_QA_fnc_startSafeStartTimerServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_SafeStart120", "SAFESTART TIMER: 2 MINUTES", {[120] remoteExecCall ["Waldo_QA_fnc_startSafeStartTimerServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_SafeStart300", "SAFESTART TIMER: 5 MINUTES", {[300] remoteExecCall ["Waldo_QA_fnc_startSafeStartTimerServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_Objective", "CREATE QA OBJECTIVE", {[] remoteExecCall ["Waldo_QA_fnc_createObjectiveServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_AARTarget", "RESET / RESPAWN AAR LIVE TARGET", {
        params ["_target", "_actor"];
        [_actor] remoteExecCall ["Waldo_QA_fnc_spawnAARTargetServer", 2];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_StartConvoy", "START / RESET CONVOY TEST", {
        [] remoteExecCall ["Waldo_QA_fnc_startConvoyServer", 2];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_StartParadrop", "ACTIVATE PARADROP AIRCRAFT", {
        [] remoteExecCall ["Waldo_QA_fnc_activateDropAircraftServer", 2];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_Endex", "RUN ENDEX + AAR (RESTART AFTER)", {[] remoteExecCall ["Waldo_QA_fnc_endexServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_EndexReset", "RESET ENDEX / RESUME AUDIT", {[] remoteExecCall ["Waldo_QA_fnc_resetEndexServer", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_Diagnostics", "RUN MISSION DIAGNOSTICS", {[] remoteExec ["Waldo_fnc_RunDiagnostics", 2];}] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_UiNotice", "SHOW CUSTOM WMP UI NOTICE", {
        ["UI SYSTEM READY", "Safe-zone card, semantic symbol, replacement channel and measured text padding are active.", "SUCCESS", 12, "TOP", "QA_UI", "WMP FULL PACK AUDIT"] call Waldo_fnc_ShowUiNotification;
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_UiQueue", "SHOW UI OVERFLOW / COALESCE TEST", {
        ["TOP-RIGHT ONE", "Independent channel one; fades first so the remaining cards visibly move up.", "INFO", 4, "TOP_RIGHT", "QA_STACK_1", "WMP UI QA"] call Waldo_fnc_ShowUiNotification;
        ["TOP-RIGHT TWO", "Independent channel two; moves into the first slot after channel one fades.", "SUCCESS", 8, "TOP_RIGHT", "QA_STACK_2", "WMP UI QA"] call Waldo_fnc_ShowUiNotification;
        ["TOP-RIGHT THREE", "Independent channel three; moves upward until the stack is gone.", "WARNING", 12, "TOP_RIGHT", "QA_STACK_3", "WMP UI QA"] call Waldo_fnc_ShowUiNotification;
        ["OVERFLOW REGION", "This fourth channel should use the next configured screen region.", "INFO", 8, "TOP_RIGHT", "QA_STACK_4", "WMP UI QA"] call Waldo_fnc_ShowUiNotification;
        for "_index" from 1 to 25 do {
            ["SPAM COALESCING", format ["Pending update %1 of 25. Only the newest pending update should survive.", _index], "INFO", 4, "TOP_RIGHT", "QA_SPAM", "WMP UI QA"] call Waldo_fnc_ShowUiNotification;
        };
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_UiPositions", "SHOW ALL UI POSITIONS", {
        [] call Waldo_fnc_ClearUiPanels;
        {
            _x params ["_placement", "_title", "_channel"];
            [_title, format ["First-class %1 placement with safe-zone sizing and stack reflow.", _placement], "INFO", 12, _placement, _channel, "WMP UI POSITION QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
        } forEach [
            ["TOP", "TOP", "QA_POSITION_TOP"],
            ["TOP_RIGHT", "TOP RIGHT", "QA_POSITION_TOP_RIGHT"],
            ["CENTER", "CENTER", "QA_POSITION_CENTER"],
            ["BOTTOM_LEFT", "BOTTOM LEFT", "QA_POSITION_BOTTOM_LEFT"],
            ["BOTTOM_CENTER", "BOTTOM CENTER", "QA_POSITION_BOTTOM_CENTER"],
            ["BOTTOM_RIGHT", "BOTTOM RIGHT", "QA_POSITION_BOTTOM_RIGHT"]
        ];
        ["BOTTOM CENTER STACK", "A second independent card verifies upward compaction within the padded bottom-centre region.", "SUCCESS", 8, "BOTTOM_CENTER", "QA_POSITION_BOTTOM_CENTER_2", "WMP UI POSITION QA", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_UiPlacement", "MOVE QA UI CHANNEL BOTTOM LEFT", {
        ["QA_UI", "BOTTOM_LEFT", false, false] call Waldo_fnc_SetUiPanelPlacement;
        ["PLACEMENT UPDATED", "Future QA_UI cards use the mission-authored bottom-left position.", "INFO", 8, "BOTTOM_LEFT", "QA_UI", "WMP UI QA"] call Waldo_fnc_ShowUiNotification;
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_UiCleanup", "CLEAR ALL WMP UI", {[] call Waldo_fnc_ClearUiPanels;}] call Waldo_QA_fnc_addAuditActionLocal;
};

// Accessible world labels make the range self-guiding without custom textures.
private _drawHandler = addMissionEventHandler ["Draw3D", {
    {
        private _label = _x getVariable ["Waldo_QA_InteractionLabel", ""];
        if (_label != "" && {player distance _x < 12}) then {
            private _state = _x getVariable ["Waldo_MG_InteractionState", "IDLE"];
            drawIcon3D ["", [1, 1, 1, 1], (getPosATL _x) vectorAdd [0, 0, 1.5], 0, 0, 0, format ["%1  [%2]", _label, _state], 2, 0.028, "RobotoCondensedBold", "center", true];
        };
    } forEach (missionNamespace getVariable ["Waldo_QA_InteractionObjects", []]);
}];
missionNamespace setVariable ["Waldo_QA_Draw3DHandler", _drawHandler];

player setPosATL [0, -2, 0];
missionNamespace setVariable ["Waldo_QA_FeatureRangeClientReady", true];
systemChat "WMP full-pack PR feature range ready. Use the AUDIT CONTROL laptop for navigation and resets.";
