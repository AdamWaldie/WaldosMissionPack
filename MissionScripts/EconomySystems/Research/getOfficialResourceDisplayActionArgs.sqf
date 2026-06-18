/*
 * Author: Waldo
 * Get official resource display action args.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _target <ANY> - target
 * 1: _caller <ANY> - caller
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_target, _caller] call Waldo_fnc_EcoResearch_getOfficialResourceDisplayActionArgs;
 */

        [
            "Display Resources",
            {
                params ["_target", "_caller"];

                private _actor = _caller;
                if (isNull _actor) then {_actor = player;};

                private _parent = findDisplay 46;
                if (isNull _parent) exitWith {hintSilent "Resource display unavailable.";};

                private _existing = uiNamespace getVariable ["WaldoEcoResearch_PubResourceDisplay", displayNull];
                if (!isNull _existing) then {_existing closeDisplay 1;};

                private _disp = _parent createDisplay "RscDisplayEmpty";
                if (isNull _disp) exitWith {};
                uiNamespace setVariable ["WaldoEcoResearch_PubResourceDisplay", _disp];
                _disp setVariable ["WaldoEcoResearch_RequestActorObject", _actor];
                _disp setVariable ["WaldoEcoResearch_SelectedResourceIndex", 0];
                _disp setVariable ["WaldoEcoResearch_SelectedSourceList", "producer"];
                _disp setVariable ["WaldoEcoResearch_SelectedSourceIndex", -1];
                _disp setVariable ["WaldoEcoResearch_SelectedBuilding", objNull];

                private _bg = _disp ctrlCreate ["RscText", -1];
                _bg ctrlSetPosition [0.02, 0.04, 1.12, 1.02];
                _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
                _bg ctrlCommit 0;

                private _title = _disp ctrlCreate ["RscText", -1];
                _title ctrlSetPosition [0.04, 0.055, 0.44, 0.04];
                _title ctrlSetText "Resource Display";
                _title ctrlCommit 0;

                private _sideLabel = _disp ctrlCreate ["RscText", -1];
                _sideLabel ctrlSetPosition [0.42, 0.055, 0.32, 0.04];
                _sideLabel ctrlCommit 0;

                private _resourceList = _disp ctrlCreate ["RscListbox", -1];
                _resourceList ctrlSetPosition [0.04, 0.11, 0.35, 0.86];
                _resourceList ctrlCommit 0;

                private _summaryLines = [];
                for "_i" from 0 to 4 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.42, 0.11 + (_i * 0.04), 0.68, 0.038];
                    _ctrl ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                    _ctrl ctrlCommit 0;
                    _summaryLines pushBack _ctrl;
                };

                private _producerLabel = _disp ctrlCreate ["RscText", -1];
                _producerLabel ctrlSetPosition [0.42, 0.34, 0.32, 0.035];
                _producerLabel ctrlSetText "Producing";
                _producerLabel ctrlCommit 0;

                private _consumerLabel = _disp ctrlCreate ["RscText", -1];
                _consumerLabel ctrlSetPosition [0.76, 0.34, 0.34, 0.035];
                _consumerLabel ctrlSetText "Consuming";
                _consumerLabel ctrlCommit 0;

                private _producerList = _disp ctrlCreate ["RscListbox", -1];
                _producerList ctrlSetPosition [0.42, 0.38, 0.32, 0.28];
                _producerList ctrlCommit 0;

                private _consumerList = _disp ctrlCreate ["RscListbox", -1];
                _consumerList ctrlSetPosition [0.76, 0.38, 0.34, 0.28];
                _consumerList ctrlCommit 0;

                private _detailsLines = [];
                for "_i" from 0 to 6 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.42, 0.69 + (_i * 0.035), 0.68, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _detailsLines pushBack _ctrl;
                };

                private _actionButton = _disp ctrlCreate ["RscButtonMenu", -1];
                _actionButton ctrlSetPosition [0.74, 1.00, 0.18, 0.05];
                _actionButton ctrlSetText "No Building";
                _actionButton ctrlEnable false;
                _actionButton ctrlCommit 0;

                private _close = _disp ctrlCreate ["RscButtonMenu", -1];
                _close ctrlSetPosition [0.93, 1.00, 0.16, 0.05];
                _close ctrlSetText "Close";
                _close ctrlCommit 0;

                _disp setVariable ["WaldoEcoResearch_ResourceList", _resourceList];
                _disp setVariable ["WaldoEcoResearch_SideLabel", _sideLabel];
                _disp setVariable ["WaldoEcoResearch_SummaryLines", _summaryLines];
                _disp setVariable ["WaldoEcoResearch_ProducerLabel", _producerLabel];
                _disp setVariable ["WaldoEcoResearch_ConsumerLabel", _consumerLabel];
                _disp setVariable ["WaldoEcoResearch_ProducerList", _producerList];
                _disp setVariable ["WaldoEcoResearch_ConsumerList", _consumerList];
                _disp setVariable ["WaldoEcoResearch_DetailsLines", _detailsLines];
                _disp setVariable ["WaldoEcoResearch_ActionButton", _actionButton];

                private _sideKeyFromActor = {
                    params [["_unit", objNull]];
                    switch (side group _unit) do {
                        case west: {"WEST"};
                        case east: {"EAST"};
                        case independent: {"GUER"};
                        case civilian: {"CIV"};
                        default {"CIV"};
                    }
                };

                private _sideLabelFromKey = {
                    params [["_sideKey", "NONE"]];
                    switch (_sideKey) do {
                        case "WEST": {"BLUFOR"};
                        case "EAST": {"OPFOR"};
                        case "GUER": {"INDEPENDENT"};
                        case "CIV": {"CIVILIAN"};
                        default {"NONE"};
                    }
                };

                private _resourceVar = {
                    params [["_sideKey", "NONE"]];
                    switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResource_Resources_WEST"};
                        case "EAST": {"WaldoEcoResource_Resources_EAST"};
                        case "GUER": {"WaldoEcoResource_Resources_GUER"};
                        case "CIV": {"WaldoEcoResource_Resources_CIV"};
                        default {""};
                    }
                };

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

                private _buildEntryFor = {
                    params [["_buildName", ""], ["_catalog", []]];
                    private _index = _catalog findIf {((_x param [0, ""]) == _buildName)};
                    if (_index < 0) exitWith {[]};
                    _catalog select _index
                };

                private _capacityFor = {
                    params [["_resourceName", ""], ["_sideKey", "NONE"], ["_resourceCatalog", []], ["_buildCatalog", []], ["_buildings", []], ["_buildEntryFn", {}]];

                    private _base = -1;
                    {
                        if ((_x param [0, ""]) == _resourceName) exitWith {
                            _base = floor (_x param [3, -1]);
                        };
                    } forEach _resourceCatalog;
                    if (_base <= 0) exitWith {-1};

                    private _bonus = 0;
                    {
                        private _building = _x;
                        if (isNull _building) then {continue;};
                        if ((_building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) != _sideKey) then {continue;};
                        if !(_building getVariable ["WaldoEcoBuild_Operational", true]) then {continue;};

                        private _entry = [_building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""], _buildCatalog] call _buildEntryFn;
                        if ((count _entry) <= 0) then {continue;};

                        private _storageRows = _entry param [17, []];
                        if ((typeName _storageRows) != "ARRAY") then {_storageRows = [];};
                        {
                            if ((_x param [0, ""]) == _resourceName) then {
                                _bonus = _bonus + floor (_x param [1, 0]);
                            };
                        } forEach _storageRows;
                    } forEach _buildings;

                    _base + _bonus
                };

                private _sourceRowsFor = {
                    params [["_resourceName", ""], ["_sideKey", "NONE"], ["_zones", []], ["_buildCatalog", []], ["_buildings", []], ["_buildEntryFn", {}]];

                    private _producerRows = [];
                    private _consumerRows = [];
                    private _gainPerMin = 0;
                    private _lossPerMin = 0;

                    {
                        private _zone = _x;
                        if ((typeName _zone) != "ARRAY") then {continue;};
                        if ((_zone param [5, "NONE"]) != _sideKey) then {continue;};

                        private _zoneName = _zone param [1, "Resource Zone"];
                        private _interval = 1 max (floor (_zone param [7, 60]));
                        private _resourceRows = _zone param [4, []];
                        if ((typeName _resourceRows) != "ARRAY") then {_resourceRows = [];};

                        {
                            if ((_x param [0, ""]) != _resourceName) then {continue;};
                            private _amount = floor (_x param [1, 0]);
                            private _remaining = floor (_x param [2, -1]);
                            private _total = floor (_x param [3, -1]);
                            if (_amount <= 0) then {continue;};
                            if (_total > 0 && {_remaining <= 0}) then {continue;};

                            _gainPerMin = _gainPerMin + ((_amount * 60) / _interval);
                            private _leftText = "infinite";
                            if (_total > 0) then {_leftText = format ["%1/%2 left", 0 max _remaining, _total];};
                            _producerRows pushBack [
                                format ["%1 | +%2 / %3s", _zoneName, _amount, _interval],
                                "",
                                [
                                    _zoneName,
                                    "Type: Resource Zone",
                                    format ["Owner: %1", _sideKey],
                                    format ["Output: +%1 %2 every %3 sec", _amount, _resourceName, _interval],
                                    format ["Deposit: %1", _leftText]
                                ],
                                true
                            ];
                        } forEach _resourceRows;
                    } forEach _zones;

                    {
                        private _building = _x;
                        if (isNull _building) then {continue;};
                        if ((_building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) != _sideKey) then {continue;};

                        private _entry = [_building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""], _buildCatalog] call _buildEntryFn;
                        if ((count _entry) <= 0) then {continue;};

                        private _buildName = _entry param [0, "Building"];
                        private _operational = _building getVariable ["WaldoEcoBuild_Operational", true];
                        private _statusText = if (_operational) then {"ACTIVE"} else {"DISABLED"};
                        private _disabledReason = _building getVariable ["WaldoEcoBuild_DisabledReason", ""];
                        if (!_operational && {_disabledReason != ""}) then {
                            _statusText = _statusText + " - " + _disabledReason;
                        };

                        private _produceResource = _entry param [9, ""];
                        private _produceAmount = floor (_entry param [10, 0]);
                        private _produceInterval = floor (_entry param [11, 0]);
                        if (_produceResource == _resourceName && {_produceAmount > 0} && {_produceInterval > 0}) then {
                            if (_operational) then {
                                _gainPerMin = _gainPerMin + ((_produceAmount * 60) / _produceInterval);
                            };
                            _producerRows pushBack [
                                format ["%1 | +%2 / %3s", _buildName, _produceAmount, _produceInterval],
                                netId _building,
                                [
                                    _buildName,
                                    "Type: Building Producer",
                                    format ["Status: %1", _statusText],
                                    format ["Output: +%1 %2 every %3 sec", _produceAmount, _resourceName, _produceInterval],
                                    _entry param [1, ""]
                                ],
                                _operational
                            ];
                        };

                        private _upkeepRows = _entry param [15, []];
                        if ((typeName _upkeepRows) != "ARRAY") then {_upkeepRows = [];};
                        private _upkeepInterval = floor (_entry param [16, 0]);
                        if (_upkeepInterval > 0) then {
                            {
                                if ((_x param [0, ""]) != _resourceName) then {continue;};
                                private _consumeAmount = floor (_x param [1, 0]);
                                if (_consumeAmount <= 0) then {continue;};
                                if (_operational) then {
                                    _lossPerMin = _lossPerMin + ((_consumeAmount * 60) / _upkeepInterval);
                                };
                                _consumerRows pushBack [
                                    format ["%1 | -%2 / %3s", _buildName, _consumeAmount, _upkeepInterval],
                                    netId _building,
                                    [
                                        _buildName,
                                        "Type: Building Consumer",
                                        format ["Status: %1", _statusText],
                                        format ["Upkeep: -%1 %2 every %3 sec", _consumeAmount, _resourceName, _upkeepInterval],
                                        _entry param [1, ""]
                                    ],
                                    _operational
                                ];
                            } forEach _upkeepRows;
                        };
                    } forEach _buildings;

                    [_producerRows, _consumerRows, _gainPerMin - _lossPerMin]
                };

                _disp setVariable ["WaldoEcoResearch_SideKeyFromActor", _sideKeyFromActor];
                _disp setVariable ["WaldoEcoResearch_SideLabelFromKey", _sideLabelFromKey];
                _disp setVariable ["WaldoEcoResearch_ResourceVar", _resourceVar];
                _disp setVariable ["WaldoEcoResearch_AmountFor", _amountFor];
                _disp setVariable ["WaldoEcoResearch_BuildEntryFor", _buildEntryFor];
                _disp setVariable ["WaldoEcoResearch_CapacityFor", _capacityFor];
                _disp setVariable ["WaldoEcoResearch_SourceRowsFor", _sourceRowsFor];

                private _setDetailLines = {
                    params [["_display", displayNull], ["_rows", []]];
                    private _lines = _display getVariable ["WaldoEcoResearch_DetailsLines", []];
                    {
                        private _index = _forEachIndex;
                        if (_index < (count _rows)) then {
                            _x ctrlSetText (_rows select _index);
                        } else {
                            _x ctrlSetText "";
                        };
                        _x ctrlCommit 0;
                    } forEach _lines;
                };
                _disp setVariable ["WaldoEcoResearch_SetDetailLines", _setDetailLines];

                private _refreshSelection = {
                    params [["_display", displayNull]];
                    if (isNull _display) exitWith {};

                    private _sourceList = _display getVariable ["WaldoEcoResearch_SelectedSourceList", "producer"];
                    private _rows = if (_sourceList == "consumer") then {
                        _display getVariable ["WaldoEcoResearch_ConsumerRows", []]
                    } else {
                        _display getVariable ["WaldoEcoResearch_ProducerRows", []]
                    };
                    private _list = if (_sourceList == "consumer") then {
                        _display getVariable ["WaldoEcoResearch_ConsumerList", controlNull]
                    } else {
                        _display getVariable ["WaldoEcoResearch_ProducerList", controlNull]
                    };

                    private _index = if (isNull _list) then {-1} else {lbCurSel _list};
                    if (_index < 0 || {_index >= count _rows}) exitWith {
                        _display setVariable ["WaldoEcoResearch_SelectedBuilding", objNull];
                        [_display, ["Select a producer or consumer to inspect it."]] call (_display getVariable ["WaldoEcoResearch_SetDetailLines", {}]);
                        private _button = _display getVariable ["WaldoEcoResearch_ActionButton", controlNull];
                        if (!isNull _button) then {
                            _button ctrlSetText "No Building";
                            _button ctrlEnable false;
                            _button ctrlCommit 0;
                        };
                    };

                    private _row = _rows select _index;
                    private _building = objectFromNetId (_row param [1, ""]);
                    _display setVariable ["WaldoEcoResearch_SelectedBuilding", _building];
                    [_display, _row param [2, []]] call (_display getVariable ["WaldoEcoResearch_SetDetailLines", {}]);

                    private _button = _display getVariable ["WaldoEcoResearch_ActionButton", controlNull];
                    if (isNull _button) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoResearch_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};

                    private _canManage = false;
                    if (!isNull _building) then {
                        private _ownerSide = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
                        private _sideKey = [_actor] call (_display getVariable ["WaldoEcoResearch_SideKeyFromActor", {}]);
                        private _groundCommandRows = missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []];
                        if ((typeName _groundCommandRows) != "ARRAY") then {_groundCommandRows = [];};
                        private _key = _actor getVariable ["WaldoEcoCommand_GroundCommandKey", ""];
                        if (_key == "") then {_key = player getVariable ["WaldoEcoCommand_GroundCommandKey", ""];};
                        private _hasCommand = ((count _groundCommandRows) <= 0)
                            || {(_key != "") && {(_groundCommandRows find _key) >= 0}};
                        _canManage = (_ownerSide == _sideKey) && {_ownerSide in ["WEST", "EAST", "GUER"]} && {_hasCommand};
                    };

                    if (_canManage) then {
                        private _operational = _building getVariable ["WaldoEcoBuild_Operational", true];
                        _button ctrlSetText (["Enable Building", "Disable Building"] select _operational);
                        _button ctrlEnable true;
                    } else {
                        _button ctrlSetText "No Access";
                        _button ctrlEnable false;
                    };
                    _button ctrlCommit 0;
                };
                _disp setVariable ["WaldoEcoResearch_RefreshSelection", _refreshSelection];

                private _refresh = {
                    params [["_display", displayNull], ["_rebuild", true]];
                    if (isNull _display) exitWith {};

                    private _resourceList = _display getVariable ["WaldoEcoResearch_ResourceList", controlNull];
                    private _sideLabel = _display getVariable ["WaldoEcoResearch_SideLabel", controlNull];
                    private _producerList = _display getVariable ["WaldoEcoResearch_ProducerList", controlNull];
                    private _consumerList = _display getVariable ["WaldoEcoResearch_ConsumerList", controlNull];
                    private _producerLabel = _display getVariable ["WaldoEcoResearch_ProducerLabel", controlNull];
                    private _consumerLabel = _display getVariable ["WaldoEcoResearch_ConsumerLabel", controlNull];
                    if (isNull _resourceList || {isNull _producerList} || {isNull _consumerList}) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoResearch_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};
                    private _sideKey = [_actor] call (_display getVariable ["WaldoEcoResearch_SideKeyFromActor", {}]);
                    private _sideLabelText = [_sideKey] call (_display getVariable ["WaldoEcoResearch_SideLabelFromKey", {}]);
                    if (!isNull _sideLabel) then {
                        _sideLabel ctrlSetText format ["Your side: %1", _sideLabelText];
                        _sideLabel ctrlCommit 0;
                    };

                    private _resourceCatalog = missionNamespace getVariable ["WaldoEcoResource_ResourceCatalog", []];
                    if ((typeName _resourceCatalog) != "ARRAY") then {_resourceCatalog = [];};
                    private _buildCatalog = missionNamespace getVariable ["WaldoEcoBuild_BuildCatalog", []];
                    if ((typeName _buildCatalog) != "ARRAY") then {_buildCatalog = [];};
                    private _buildings = missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []];
                    if ((typeName _buildings) != "ARRAY") then {_buildings = [];};
                    private _zones = missionNamespace getVariable ["WaldoEcoResource_ResourceZones", []];
                    if ((typeName _zones) != "ARRAY") then {_zones = [];};
                    private _resourceRows = missionNamespace getVariable [[_sideKey] call (_display getVariable ["WaldoEcoResearch_ResourceVar", {}]), []];
                    if ((typeName _resourceRows) != "ARRAY") then {_resourceRows = [];};

                    if (_rebuild) then {
                        lbClear _resourceList;
                        {
                            private _resourceName = _x param [0, "Resource"];
                            private _stats = [_resourceName, _sideKey, _zones, _buildCatalog, _buildings, _display getVariable ["WaldoEcoResearch_BuildEntryFor", {}]] call (_display getVariable ["WaldoEcoResearch_SourceRowsFor", {}]);
                            private _net = _stats param [2, 0];
                            private _amount = [_resourceName, _resourceRows] call (_display getVariable ["WaldoEcoResearch_AmountFor", {}]);
                            private _capacity = [_resourceName, _sideKey, _resourceCatalog, _buildCatalog, _buildings, _display getVariable ["WaldoEcoResearch_BuildEntryFor", {}]] call (_display getVariable ["WaldoEcoResearch_CapacityFor", {}]);
                            private _capText = if (_capacity > 0) then {format ["/%1", _capacity]} else {""};
                            private _index = _resourceList lbAdd format ["%1: %2%3", _resourceName, _amount, _capText];
                            _resourceList lbSetData [_index, _resourceName];
                            if (_net > 0.01) then {_resourceList lbSetColor [_index, [0.68, 1.0, 0.68, 1]];};
                            if (_net < -0.01) then {_resourceList lbSetColor [_index, [1.0, 0.62, 0.62, 1]];};
                            if (_net > 0.01) then {_resourceList lbSetTextRight [_index, format ["+%1/min", floor _net]];};
                            if (_net < -0.01) then {_resourceList lbSetTextRight [_index, format ["%1/min", floor _net]];};
                            if (_net >= -0.01 && {_net <= 0.01}) then {_resourceList lbSetTextRight [_index, "+0/min"];};
                        } forEach _resourceCatalog;
                    };

                    private _selected = _display getVariable ["WaldoEcoResearch_SelectedResourceIndex", 0];
                    if (_selected < 0) then {_selected = 0;};
                    if (_selected >= lbSize _resourceList) then {_selected = (lbSize _resourceList) - 1;};
                    if (_selected < 0 || {(count _resourceCatalog) <= 0}) exitWith {
                        private _summaryLines = _display getVariable ["WaldoEcoResearch_SummaryLines", []];
                        {
                            _x ctrlSetText "";
                            _x ctrlCommit 0;
                        } forEach _summaryLines;
                        lbClear _producerList;
                        lbClear _consumerList;
                        [_display, ["No resources configured."]] call (_display getVariable ["WaldoEcoResearch_SetDetailLines", {}]);
                    };

                    _display setVariable ["WaldoEcoResearch_SelectedResourceIndex", _selected];
                    if (_rebuild) then {_resourceList lbSetCurSel _selected;};

                    private _resourceName = _resourceList lbData _selected;
                    private _amount = [_resourceName, _resourceRows] call (_display getVariable ["WaldoEcoResearch_AmountFor", {}]);
                    private _capacity = [_resourceName, _sideKey, _resourceCatalog, _buildCatalog, _buildings, _display getVariable ["WaldoEcoResearch_BuildEntryFor", {}]] call (_display getVariable ["WaldoEcoResearch_CapacityFor", {}]);
                    private _stats = [_resourceName, _sideKey, _zones, _buildCatalog, _buildings, _display getVariable ["WaldoEcoResearch_BuildEntryFor", {}]] call (_display getVariable ["WaldoEcoResearch_SourceRowsFor", {}]);
                    private _producerRows = _stats param [0, []];
                    private _consumerRows = _stats param [1, []];
                    private _net = _stats param [2, 0];
                    _display setVariable ["WaldoEcoResearch_ProducerRows", _producerRows];
                    _display setVariable ["WaldoEcoResearch_ConsumerRows", _consumerRows];

                    private _summaryRows = [
                        format ["Resource: %1", _resourceName],
                        format ["Stored: %1%2", _amount, if (_capacity > 0) then {format [" / %1", _capacity]} else {" / Unlimited"}],
                        format ["Net: %1%2 per minute", if (_net > 0) then {"+"} else {""}, floor _net],
                        format ["Producing sources: %1", count _producerRows],
                        format ["Consuming sources: %1", count _consumerRows]
                    ];
                    {
                        private _index = _forEachIndex;
                        _x ctrlSetText (_summaryRows select _index);
                        if (_index == 2) then {
                            _x ctrlSetTextColor ([[1, 0.55, 0.55, 1], [0.55, 1, 0.55, 1]] select (_net >= 0));
                        } else {
                            _x ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                        };
                        _x ctrlCommit 0;
                    } forEach (_display getVariable ["WaldoEcoResearch_SummaryLines", []]);

                    lbClear _producerList;
                    {
                        private _index = _producerList lbAdd (_x param [0, ""]);
                        _producerList lbSetData [_index, _x param [1, ""]];
                        if !(_x param [3, true]) then {_producerList lbSetColor [_index, [1, 0.45, 0.45, 1]];};
                    } forEach _producerRows;

                    lbClear _consumerList;
                    {
                        private _index = _consumerList lbAdd (_x param [0, ""]);
                        _consumerList lbSetData [_index, _x param [1, ""]];
                        if !(_x param [3, true]) then {_consumerList lbSetColor [_index, [1, 0.45, 0.45, 1]];};
                    } forEach _consumerRows;

                    if (!isNull _producerLabel) then {
                        _producerLabel ctrlSetText format ["Producing (%1)", count _producerRows];
                        _producerLabel ctrlCommit 0;
                    };
                    if (!isNull _consumerLabel) then {
                        _consumerLabel ctrlSetText format ["Consuming (%1)", count _consumerRows];
                        _consumerLabel ctrlCommit 0;
                    };

                    private _sourceList = _display getVariable ["WaldoEcoResearch_SelectedSourceList", "producer"];
                    private _sourceIndex = _display getVariable ["WaldoEcoResearch_SelectedSourceIndex", -1];
                    if (_sourceList == "consumer") then {
                        if (_sourceIndex >= 0 && {_sourceIndex < lbSize _consumerList}) then {
                            _consumerList lbSetCurSel _sourceIndex;
                        } else {
                            _consumerList lbSetCurSel -1;
                        };
                        _producerList lbSetCurSel -1;
                    } else {
                        if (_sourceIndex >= 0 && {_sourceIndex < lbSize _producerList}) then {
                            _producerList lbSetCurSel _sourceIndex;
                        } else {
                            if ((lbSize _producerList) > 0) then {
                                _producerList lbSetCurSel 0;
                                _display setVariable ["WaldoEcoResearch_SelectedSourceIndex", 0];
                            } else {
                                _producerList lbSetCurSel -1;
                            };
                        };
                        _consumerList lbSetCurSel -1;
                    };

                    [_display] call (_display getVariable ["WaldoEcoResearch_RefreshSelection", {}]);
                };
                _disp setVariable ["WaldoEcoResearch_Refresh", _refresh];

                _resourceList ctrlAddEventHandler ["LBSelChanged", {
                    params ["_ctrl", "_index"];
                    private _display = ctrlParent _ctrl;
                    if (_index < 0) exitWith {};
                    _display setVariable ["WaldoEcoResearch_SelectedResourceIndex", _index];
                    _display setVariable ["WaldoEcoResearch_SelectedSourceList", "producer"];
                    _display setVariable ["WaldoEcoResearch_SelectedSourceIndex", -1];
                    [_display, false] call (_display getVariable ["WaldoEcoResearch_Refresh", {}]);
                }];

                _producerList ctrlAddEventHandler ["LBSelChanged", {
                    params ["_ctrl", "_index"];
                    if (_index < 0) exitWith {};
                    private _display = ctrlParent _ctrl;
                    _display setVariable ["WaldoEcoResearch_SelectedSourceList", "producer"];
                    _display setVariable ["WaldoEcoResearch_SelectedSourceIndex", _index];
                    private _other = _display getVariable ["WaldoEcoResearch_ConsumerList", controlNull];
                    if (!isNull _other) then {_other lbSetCurSel -1;};
                    [_display] call (_display getVariable ["WaldoEcoResearch_RefreshSelection", {}]);
                }];

                _consumerList ctrlAddEventHandler ["LBSelChanged", {
                    params ["_ctrl", "_index"];
                    if (_index < 0) exitWith {};
                    private _display = ctrlParent _ctrl;
                    _display setVariable ["WaldoEcoResearch_SelectedSourceList", "consumer"];
                    _display setVariable ["WaldoEcoResearch_SelectedSourceIndex", _index];
                    private _other = _display getVariable ["WaldoEcoResearch_ProducerList", controlNull];
                    if (!isNull _other) then {_other lbSetCurSel -1;};
                    [_display] call (_display getVariable ["WaldoEcoResearch_RefreshSelection", {}]);
                }];

                _actionButton ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    private _display = ctrlParent _ctrl;
                    private _building = _display getVariable ["WaldoEcoResearch_SelectedBuilding", objNull];
                    if (isNull _building) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoResearch_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};

                    private _operation = if (_building getVariable ["WaldoEcoBuild_Operational", true]) then {"DISABLE"} else {"ENABLE"};
                    private _uid = getPlayerUID player;
                    if (_uid == "") then {_uid = name _actor;};
                    private _requestId = format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)];
                    _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [_operation, netId _actor, _requestId], true];
                    hintSilent format ["%1 request sent.", _operation];

                    [_display] spawn {
                        params ["_display"];
                        uiSleep 1;
                        if (!isNull _display) then {
                            [_display, true] call (_display getVariable ["WaldoEcoResearch_Refresh", {}]);
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
                            [_display, true] call (_display getVariable ["WaldoEcoResearch_Refresh", {}]);
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

