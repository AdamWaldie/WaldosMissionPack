/* Local interactions and labels for the walkable PR21-PR32 feature range. */
if (!hasInterface) exitWith {};
waitUntil {uiSleep 0.1; !isNull player && {missionNamespace getVariable ["Waldo_QA_FeatureRangeReady", false]}};
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
            missionNamespace getVariable ["Waldo_QA_CoreConsole", objNull]
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
    [_coreConsole, "Waldo_QA_AssignZeus", "ASSIGN ZEUS TO ME", {
        params ["_target", "_actor"];
        [_actor] remoteExecCall ["Waldo_QA_fnc_assignCuratorServer", 2];
    }] call Waldo_QA_fnc_addAuditActionLocal;
    [_coreConsole, "Waldo_QA_ModStatus", "SHOW REQUIRED MOD STATUS", {
        private _checks = [
            ["CBA", "cba_main"],
            ["ACE", "ace_main"],
            ["ZEN", "zen_main"],
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
        private _message = if (_missing isEqualTo []) then {
            format ["REQUIRED MODS LOADED: %1", _loaded joinString ", "]
        } else {
            format ["MISSING REQUIRED MODS: %1", _missing joinString ", "]
        };
        [_message, if (_missing isEqualTo []) then {"OK"} else {"ERROR"}, 8] call Waldo_fnc_MiniGameInteractionNotifyClient;
        diag_log format ["[WMP QA] %1", _message];
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
systemChat "WMP PR21-PR32 feature range ready. Use the AUDIT CONTROL laptop for navigation and resets.";
