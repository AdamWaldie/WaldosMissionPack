/*
 * Author: WaldoTheWarfighter
 * Runs the full-pack audit cases that require a local player interface and real interaction context.
 *
 * Arguments: None.
 * Return Value: Nothing; records assertions through Waldo_QA_fnc_assert and publishes client completion.
 *
 * Example: [] execVM "runClientAudit.sqf";
 * Current caller: auditInitPlayerLocal.sqf when automated audit mode is enabled.
 */

private _suite = missionNamespace getVariable ["Waldo_QA_Suite", "all"];
waitUntil {uiSleep 0.1; missionNamespace getVariable ["Waldo_QA_FeatureRangeClientReady", false]};
["client/mods/required-loaded", {
    private _missing = missionNamespace getVariable ["Waldo_QA_MissingPatches", []];
    ["client/mods/required-loaded", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

["client/runtime", {
    ["client/runtime", hasInterface && {!isNull player}, [clientOwner, profileName]] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

["client/startup/full-pack-init", {
    private _complete = missionNamespace getVariable ["WALDO_INIT_COMPLETE", false];
    private _observed = missionNamespace getVariable ["Waldo_QA_FullPackInitObserved", false];
    ["client/startup/full-pack-init", _complete && {_observed}, [_complete, _observed, diag_tickTime]] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

if (_suite in ["all", "core"]) then {
    ["core/markers/client-renderer", {
        private _handler = missionNamespace getVariable ["Waldo_3DMarker_DrawHandler", -1];
        ["core/markers/client-renderer", _handler >= 0, _handler] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/loading/version-artwork", {
        private _version = missionNamespace getVariable ["Waldo_QA_ExpectedVersion", ""];
        private _screen = (missionNamespace getVariable ["Waldo_QA_Root", ""]) + "Pictures\loading.jpg";
        ["core/loading/version-artwork", _version != "" && {fileExists _screen}, [_version, _screen]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/logistics/mhq-vvd-actions", {
        private _mhq = missionNamespace getVariable ["Waldo_QA_MHQ", objNull];
        (missionNamespace getVariable ["Waldo_QA_VVD", []]) params [["_terminal", objNull], ["_pad", objNull]];
        private _mhqTitles = if (isNull _mhq) then {[]} else {(actionIDs _mhq) apply {(_mhq actionParams _x) param [0, ""]}};
        private _vvdTitles = if (isNull _terminal) then {[]} else {(actionIDs _terminal) apply {(_terminal actionParams _x) param [0, ""]}};
        private _mhqDeployCount = {_x find "Deploy Command Post" >= 0} count _mhqTitles;
        private _mhqTearCount = {_x find "Tear Down Command Post" >= 0} count _mhqTitles;
        private _vvdOpenCount = {_x find "Open Vehicle Garage" >= 0} count _vvdTitles;
        private _vvdClearCount = {_x find "Clear Depot Spawn Area" >= 0} count _vvdTitles;
        private _displayDefined = isClass (missionConfigFile >> "GarageLoadDisplay");
        private _installed = !isNull _mhq && {!isNull _terminal}
            && {_mhq getVariable ["Waldo_MHQ_LocalActionsInstalled", false]}
            && {_terminal getVariable ["Waldo_VVD_LocalActionsInstalled", false]};
        private _aceOnly = (_mhq getVariable ["Waldo_MHQ_InteractionMode", ""]) == "ACE"
            && {_mhq getVariable ["Waldo_MHQ_ACEActionsInstalled", false]}
            && {(count (_mhq getVariable ["Waldo_MHQ_ACEActionPaths", []])) == 3}
            && {_mhqDeployCount == 0 && {_mhqTearCount == 0} && {_vvdOpenCount == 0} && {_vvdClearCount == 0}};
        ["core/logistics/mhq-vvd-actions", _installed && {_displayDefined} && {_aceOnly}, [_mhqTitles, _vvdTitles, _displayDefined, _mhq getVariable ["Waldo_MHQ_InteractionMode", "NONE"], count (_mhq getVariable ["Waldo_MHQ_ACEActionPaths", []])]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/zen/all-module-families", {
        private _coreCount = missionNamespace getVariable ["Waldo_ZenModuleCount", 0];
        private _economyCount = missionNamespace getVariable ["WaldoEcoCore_ZenModuleCount", 0];
        ["core/zen/all-module-families", _coreCount == 15 && {_economyCount == 19}, [_coreCount, _economyCount]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/zen/icons-present", {
        private _icons = [
            "\A3\ui_f\data\map\vehicleicons\iconCrate_ca.paa",
            "\a3\modules_f\data\portraitmodule_ca.paa",
            "\a3\Missions_F_Orange\Data\Img\Showcase_LawsOfWar\action_end_sim_CA.paa",
            "\z\ACE\addons\medical_gui\ui\cross.paa",
            "\z\ACE\addons\fortify\ui\hammer_ca.paa",
            "\A3\ui_f\data\map\vehicleicons\iconTruck_ca.paa",
            "\A3\ui_f\data\map\vehicleicons\iconMan_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\interact_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\attack_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\download_ca.paa",
            "\a3\ui_f\data\map\markers\military\destroy_ca.paa",
            "\a3\ui_f\data\igui\cfg\simpletasks\types\backpack_ca.paa"
        ];
        private _missing = _icons select {!(fileExists _x)};
        ["core/zen/icons-present", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "interactions"]) then {
    ["interactions/integration/linked-ace-vanilla-actions", {
        private _objects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
        private _missing = _objects select {
            !(_x getVariable ["Waldo_MG_Int_ACEActionInstalled", false])
            || {!(_x getVariable ["Waldo_QA_ResultACEInstalled", false])}
            || {!(_x getVariable ["Waldo_MG_Int_VanillaActionInstalled", false])}
            || {!(_x getVariable ["Waldo_QA_ResultVanillaInstalled", false])}
        };
        ["interactions/integration/linked-ace-vanilla-actions", (count _objects) == 40 && {_missing isEqualTo []}, [count _objects, _missing apply {netId _x}]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["interactions/integration/ace-action-condition", {
        private _objects = missionNamespace getVariable ["Waldo_QA_InteractionObjects", []];
        private _originalPosition = getPosATL player;
        private _failed = _objects select {
            // The real action condition deliberately includes interaction
            // distance. Evaluate it where a player could actually use it.
            player setPosATL ((getPosATL _x) vectorAdd [0, -1.2, 0]);
            private _action = _x getVariable ["Waldo_MG_Int_ACEAction", []];
            private _path = _x getVariable ["Waldo_MG_Int_ACEActionPath", []];
            (count _action) < 7
            || {!([_x, player, _action select 6] call (_action select 4))}
            || {_path isEqualTo []}
        };
        player setPosATL _originalPosition;
        ["interactions/integration/ace-action-condition", (count _objects) == 40 && {_failed isEqualTo []}, [count _objects, _failed apply {netId _x}]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["interactions/catalogue/ten-procedures", {
        missionNamespace setVariable ["Waldo_MG_ChallengeRegistry", []];
        {
            _x params ["_id", "_opener"];
            [_id, _opener, _id] call Waldo_fnc_MiniGameRegisterChallenge;
        } forEach [
            ["wirecut", Waldo_fnc_MiniGameWireCut], ["minesweeper", Waldo_fnc_MiniGameMinesweeper],
            ["keypad", Waldo_fnc_MiniGameKeypad], ["lockpick", Waldo_fnc_MiniGameLockpick],
            ["circuit", Waldo_fnc_MiniGameCircuit], ["repair", Waldo_fnc_MiniGameRepair],
            ["radiotune", Waldo_fnc_MiniGameRadioTune], ["pressure", Waldo_fnc_MiniGamePressure],
            ["sequence", Waldo_fnc_MiniGameSequence], ["commandinput", Waldo_fnc_MiniGameCommandInput]
        ];
        private _registered = (missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []]) apply {_x select 0};
        ["interactions/catalogue/ten-procedures", count _registered == 10, _registered] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "party"]) then {
    ["party/integration/linked-ace-vanilla-actions", {
        call Waldo_MG_fnc_ensureTableActionsLocal;
        call Waldo_MG_fnc_ensurePlayerActionsLocal;
        private _table = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
        private _actions = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_TableACEActions", []]};
        private _paths = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_TableACEActionPaths", []]};
        private _vanilla = if (isNull _table) then {[]} else {_table getVariable ["Waldo_MG_TableActionIdsLocal", []]};
        private _sitAvailable = false;
        if ((count _actions) >= 2 && {!isNull _table}) then {
            private _originalPosition = getPosATL player;
            player setPosATL ((getPosATL _table) vectorAdd [0, -1.2, 0]);
            private _sit = _actions select 1;
            _sitAvailable = [_table, player, _sit select 6] call (_sit select 4);
            player setPosATL _originalPosition;
        };
        private _playerActions = missionNamespace getVariable ["Waldo_MG_PlayerACEActionsLocal", []];
        private _ok = !isNull _table
            && {(_table getVariable ["Waldo_MG_TableInteractionMode", ""]) == "ACE+VANILLA"}
            && {(count _actions) == 4}
            && {(count _paths) == 4}
            && {(count _vanilla) == 3}
            && {_sitAvailable}
            && {(count _playerActions) == 2}
            && {(count (missionNamespace getVariable ["Waldo_MG_PlayerActionIdsLocal", []])) == 2};
        ["party/integration/linked-ace-vanilla-actions", _ok, [count _actions, count _paths, _vanilla, _sitAvailable, count _playerActions]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["party/integration/preserves-foreign-actions", {
        private _table = missionNamespace getVariable ["Waldo_QA_PartyTable", objNull];
        private _tableSentinel = -1;
        private _playerSentinel = -1;
        if (!isNull _table) then {
            _tableSentinel = _table addAction ["QA FOREIGN TABLE ACTION", {}];
        };
        if (!isNull player) then {
            _playerSentinel = player addAction ["QA FOREIGN PLAYER ACTION", {}];
        };

        call Waldo_MG_fnc_ensureTableActionsLocal;
        call Waldo_MG_fnc_ensurePlayerActionsLocal;

        private _tablePreserved = !isNull _table && {_tableSentinel >= 0} && {_tableSentinel in (actionIDs _table)};
        private _playerPreserved = !isNull player && {_playerSentinel >= 0} && {_playerSentinel in (actionIDs player)};
        ["party/integration/preserves-foreign-actions", _tablePreserved && {_playerPreserved}, [_tablePreserved, _playerPreserved]] call Waldo_QA_fnc_assert;

        if (_tableSentinel >= 0 && {!isNull _table}) then {_table removeAction _tableSentinel;};
        if (_playerSentinel >= 0 && {!isNull player}) then {player removeAction _playerSentinel;};
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "economy"]) then {
    ["economy/integration/local-ace-actions", {
        private _checks = [
            [missionNamespace getVariable ["qa_economy_crate", objNull], "WaldoEcoResource_CollectActionAddedLocal"],
            [missionNamespace getVariable ["qa_economy_research", objNull], "WaldoEcoResearch_DisplayResourcesAddedLocal"],
            [missionNamespace getVariable ["qa_economy_construction", objNull], "WaldoEcoBuild_PlayerConstructionActionAddedLocal"],
            [missionNamespace getVariable ["qa_economy_terminal", objNull], "WaldoEcoBuy_PurchaseActionAddedLocalV2"]
        ];
        private _failed = _checks select {
            _x params ["_object", "_flag"];
            isNull _object
            || {!(_object getVariable [format ["%1_ACE", _flag], false])}
            || {(_object getVariable [format ["%1_ACEPath", _flag], []]) isEqualTo []}
            || {(count (_object getVariable [format ["%1_ACEAction", _flag], []])) < 7}
        };
        ["economy/integration/local-ace-actions", _failed isEqualTo [], _failed apply {if (isNull (_x select 0)) then {"NULL"} else {netId (_x select 0)}}] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["economy/integration/action-adapter-executes", {
        private _probe = "Land_HelipadEmpty_F" createVehicleLocal [0, 0, 0];
        private _flag = "Waldo_QA_EconomyActionProbe";
        missionNamespace setVariable [_flag, false];
        [_probe, _flag, [
            "Audit Action Probe",
            {missionNamespace setVariable ["Waldo_QA_EconomyActionProbe", true];},
            [], 1.5, true, true, "", "true", 3
        ]] call Waldo_fnc_EcoCore_ensureLocalObjectAction;
        private _action = _probe getVariable [format ["%1_ACEAction", _flag], []];
        if ((count _action) >= 7) then {
            [_probe, player, _action select 6] call (_action select 3);
        };
        private _executed = missionNamespace getVariable [_flag, false];
        deleteVehicle _probe;
        ["economy/integration/action-adapter-executes", _executed, [count _action, _executed]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "ew"]) then {
    ["ew/client/jamming-factor-near-emitter", {
        private _jammer = missionNamespace getVariable ["Waldo_QA_Jammer", objNull];
        private _sample = if (isNull _jammer) then {[]} else {(getPosASL _jammer) vectorAdd [0, 0, 1.7]};
        private _factor = if (_sample isEqualTo []) then {0} else {[_sample, west, -1] call Waldo_fnc_JammingFactor};
        private _ready = missionNamespace getVariable ["Waldo_Jamming_UiRunning", false]
            && {missionNamespace getVariable ["Waldo_Jamming_AcreInstalled", false]};
        ["ew/client/jamming-factor-near-emitter", !isNull _jammer && {_factor > 0.7} && {_ready}, [_factor, _ready, count (missionNamespace getVariable ["Waldo_Jamming_Registry", []])]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

private _passed = call Waldo_QA_fnc_complete;
player setVariable ["Waldo_QA_ClientComplete", [_passed, missionNamespace getVariable ["Waldo_QA_LocalResults", []]], true];

