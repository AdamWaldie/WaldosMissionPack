/*
 * Author: Waldo
 * Get official purchase action args.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _target <ANY> - target
 * 1: _caller <ANY> - caller
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_target, _caller] call Waldo_fnc_EcoBuy_getOfficialPurchaseActionArgs;
 */

        [
            "Open Purchase Menu",
            {
                params ["_target", "_caller"];

                private _actor = _caller;
                if (isNull _actor) then {_actor = player;};

                private _parent = findDisplay 46;
                if (isNull _parent) exitWith {hintSilent "Purchase display unavailable.";};

                private _existing = uiNamespace getVariable ["WaldoEcoBuy_PubPurchaseDisplay", displayNull];
                if (!isNull _existing) then {_existing closeDisplay 1;};

                private _disp = _parent createDisplay "RscDisplayEmpty";
                if (isNull _disp) exitWith {};
                uiNamespace setVariable ["WaldoEcoBuy_PubPurchaseDisplay", _disp];

                _disp setVariable ["WaldoEcoBuy_PurchaseTerminal", _target];
                _disp setVariable ["WaldoEcoBuy_RequestActorObject", _actor];
                _disp setVariable ["WaldoEcoBuy_PlayerSelectedIndex", 0];

                private _bg = _disp ctrlCreate ["RscText", -1];
                _bg ctrlSetPosition [0.16, 0.08, 0.88, 0.86];
                _bg ctrlSetBackgroundColor [0, 0, 0, 0.88];
                _bg ctrlCommit 0;

                private _title = _disp ctrlCreate ["RscText", -1];
                _title ctrlSetPosition [0.19, 0.10, 0.34, 0.04];
                _title ctrlSetText "Purchase Menu";
                _title ctrlCommit 0;

                private _sideLabel = _disp ctrlCreate ["RscText", -1];
                _sideLabel ctrlSetPosition [0.55, 0.10, 0.44, 0.04];
                _sideLabel ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                _sideLabel ctrlCommit 0;

                private _list = _disp ctrlCreate ["RscListbox", -1];
                _list ctrlSetPosition [0.19, 0.16, 0.31, 0.70];
                _list ctrlCommit 0;

                private _nameCtrl = _disp ctrlCreate ["RscText", -1];
                _nameCtrl ctrlSetPosition [0.54, 0.16, 0.45, 0.045];
                _nameCtrl ctrlCommit 0;

                private _statusCtrl = _disp ctrlCreate ["RscText", -1];
                _statusCtrl ctrlSetPosition [0.54, 0.21, 0.45, 0.04];
                _statusCtrl ctrlCommit 0;

                private _descHeader = _disp ctrlCreate ["RscText", -1];
                _descHeader ctrlSetPosition [0.54, 0.27, 0.28, 0.035];
                _descHeader ctrlSetText "Description";
                _descHeader ctrlCommit 0;

                private _descLines = [];
                for "_i" from 0 to 2 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.54, 0.31 + (_i * 0.035), 0.45, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _descLines pushBack _ctrl;
                };

                private _costHeader = _disp ctrlCreate ["RscText", -1];
                _costHeader ctrlSetPosition [0.54, 0.44, 0.20, 0.035];
                _costHeader ctrlSetText "Cost";
                _costHeader ctrlCommit 0;

                private _costLines = [];
                for "_i" from 0 to 4 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.54, 0.48 + (_i * 0.035), 0.21, 0.033];
                    _ctrl ctrlCommit 0;
                    _costLines pushBack _ctrl;
                };

                private _reqHeader = _disp ctrlCreate ["RscText", -1];
                _reqHeader ctrlSetPosition [0.77, 0.44, 0.22, 0.035];
                _reqHeader ctrlSetText "Requirements";
                _reqHeader ctrlCommit 0;

                private _reqLines = [];
                for "_i" from 0 to 4 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.77, 0.48 + (_i * 0.035), 0.22, 0.033];
                    _ctrl ctrlCommit 0;
                    _reqLines pushBack _ctrl;
                };

                private _deliveryHeader = _disp ctrlCreate ["RscText", -1];
                _deliveryHeader ctrlSetPosition [0.54, 0.68, 0.20, 0.035];
                _deliveryHeader ctrlSetText "Delivery";
                _deliveryHeader ctrlCommit 0;

                private _deliveryLines = [];
                for "_i" from 0 to 2 do {
                    private _ctrl = _disp ctrlCreate ["RscText", -1];
                    _ctrl ctrlSetPosition [0.54, 0.72 + (_i * 0.035), 0.45, 0.033];
                    _ctrl ctrlSetTextColor [0.88, 0.88, 0.88, 1];
                    _ctrl ctrlCommit 0;
                    _deliveryLines pushBack _ctrl;
                };

                private _button = _disp ctrlCreate ["RscButtonMenu", -1];
                _button ctrlSetPosition [0.67, 0.88, 0.15, 0.045];
                _button ctrlSetText "Purchase";
                _button ctrlCommit 0;

                private _close = _disp ctrlCreate ["RscButtonMenu", -1];
                _close ctrlSetPosition [0.84, 0.88, 0.15, 0.045];
                _close ctrlSetText "Close";
                _close ctrlCommit 0;

                _disp setVariable ["WaldoEcoBuy_PlayerList", _list];
                _disp setVariable ["WaldoEcoBuy_SideLabel", _sideLabel];
                _disp setVariable ["WaldoEcoBuy_PlayerName", _nameCtrl];
                _disp setVariable ["WaldoEcoBuy_PlayerStatus", _statusCtrl];
                _disp setVariable ["WaldoEcoBuy_PlayerDescLines", _descLines];
                _disp setVariable ["WaldoEcoBuy_PlayerCostLines", _costLines];
                _disp setVariable ["WaldoEcoBuy_PlayerReqLines", _reqLines];
                _disp setVariable ["WaldoEcoBuy_PlayerDeliveryLines", _deliveryLines];
                _disp setVariable ["WaldoEcoBuy_PlayerButton", _button];

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
                _disp setVariable ["WaldoEcoBuy_SetLines", _setLines];

                private _sideKeyFromActor = {
                    params [["_unit", objNull]];
                    switch (side group _unit) do {
                        case west: {"WEST"};
                        case east: {"EAST"};
                        case independent: {"GUER"};
                        default {"CIV"};
                    }
                };
                _disp setVariable ["WaldoEcoBuy_SideKeyFromActor", _sideKeyFromActor];

                private _sideLabelFromKey = {
                    params [["_sideKey", "NONE"]];
                    switch (_sideKey) do {
                        case "WEST": {"BLUFOR"};
                        case "EAST": {"OPFOR"};
                        case "GUER": {"INDEP"};
                        default {"EVERYONE"};
                    }
                };
                _disp setVariable ["WaldoEcoBuy_SideLabelFromKey", _sideLabelFromKey];

                private _resourceVar = {
                    params [["_sideKey", "NONE"]];
                    switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResource_Resources_WEST"};
                        case "EAST": {"WaldoEcoResource_Resources_EAST"};
                        case "GUER": {"WaldoEcoResource_Resources_GUER"};
                        default {"WaldoEcoResource_Resources_CIV"};
                    }
                };
                _disp setVariable ["WaldoEcoBuy_ResourceVar", _resourceVar];

                private _researchDoneVar = {
                    params [["_sideKey", "NONE"]];
                    switch (_sideKey) do {
                        case "WEST": {"WaldoEcoResearch_ResearchDone_WEST"};
                        case "EAST": {"WaldoEcoResearch_ResearchDone_EAST"};
                        case "GUER": {"WaldoEcoResearch_ResearchDone_GUER"};
                        default {"WaldoEcoResearch_ResearchDone_CIV"};
                    }
                };
                _disp setVariable ["WaldoEcoBuy_ResearchDoneVar", _researchDoneVar];

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
                _disp setVariable ["WaldoEcoBuy_AmountFor", _amountFor];

                private _canSideUse = {
                    params [["_entry", []], ["_sideKey", "NONE"], ["_labelFn", {}]];
                    private _allowed = _entry param [6, "EVERYONE"];
                    (_allowed == "EVERYONE") || {_allowed == ([_sideKey] call _labelFn)}
                };
                _disp setVariable ["WaldoEcoBuy_CanSideUse", _canSideUse];

                private _dropPointRows = {
                    params [["_typeName", "Ground"], ["_sideKey", "NONE"], ["_dropRows", []]];
                    private _rows = [];
                    {
                        private _rowType = _x param [1, "Ground"];
                        private _rowSide = _x param [5, "ANY"];
                        if (_rowType == _typeName && {(_rowSide == "ANY") || {_rowSide == _sideKey}}) then {
                            _rows pushBack _x;
                        };
                    } forEach _dropRows;
                    _rows
                };
                _disp setVariable ["WaldoEcoBuy_DropPointRows", _dropPointRows];

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
                _disp setVariable ["WaldoEcoBuy_RequirementMet", _requirementMet];

                private _statusFor = {
                    params [
                        ["_entry", []],
                        ["_sideKey", "NONE"],
                        ["_resources", []],
                        ["_researchCatalog", []],
                        ["_doneLower", []],
                        ["_buildingRows", []],
                        ["_dropRows", []],
                        ["_hasCommand", true],
                        ["_amountFn", {}],
                        ["_requirementFn", {}],
                        ["_dropPointFn", {}],
                        ["_labelFn", {}],
                        ["_sideUseFn", {}]
                    ];

                    if ((count _entry) <= 0) exitWith {"invalid"};
                    if !([_entry, _sideKey, _labelFn] call _sideUseFn) exitWith {"side"};
                    if (!_hasCommand) exitWith {"command"};
                    if !(isClass (configFile >> "CfgVehicles" >> (_entry param [4, ""]))) exitWith {"invalid"};

                    private _requirementsOk = true;
                    {
                        if !([_x, _sideKey, _researchCatalog, _doneLower, _buildingRows] call _requirementFn) exitWith {
                            _requirementsOk = false;
                        };
                    } forEach (_entry param [3, []]);
                    if (!_requirementsOk) exitWith {"requirements"};

                    private _canPay = true;
                    {
                        private _have = [_x param [0, ""], _resources] call _amountFn;
                        if (_have < (_x param [1, 0])) exitWith {_canPay = false;};
                    } forEach (_entry param [2, []]);
                    if (!_canPay) exitWith {"cost"};

                    private _matchingDrops = [_entry param [5, "Ground"], _sideKey, _dropRows] call _dropPointFn;
                    if ((count _matchingDrops) <= 0) exitWith {"drop"};

                    "ready"
                };
                _disp setVariable ["WaldoEcoBuy_StatusFor", _statusFor];

                private _refresh = {
                    params [["_display", displayNull], ["_rebuild", true]];
                    if (isNull _display) exitWith {};

                    private _list = _display getVariable ["WaldoEcoBuy_PlayerList", controlNull];
                    private _sideLabel = _display getVariable ["WaldoEcoBuy_SideLabel", controlNull];
                    private _nameCtrl = _display getVariable ["WaldoEcoBuy_PlayerName", controlNull];
                    private _statusCtrl = _display getVariable ["WaldoEcoBuy_PlayerStatus", controlNull];
                    private _button = _display getVariable ["WaldoEcoBuy_PlayerButton", controlNull];
                    if (isNull _list || {isNull _button} || {isNull _nameCtrl} || {isNull _statusCtrl}) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoBuy_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};
                    private _sideKey = [_actor] call (_display getVariable ["WaldoEcoBuy_SideKeyFromActor", {}]);
                    private _sideText = [_sideKey] call (_display getVariable ["WaldoEcoBuy_SideLabelFromKey", {}]);
                    if (!isNull _sideLabel) then {
                        _sideLabel ctrlSetText format ["Your side: %1", _sideText];
                        _sideLabel ctrlCommit 0;
                    };

                    private _catalog = missionNamespace getVariable ["WaldoEcoBuy_PurchaseCatalog", []];
                    if ((typeName _catalog) != "ARRAY") then {_catalog = [];};
                    private _resources = missionNamespace getVariable [[_sideKey] call (_display getVariable ["WaldoEcoBuy_ResourceVar", {}]), []];
                    if ((typeName _resources) != "ARRAY") then {_resources = [];};
                    private _researchCatalog = missionNamespace getVariable ["WaldoEcoResearch_ResearchCatalog", []];
                    if ((typeName _researchCatalog) != "ARRAY") then {_researchCatalog = [];};
                    private _doneRows = missionNamespace getVariable [[_sideKey] call (_display getVariable ["WaldoEcoBuy_ResearchDoneVar", {}]), []];
                    if ((typeName _doneRows) != "ARRAY") then {_doneRows = [];};
                    private _doneLower = _doneRows apply {toLower _x};
                    private _buildingRows = missionNamespace getVariable ["WaldoEcoBuild_SpawnedBuildings", []];
                    if ((typeName _buildingRows) != "ARRAY") then {_buildingRows = [];};
                    private _dropRows = missionNamespace getVariable ["WaldoEcoBuy_DropPoints", []];
                    if ((typeName _dropRows) != "ARRAY") then {_dropRows = [];};

                    private _groundCommandRows = missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []];
                    if ((typeName _groundCommandRows) != "ARRAY") then {_groundCommandRows = [];};
                    private _key = _actor getVariable ["WaldoEcoCommand_GroundCommandKey", ""];
                    if (_key == "") then {_key = player getVariable ["WaldoEcoCommand_GroundCommandKey", ""];};
                    private _hasCommand = ((count _groundCommandRows) <= 0) || {(_key != "") && {(_groundCommandRows find _key) >= 0}};

                    private _visible = [];
                    {
                        if ((typeName _x) != "ARRAY") then {continue;};
                        if ((_x param [0, ""]) == "") then {continue;};
                        if !([_x, _sideKey, _display getVariable ["WaldoEcoBuy_SideLabelFromKey", {}]] call (_display getVariable ["WaldoEcoBuy_CanSideUse", {}])) then {continue;};
                        _visible pushBack _x;
                    } forEach _catalog;

                    _display setVariable ["WaldoEcoBuy_PlayerVisibleCatalog", _visible];

                    if (_rebuild) then {
                        lbClear _list;
                        {
                            private _entry = _x;
                            private _idx = _list lbAdd (_entry param [0, "Purchase"]);
                            _list lbSetData [_idx, _entry param [0, "Purchase"]];
                            private _status = [
                                _entry,
                                _sideKey,
                                _resources,
                                _researchCatalog,
                                _doneLower,
                                _buildingRows,
                                _dropRows,
                                _hasCommand,
                                _display getVariable ["WaldoEcoBuy_AmountFor", {}],
                                _display getVariable ["WaldoEcoBuy_RequirementMet", {}],
                                _display getVariable ["WaldoEcoBuy_DropPointRows", {}],
                                _display getVariable ["WaldoEcoBuy_SideLabelFromKey", {}],
                                _display getVariable ["WaldoEcoBuy_CanSideUse", {}]
                            ] call (_display getVariable ["WaldoEcoBuy_StatusFor", {}]);

                            if (_status == "ready") then {
                                _list lbSetColor [_idx, [0.55, 1, 0.55, 1]];
                            } else {
                                _list lbSetColor [_idx, [1, 0.45, 0.45, 1]];
                            };
                            switch (_status) do {
                                case "requirements": {_list lbSetTextRight [_idx, "REQ"];};
                                case "cost": {_list lbSetTextRight [_idx, "COST"];};
                                case "drop": {_list lbSetTextRight [_idx, "DROP"];};
                                case "command": {_list lbSetTextRight [_idx, "GC"];};
                                case "invalid": {_list lbSetTextRight [_idx, "BAD"];};
                            };
                        } forEach _visible;
                    };

                    private _selected = _display getVariable ["WaldoEcoBuy_PlayerSelectedIndex", 0];
                    if (_selected < 0) then {_selected = 0;};
                    if (_selected >= lbSize _list) then {_selected = (lbSize _list) - 1;};
                    if (_selected < 0 || {(count _visible) <= 0}) exitWith {
                        _nameCtrl ctrlSetText "No purchases available";
                        _nameCtrl ctrlCommit 0;
                        _statusCtrl ctrlSetText "";
                        _statusCtrl ctrlCommit 0;
                        [_display getVariable ["WaldoEcoBuy_PlayerDescLines", []], []] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);
                        [_display getVariable ["WaldoEcoBuy_PlayerCostLines", []], []] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);
                        [_display getVariable ["WaldoEcoBuy_PlayerReqLines", []], []] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);
                        [_display getVariable ["WaldoEcoBuy_PlayerDeliveryLines", []], [["No matching catalogue entries for this side.", [0.9, 0.9, 0.9, 1]]]] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);
                        _button ctrlSetText "Purchase";
                        _button ctrlEnable false;
                        _button ctrlCommit 0;
                    };

                    _display setVariable ["WaldoEcoBuy_PlayerSelectedIndex", _selected];
                    if (_rebuild) then {_list lbSetCurSel _selected;};

                    private _entry = _visible select _selected;
                    private _entryName = _entry param [0, "Purchase"];
                    private _status = [
                        _entry,
                        _sideKey,
                        _resources,
                        _researchCatalog,
                        _doneLower,
                        _buildingRows,
                        _dropRows,
                        _hasCommand,
                        _display getVariable ["WaldoEcoBuy_AmountFor", {}],
                        _display getVariable ["WaldoEcoBuy_RequirementMet", {}],
                        _display getVariable ["WaldoEcoBuy_DropPointRows", {}],
                        _display getVariable ["WaldoEcoBuy_SideLabelFromKey", {}],
                        _display getVariable ["WaldoEcoBuy_CanSideUse", {}]
                    ] call (_display getVariable ["WaldoEcoBuy_StatusFor", {}]);

                    _nameCtrl ctrlSetText _entryName;
                    _nameCtrl ctrlSetTextColor [0.9, 0.9, 0.9, 1];
                    _nameCtrl ctrlCommit 0;

                    private _statusText = switch (_status) do {
                        case "ready": {"Status: Ready"};
                        case "requirements": {"Status: Requirements missing"};
                        case "cost": {"Status: Not enough resources"};
                        case "drop": {"Status: No drop point"};
                        case "command": {"Status: Ground Command required"};
                        case "side": {"Status: Wrong side"};
                        default {"Status: Invalid configuration"};
                    };
                    _statusCtrl ctrlSetText _statusText;
                    _statusCtrl ctrlSetTextColor ([[1, 0.55, 0.55, 1], [0.55, 1, 0.55, 1]] select (_status == "ready"));
                    _statusCtrl ctrlCommit 0;

                    private _desc = _entry param [1, ""];
                    [
                        _display getVariable ["WaldoEcoBuy_PlayerDescLines", []],
                        [
                            [_desc select [0, 70], [0.88, 0.88, 0.88, 1]],
                            [_desc select [70, 70], [0.88, 0.88, 0.88, 1]],
                            [_desc select [140, 70], [0.88, 0.88, 0.88, 1]]
                        ]
                    ] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);

                    private _costRows = [];
                    {
                        private _resourceName = _x param [0, ""];
                        private _cost = floor (_x param [1, 0]);
                        private _have = [_resourceName, _resources] call (_display getVariable ["WaldoEcoBuy_AmountFor", {}]);
                        _costRows pushBack [
                            format ["%1: %2 / %3", _resourceName, _have, _cost],
                            [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select (_have >= _cost)
                        ];
                    } forEach (_entry param [2, []]);
                    if ((count _costRows) <= 0) then {_costRows pushBack ["No cost", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuy_PlayerCostLines", []], _costRows] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);

                    private _reqRows = [];
                    {
                        private _req = _x;
                        private _lower = toLower _req;
                        private _isResearch = (_researchCatalog findIf {(toLower (_x param [0, ""])) == _lower}) >= 0;
                        private _met = [_req, _sideKey, _researchCatalog, _doneLower, _buildingRows] call (_display getVariable ["WaldoEcoBuy_RequirementMet", {}]);
                        _reqRows pushBack [format ["%1 (%2)", _req, ["Building", "Research"] select _isResearch], [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select _met];
                    } forEach (_entry param [3, []]);
                    if ((count _reqRows) <= 0) then {_reqRows pushBack ["None", [0.9, 0.9, 0.9, 1]];};
                    [_display getVariable ["WaldoEcoBuy_PlayerReqLines", []], _reqRows] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);

                    private _dropType = _entry param [5, "Ground"];
                    private _matchingDrops = [_dropType, _sideKey, _dropRows] call (_display getVariable ["WaldoEcoBuy_DropPointRows", {}]);
                    private _className = _entry param [4, ""];
                    private _deliveryRows = [
                        [format ["Type: %1", _dropType], [0.88, 0.88, 0.88, 1]],
                        [format ["Drop points: %1", count _matchingDrops], [[1, 0.45, 0.45, 1], [0.45, 1, 0.45, 1]] select ((count _matchingDrops) > 0)],
                        [format ["Class: %1", _className], [[1, 0.45, 0.45, 1], [0.88, 0.88, 0.88, 1]] select (isClass (configFile >> "CfgVehicles" >> _className))]
                    ];
                    [_display getVariable ["WaldoEcoBuy_PlayerDeliveryLines", []], _deliveryRows] call (_display getVariable ["WaldoEcoBuy_SetLines", {}]);

                    private _buttonText = switch (_status) do {
                        case "ready": {"Purchase"};
                        case "requirements": {"Requirements"};
                        case "cost": {"Not Enough"};
                        case "drop": {"No Drop Point"};
                        case "command": {"Ground Cmd"};
                        default {"Unavailable"};
                    };
                    _button ctrlSetText _buttonText;
                    _button ctrlEnable (_status == "ready");
                    _button setVariable ["WaldoEcoBuy_SelectedPurchaseName", _entryName];
                    _button ctrlCommit 0;
                };
                _disp setVariable ["WaldoEcoBuy_PubRefresh", _refresh];

                _list ctrlAddEventHandler ["LBSelChanged", {
                    params ["_ctrl", "_index"];
                    private _display = ctrlParent _ctrl;
                    _display setVariable ["WaldoEcoBuy_PlayerSelectedIndex", _index];
                    [_display, false] call (_display getVariable ["WaldoEcoBuy_PubRefresh", {}]);
                }];

                _button ctrlAddEventHandler ["ButtonClick", {
                    params ["_ctrl"];
                    private _display = ctrlParent _ctrl;
                    private _purchaseName = _ctrl getVariable ["WaldoEcoBuy_SelectedPurchaseName", ""];
                    if (_purchaseName == "") exitWith {};

                    private _terminal = _display getVariable ["WaldoEcoBuy_PurchaseTerminal", objNull];
                    if (isNull _terminal) exitWith {};

                    private _actor = _display getVariable ["WaldoEcoBuy_RequestActorObject", objNull];
                    if (isNull _actor) then {_actor = player;};

                    private _sideKey = [_actor] call (_display getVariable ["WaldoEcoBuy_SideKeyFromActor", {}]);
                    private _uid = getPlayerUID player;
                    if (_uid == "") then {_uid = name _actor;};
                    private _requestId = format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)];

                    _terminal setVariable [
                        "WaldoEcoBuy_PurchaseRequest",
                        [_sideKey, _purchaseName, getPosATL _actor, netId _actor, _requestId],
                        true
                    ];

                    hintSilent "Purchase request sent.";
                    [_display] spawn {
                        params ["_display"];
                        uiSleep 1;
                        if (!isNull _display) then {
                            [_display, true] call (_display getVariable ["WaldoEcoBuy_PubRefresh", {}]);
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
                            [_display, !(missionNamespace getVariable ["WaldoEcoCore_CommitmentModeEnabled", false])] call (_display getVariable ["WaldoEcoBuy_PubRefresh", {}]);
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
            15
        ]

