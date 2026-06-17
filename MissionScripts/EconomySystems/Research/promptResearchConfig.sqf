/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - promptResearchConfig
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_promptResearchConfig via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if (!hasInterface) exitWith {};

        private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _zeusDisp) exitWith {};

        [_zeusDisp] call Waldo_fnc_EcoResearch_cleanupResearchConfigPrompt;

        private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
        if (isNull _disp) exitWith {};

                private _bg = _disp ctrlCreate ["RscText", -1];
        _bg ctrlSetPosition [0.24, 0.01, 0.71, 0.97];
        _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
        _bg ctrlCommit 0;

        private _title = _disp ctrlCreate ["RscText", -1];
        _title ctrlSetPosition [0.26, 0.03, 0.63, 0.03];
        _title ctrlSetText "Configure Research";
        _title ctrlCommit 0;

        private _listLabel = _disp ctrlCreate ["RscText", -1];
        _listLabel ctrlSetPosition [0.26, 0.07, 0.22, 0.025];
        _listLabel ctrlSetText "Research list";
        _listLabel ctrlCommit 0;

        private _list = _disp ctrlCreate ["RscListbox", -1];
        _list ctrlSetPosition [0.26, 0.10, 0.22, 0.72];
        _list ctrlCommit 0;

        private _nameLabel = _disp ctrlCreate ["RscText", -1];
        _nameLabel ctrlSetPosition [0.50, 0.08, 0.41, 0.025];
        _nameLabel ctrlSetText "Name of Research";
        _nameLabel ctrlCommit 0;

        private _nameEdit = _disp ctrlCreate ["RscEdit", -1];
        _nameEdit ctrlSetPosition [0.50, 0.11, 0.41, 0.05];
        _nameEdit ctrlCommit 0;

        private _descLabel = _disp ctrlCreate ["RscText", -1];
        _descLabel ctrlSetPosition [0.50, 0.17, 0.41, 0.025];
        _descLabel ctrlSetText "Description";
        _descLabel ctrlCommit 0;

        private _descEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _descEdit ctrlSetPosition [0.50, 0.20, 0.41, 0.12];
        _descEdit ctrlCommit 0;

        private _costsLabel = _disp ctrlCreate ["RscText", -1];
        _costsLabel ctrlSetPosition [0.50, 0.33, 0.41, 0.025];
        _costsLabel ctrlSetText "Resource + Cost list (one per line, e.g. Wood=2)";
        _costsLabel ctrlCommit 0;

        private _costsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _costsEdit ctrlSetPosition [0.50, 0.36, 0.41, 0.12];
        _costsEdit ctrlCommit 0;

        private _reqsLabel = _disp ctrlCreate ["RscText", -1];
        _reqsLabel ctrlSetPosition [0.50, 0.49, 0.41, 0.025];
        _reqsLabel ctrlSetText "Required previous research (one per line)";
        _reqsLabel ctrlCommit 0;

        private _reqsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _reqsEdit ctrlSetPosition [0.50, 0.52, 0.41, 0.11];
        _reqsEdit ctrlCommit 0;

        private _exclusiveLabel = _disp ctrlCreate ["RscText", -1];
        _exclusiveLabel ctrlSetPosition [0.50, 0.64, 0.41, 0.025];
        _exclusiveLabel ctrlSetText "Exclusive With (one per line)";
        _exclusiveLabel ctrlCommit 0;

        private _exclusiveEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _exclusiveEdit ctrlSetPosition [0.50, 0.67, 0.41, 0.08];
        _exclusiveEdit ctrlCommit 0;

        private _timeLabel = _disp ctrlCreate ["RscText", -1];
        _timeLabel ctrlSetPosition [0.50, 0.76, 0.18, 0.025];
        _timeLabel ctrlSetText "Research time (sec)";
        _timeLabel ctrlCommit 0;

        private _timeEdit = _disp ctrlCreate ["RscEdit", -1];
        _timeEdit ctrlSetPosition [0.50, 0.79, 0.16, 0.05];
        _timeEdit ctrlSetText "60";
        _timeEdit ctrlCommit 0;

        private _colorLabel = _disp ctrlCreate ["RscText", -1];
        _colorLabel ctrlSetPosition [0.72, 0.76, 0.19, 0.025];
        _colorLabel ctrlSetText "Color (#RRGGBB)";
        _colorLabel ctrlCommit 0;

        private _colorEdit = _disp ctrlCreate ["RscEdit", -1];
        _colorEdit ctrlSetPosition [0.72, 0.79, 0.19, 0.05];
        _colorEdit ctrlSetText "#FFFFFF";
        _colorEdit ctrlCommit 0;

        private _researchedCheck = _disp ctrlCreate ["RscCheckBox", -1];
        _researchedCheck ctrlSetPosition [0.50, 0.85, 0.03, 0.03];
        _researchedCheck cbSetChecked false;
        _researchedCheck ctrlCommit 0;

        private _researchedLabel = _disp ctrlCreate ["RscText", -1];
        _researchedLabel ctrlSetPosition [0.535, 0.852, 0.16, 0.025];
        _researchedLabel ctrlSetText "Researched?";
        _researchedLabel ctrlCommit 0;

        private _iconLabel = _disp ctrlCreate ["RscText", -1];
        _iconLabel ctrlSetPosition [0.68, 0.85, 0.23, 0.025];
        _iconLabel ctrlSetText "Marker Icon";
        _iconLabel ctrlCommit 0;

        private _iconPrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _iconPrev ctrlSetPosition [0.68, 0.88, 0.05, 0.05];
        _iconPrev ctrlSetText "<";
        _iconPrev ctrlCommit 0;

        private _iconValue = _disp ctrlCreate ["RscStructuredText", -1];
        _iconValue ctrlSetPosition [0.74, 0.88, 0.17, 0.05];
        _iconValue ctrlSetStructuredText parseText "";
        _iconValue ctrlCommit 0;

        private _iconNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _iconNext ctrlSetPosition [0.86, 0.88, 0.05, 0.05];
        _iconNext ctrlSetText ">";
        _iconNext ctrlCommit 0;

        private _add = _disp ctrlCreate ["RscButtonMenu", -1];
        _add ctrlSetPosition [0.26, 0.88, 0.14, 0.06];
        _add ctrlSetText "Add";
        _add ctrlCommit 0;

        private _remove = _disp ctrlCreate ["RscButtonMenu", -1];
        _remove ctrlSetPosition [0.42, 0.88, 0.14, 0.06];
        _remove ctrlSetText "Remove";
        _remove ctrlCommit 0;

        private _save = _disp ctrlCreate ["RscButtonMenu", -1];
        _save ctrlSetPosition [0.72, 0.94, 0.10, 0.04];
        _save ctrlSetText "Save";
        _save ctrlCommit 0;

        private _ok = _disp ctrlCreate ["RscButtonMenu", -1];
        _ok ctrlSetPosition [0.84, 0.94, 0.07, 0.04];
        _ok ctrlSetText "Ok";
        _ok ctrlCommit 0;

        _disp setVariable ["WaldoEcoResearch_ConfigBG", _bg];
        _disp setVariable ["WaldoEcoResearch_ConfigTitle", _title];
        _disp setVariable ["WaldoEcoResearch_ConfigListLabel", _listLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigList", _list];
        _disp setVariable ["WaldoEcoResearch_ConfigNameLabel", _nameLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigNameEdit", _nameEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigDescLabel", _descLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigDescEdit", _descEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigCostsLabel", _costsLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigCostsEdit", _costsEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigReqsLabel", _reqsLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigReqsEdit", _reqsEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigExclusiveLabel", _exclusiveLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigExclusiveEdit", _exclusiveEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigTimeLabel", _timeLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigTimeEdit", _timeEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigColorLabel", _colorLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigColorEdit", _colorEdit];
        _disp setVariable ["WaldoEcoResearch_ConfigResearchedCheck", _researchedCheck];
        _disp setVariable ["WaldoEcoResearch_ConfigResearchedLabel", _researchedLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigIconLabel", _iconLabel];
        _disp setVariable ["WaldoEcoResearch_ConfigIconPrev", _iconPrev];
        _disp setVariable ["WaldoEcoResearch_ConfigIconValue", _iconValue];
        _disp setVariable ["WaldoEcoResearch_ConfigIconNext", _iconNext];
        _disp setVariable ["WaldoEcoResearch_ConfigAdd", _add];
        _disp setVariable ["WaldoEcoResearch_ConfigRemove", _remove];
        _disp setVariable ["WaldoEcoResearch_ConfigSave", _save];
        _disp setVariable ["WaldoEcoResearch_ConfigOk", _ok];
        _disp setVariable ["WaldoEcoResearch_ConfigIconIndex", 0];
        _disp setVariable ["WaldoEcoResearch_ConfigSelectedIndex", -1];
        {
            _x setVariable ["WaldoEcoResearch_ZeusDisplay", _disp];
        } forEach [_iconPrev, _iconNext, _add, _remove, _save, _ok];

        _iconPrev setVariable ["WaldoEcoResearch_Delta", -1];
        _iconNext setVariable ["WaldoEcoResearch_Delta", 1];

        _list ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_index"];
            private _disp = ctrlParent _ctrl;
            [_disp, _index] call Waldo_fnc_EcoResearch_loadResearchIntoPrompt;
        }];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoResearch_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoResearch_Delta", 0]] call Waldo_fnc_EcoResearch_cycleResearchConfigIcon;
            }];
        } forEach [_iconPrev, _iconNext];

        _add ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoResearch_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoResearch_collectResearchFormData;
            if ((count _entry) <= 0) exitWith {};

            private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
            if ((_catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))}) >= 0) exitWith {};

            _catalog pushBack _entry;
            _catalog = [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog;

            [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalogLocal;
            [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalog;

            private _newIndex = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))};
            _disp setVariable ["WaldoEcoResearch_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoResearch_populateResearchConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoResearch_loadResearchIntoPrompt;
        }];

        _remove ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoResearch_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _index = _disp getVariable ["WaldoEcoResearch_ConfigSelectedIndex", -1];
            private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
            if (_index < 0 || {_index >= count _catalog}) exitWith {};

            _catalog deleteAt _index;
            _catalog = [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog;

            [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalogLocal;
            [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalog;

            if (_index >= count _catalog) then {
                _index = (count _catalog) - 1;
            };

            _disp setVariable ["WaldoEcoResearch_ConfigSelectedIndex", _index];
            [_disp] call Waldo_fnc_EcoResearch_populateResearchConfigList;
            [_disp, _index] call Waldo_fnc_EcoResearch_loadResearchIntoPrompt;
        }];

        _save ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoResearch_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _index = _disp getVariable ["WaldoEcoResearch_ConfigSelectedIndex", -1];
            private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
            if (_index < 0 || {_index >= count _catalog}) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoResearch_collectResearchFormData;
            if ((count _entry) <= 0) exitWith {};

            private _duplicate = -1;
            for "_i" from 0 to ((count _catalog) - 1) do {
                if (_i isEqualTo _index) then {continue;};
                if ((toLower ((_catalog select _i) param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))) exitWith {
                    _duplicate = _i;
                };
            };
            if (_duplicate >= 0) exitWith {};

            _catalog set [_index, _entry];
            _catalog = [_catalog] call Waldo_fnc_EcoResearch_normalizeResearchCatalog;

            [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalogLocal;
            [_catalog] call Waldo_fnc_EcoResearch_setResearchCatalog;

            private _newIndex = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))};
            _disp setVariable ["WaldoEcoResearch_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoResearch_populateResearchConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoResearch_loadResearchIntoPrompt;
        }];

        _ok ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoResearch_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoResearch_cleanupResearchConfigPrompt;
            };
        }];

        [_disp, [_nameEdit, _descEdit, _costsEdit, _reqsEdit, _exclusiveEdit, _timeEdit, _colorEdit], _nameEdit] call Waldo_fnc_EcoResearch_setPromptInputTargets;
        [_disp] call Waldo_fnc_EcoResearch_populateResearchConfigList;
        [_disp, -1] call Waldo_fnc_EcoResearch_loadResearchIntoPrompt;

