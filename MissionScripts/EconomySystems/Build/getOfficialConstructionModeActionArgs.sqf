/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getOfficialConstructionModeActionArgs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getOfficialConstructionModeActionArgs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        [
            "Construction Mode",
            {
                params ["_target", "_caller"];

                private _actor = _caller;
                if (isNull _actor) then {_actor = player;};

                private _parent = findDisplay 46;
                if (isNull _parent) exitWith {hintSilent "Construction display unavailable.";};

                private _existing = uiNamespace getVariable ["WaldoEcoBuild_PubConstructionDisplay", displayNull];
                if (!isNull _existing) then {_existing closeDisplay 1;};

                private _disp = _parent createDisplay "RscDisplayEmpty";
                if (isNull _disp) exitWith {};
                uiNamespace setVariable ["WaldoEcoBuild_PubConstructionDisplay", _disp];

                _disp setVariable ["WaldoEcoBuild_ConstructionSource", _target];
                _disp setVariable ["WaldoEcoBuild_RequestActorObject", _actor];
                _disp setVariable ["WaldoEcoBuild_PlayerSelectedIndex", 0];
                _disp setVariable ["WaldoEcoBuild_PlayerSelectedCategory", "ALL"];
                _disp setVariable ["WaldoEcoBuild_PlayerCategoryOptions", ["ALL"]];

                private _bg = _disp ctrlCreate ["RscText", -1];
                _bg ctrlSetPosition [0.02, 0.04, 1.10, 1.06];
                _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
                _bg ctrlCommit 0;

                private _title = _disp ctrlCreate ["RscText", -1];
                _title ctrlSetPosition [0.04, 0.055, 0.46, 0.04];
                _title ctrlSetText "Construct Building";
                _title ctrlCommit 0;

                private _categoryLabel = _disp ctrlCreate ["RscText", -1];
                _categoryLabel ctrlSetPosition [0.04, 0.105, 0.16, 0.03];
                _categoryLabel ctrlSetText "Category";
                _categoryLabel ctrlSetTextColor [0.92, 0.92, 0.92, 1];
                _categoryLabel ctrlCommit 0;

                private _categoryPrev = _disp ctrlCreate ["RscButtonMenu", -1];
                _categoryPrev ctrlSetPosition [0.04, 0.14, 0.045, 0.045];
                _categoryPrev ctrlSetText "<";
                _categoryPrev ctrlCommit 0;

                private _categoryValue = _disp ctrlCreate ["RscText", -1];
                _categoryValue ctrlSetPosition [0.09, 0.14, 0.25, 0.045];
                _categoryValue ctrlSetText "ALL";
                _categoryValue ctrlSetBackgroundColor [0, 0, 0, 0.25];
                _categoryValue ctrlSetTextColor [0.92, 0.92, 0.92, 1];
                _categoryValue ctrlCommit 0;

                private _categoryNext = _disp ctrlCreate ["RscButtonMenu", -1];
                _categoryNext ctrlSetPosition [0.345, 0.14, 0.045, 0.045];
                _categoryNext ctrlSetText ">";
                _categoryNext ctrlCommit 0;

                private _list = _disp ctrlCreate ["RscListbox", -1];
                _list ctrlSetPosition [0.04, 0.20, 0.35, 0.82];
                _list ctrlCommit 0;

                private _nameCtrl = _disp ctrlCreate ["RscText", -1];
                _nameCtrl ctrlSetPosition [0.43, 0.08, 0.66, 0.045];
                _nameCtrl ctrlCommit 0;

                private _statusCtrl = _disp ctrlCreate ["RscText", -1];
                _statusCtrl ctrlSetPosition [0.43, 0.13, 0.66, 0.04];
                _statusCtrl ctrlCommit 0;

                private _descLines = [];
                for "_i" from 0 to 2 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.43, 0.18 + (_i * 0.035), 0.66, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _descLines pushBack _ctrl;
                };

                private _timeCtrl = _disp ctrlCreate ["RscText", -1];
                _timeCtrl ctrlSetPosition [0.43, 0.295, 0.32, 0.035];
                _timeCtrl ctrlCommit 0;

                private _limitCtrl = _disp ctrlCreate ["RscText", -1];
                _limitCtrl ctrlSetPosition [0.76, 0.295, 0.32, 0.035];
                _limitCtrl ctrlCommit 0;

                private _costHeader = _disp ctrlCreate ["RscText", -1];
                _costHeader ctrlSetPosition [0.43, 0.35, 0.28, 0.035];
                _costHeader ctrlSetText "Build Cost";
                _costHeader ctrlCommit 0;

                private _costLines = [];
                for "_i" from 0 to 3 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.43, 0.39 + (_i * 0.035), 0.32, 0.033];
                    _ctrl ctrlCommit 0;
                    _costLines pushBack _ctrl;
                };

                private _reqHeader = _disp ctrlCreate ["RscText", -1];
                _reqHeader ctrlSetPosition [0.76, 0.35, 0.32, 0.035];
                _reqHeader ctrlSetText "Requirements";
                _reqHeader ctrlCommit 0;

                private _reqLines = [];
                for "_i" from 0 to 4 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.76, 0.39 + (_i * 0.035), 0.32, 0.033];
                    _ctrl ctrlCommit 0;
                    _reqLines pushBack _ctrl;
                };

                private _effectsHeader = _disp ctrlCreate ["RscText", -1];
                _effectsHeader ctrlSetPosition [0.43, 0.60, 0.32, 0.035];
                _effectsHeader ctrlSetText "Effects";
                _effectsHeader ctrlCommit 0;

                private _effectLines = [];
                for "_i" from 0 to 7 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.43, 0.64 + (_i * 0.035), 0.66, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _effectLines pushBack _ctrl;
                };

                private _button = _disp ctrlCreate ["RscButtonMenu", -1];
                _button ctrlSetPosition [0.75, 1.03, 0.17, 0.055];
                _button ctrlSetText "Place";
                _button ctrlCommit 0;

                private _close = _disp ctrlCreate ["RscButtonMenu", -1];
                _close ctrlSetPosition [0.93, 1.03, 0.16, 0.055];
                _close ctrlSetText "Close";
                _close ctrlCommit 0;

                _disp setVariable ["WaldoEcoBuild_PlayerList", _list];
                _disp setVariable ["WaldoEcoBuild_PlayerCategoryPrev", _categoryPrev];
                _disp setVariable ["WaldoEcoBuild_PlayerCategoryValue", _categoryValue];
                _disp setVariable ["WaldoEcoBuild_PlayerCategoryNext", _categoryNext];
                _disp setVariable ["WaldoEcoBuild_PlayerName", _nameCtrl];
                _disp setVariable ["WaldoEcoBuild_PlayerStatus", _statusCtrl];
                _disp setVariable ["WaldoEcoBuild_PlayerDescLines", _descLines];
                _disp setVariable ["WaldoEcoBuild_PlayerTime", _timeCtrl];
                _disp setVariable ["WaldoEcoBuild_PlayerLimit", _limitCtrl];
                _disp setVariable ["WaldoEcoBuild_PlayerCostLines", _costLines];
                _disp setVariable ["WaldoEcoBuild_PlayerReqLines", _reqLines];
                _disp setVariable ["WaldoEcoBuild_PlayerEffectLines", _effectLines];
                _disp setVariable ["WaldoEcoBuild_PlayerButton", _button];

                private _refresh = {
                    params [["_display", displayNull], ["_rebuild", true]];
                    if (isNull _display) exitWith {};

                    private _list = _display getVariable ["WaldoEcoBuild_PlayerList", controlNull];
                    private _categoryValue = _display getVariable ["WaldoEcoBuild_PlayerCategoryValue", controlNull];
                    private _categoryPrev = _display getVariable ["WaldoEcoBuild_PlayerCategoryPrev", controlNull];
                    private _categoryNext = _display getVariable ["WaldoEcoBuild_PlayerCategoryNext", controlNull];
                    private _nameCtrl = _display getVariable ["WaldoEcoBuild_PlayerName", controlNull];
                    private _statusCtrl = _display getVariable ["WaldoEcoBuild_PlayerStatus", controlNull];
                    private _timeCtrl = _display getVariable ["WaldoEcoBuild_PlayerTime", controlNull];
                    private _limitCtrl = _display getVariable ["WaldoEcoBuild_PlayerLimit", controlNull];
                    private _button = _display getVariable ["WaldoEcoBuild_PlayerButton", controlNull];
                    if (isNull _list || isNull _button || isNull _nameCtrl || isNull _statusCtrl) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoBuild_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};

                    private _sideKey = switch (side group _actor) do {
                        case west: {"WEST"};
                        case east: {"EAST"};
                        case independent: {"GUER"};
                        default {"CIV"};
                    };

                    private _resourceVar = switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResource_Resources_WEST"};
                        case "EAST": {"WaldoEcoResource_Resources_EAST"};
                        case "GUER": {"WaldoEcoResource_Resources_GUER"};
                        default {"WaldoEcoResource_Resources_CIV"};
                    };
                    private _researchDoneVar = switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
                        case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
                        case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
                        default {"WaldoEcoResearch_ResearchDone_CIV"};
                    };

                    private _resources = missionNamespace getVariable [_resourceVar, []];
                    if ((typeName _resources) != "ARRAY") then {_resources = [];};
                    private _doneRows = missionNamespace getVariable [_researchDoneVar, []];
                    if ((typeName _doneRows) != "ARRAY") then {_doneRows = [];};
                    private _doneLower = _doneRows apply {toLower _x};
                    private _researchCatalog = missionNamespace getVariable ["WaldoEcoResearch_ResearchCatalog", []];
                    if ((typeName _researchCatalog) != "ARRAY") then {_researchCatalog = [];};
                    private _buildings = missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []];
                    if ((typeName _buildings) != "ARRAY") then {_buildings = [];};
                    private _activeJobs = missionNamespace getVariable ["WaldoEcoBuild_ActiveConstructionJobs", []];
                    if ((typeName _activeJobs) != "ARRAY") then {_activeJobs = [];};
                    private _catalogRaw = missionNamespace getVariable ["WaldoEcoBuild_BuildCatalog", []];
                    if ((typeName _catalogRaw) != "ARRAY") then {_catalogRaw = [];};

                    private _uid = getPlayerUID player;
                    private _groundCommandRows = missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []];
                    if ((typeName _groundCommandRows) != "ARRAY") then {_groundCommandRows = [];};
                    private _hasCommand = ((count _groundCommandRows) <= 0) || {(_groundCommandRows find _uid) >= 0};

                    private _getAmount = {
                        params ["_resourceName", "_rows"];
                        private _amount = 0;
                        {
                            if ((_x param [0, ""]) == _resourceName) exitWith {
                                _amount = floor (_x param [1, 0]);
                            };
                        } forEach _rows;
                        _amount
                    };

                    private _availableForSide = {
                        params ["_entry", "_side"];
                        private _availability = _entry param [20, ["ALL"]];
                        if ((typeName _availability) != "ARRAY") then {_availability = [_availability];};
                        ((_availability find "ALL") >= 0) || {(_availability find _side) >= 0}
                    };

                    private _buildCount = {
                        params ["_side", "_name", "_buildingRows", "_jobRows"];
                        private _count = 0;
                        {
                            if (
                                !isNull _x
                                && {(_x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) == _side}
                                && {(_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]) == _name}
                            ) then {
                                _count = _count + 1;
                            };
                        } forEach _buildingRows;
                        {
                            if (((_x param [1, ""]) == _name) && {(_x param [2, "NONE"]) == _side}) then {
                                _count = _count + 1;
                            };
                        } forEach _jobRows;
                        _count
                    };

                    private _requirementMet = {
                        params ["_req", "_side", "_researchRows", "_doneLowerRows", "_buildingRows"];
                        private _lower = toLower _req;
                        private _researchIndex = _researchRows findIf {(toLower (_x param [0, ""])) == _lower};
                        if (_researchIndex >= 0) exitWith {
                            ((_researchRows select _researchIndex) param [7, false]) || {(_doneLowerRows find _lower) >= 0}
                        };

                        private _met = false;
                        {
                            if (
                                !isNull _x
                                && {(_x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) == _side}
                                && {toLower (_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]) == _lower}
                                && {_x getVariable ["WaldoEcoBuild_Operational", true]}
                            ) exitWith {
                                _met = true;
                            };
                        } forEach _buildingRows;
                        _met
                    };

                    private _statusFor = {
                        params ["_entry", "_side", "_resRows", "_researchRows", "_doneLowerRows", "_buildingRows", "_jobRows", "_hasCommandAuthority", "_amountFn", "_requirementFn", "_buildCountFn", "_availabilityFn"];
                        if ((count _entry) <= 0) exitWith {"invalid"};
                        if (!_hasCommandAuthority) exitWith {"command"};
                        if !([_entry, _side] call _availabilityFn) exitWith {"unavailable"};

                        private _requirementsOk = true;
                        {
                            if !([_x, _side, _researchRows, _doneLowerRows, _buildingRows] call _requirementFn) exitWith {
                                _requirementsOk = false;
                            };
                        } forEach (_entry param [3, []]);
                        if (!_requirementsOk) exitWith {"requirements"};

                        private _limit = 0 max (floor (_entry param [19, 0]));
                        if (_limit > 0) then {
                            private _countNow = [_side, _entry param [0, ""], _buildingRows, _jobRows] call _buildCountFn;
                            if (_countNow >= _limit) exitWith {"limit"};
                        };

                        private _canPay = true;
                        {
                            private _have = [_x param [0, ""], _resRows] call _amountFn;
                            if (_have < (_x param [1, 0])) exitWith {_canPay = false;};
                        } forEach (_entry param [2, []]);
                        if (!_canPay) exitWith {"cost"};

                        "build"
                    };

                    private _visible = [];
                    {
                        if ((typeName _x) != "ARRAY") then {continue;};
                        if ((_x param [0, ""]) == "") then {continue;};
                        if !([_x, _sideKey] call _availableForSide) then {continue;};
                        _visible pushBack _x;
                    } forEach _catalogRaw;

                    private _categoryOptions = ["ALL"];
                    {
                        private _category = _x param [21, ""];
                        if (_category == "") then {continue;};
                        if ((_categoryOptions find _category) < 0) then {
                            _categoryOptions pushBack _category;
                        };
                    } forEach _visible;

                    private _selectedCategory = _display getVariable ["WaldoEcoBuild_PlayerSelectedCategory", "ALL"];
                    if ((_categoryOptions find _selectedCategory) < 0) then {
                        _selectedCategory = "ALL";
                    };
                    _display setVariable ["WaldoEcoBuild_PlayerCategoryOptions", _categoryOptions];
                    _display setVariable ["WaldoEcoBuild_PlayerSelectedCategory", _selectedCategory];

                    if (!isNull _categoryValue) then {
                        _categoryValue ctrlSetText _selectedCategory;
                        _categoryValue ctrlCommit 0;
                    };
                    if (!isNull _categoryPrev) then {
                        _categoryPrev ctrlEnable ((count _categoryOptions) > 1);
                        _categoryPrev ctrlCommit 0;
                    };
                    if (!isNull _categoryNext) then {
                        _categoryNext ctrlEnable ((count _categoryOptions) > 1);
                        _categoryNext ctrlCommit 0;
                    };

                    private _shown = [];
                    {
                        private _category = _x param [21, ""];
                        if (_selectedCategory == "ALL" || {_category == _selectedCategory}) then {
                            _shown pushBack _x;
                        };
                    } forEach _visible;

                    if (_rebuild) then {
                        lbClear _list;
                        {
                            private _entry = _x;
                            private _idx = _list lbAdd (_entry param [0, "Buildable"]);
                            _list lbSetData [_idx, _entry param [0, "Buildable"]];
                            private _icon = _entry param [5, ""];
                            if (_icon != "") then {_list lbSetPicture [_idx, _icon];};
                            private _status = [
                                _entry,
                                _sideKey,
                                _resources,
                                _researchCatalog,
                                _doneLower,
                                _buildings,
                                _activeJobs,
                                _hasCommand,
                                _getAmount,
                                _requirementMet,
                                _buildCount,
                                _availableForSide
                            ] call _statusFor;
                            if (_status == "build") then {
                                _list lbSetColor [_idx, [0.55, 1, 0.55, 1]];
                            } else {
                                _list lbSetColor [_idx, [1, 0.45, 0.45, 1]];
                            };
                            private _limit = 0 max (floor (_entry param [19, 0]));
                            if (_status == "limit") then {_list lbSetTextRight [_idx, "LIMIT"];};
                            if (_status == "requirements") then {_list lbSetTextRight [_idx, "REQ"];};
                            if (_status == "cost") then {_list lbSetTextRight [_idx, "COST"];};
                            if (_status == "command") then {_list lbSetTextRight [_idx, "GC"];};
                            if (_status == "build" && {_limit > 0}) then {
                                private _countNow = [_sideKey, _entry param [0, ""], _buildings, _activeJobs] call _buildCount;
                                _list lbSetTextRight [_idx, format ["%1/%2", _countNow, _limit]];
                            };
                        } forEach _shown;
                    };

                    private _selected = _display getVariable ["WaldoEcoBuild_PlayerSelectedIndex", 0];
                    if (_selected < 0) then {_selected = 0;};
                    if (_selected >= lbSize _list) then {_selected = (lbSize _list) - 1;};
                    if (_selected < 0 || {(count _shown) <= 0}) exitWith {
                        _nameCtrl ctrlSetText "No available buildings.";
                        _statusCtrl ctrlSetText "";
                        _button ctrlSetText "Place";
                        _button ctrlEnable false;
                        _button setVariable ["WaldoEcoBuild_SelectedBuildName", ""];
                        _button setVariable ["WaldoEcoBuild_SelectedBuildClass", ""];
                        _button ctrlCommit 0;
                    };

                    _display setVariable ["WaldoEcoBuild_PlayerSelectedIndex", _selected];
                    if (_rebuild) then {_list lbSetCurSel _selected;};

                    private _entry = _shown select _selected;
                    private _entryName = _entry param [0, "Buildable"];
                    private _status = [
                        _entry,
                        _sideKey,
                        _resources,
                        _researchCatalog,
                        _doneLower,
                        _buildings,
                        _activeJobs,
                        _hasCommand,
                        _getAmount,
                        _requirementMet,
                        _buildCount,
                        _availableForSide
                    ] call _statusFor;

                    private _statusText = switch (_status) do {
                        case "build": {"Status: Ready"};
                        case "requirements": {"Status: Requirements missing"};
                        case "limit": {"Status: Build limit reached"};
                        case "cost": {"Status: Not enough resources"};
                        case "command": {"Status: Ground Command required"};
                        case "unavailable": {"Status: Not available"};
                        default {"Status: Invalid"};
                    };
                    private _statusColor = [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select (_status == "build");

                    _nameCtrl ctrlSetText _entryName;
                    _nameCtrl ctrlSetTextColor [1, 1, 1, 1];
                    _nameCtrl ctrlCommit 0;
                    _statusCtrl ctrlSetText _statusText;
                    _statusCtrl ctrlSetTextColor _statusColor;
                    _statusCtrl ctrlCommit 0;

                    private _setLines = {
                        params ["_controls", "_rows"];
                        {
                            private _rowIndex = _forEachIndex;
                            if (_rowIndex < (count _rows)) then {
                                private _row = _rows select _rowIndex;
                                _x ctrlSetText (_row param [0, ""]);
                                _x ctrlSetTextColor (_row param [1, [0.88, 0.88, 0.88, 1]]);
                            } else {
                                _x ctrlSetText "";
                            };
                            _x ctrlCommit 0;
                        } forEach _controls;
                    };

                    private _desc = _entry param [1, ""];
                    [
                        _display getVariable ["WaldoEcoBuild_PlayerDescLines", []],
                        [
                            [_desc select [0, 76], [0.88, 0.88, 0.88, 1]],
                            [_desc select [76, 76], [0.88, 0.88, 0.88, 1]],
                            [_desc select [152, 76], [0.88, 0.88, 0.88, 1]]
                        ]
                    ] call _setLines;

                    if (!isNull _timeCtrl) then {
                        _timeCtrl ctrlSetText format ["Build Time: %1 sec", floor (_entry param [4, 60])];
                        _timeCtrl ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                        _timeCtrl ctrlCommit 0;
                    };
                    if (!isNull _limitCtrl) then {
                        private _limit = 0 max (floor (_entry param [19, 0]));
                        if (_limit > 0) then {
                            private _countNow = [_sideKey, _entryName, _buildings, _activeJobs] call _buildCount;
                            _limitCtrl ctrlSetText format ["Limit: %1 / %2", _countNow, _limit];
                            _limitCtrl ctrlSetTextColor ([[0.45, 1, 0.45, 1], [1, 0.45, 0.45, 1]] select (_countNow >= _limit));
                        } else {
                            _limitCtrl ctrlSetText "Limit: Unlimited";
                            _limitCtrl ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                        };
                        _limitCtrl ctrlCommit 0;
                    };

                    private _costRows = [];
                    {
                        private _res = _x param [0, ""];
                        private _cost = floor (_x param [1, 0]);
                        private _have = [_res, _resources] call _getAmount;
                        _costRows pushBack [
                            format ["%1: %2 / %3", _res, _have, _cost],
                            [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select (_have >= _cost)
                        ];
                    } forEach (_entry param [2, []]);
                    if ((count _costRows) <= 0) then {_costRows pushBack ["No cost", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuild_PlayerCostLines", []], _costRows] call _setLines;

                    private _reqRows = [];
                    {
                        private _met = [_x, _sideKey, _researchCatalog, _doneLower, _buildings] call _requirementMet;
                        _reqRows pushBack [_x, [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select _met];
                    } forEach (_entry param [3, []]);
                    if ((count _reqRows) <= 0) then {_reqRows pushBack ["None", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuild_PlayerReqLines", []], _reqRows] call _setLines;

                    private _effectRows = [];
                    private _produceResource = _entry param [9, ""];
                    private _produceAmount = floor (_entry param [10, 0]);
                    private _produceInterval = floor (_entry param [11, 0]);
                    if (_produceResource != "" && {_produceAmount > 0} && {_produceInterval > 0}) then {
                        _effectRows pushBack [format ["Produces %1 %2 every %3 sec", _produceAmount, _produceResource, _produceInterval], [0.88, 0.88, 0.88, 1]];
                    };
                    private _upkeepRows = _entry param [15, []];
                    private _upkeepInterval = floor (_entry param [16, 0]);
                    if ((count _upkeepRows) > 0 && {_upkeepInterval > 0}) then {
                        _effectRows pushBack [format ["Upkeep every %1 sec", _upkeepInterval], [0.88, 0.88, 0.88, 1]];
                    };
                    private _storageRows = _entry param [17, []];
                    if ((typeName _storageRows) == "ARRAY" && {(count _storageRows) > 0}) then {
                        _effectRows pushBack ["Provides storage", [0.88, 0.88, 0.88, 1]];
                    };
                    if ((_entry param [12, 0]) > 0) then {_effectRows pushBack [format ["Research speed +%1%%", _entry param [12, 0]], [0.88, 0.88, 0.88, 1]];};
                    if ((_entry param [13, 0]) > 0) then {_effectRows pushBack [format ["Build speed +%1%%", _entry param [13, 0]], [0.88, 0.88, 0.88, 1]];};
                    if ((_entry param [14, 0]) > 0) then {_effectRows pushBack [format ["Detector range %1m", _entry param [14, 0]], [0.88, 0.88, 0.88, 1]];};
                    private _category = _entry param [21, ""];
                    if (_category != "") then {_effectRows pushBack [format ["Category: %1", _category], [0.88, 0.88, 0.88, 1]];};
                    if ((count _effectRows) <= 0) then {_effectRows pushBack ["No active effects", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuild_PlayerEffectLines", []], _effectRows] call _setLines;

                    private _className = _entry param [8, ""];
                    if (_className == "" || {!(isClass (configFile >> "CfgVehicles" >> _className))}) then {
                        _className = "PortableHelipadLight_01_red_F";
                        if !(isClass (configFile >> "CfgVehicles" >> _className)) then {
                            _className = "Land_HelipadEmpty_F";
                        };
                    };

                    _button ctrlSetText (["Place", "Place"] select (_status == "build"));
                    _button ctrlEnable (_status == "build");
                    _button setVariable ["WaldoEcoBuild_SelectedBuildName", _entryName];
                    _button setVariable ["WaldoEcoBuild_SelectedBuildClass", _className];
                    _button ctrlCommit 0;
                };

                private _startPlacement = {
                    params [["_display", displayNull], ["_buildName", ""], ["_className", ""]];
                    if (_buildName == "") exitWith {};

                    private _actor = _display getVariable ["WaldoEcoBuild_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};
                    if (isNull _actor) exitWith {};

                    private _source = _display getVariable ["WaldoEcoBuild_ConstructionSource", objNull];
                    if (isNull _source) exitWith {};

                    private _cleanup = {
                        params [["_unit", objNull]];
                        if (isNull _unit) exitWith {};
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPlacementActive", false];
                        private _preview = _unit getVariable ["WaldoEcoBuild_PubConstructionPreviewObject", objNull];
                        if (!isNull _preview) then {deleteVehicle _preview;};
                        {
                            private _actionId = _unit getVariable [_x, -1];
                            if (_actionId >= 0) then {_unit removeAction _actionId;};
                            _unit setVariable [_x, -1];
                        } forEach [
                            "WaldoEcoBuild_PubConstructionBeginAction",
                            "WaldoEcoBuild_PubConstructionCancelAction",
                            "WaldoEcoBuild_PubConstructionRotateLeftAction",
                            "WaldoEcoBuild_PubConstructionRotateRightAction"
                        ];
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewObject", objNull];
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewBuildName", ""];
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewSource", objNull];
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewPos", [0, 0, 0]];
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewDir", 0];
                        _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", 0];
                    };

                    [_actor] call _cleanup;
                    _actor setVariable ["WaldoEcoBuild_PubConstructionCleanupCode", _cleanup];

                    if (_className == "" || {!(isClass (configFile >> "CfgVehicles" >> _className))}) then {
                        _className = "PortableHelipadLight_01_red_F";
                    };
                    if !(isClass (configFile >> "CfgVehicles" >> _className)) then {
                        _className = "Land_HelipadEmpty_F";
                    };

                    private _pos = screenToWorld [0.5, 0.5];
                    if ((count _pos) < 3) then {_pos = [_pos select 0, _pos select 1, 0];};
                    _pos set [2, 0 max (_pos select 2)];
                    private _dir = getDir _actor;
                    private _preview = createVehicleLocal [_className, _pos, [], 0, "CAN_COLLIDE"];
                    _preview setDir _dir;
                    _preview setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
                    _preview enableSimulation false;
                    _preview allowDamage false;

                    _actor setVariable ["WaldoEcoBuild_PubConstructionPlacementActive", true];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionPreviewObject", _preview];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionPreviewBuildName", _buildName];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionPreviewSource", _source];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionPreviewPos", _pos];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionPreviewDir", _dir];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", 0];

                    private _beginAction = _actor addAction [
                        "Begin Construction",
                        {
                            params ["_target", "_caller"];
                            private _buildName = _target getVariable ["WaldoEcoBuild_PubConstructionPreviewBuildName", ""];
                            private _source = _target getVariable ["WaldoEcoBuild_PubConstructionPreviewSource", objNull];
                            private _pos = _target getVariable ["WaldoEcoBuild_PubConstructionPreviewPos", getPosATL _target];
                            private _dir = _target getVariable ["WaldoEcoBuild_PubConstructionPreviewDir", getDir _target];
                            if (_buildName != "" && {!isNull _source}) then {
                                private _uid = getPlayerUID player;
                                private _requestId = format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)];
                                _source setVariable [
                                    "WaldoEcoBuild_StartConstructionRequest",
                                    [_buildName, netId _source, netId _caller, _pos, _dir, _requestId],
                                    true
                                ];
                                hintSilent "Construction request sent.";
                            };
                            [_target] call (_target getVariable ["WaldoEcoBuild_PubConstructionCleanupCode", {}]);
                        },
                        nil,
                        1.6,
                        true,
                        true,
                        "",
                        "_target getVariable ['WaldoEcoBuild_PubConstructionPlacementActive', false]",
                        8
                    ];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionBeginAction", _beginAction];

                    private _cancelAction = _actor addAction [
                        "Cancel Construction",
                        {
                            params ["_target"];
                            [_target] call (_target getVariable ["WaldoEcoBuild_PubConstructionCleanupCode", {}]);
                            hintSilent "Construction placement cancelled.";
                        },
                        nil,
                        1.5,
                        true,
                        true,
                        "",
                        "_target getVariable ['WaldoEcoBuild_PubConstructionPlacementActive', false]",
                        8
                    ];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionCancelAction", _cancelAction];

                    private _rotateLeftAction = _actor addAction [
                        "Rotate Construction Left",
                        {
                            params ["_target"];
                            private _offset = (_target getVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", 0]) - 15;
                            _offset = _offset % 360;
                            if (_offset < 0) then {_offset = _offset + 360;};
                            _target setVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", _offset];
                        },
                        nil,
                        1.4,
                        true,
                        true,
                        "",
                        "_target getVariable ['WaldoEcoBuild_PubConstructionPlacementActive', false]",
                        8
                    ];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionRotateLeftAction", _rotateLeftAction];

                    private _rotateRightAction = _actor addAction [
                        "Rotate Construction Right",
                        {
                            params ["_target"];
                            private _offset = (_target getVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", 0]) + 15;
                            _offset = _offset % 360;
                            if (_offset < 0) then {_offset = _offset + 360;};
                            _target setVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", _offset];
                        },
                        nil,
                        1.4,
                        true,
                        true,
                        "",
                        "_target getVariable ['WaldoEcoBuild_PubConstructionPlacementActive', false]",
                        8
                    ];
                    _actor setVariable ["WaldoEcoBuild_PubConstructionRotateRightAction", _rotateRightAction];

                    [_actor] spawn {
                        params [["_unit", objNull]];
                        while {
                            !isNull _unit
                            && {alive _unit}
                            && {_unit getVariable ["WaldoEcoBuild_PubConstructionPlacementActive", false]}
                        } do {
                            private _preview = _unit getVariable ["WaldoEcoBuild_PubConstructionPreviewObject", objNull];
                            if (isNull _preview) exitWith {};
                            private _pos = screenToWorld [0.5, 0.5];
                            if ((count _pos) < 3) then {_pos = [_pos select 0, _pos select 1, 0];};
                            _pos set [2, 0 max (_pos select 2)];
                            private _dir = ((getDir _unit) + (_unit getVariable ["WaldoEcoBuild_PubConstructionPreviewDirOffset", 0])) % 360;
                            if (_dir < 0) then {_dir = _dir + 360;};
                            _preview setDir _dir;
                            _preview setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
                            _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewPos", _pos];
                            _unit setVariable ["WaldoEcoBuild_PubConstructionPreviewDir", _dir];
                            uiSleep 0.03;
                        };

                        if (!isNull _unit && {_unit getVariable ["WaldoEcoBuild_PubConstructionPlacementActive", false]}) then {
                            [_unit] call (_unit getVariable ["WaldoEcoBuild_PubConstructionCleanupCode", {}]);
                        };
                    };

                    hintSilent "Construction placement active. Aim, use rotate actions if needed, then Begin Construction.";
                };

                _disp setVariable ["WaldoEcoBuild_PubRefresh", _refresh];
                _disp setVariable ["WaldoEcoBuild_PubStartPlacement", _startPlacement];

                _list ctrlAddEventHandler ["LBSelChanged", {
                    params ["_ctrl", "_index"];
                    private _display = ctrlParent _ctrl;
                    _display setVariable ["WaldoEcoBuild_PlayerSelectedIndex", _index];
                    [_display, false] call (_display getVariable ["WaldoEcoBuild_PubRefresh", {}]);
                }];

                _categoryPrev ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    private _display = ctrlParent _ctrl;
                    private _options = _display getVariable ["WaldoEcoBuild_PlayerCategoryOptions", ["ALL"]];
                    if ((count _options) <= 1) exitWith {};
                    private _current = _display getVariable ["WaldoEcoBuild_PlayerSelectedCategory", "ALL"];
                    private _index = _options find _current;
                    if (_index < 0) then {_index = 0;};
                    _index = _index - 1;
                    if (_index < 0) then {_index = (count _options) - 1;};
                    _display setVariable ["WaldoEcoBuild_PlayerSelectedCategory", _options select _index];
                    _display setVariable ["WaldoEcoBuild_PlayerSelectedIndex", 0];
                    [_display, true] call (_display getVariable ["WaldoEcoBuild_PubRefresh", {}]);
                }];

                _categoryNext ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    private _display = ctrlParent _ctrl;
                    private _options = _display getVariable ["WaldoEcoBuild_PlayerCategoryOptions", ["ALL"]];
                    if ((count _options) <= 1) exitWith {};
                    private _current = _display getVariable ["WaldoEcoBuild_PlayerSelectedCategory", "ALL"];
                    private _index = _options find _current;
                    if (_index < 0) then {_index = 0;};
                    _index = (_index + 1) mod (count _options);
                    _display setVariable ["WaldoEcoBuild_PlayerSelectedCategory", _options select _index];
                    _display setVariable ["WaldoEcoBuild_PlayerSelectedIndex", 0];
                    [_display, true] call (_display getVariable ["WaldoEcoBuild_PubRefresh", {}]);
                }];

                _button ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    private _display = ctrlParent _ctrl;
                    private _buildName = _ctrl getVariable ["WaldoEcoBuild_SelectedBuildName", ""];
                    private _className = _ctrl getVariable ["WaldoEcoBuild_SelectedBuildClass", ""];
                    if (_buildName == "") exitWith {};
                    [_display, _buildName, _className] call (_display getVariable ["WaldoEcoBuild_PubStartPlacement", {}]);
                    _display closeDisplay 1;
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
                            [_display, !(missionNamespace getVariable ["WaldoEcoCore_CommitmentModeEnabled", false])] call (_display getVariable ["WaldoEcoBuild_PubRefresh", {}]);
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

