/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - ensureResearchCenterActionsLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_researchCenter", objNull]];

        if (!hasInterface) exitWith {};
        if (isNull _researchCenter) exitWith {};
        if !(_researchCenter getVariable ["WaldoEcoResearch_IsResearchCenter", false]) exitWith {};

        [
            _researchCenter,
            "WaldoEcoResearch_DisplayResourcesAddedLocal",
            call Waldo_fnc_EcoResearch_getOfficialResourceDisplayActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

        [
            _researchCenter,
            "WaldoEcoResearch_ResearchActionAddedLocal",
            [
                "Research",
                {
                    params ["_target", "_caller"];

                    private _parent = findDisplay 46;
                    if (isNull _parent) exitWith {hintSilent "Research display unavailable.";};

                    private _existing = uiNamespace getVariable ["WaldoEcoResearch_PlayerResearchDisplay", displayNull];
                    if (!isNull _existing) then {_existing closeDisplay 1;};

                    private _disp = _parent createDisplay "RscDisplayEmpty";
                    if (isNull _disp) exitWith {};
                    uiNamespace setVariable ["WaldoEcoResearch_PlayerResearchDisplay", _disp];
                    _disp setVariable ["WaldoEcoResearch_ResearchCenterObject", _target];
                    _disp setVariable ["WaldoEcoResearch_RequestActorObject", _caller];
                    _disp setVariable ["WaldoEcoResearch_PlayerSelectedIndex", 0];

                    private _bg = _disp ctrlCreate ["RscText", -1];
                    _bg ctrlSetPosition [0.02, 0.05, 1.09, 1.1];
                    _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
                    _bg ctrlCommit 0;

                    private _title = _disp ctrlCreate ["RscText", -1];
                    _title ctrlSetPosition [0.03, 0.06, 0.7, 0.03];
                    _title ctrlSetText "Research";
                    _title ctrlCommit 0;

                    private _list = _disp ctrlCreate ["RscListbox", -1];
                    _list ctrlSetPosition [0.03, 0.1, 0.4, 1.03];
                    _list ctrlCommit 0;

                    private _name = _disp ctrlCreate ["RscText", -1];
                    _name ctrlSetPosition [0.43, 0.09, 0.67, 0.05];
                    _name ctrlCommit 0;

                    private _desc1 = _disp ctrlCreate ["RscText", -1];
                    _desc1 ctrlSetPosition [0.43, 0.15, 0.67, 0.045];
                    _desc1 ctrlCommit 0;

                    private _desc2 = _disp ctrlCreate ["RscText", -1];
                    _desc2 ctrlSetPosition [0.43, 0.195, 0.67, 0.045];
                    _desc2 ctrlCommit 0;

                    private _desc3 = _disp ctrlCreate ["RscText", -1];
                    _desc3 ctrlSetPosition [0.43, 0.24, 0.67, 0.045];
                    _desc3 ctrlCommit 0;

                    private _status = _disp ctrlCreate ["RscText", -1];
                    _status ctrlSetPosition [0.43, 0.295, 0.67, 0.04];
                    _status ctrlCommit 0;

                    private _costHeader = _disp ctrlCreate ["RscText", -1];
                    _costHeader ctrlSetPosition [0.43, 0.36, 0.22, 0.04];
                    _costHeader ctrlSetText "Cost";
                    _costHeader ctrlCommit 0;

                    private _timeHeader = _disp ctrlCreate ["RscText", -1];
                    _timeHeader ctrlSetPosition [0.72, 0.36, 0.18, 0.04];
                    _timeHeader ctrlSetText "Time";
                    _timeHeader ctrlCommit 0;

                    private _time = _disp ctrlCreate ["RscText", -1];
                    _time ctrlSetPosition [0.72, 0.405, 0.38, 0.04];
                    _time ctrlCommit 0;

                    private _costLines = [];
                    for "_i" from 0 to 4 do {
                        private _ctrl = _disp ctrlCreate ["RscText", -1];
                        _ctrl ctrlSetPosition [0.43, 0.405 + (_i * 0.04), 0.28, 0.038];
                        _ctrl ctrlCommit 0;
                        _costLines pushBack _ctrl;
                    };

                    private _reqHeader = _disp ctrlCreate ["RscText", -1];
                    _reqHeader ctrlSetPosition [0.43, 0.63, 0.32, 0.04];
                    _reqHeader ctrlSetText "Requirements";
                    _reqHeader ctrlCommit 0;

                    private _reqLines = [];
                    for "_i" from 0 to 5 do {
                        private _ctrl = _disp ctrlCreate ["RscText", -1];
                        _ctrl ctrlSetPosition [0.43, 0.675 + (_i * 0.04), 0.67, 0.038];
                        _ctrl ctrlCommit 0;
                        _reqLines pushBack _ctrl;
                    };

                    private _exclusiveHeader = _disp ctrlCreate ["RscText", -1];
                    _exclusiveHeader ctrlSetPosition [0.43, 0.93, 0.32, 0.04];
                    _exclusiveHeader ctrlSetText "Exclusive With";
                    _exclusiveHeader ctrlCommit 0;

                    private _exclusiveLines = [];
                    for "_i" from 0 to 2 do {
                        private _ctrl = _disp ctrlCreate ["RscText", -1];
                        _ctrl ctrlSetPosition [0.43, 0.975 + (_i * 0.04), 0.5, 0.038];
                        _ctrl ctrlCommit 0;
                        _exclusiveLines pushBack _ctrl;
                    };

                    private _button = _disp ctrlCreate ["RscButtonMenu", -1];
                    _button ctrlSetPosition [0.75, 1.07, 0.2, 0.06];
                    _button ctrlSetText "Research";
                    _button ctrlCommit 0;

                    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
                    _close ctrlSetPosition [0.96, 1.07, 0.14, 0.06];
                    _close ctrlSetText "Close";
                    _close ctrlCommit 0;

                    _disp setVariable ["WaldoEcoResearch_PlayerList", _list];
                    _disp setVariable ["WaldoEcoResearch_PlayerName", _name];
                    _disp setVariable ["WaldoEcoResearch_PlayerDescLines", [_desc1, _desc2, _desc3]];
                    _disp setVariable ["WaldoEcoResearch_PlayerStatus", _status];
                    _disp setVariable ["WaldoEcoResearch_PlayerCostLines", _costLines];
                    _disp setVariable ["WaldoEcoResearch_PlayerTime", _time];
                    _disp setVariable ["WaldoEcoResearch_PlayerReqLines", _reqLines];
                    _disp setVariable ["WaldoEcoResearch_PlayerExclusiveLines", _exclusiveLines];
                    _disp setVariable ["WaldoEcoResearch_PlayerButton", _button];

                    private _refresh = {
                        params [["_display", displayNull], ["_rebuild", true]];
                        if (isNull _display) exitWith {};

                        private _trim = {
                            params [["_value", ""]];
                            if ((typeName _value) == "STRING") exitWith {_value};
                            str _value
                        };

                        private _actor = _display getVariable ["WaldoEcoResearch_RequestActorObject", objNull];
                        if (isNull _actor) then {_actor = player;};

                        private _sideKey = switch (side group _actor) do {
                            case west: {"WEST"};
                            case east: {"EAST"};
                            case independent: {"GUER"};
                            case civilian: {"CIV"};
                            default {"CIV"};
                        };

                        private _doneVar = switch (_sideKey) do {
                            case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
                            case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
                            case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
                            case "CIV": {"WaldoEcoResearch_ResearchDone_CIV"};
                            default {""};
                        };
                        private _activeVar = switch (_sideKey) do {
                            case "WEST": {"WaldoEcoResearch_ResearchActive_WEST"};
                            case "EAST": {"WaldoEcoResearch_ResearchActive_EAST"};
                            case "GUER": {"WaldoEcoResearch_ResearchActive_GUER"};
                            case "CIV": {"WaldoEcoResearch_ResearchActive_CIV"};
                            default {""};
                        };
                        private _resourceVar = switch (_sideKey) do {
                            case "WEST": {"WaldoEcoResource_Resources_WEST"};
                            case "EAST": {"WaldoEcoResource_Resources_EAST"};
                            case "GUER": {"WaldoEcoResource_Resources_GUER"};
                            case "CIV": {"WaldoEcoResource_Resources_CIV"};
                            default {""};
                        };

                        private _catalog = missionNamespace getVariable ["WaldoEcoResearch_ResearchCatalog", []];
                        if ((typeName _catalog) != "ARRAY") then {_catalog = [];};
                        _catalog = _catalog select {((_x param [0, ""]) != "")};

                        private _doneRows = missionNamespace getVariable [_doneVar, []];
                        if ((typeName _doneRows) != "ARRAY") then {_doneRows = [];};

                        private _active = missionNamespace getVariable [_activeVar, []];
                        if ((typeName _active) != "ARRAY") then {_active = [];};

                        private _resources = missionNamespace getVariable [_resourceVar, []];
                        if ((typeName _resources) != "ARRAY") then {_resources = [];};

                        private _isDone = {
                            params [["_name", ""], ["_catalog", []], ["_doneRows", []], ["_trim", {}]];
                            private _clean = [_name] call _trim;
                            if (_clean == "") exitWith {false};
                            private _index = _catalog findIf {(toLower (_x param [0, ""])) == (toLower _clean)};
                            if (_index >= 0 && {(_catalog select _index) param [7, false]}) exitWith {true};
                            (_doneRows findIf {(toLower _x) == (toLower _clean)}) >= 0
                        };

                        private _resourceAmount = {
                            params [["_resourceName", ""], ["_resources", []]];
                            private _index = _resources findIf {((_x param [0, ""]) == _resourceName)};
                            if (_index < 0) exitWith {0};
                            floor ((_resources select _index) param [1, 0])
                        };

                        private _requirementMet = {
                            params [["_requirement", ""], ["_sideKey", "NONE"], ["_catalog", []], ["_doneRows", []], ["_trim", {}], ["_isDone", {}]];
                            private _req = [_requirement] call _trim;
                            if (_req == "") exitWith {true};
                            if ([_req, _catalog, _doneRows, _trim] call _isDone) exitWith {true};

                            private _buildings = missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []];
                            if ((typeName _buildings) != "ARRAY") exitWith {false};
                            (_buildings findIf {
                                private _owner = _x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
                                private _buildName = _x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
                                private _ownerOk = _owner == _sideKey;
                                private _nameOk = (toLower _buildName) == (toLower _req);
                                (!isNull _x) && _ownerOk && _nameOk
                            }) >= 0
                        };

                        private _hasCommand = {
                            private _uids = missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []];
                            if ((typeName _uids) != "ARRAY") exitWith {true};
                            if ((count _uids) <= 0) exitWith {true};
                            private _uid = getPlayerUID player;
                            private _key = if (_uid != "") then {_uid} else {str (owner player)};
                            (_uids find _key) >= 0
                        };

                        private _statusFor = {
                            params [
                                ["_entry", []],
                                ["_sideKey", "NONE"],
                                ["_catalog", []],
                                ["_doneRows", []],
                                ["_active", []],
                                ["_resources", []],
                                ["_trim", {}],
                                ["_isDone", {}],
                                ["_resourceAmount", {}],
                                ["_requirementMet", {}],
                                ["_hasCommand", {}]
                            ];

                            private _name = _entry param [0, ""];
                            if (_name == "") exitWith {"invalid"};
                            if ([_name, _catalog, _doneRows, _trim] call _isDone) exitWith {"done"};
                            if ((count _active) > 0 && {(toLower (_active param [0, ""])) == (toLower _name)}) exitWith {"active"};
                            if ((count _active) > 0) exitWith {"busy"};
                            if !(call _hasCommand) exitWith {"command"};

                            private _requirementsMet = true;
                            {
                                if !([_x, _sideKey, _catalog, _doneRows, _trim, _isDone] call _requirementMet) exitWith {_requirementsMet = false;};
                            } forEach (_entry param [3, []]);
                            if (!_requirementsMet) exitWith {"locked"};

                            private _exclusiveBlocked = false;
                            {
                                if ([_x, _catalog, _doneRows, _trim] call _isDone) exitWith {_exclusiveBlocked = true;};
                            } forEach (_entry param [8, []]);
                            if (_exclusiveBlocked) exitWith {"exclusive"};

                            private _affordable = true;
                            {
                                private _res = _x param [0, ""];
                                private _cost = floor (_x param [1, 0]);
                                if (([_res, _resources] call _resourceAmount) < _cost) exitWith {_affordable = false;};
                            } forEach (_entry param [2, []]);
                            if (!_affordable) exitWith {"unaffordable"};

                            "ready"
                        };

                        private _setLines = {
                            params [["_controls", []], ["_rows", []]];
                            {
                                _x ctrlSetText "";
                                _x ctrlSetTextColor [0.85, 0.85, 0.85, 1];
                                _x ctrlCommit 0;
                            } forEach _controls;

                            private _limit = (count _controls) min (count _rows);
                            if (_limit > 0) then {
                                for "_i" from 0 to (_limit - 1) do {
                                    private _row = _rows select _i;
                                    private _ctrl = _controls select _i;
                                    _ctrl ctrlSetText (_row param [0, ""]);
                                    _ctrl ctrlSetTextColor (_row param [1, [0.85, 0.85, 0.85, 1]]);
                                    _ctrl ctrlCommit 0;
                                };
                            };
                        };

                        private _list = _display getVariable ["WaldoEcoResearch_PlayerList", controlNull];
                        private _nameCtrl = _display getVariable ["WaldoEcoResearch_PlayerName", controlNull];
                        private _descLines = _display getVariable ["WaldoEcoResearch_PlayerDescLines", []];
                        private _statusCtrl = _display getVariable ["WaldoEcoResearch_PlayerStatus", controlNull];
                        private _costLines = _display getVariable ["WaldoEcoResearch_PlayerCostLines", []];
                        private _timeCtrl = _display getVariable ["WaldoEcoResearch_PlayerTime", controlNull];
                        private _reqLines = _display getVariable ["WaldoEcoResearch_PlayerReqLines", []];
                        private _exclusiveLines = _display getVariable ["WaldoEcoResearch_PlayerExclusiveLines", []];
                        private _button = _display getVariable ["WaldoEcoResearch_PlayerButton", controlNull];
                        if (isNull _list || {isNull _nameCtrl} || {isNull _statusCtrl} || {isNull _timeCtrl} || {isNull _button}) exitWith {};

                        if (_rebuild) then {
                            lbClear _list;
                            {
                                private _entry = _x;
                                private _entryName = _entry param [0, "Research"];
                                private _index = _list lbAdd _entryName;
                                _list lbSetData [_index, _entryName];
                                private _icon = _entry param [5, ""];
                                if (_icon != "") then {_list lbSetPicture [_index, _icon];};

                                private _rowStatus = [
                                    _entry,
                                    _sideKey,
                                    _catalog,
                                    _doneRows,
                                    _active,
                                    _resources,
                                    _trim,
                                    _isDone,
                                    _resourceAmount,
                                    _requirementMet,
                                    _hasCommand
                                ] call _statusFor;
                                if (_rowStatus == "done") then {_list lbSetColor [_index, [0.35, 1, 0.35, 1]];};
                                if (_rowStatus == "active") then {
                                    _list lbSetColor [_index, [1, 0.92, 0.25, 1]];
                                    _list lbSetTextRight [_index, "ACTIVE"];
                                };
                                if (_rowStatus in ["locked", "exclusive", "unaffordable", "command", "busy"]) then {
                                    _list lbSetColor [_index, [0.72, 0.72, 0.72, 1]];
                                };
                            } forEach _catalog;
                        };

                        private _selected = _display getVariable ["WaldoEcoResearch_PlayerSelectedIndex", 0];
                        if (_selected < 0) then {_selected = 0;};
                        if (_selected >= lbSize _list) then {_selected = (lbSize _list) - 1;};
                        if (_selected < 0 || {(count _catalog) <= 0}) exitWith {
                            _nameCtrl ctrlSetText "No valid research configured.";
                            _nameCtrl ctrlSetTextColor [1, 1, 1, 1];
                            _statusCtrl ctrlSetText "";
                            [_descLines, []] call _setLines;
                            [_costLines, []] call _setLines;
                            [_reqLines, []] call _setLines;
                            [_exclusiveLines, []] call _setLines;
                            _timeCtrl ctrlSetText "";
                            _button ctrlSetText "Research";
                            _button ctrlEnable false;
                            _button setVariable ["WaldoEcoResearch_SelectedResearchName", ""];
                            _button ctrlCommit 0;
                        };

                        _display setVariable ["WaldoEcoResearch_PlayerSelectedIndex", _selected];
                        if (_rebuild) then {_list lbSetCurSel _selected;};

                        private _entry = _catalog select _selected;
                        private _entryName = _entry param [0, "Research"];
                        private _entryStatus = [
                            _entry,
                            _sideKey,
                            _catalog,
                            _doneRows,
                            _active,
                            _resources,
                            _trim,
                            _isDone,
                            _resourceAmount,
                            _requirementMet,
                            _hasCommand
                        ] call _statusFor;

                        private _nameColor = [1, 1, 1, 1];
                        if (_entryStatus == "done") then {_nameColor = [0.35, 1, 0.35, 1];};
                        if (_entryStatus == "active") then {_nameColor = [1, 0.92, 0.25, 1];};

                        _nameCtrl ctrlSetText _entryName;
                        _nameCtrl ctrlSetTextColor _nameColor;
                        _nameCtrl ctrlCommit 0;

                        private _desc = _entry param [1, ""];
                        private _descRows = [
                            [_desc select [0, 78], [0.9, 0.9, 0.9, 1]],
                            [_desc select [78, 78], [0.9, 0.9, 0.9, 1]],
                            [_desc select [156, 78], [0.9, 0.9, 0.9, 1]]
                        ];
                        [_descLines, _descRows] call _setLines;

                        private _statusText = switch (_entryStatus) do {
                            case "done": {"Status: Researched"};
                            case "active": {"Status: Researching"};
                            case "busy": {"Status: Another research is active"};
                            case "command": {"Status: Ground Command required"};
                            case "locked": {"Status: Requirements missing"};
                            case "exclusive": {"Status: Exclusive research blocked"};
                            case "unaffordable": {"Status: Not enough resources"};
                            default {"Status: Ready"};
                        };
                        private _statusColor = switch (_entryStatus) do {
                            case "done": {[0.35, 1, 0.35, 1]};
                            case "active": {[1, 0.92, 0.25, 1]};
                            case "ready": {[0.35, 1, 0.35, 1]};
                            default {[1, 0.45, 0.45, 1]};
                        };
                        _statusCtrl ctrlSetText _statusText;
                        _statusCtrl ctrlSetTextColor _statusColor;
                        _statusCtrl ctrlCommit 0;

                        private _costRows = [];
                        {
                            private _res = _x param [0, ""];
                            private _cost = floor (_x param [1, 0]);
                            private _have = [_res, _resources] call _resourceAmount;
                            _costRows pushBack [
                                format ["%1: %2 / %3", _res, _have, _cost],
                                [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select (_have >= _cost)
                            ];
                        } forEach (_entry param [2, []]);
                        if ((count _costRows) <= 0) then {_costRows pushBack ["No cost", [0.9, 0.9, 0.9, 1]];};
                        if ((count _costRows) > (count _costLines)) then {
                            _costRows set [(count _costLines) - 1, ["More costs not shown...", [0.9, 0.9, 0.9, 1]]];
                        };
                        [_costLines, _costRows] call _setLines;

                        private _timeSeconds = floor (_entry param [4, 60]);
                        private _timeText = format ["%1 sec", _timeSeconds];
                        if (_entryStatus == "active") then {
                            private _remaining = 0;
                            if ((count _active) >= 5) then {
                                _remaining = ceil (0 max ((_active param [1, 60]) - ((_active param [2, 0]) + (_active param [3, 0]))));
                            } else {
                                _remaining = ceil (0 max ((_active param [1, serverTime]) - serverTime));
                            };
                            _timeText = format ["%1 sec total, ~%2 sec left", _timeSeconds, _remaining];
                        };
                        _timeCtrl ctrlSetText _timeText;
                        _timeCtrl ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                        _timeCtrl ctrlCommit 0;

                        private _reqRows = [];
                        {
                            private _met = [_x, _sideKey, _catalog, _doneRows, _trim, _isDone] call _requirementMet;
                            _reqRows pushBack [_x, [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select _met];
                        } forEach (_entry param [3, []]);
                        if ((count _reqRows) <= 0) then {_reqRows pushBack ["None", [0.9, 0.9, 0.9, 1]];};
                        if ((count _reqRows) > (count _reqLines)) then {
                            _reqRows set [(count _reqLines) - 1, ["More requirements not shown...", [0.9, 0.9, 0.9, 1]]];
                        };
                        [_reqLines, _reqRows] call _setLines;

                        private _exclusiveRows = [];
                        {
                            private _blocked = [_x, _catalog, _doneRows, _trim] call _isDone;
                            _exclusiveRows pushBack [_x, [[0.75, 0.75, 0.75, 1], [1, 0.45, 0.45, 1]] select _blocked];
                        } forEach (_entry param [8, []]);
                        if ((count _exclusiveRows) <= 0) then {_exclusiveRows pushBack ["None", [0.9, 0.9, 0.9, 1]];};
                        if ((count _exclusiveRows) > (count _exclusiveLines)) then {
                            _exclusiveRows set [(count _exclusiveLines) - 1, ["More exclusives not shown...", [0.9, 0.9, 0.9, 1]]];
                        };
                        [_exclusiveLines, _exclusiveRows] call _setLines;

                        private _buttonText = switch (_entryStatus) do {
                            case "done": {"Researched"};
                            case "active": {"Researching..."};
                            case "busy": {"Another Active"};
                            case "command": {"Ground Cmd"};
                            case "locked": {"Requirements"};
                            case "exclusive": {"Exclusive"};
                            case "unaffordable": {"Not Enough"};
                            default {"Research"};
                        };

                        _button ctrlSetText _buttonText;
                        _button ctrlEnable (_entryStatus == "ready");
                        _button setVariable ["WaldoEcoResearch_SelectedResearchName", _entryName];
                        _button ctrlCommit 0;
                    };

                    _disp setVariable ["WaldoEcoResearch_PubRefresh", _refresh];

                    _list ctrlAddEventHandler ["LBSelChanged", {
                        params ["_ctrl", "_index"];
                        private _display = ctrlParent _ctrl;
                        _display setVariable ["WaldoEcoResearch_PlayerSelectedIndex", _index];
                        [_display, false] call (_display getVariable ["WaldoEcoResearch_PubRefresh", {}]);
                    }];

                    _button ctrlAddEventHandler ["ButtonClick", {
                        params ["_ctrl"];
                        private _display = ctrlParent _ctrl;
                        private _researchName = _ctrl getVariable ["WaldoEcoResearch_SelectedResearchName", ""];
                        if (_researchName == "") exitWith {};

                        private _actor = _display getVariable ["WaldoEcoResearch_RequestActorObject", objNull];
                        if (isNull _actor) then {_actor = player;};

                        private _sideKey = switch (side group _actor) do {
                            case west: {"WEST"};
                            case east: {"EAST"};
                            case independent: {"GUER"};
                            case civilian: {"CIV"};
                            default {"CIV"};
                        };

                        private _center = _display getVariable ["WaldoEcoResearch_ResearchCenterObject", objNull];
                        private _uid = getPlayerUID player;
                        if (_uid == "") then {_uid = getPlayerUID _actor;};
                        private _actorName = name _actor;
                        private _request = [
                            _sideKey,
                            _researchName,
                            netId _center,
                            getPosATL _actor,
                            _uid,
                            _actorName,
                            format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)],
                            netId _actor
                        ];
                        player setVariable [
                            "WaldoEcoResearch_StartResearchRequest",
                            _request,
                            true
                        ];
                        if (!isNull _center) then {
                            _center setVariable ["WaldoEcoResearch_StartResearchRequest", _request, true];
                        };

                        hintSilent "Research request sent.";
                        [_display] spawn {
                            params ["_display"];
                            uiSleep 1;
                            if (!isNull _display) then {
                                [_display, true] call (_display getVariable ["WaldoEcoResearch_PubRefresh", {}]);
                            };
                        };
                    }];

                    _close ctrlAddEventHandler ["ButtonClick", {
                        params ["_ctrl"];
                        (ctrlParent _ctrl) closeDisplay 1;
                    }];

                    [_disp, true] call _refresh;

                    [_disp] spawn {
                        params ["_display"];
                        while {!isNull _display} do {
                            uiSleep 10;
                            if (!isNull _display) then {
                                [_display, !(missionNamespace getVariable ["WaldoEcoCore_CommitmentModeEnabled", false])] call (_display getVariable ["WaldoEcoResearch_PubRefresh", {}]);
                            };
                        };
                    };
                },
                nil,
                1.5,
                true,
                true,
                "",
                "true",
                8
            ]
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

        if (isNil "Waldo_fnc_EcoBuild_getOfficialConstructionModeActionArgs") exitWith {-1};
        [
            _researchCenter,
            "WaldoEcoResearch_ConstructionModeActionAddedLocal",
            call Waldo_fnc_EcoBuild_getOfficialConstructionModeActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

