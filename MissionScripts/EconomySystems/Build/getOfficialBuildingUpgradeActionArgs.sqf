/*
 * Author: Waldo
 * Get official building upgrade action args.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingUpgradeActionArgs;
 */

        params [["_entry", []]];

        [
            "Upgrade",
            {
                params ["_target", "_caller"];

                private _actor = _caller;
                if (isNull _actor) then {_actor = player;};

                private _parent = findDisplay 46;
                if (isNull _parent) exitWith {hintSilent "Upgrade display unavailable.";};

                private _existing = uiNamespace getVariable ["WaldoEcoBuild_PubUpgradeDisplay", displayNull];
                if (!isNull _existing) then {_existing closeDisplay 1;};

                private _disp = _parent createDisplay "RscDisplayEmpty";
                if (isNull _disp) exitWith {};
                uiNamespace setVariable ["WaldoEcoBuild_PubUpgradeDisplay", _disp];
                _disp setVariable ["WaldoEcoBuild_UpgradeBuilding", _target];
                _disp setVariable ["WaldoEcoBuild_RequestActorObject", _actor];

                private _bg = _disp ctrlCreate ["RscText", -1];
                _bg ctrlSetPosition [0.14, 0.09, 0.86, 0.82];
                _bg ctrlSetBackgroundColor [0, 0, 0, 0.88];
                _bg ctrlCommit 0;

                private _title = _disp ctrlCreate ["RscText", -1];
                _title ctrlSetPosition [0.17, 0.11, 0.32, 0.04];
                _title ctrlSetText "Upgrade Building";
                _title ctrlCommit 0;

                private _path = _disp ctrlCreate ["RscText", -1];
                _path ctrlSetPosition [0.17, 0.17, 0.79, 0.04];
                _path ctrlSetTextColor [0.55, 1, 0.55, 1];
                _path ctrlCommit 0;

                private _status = _disp ctrlCreate ["RscText", -1];
                _status ctrlSetPosition [0.17, 0.215, 0.79, 0.04];
                _status ctrlCommit 0;

                private _descHeader = _disp ctrlCreate ["RscText", -1];
                _descHeader ctrlSetPosition [0.17, 0.275, 0.35, 0.035];
                _descHeader ctrlSetText "Description";
                _descHeader ctrlCommit 0;

                private _descLines = [];
                for "_i" from 0 to 2 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.17, 0.315 + (_i * 0.035), 0.79, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _descLines pushBack _ctrl;
                };

                private _costHeader = _disp ctrlCreate ["RscText", -1];
                _costHeader ctrlSetPosition [0.17, 0.45, 0.28, 0.035];
                _costHeader ctrlSetText "Upgrade Cost";
                _costHeader ctrlCommit 0;

                private _costLines = [];
                for "_i" from 0 to 4 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.17, 0.49 + (_i * 0.035), 0.34, 0.033];
                    _ctrl ctrlCommit 0;
                    _costLines pushBack _ctrl;
                };

                private _reqHeader = _disp ctrlCreate ["RscText", -1];
                _reqHeader ctrlSetPosition [0.55, 0.45, 0.34, 0.035];
                _reqHeader ctrlSetText "Requirements";
                _reqHeader ctrlCommit 0;

                private _reqLines = [];
                for "_i" from 0 to 5 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.55, 0.49 + (_i * 0.035), 0.41, 0.033];
                    _ctrl ctrlCommit 0;
                    _reqLines pushBack _ctrl;
                };

                private _effectHeader = _disp ctrlCreate ["RscText", -1];
                _effectHeader ctrlSetPosition [0.17, 0.69, 0.28, 0.035];
                _effectHeader ctrlSetText "Effects";
                _effectHeader ctrlCommit 0;

                private _effectLines = [];
                for "_i" from 0 to 4 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.17, 0.73 + (_i * 0.035), 0.79, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _effectLines pushBack _ctrl;
                };

                private _button = _disp ctrlCreate ["RscButtonMenu", -1];
                _button ctrlSetPosition [0.66, 0.86, 0.14, 0.045];
                _button ctrlSetText "Upgrade";
                _button ctrlCommit 0;

                private _close = _disp ctrlCreate ["RscButtonMenu", -1];
                _close ctrlSetPosition [0.82, 0.86, 0.14, 0.045];
                _close ctrlSetText "Close";
                _close ctrlCommit 0;

                _disp setVariable ["WaldoEcoBuild_Path", _path];
                _disp setVariable ["WaldoEcoBuild_Status", _status];
                _disp setVariable ["WaldoEcoBuild_DescLines", _descLines];
                _disp setVariable ["WaldoEcoBuild_CostLines", _costLines];
                _disp setVariable ["WaldoEcoBuild_ReqLines", _reqLines];
                _disp setVariable ["WaldoEcoBuild_EffectLines", _effectLines];
                _disp setVariable ["WaldoEcoBuild_UpgradeButton", _button];

                private _setLines = {
                    params [["_controls", []], ["_rows", []]];
                    if ((typeName _controls) != "ARRAY") exitWith {};
                    if ((typeName _rows) != "ARRAY") then {_rows = [];};
                    {
                        private _index = _forEachIndex;
                        if (_index < (count _rows)) then {
                            private _row = _rows select _index;
                            _x ctrlSetText (_row param [0, ""]);
                            _x ctrlSetTextColor (_row param [1, [0.9, 0.9, 0.9, 1]]);
                        } else {
                            _x ctrlSetText "";
                            _x ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                        };
                        _x ctrlCommit 0;
                    } forEach _controls;
                };
                _disp setVariable ["WaldoEcoBuild_SetLines", _setLines];

                private _sideKeyFromActor = {
                    params [["_unit", objNull]];
                    switch (side group _unit) do {
                        case west: {"WEST"};
                        case east: {"EAST"};
                        case independent: {"GUER"};
                        default {"CIV"};
                    }
                };
                _disp setVariable ["WaldoEcoBuild_SideKeyFromActor", _sideKeyFromActor];

                private _resourceVar = {
                    params [["_sideKey", "NONE"]];
                    switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResource_Resources_WEST"};
                        case "EAST": {"WaldoEcoResource_Resources_EAST"};
                        case "GUER": {"WaldoEcoResource_Resources_GUER"};
                        default {"WaldoEcoResource_Resources_CIV"};
                    }
                };
                _disp setVariable ["WaldoEcoBuild_ResourceVar", _resourceVar];

                private _entryForName = {
                    params [["_name", ""], ["_catalog", []]];
                    private _index = _catalog findIf {((_x param [0, ""]) == _name)};
                    if (_index < 0) exitWith {[]};
                    _catalog select _index
                };
                _disp setVariable ["WaldoEcoBuild_EntryForName", _entryForName];

                private _amountFor = {
                    params [["_resourceName", ""], ["_rows", []]];
                    private _amount = 0;
                    {
                        if ((_x param [0, ""]) == _resourceName) exitWith {
                            _amount = floor (_x param [1, 0]);
                        };
                    } forEach _rows;
                    _amount
                };
                _disp setVariable ["WaldoEcoBuild_AmountFor", _amountFor];

                private _requirementMet = {
                    params [["_req", ""], ["_sideKey", "NONE"], ["_researchCatalog", []], ["_doneLower", []], ["_buildingRows", []]];
                    private _lower = toLower _req;
                    private _researchIndex = _researchCatalog findIf {(toLower (_x param [0, ""])) == _lower};
                    if (_researchIndex >= 0) exitWith {
                        ((_researchCatalog select _researchIndex) param [7, false]) || {(_doneLower find _lower) >= 0}
                    };

                    private _met = false;
                    {
                        if (
                            !isNull _x
                            && {(_x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) == _sideKey}
                            && {toLower (_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]) == _lower}
                            && {_x getVariable ["WaldoEcoBuild_Operational", true]}
                        ) exitWith {
                            _met = true;
                        };
                    } forEach _buildingRows;
                    _met
                };
                _disp setVariable ["WaldoEcoBuild_RequirementMet", _requirementMet];

                private _effectRowsFor = {
                    params [["_entry", []]];
                    private _rows = [];
                    private _produceResource = _entry param [9, ""];
                    private _produceAmount = floor (_entry param [10, 0]);
                    private _produceInterval = floor (_entry param [11, 0]);
                    if (_produceResource != "" && {_produceAmount > 0} && {_produceInterval > 0}) then {
                        _rows pushBack [format ["Produces %1 %2 every %3 sec", _produceAmount, _produceResource, _produceInterval], [0.88, 0.88, 0.88, 1]];
                    };

                    private _upkeepRows = _entry param [15, []];
                    private _upkeepInterval = floor (_entry param [16, 0]);
                    if ((typeName _upkeepRows) == "ARRAY" && {(count _upkeepRows) > 0} && {_upkeepInterval > 0}) then {
                        _rows pushBack [format ["Upkeep every %1 sec", _upkeepInterval], [0.88, 0.88, 0.88, 1]];
                    };

                    private _storageRows = _entry param [17, []];
                    if ((typeName _storageRows) == "ARRAY" && {(count _storageRows) > 0}) then {
                        _rows pushBack ["Provides resource storage", [0.88, 0.88, 0.88, 1]];
                    };

                    if ((_entry param [12, 0]) > 0) then {_rows pushBack [format ["Research speed +%1%%", _entry param [12, 0]], [0.88, 0.88, 0.88, 1]];};
                    if ((_entry param [13, 0]) > 0) then {_rows pushBack [format ["Build speed +%1%%", _entry param [13, 0]], [0.88, 0.88, 0.88, 1]];};
                    if ((_entry param [14, 0]) > 0) then {_rows pushBack [format ["Detector range %1m", _entry param [14, 0]], [0.88, 0.88, 0.88, 1]];};
                    if ((count _rows) <= 0) then {_rows pushBack ["No active effects", [0.9, 0.9, 0.9, 1]];};
                    _rows
                };
                _disp setVariable ["WaldoEcoBuild_EffectRowsFor", _effectRowsFor];

                private _refresh = {
                    params [["_display", displayNull]];
                    if (isNull _display) exitWith {};

                    private _building = _display getVariable ["WaldoEcoBuild_UpgradeBuilding", objNull];
                    private _actor = _display getVariable ["WaldoEcoBuild_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};

                    private _path = _display getVariable ["WaldoEcoBuild_Path", controlNull];
                    private _statusCtrl = _display getVariable ["WaldoEcoBuild_Status", controlNull];
                    private _button = _display getVariable ["WaldoEcoBuild_UpgradeButton", controlNull];
                    if (isNull _building || {isNull _path} || {isNull _statusCtrl} || {isNull _button}) exitWith {};

                    private _catalog = missionNamespace getVariable ["WaldoEcoBuild_BuildCatalog", []];
                    if ((typeName _catalog) != "ARRAY") then {_catalog = [];};
                    private _researchCatalog = missionNamespace getVariable ["WaldoEcoResearch_ResearchCatalog", []];
                    if ((typeName _researchCatalog) != "ARRAY") then {_researchCatalog = [];};
                    private _buildingRows = missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []];
                    if ((typeName _buildingRows) != "ARRAY") then {_buildingRows = [];};

                    private _sideKey = [_actor] call (_display getVariable ["WaldoEcoBuild_SideKeyFromActor", {}]);
                    private _ownerSide = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
                    private _currentName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", "Building"];
                    private _currentEntry = [_currentName, _catalog] call (_display getVariable ["WaldoEcoBuild_EntryForName", {}]);
                    private _targetName = _currentEntry param [18, ""];
                    private _targetEntry = [_targetName, _catalog] call (_display getVariable ["WaldoEcoBuild_EntryForName", {}]);

                    _path ctrlSetText format ["%1 -> %2", _currentName, if (_targetName == "") then {"No upgrade configured"} else {_targetName}];
                    _path ctrlCommit 0;

                    private _desc = _targetEntry param [1, "No upgrade description available."];
                    [
                        _display getVariable ["WaldoEcoBuild_DescLines", []],
                        [
                            [_desc select [0, 90], [0.88, 0.88, 0.88, 1]],
                            [_desc select [90, 90], [0.88, 0.88, 0.88, 1]],
                            [_desc select [180, 90], [0.88, 0.88, 0.88, 1]]
                        ]
                    ] call (_display getVariable ["WaldoEcoBuild_SetLines", {}]);

                    private _resourceVarName = [_sideKey] call (_display getVariable ["WaldoEcoBuild_ResourceVar", {}]);
                    private _resources = missionNamespace getVariable [_resourceVarName, []];
                    if ((typeName _resources) != "ARRAY") then {_resources = [];};

                    private _doneVar = switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
                        case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
                        case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
                        default {"WaldoEcoResearch_ResearchDone_CIV"};
                    };
                    private _doneRows = missionNamespace getVariable [_doneVar, []];
                    if ((typeName _doneRows) != "ARRAY") then {_doneRows = [];};
                    private _doneLower = _doneRows apply {toLower _x};

                    private _costOk = true;
                    private _costRows = [];
                    {
                        private _resourceName = _x param [0, ""];
                        private _cost = floor (_x param [1, 0]);
                        private _have = [_resourceName, _resources] call (_display getVariable ["WaldoEcoBuild_AmountFor", {}]);
                        private _ok = _have >= _cost;
                        if (!_ok) then {_costOk = false;};
                        _costRows pushBack [format ["%1: %2 / %3", _resourceName, _have, _cost], [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select _ok];
                    } forEach (_targetEntry param [2, []]);
                    if ((count _costRows) <= 0) then {_costRows pushBack ["No cost", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuild_CostLines", []], _costRows] call (_display getVariable ["WaldoEcoBuild_SetLines", {}]);

                    private _reqOk = true;
                    private _reqRows = [];
                    {
                        private _req = _x;
                        private _lower = toLower _req;
                        private _isResearch = (_researchCatalog findIf {(toLower (_x param [0, ""])) == _lower}) >= 0;
                        private _met = [_req, _sideKey, _researchCatalog, _doneLower, _buildingRows] call (_display getVariable ["WaldoEcoBuild_RequirementMet", {}]);
                        if (!_met) then {_reqOk = false;};
                        _reqRows pushBack [format ["%1 (%2)", _req, ["Building", "Research"] select _isResearch], [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select _met];
                    } forEach (_targetEntry param [3, []]);
                    if ((count _reqRows) <= 0) then {_reqRows pushBack ["None", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuild_ReqLines", []], _reqRows] call (_display getVariable ["WaldoEcoBuild_SetLines", {}]);

                    [_display getVariable ["WaldoEcoBuild_EffectLines", []], [_targetEntry] call (_display getVariable ["WaldoEcoBuild_EffectRowsFor", {}])] call (_display getVariable ["WaldoEcoBuild_SetLines", {}]);

                    private _groundCommandRows = missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []];
                    if ((typeName _groundCommandRows) != "ARRAY") then {_groundCommandRows = [];};
                    private _key = _actor getVariable ["WaldoEcoCommand_GroundCommandKey", ""];
                    if (_key == "") then {_key = player getVariable ["WaldoEcoCommand_GroundCommandKey", ""];};
                    private _hasCommand = ((count _groundCommandRows) <= 0) || {(_key != "") && {(_groundCommandRows find _key) >= 0}};

                    private _statusText = "Ready to upgrade";
                    private _buttonText = "Upgrade";
                    private _buttonEnabled = true;
                    if ((count _targetEntry) <= 0 || {_targetName == ""}) then {
                        _statusText = "No valid upgrade target.";
                        _buttonText = "Invalid";
                        _buttonEnabled = false;
                    };
                    if (_buttonEnabled && {_building getVariable ["WaldoEcoBuild_IsUpgrading", false]}) then {
                        _statusText = "This building is already upgrading.";
                        _buttonText = "Upgrading";
                        _buttonEnabled = false;
                    };
                    if (_buttonEnabled && {!(_ownerSide in ["WEST", "EAST", "GUER"]) || {_ownerSide != _sideKey}}) then {
                        _statusText = "Only the owning side can upgrade this building.";
                        _buttonText = "No Access";
                        _buttonEnabled = false;
                    };
                    if (_buttonEnabled && {!_hasCommand}) then {
                        _statusText = "Ground Command authority is required.";
                        _buttonText = "Ground Cmd";
                        _buttonEnabled = false;
                    };
                    if (_buttonEnabled && {!_reqOk}) then {
                        _statusText = "Requirements are not met.";
                        _buttonText = "Requirements";
                        _buttonEnabled = false;
                    };
                    if (_buttonEnabled && {!_costOk}) then {
                        _statusText = "Not enough resources.";
                        _buttonText = "Not Enough";
                        _buttonEnabled = false;
                    };

                    _statusCtrl ctrlSetText _statusText;
                    _statusCtrl ctrlSetTextColor ([[1, 0.55, 0.55, 1], [0.55, 1, 0.55, 1]] select _buttonEnabled);
                    _statusCtrl ctrlCommit 0;

                    _button ctrlSetText _buttonText;
                    _button ctrlEnable _buttonEnabled;
                    _button ctrlCommit 0;
                };
                _disp setVariable ["WaldoEcoBuild_PubUpgradeRefresh", _refresh];

                _button ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    private _display = ctrlParent _ctrl;
                    private _building = _display getVariable ["WaldoEcoBuild_UpgradeBuilding", objNull];
                    if (isNull _building) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoBuild_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};

                    private _uid = getPlayerUID player;
                    if (_uid == "") then {_uid = name _actor;};
                    private _requestId = format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)];
                    _building setVariable ["WaldoEcoBuild_BuildingManageRequest", ["UPGRADE", netId _actor, _requestId], true];
                    hintSilent "Upgrade request sent.";

                    [_display] spawn {
                        params ["_display"];
                        uiSleep 1;
                        if (!isNull _display) then {
                            [_display] call (_display getVariable ["WaldoEcoBuild_PubUpgradeRefresh", {}]);
                        };
                    };
                }];

                _close ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    (ctrlParent _ctrl) closeDisplay 1;
                }];

                [_disp] call _refresh;
            },
            nil,
            1.5,
            true,
            true,
            "",
            "private _sideKey = switch (side group _this) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'};}; private _catalog = missionNamespace getVariable ['WaldoEcoBuild_BuildCatalog', []]; if ((typeName _catalog) != 'ARRAY') then {_catalog = [];}; private _buildName = _target getVariable ['WaldoEcoBuild_BuildDefinitionName', '']; private _index = _catalog findIf {((_x param [0, '']) == _buildName)}; private _upgradeName = ''; if (_index >= 0) then {_upgradeName = (_catalog select _index) param [18, ''];}; (_upgradeName != '') && {(_target getVariable ['WaldoEcoBuild_BuildOwnerSideKey','NONE']) == _sideKey} && {!(_target getVariable ['WaldoEcoBuild_IsUpgrading', false])}",
            20
        ]

