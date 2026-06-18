/*
 * Author: Waldo
 * Prompt build config.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 * 1: _index <ANY> - index
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_ctrl, _index] call Waldo_fnc_EcoBuild_promptBuildConfig;
 */

        if (!hasInterface) exitWith {};

        private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _zeusDisp) exitWith {};

        [_zeusDisp] call Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt;
        [_zeusDisp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;

        private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
        if (isNull _disp) exitWith {};

                private _bg = _disp ctrlCreate ["RscText", -1];
        _bg ctrlSetPosition [0.00, 0.00, 1.10, 1.00];
        _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
        _bg ctrlCommit 0;

        private _title = _disp ctrlCreate ["RscText", -1];
        _title ctrlSetPosition [0.03, 0.02, 0.35, 0.03];
        _title ctrlSetText "Configure Buildables";
        _title ctrlCommit 0;

        private _listLabel = _disp ctrlCreate ["RscText", -1];
        _listLabel ctrlSetPosition [0.04, 0.06, 0.24, 0.025];
        _listLabel ctrlSetText "Buildable list";
        _listLabel ctrlCommit 0;

        private _list = _disp ctrlCreate ["RscListbox", -1];
        _list ctrlSetPosition [0.04, 0.09, 0.24, 0.77];
        _list ctrlCommit 0;

        private _tabFrame = _disp ctrlCreate ["RscText", -1];
        _tabFrame ctrlSetPosition [0.30, 0.065, 0.69, 0.90];
        _tabFrame ctrlSetBackgroundColor [0, 0, 0, 0.18];
        _tabFrame ctrlCommit 0;

        private _tabDefinitions = _disp ctrlCreate ["RscButtonMenu", -1];
        _tabDefinitions ctrlSetPosition [0.66, 0.02, 0.14, 0.035];
        _tabDefinitions ctrlSetText "Definitions";
        _tabDefinitions ctrlCommit 0;

        private _tabEffects = _disp ctrlCreate ["RscButtonMenu", -1];
        _tabEffects ctrlSetPosition [0.82, 0.02, 0.14, 0.035];
        _tabEffects ctrlSetText "Effects";
        _tabEffects ctrlCommit 0;

        private _nameLabel = _disp ctrlCreate ["RscText", -1];
        _nameLabel ctrlSetPosition [0.32, 0.06, 0.66, 0.025];
        _nameLabel ctrlSetText "Name";
        _nameLabel ctrlCommit 0;

        private _nameEdit = _disp ctrlCreate ["RscEdit", -1];
        _nameEdit ctrlSetPosition [0.32, 0.09, 0.66, 0.04];
        _nameEdit ctrlCommit 0;

        private _descLabel = _disp ctrlCreate ["RscText", -1];
        _descLabel ctrlSetPosition [0.32, 0.14, 0.66, 0.025];
        _descLabel ctrlSetText "Description";
        _descLabel ctrlCommit 0;

        private _descEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _descEdit ctrlSetPosition [0.32, 0.17, 0.66, 0.07];
        _descEdit ctrlCommit 0;

        private _costsLabel = _disp ctrlCreate ["RscText", -1];
        _costsLabel ctrlSetPosition [0.32, 0.25, 0.66, 0.025];
        _costsLabel ctrlSetText "Resource + Cost list (one per line, e.g. Resource=2)";
        _costsLabel ctrlCommit 0;

        private _costsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _costsEdit ctrlSetPosition [0.32, 0.28, 0.66, 0.07];
        _costsEdit ctrlCommit 0;

        private _reqsLabel = _disp ctrlCreate ["RscText", -1];
        _reqsLabel ctrlSetPosition [0.32, 0.36, 0.66, 0.025];
        _reqsLabel ctrlSetText "Requirements (research or buildings, one per line)";
        _reqsLabel ctrlCommit 0;

        private _reqsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _reqsEdit ctrlSetPosition [0.32, 0.39, 0.66, 0.07];
        _reqsEdit ctrlCommit 0;

        private _classLabel = _disp ctrlCreate ["RscText", -1];
        _classLabel ctrlSetPosition [0.32, 0.47, 0.66, 0.025];
        _classLabel ctrlSetText "Building Classname";
        _classLabel ctrlCommit 0;

        private _classEdit = _disp ctrlCreate ["RscEdit", -1];
        _classEdit ctrlSetPosition [0.32, 0.50, 0.66, 0.04];
        _classEdit ctrlSetText "";
        _classEdit ctrlCommit 0;

        private _timeLabel = _disp ctrlCreate ["RscText", -1];
        _timeLabel ctrlSetPosition [0.32, 0.55, 0.16, 0.025];
        _timeLabel ctrlSetText "Build time (sec)";
        _timeLabel ctrlCommit 0;

        private _timeEdit = _disp ctrlCreate ["RscEdit", -1];
        _timeEdit ctrlSetPosition [0.32, 0.58, 0.15, 0.04];
        _timeEdit ctrlSetText "60";
        _timeEdit ctrlCommit 0;

        private _colorLabel = _disp ctrlCreate ["RscText", -1];
        _colorLabel ctrlSetPosition [0.50, 0.55, 0.18, 0.025];
        _colorLabel ctrlSetText "Color (#RRGGBB)";
        _colorLabel ctrlCommit 0;

        private _colorEdit = _disp ctrlCreate ["RscEdit", -1];
        _colorEdit ctrlSetPosition [0.50, 0.58, 0.18, 0.04];
        _colorEdit ctrlSetText "#FFFFFF";
        _colorEdit ctrlCommit 0;

        private _iconLabel = _disp ctrlCreate ["RscText", -1];
        _iconLabel ctrlSetPosition [0.82, 0.55, 0.14, 0.025];
        _iconLabel ctrlSetText "Marker Icon";
        _iconLabel ctrlCommit 0;

        private _iconPrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _iconPrev ctrlSetPosition [0.82, 0.58, 0.04, 0.04];
        _iconPrev ctrlSetText "<";
        _iconPrev ctrlCommit 0;

        private _iconValue = _disp ctrlCreate ["RscStructuredText", -1];
        _iconValue ctrlSetPosition [0.865, 0.58, 0.06, 0.04];
        _iconValue ctrlSetStructuredText parseText "";
        _iconValue ctrlCommit 0;

        private _iconNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _iconNext ctrlSetPosition [0.93, 0.58, 0.04, 0.04];
        _iconNext ctrlSetText ">";
        _iconNext ctrlCommit 0;

        private _categoryLabel = _disp ctrlCreate ["RscText", -1];
        _categoryLabel ctrlSetPosition [0.32, 0.66, 0.30, 0.025];
        _categoryLabel ctrlSetText "Category";
        _categoryLabel ctrlCommit 0;

        private _categoryEdit = _disp ctrlCreate ["RscEdit", -1];
        _categoryEdit ctrlSetPosition [0.32, 0.69, 0.34, 0.04];
        _categoryEdit ctrlSetText "";
        _categoryEdit ctrlCommit 0;

        private _buildLimitLabel = _disp ctrlCreate ["RscText", -1];
        _buildLimitLabel ctrlSetPosition [0.69, 0.66, 0.16, 0.025];
        _buildLimitLabel ctrlSetText "Build Limit";
        _buildLimitLabel ctrlCommit 0;

        private _buildLimitEdit = _disp ctrlCreate ["RscEdit", -1];
        _buildLimitEdit ctrlSetPosition [0.69, 0.69, 0.12, 0.04];
        _buildLimitEdit ctrlSetText "0";
        _buildLimitEdit ctrlCommit 0;

        private _availLabel = _disp ctrlCreate ["RscText", -1];
        _availLabel ctrlSetPosition [0.32, 0.76, 0.30, 0.025];
        _availLabel ctrlSetText "Available For";
        _availLabel ctrlCommit 0;

        private _availWestCheck = _disp ctrlCreate ["RscCheckBox", -1];
        _availWestCheck ctrlSetPosition [0.32, 0.80, 0.022, 0.022];
        _availWestCheck cbSetChecked false;
        _availWestCheck ctrlCommit 0;

        private _availWestLabel = _disp ctrlCreate ["RscText", -1];
        _availWestLabel ctrlSetPosition [0.345, 0.80, 0.10, 0.025];
        _availWestLabel ctrlSetText "BLUFOR";
        _availWestLabel ctrlCommit 0;

        private _availEastCheck = _disp ctrlCreate ["RscCheckBox", -1];
        _availEastCheck ctrlSetPosition [0.45, 0.80, 0.022, 0.022];
        _availEastCheck cbSetChecked false;
        _availEastCheck ctrlCommit 0;

        private _availEastLabel = _disp ctrlCreate ["RscText", -1];
        _availEastLabel ctrlSetPosition [0.475, 0.80, 0.10, 0.025];
        _availEastLabel ctrlSetText "OPFOR";
        _availEastLabel ctrlCommit 0;

        private _availGuerCheck = _disp ctrlCreate ["RscCheckBox", -1];
        _availGuerCheck ctrlSetPosition [0.58, 0.80, 0.022, 0.022];
        _availGuerCheck cbSetChecked false;
        _availGuerCheck ctrlCommit 0;

        private _availGuerLabel = _disp ctrlCreate ["RscText", -1];
        _availGuerLabel ctrlSetPosition [0.605, 0.80, 0.10, 0.025];
        _availGuerLabel ctrlSetText "INDEP";
        _availGuerLabel ctrlCommit 0;

        private _availAllCheck = _disp ctrlCreate ["RscCheckBox", -1];
        _availAllCheck ctrlSetPosition [0.71, 0.80, 0.022, 0.022];
        _availAllCheck cbSetChecked true;
        _availAllCheck ctrlCommit 0;

        private _availAllLabel = _disp ctrlCreate ["RscText", -1];
        _availAllLabel ctrlSetPosition [0.735, 0.80, 0.12, 0.025];
        _availAllLabel ctrlSetText "EVERYONE";
        _availAllLabel ctrlCommit 0;

        private _effectsLabel = _disp ctrlCreate ["RscText", -1];
        _effectsLabel ctrlSetPosition [0.32, 0.09, 0.66, 0.025];
        _effectsLabel ctrlSetText "";
        _effectsLabel ctrlCommit 0;

        private _upgradeToLabel = _disp ctrlCreate ["RscText", -1];
        _upgradeToLabel ctrlSetPosition [0.32, 0.14, 0.30, 0.025];
        _upgradeToLabel ctrlSetText "Upgrades To";
        _upgradeToLabel ctrlCommit 0;

        private _upgradeToEdit = _disp ctrlCreate ["RscEdit", -1];
        _upgradeToEdit ctrlSetPosition [0.32, 0.17, 0.66, 0.04];
        _upgradeToEdit ctrlSetText "";
        _upgradeToEdit ctrlCommit 0;

        private _produceResourceLabel = _disp ctrlCreate ["RscText", -1];
        _produceResourceLabel ctrlSetPosition [0.32, 0.25, 0.22, 0.025];
        _produceResourceLabel ctrlSetText "Produces Resource";
        _produceResourceLabel ctrlCommit 0;

        private _produceResourceEdit = _disp ctrlCreate ["RscEdit", -1];
        _produceResourceEdit ctrlSetPosition [0.32, 0.28, 0.22, 0.04];
        _produceResourceEdit ctrlSetText "";
        _produceResourceEdit ctrlCommit 0;

        private _produceAmountLabel = _disp ctrlCreate ["RscText", -1];
        _produceAmountLabel ctrlSetPosition [0.56, 0.25, 0.12, 0.025];
        _produceAmountLabel ctrlSetText "Amount";
        _produceAmountLabel ctrlCommit 0;

        private _produceAmountEdit = _disp ctrlCreate ["RscEdit", -1];
        _produceAmountEdit ctrlSetPosition [0.56, 0.28, 0.10, 0.04];
        _produceAmountEdit ctrlSetText "0";
        _produceAmountEdit ctrlCommit 0;

        private _produceIntervalLabel = _disp ctrlCreate ["RscText", -1];
        _produceIntervalLabel ctrlSetPosition [0.69, 0.25, 0.12, 0.025];
        _produceIntervalLabel ctrlSetText "Every Y sec";
        _produceIntervalLabel ctrlCommit 0;

        private _produceIntervalEdit = _disp ctrlCreate ["RscEdit", -1];
        _produceIntervalEdit ctrlSetPosition [0.69, 0.28, 0.12, 0.04];
        _produceIntervalEdit ctrlSetText "0";
        _produceIntervalEdit ctrlCommit 0;

        private _upkeepCostsLabel = _disp ctrlCreate ["RscText", -1];
        _upkeepCostsLabel ctrlSetPosition [0.32, 0.37, 0.31, 0.025];
        _upkeepCostsLabel ctrlSetText "Upkeep Cost list (one per line)";
        _upkeepCostsLabel ctrlCommit 0;

        private _upkeepCostsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _upkeepCostsEdit ctrlSetPosition [0.32, 0.40, 0.31, 0.10];
        _upkeepCostsEdit ctrlSetText "";
        _upkeepCostsEdit ctrlCommit 0;

        private _upkeepIntervalLabel = _disp ctrlCreate ["RscText", -1];
        _upkeepIntervalLabel ctrlSetPosition [0.66, 0.37, 0.14, 0.025];
        _upkeepIntervalLabel ctrlSetText "Upkeep Delay";
        _upkeepIntervalLabel ctrlCommit 0;

        private _upkeepIntervalEdit = _disp ctrlCreate ["RscEdit", -1];
        _upkeepIntervalEdit ctrlSetPosition [0.66, 0.40, 0.12, 0.04];
        _upkeepIntervalEdit ctrlSetText "0";
        _upkeepIntervalEdit ctrlCommit 0;

        private _storageLabel = _disp ctrlCreate ["RscText", -1];
        _storageLabel ctrlSetPosition [0.80, 0.37, 0.18, 0.025];
        _storageLabel ctrlSetText "Storage list";
        _storageLabel ctrlCommit 0;

        private _storageEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _storageEdit ctrlSetPosition [0.80, 0.40, 0.18, 0.16];
        _storageEdit ctrlSetText "";
        _storageEdit ctrlCommit 0;

        private _researchSpeedLabel = _disp ctrlCreate ["RscText", -1];
        _researchSpeedLabel ctrlSetPosition [0.32, 0.60, 0.14, 0.02];
        _researchSpeedLabel ctrlSetText "Research Speed %";
        _researchSpeedLabel ctrlCommit 0;

        private _researchSpeedEdit = _disp ctrlCreate ["RscEdit", -1];
        _researchSpeedEdit ctrlSetPosition [0.32, 0.63, 0.12, 0.04];
        _researchSpeedEdit ctrlSetText "0";
        _researchSpeedEdit ctrlCommit 0;

        private _buildSpeedLabel = _disp ctrlCreate ["RscText", -1];
        _buildSpeedLabel ctrlSetPosition [0.47, 0.60, 0.12, 0.02];
        _buildSpeedLabel ctrlSetText "Build Speed %";
        _buildSpeedLabel ctrlCommit 0;

        private _buildSpeedEdit = _disp ctrlCreate ["RscEdit", -1];
        _buildSpeedEdit ctrlSetPosition [0.47, 0.63, 0.12, 0.04];
        _buildSpeedEdit ctrlSetText "0";
        _buildSpeedEdit ctrlCommit 0;

        private _detectorRangeLabel = _disp ctrlCreate ["RscText", -1];
        _detectorRangeLabel ctrlSetPosition [0.62, 0.60, 0.13, 0.02];
        _detectorRangeLabel ctrlSetText "Detector Range";
        _detectorRangeLabel ctrlCommit 0;

        private _detectorRangeEdit = _disp ctrlCreate ["RscEdit", -1];
        _detectorRangeEdit ctrlSetPosition [0.62, 0.63, 0.12, 0.04];
        _detectorRangeEdit ctrlSetText "0";
        _detectorRangeEdit ctrlCommit 0;

        private _add = _disp ctrlCreate ["RscButtonMenu", -1];
        _add ctrlSetPosition [0.04, 0.89, 0.11, 0.045];
        _add ctrlSetText "Add";
        _add ctrlCommit 0;

        private _remove = _disp ctrlCreate ["RscButtonMenu", -1];
        _remove ctrlSetPosition [0.17, 0.89, 0.11, 0.045];
        _remove ctrlSetText "Remove";
        _remove ctrlCommit 0;

        private _save = _disp ctrlCreate ["RscButtonMenu", -1];
        _save ctrlSetPosition [0.04, 0.945, 0.11, 0.04];
        _save ctrlSetText "Save";
        _save ctrlCommit 0;

        private _ok = _disp ctrlCreate ["RscButtonMenu", -1];
        _ok ctrlSetPosition [0.17, 0.945, 0.11, 0.04];
        _ok ctrlSetText "Ok";
        _ok ctrlCommit 0;

        _disp setVariable ["WaldoEcoBuild_ConfigBG", _bg];
        _disp setVariable ["WaldoEcoBuild_ConfigTitle", _title];
        _disp setVariable ["WaldoEcoBuild_ConfigListLabel", _listLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigList", _list];
        _disp setVariable ["WaldoEcoBuild_ConfigTabFrame", _tabFrame];
        _disp setVariable ["WaldoEcoBuild_ConfigTabDefinitions", _tabDefinitions];
        _disp setVariable ["WaldoEcoBuild_ConfigTabEffects", _tabEffects];
        _disp setVariable ["WaldoEcoBuild_ConfigNameLabel", _nameLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigNameEdit", _nameEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigDescLabel", _descLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigDescEdit", _descEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigCostsLabel", _costsLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigCostsEdit", _costsEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigReqsLabel", _reqsLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigReqsEdit", _reqsEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigClassLabel", _classLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigClassEdit", _classEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigTimeLabel", _timeLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigTimeEdit", _timeEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigColorLabel", _colorLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigColorEdit", _colorEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigCategoryLabel", _categoryLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigCategoryEdit", _categoryEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigBuildLimitLabel", _buildLimitLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigBuildLimitEdit", _buildLimitEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailLabel", _availLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailAllCheck", _availAllCheck];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailAllLabel", _availAllLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailWestCheck", _availWestCheck];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailWestLabel", _availWestLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailEastCheck", _availEastCheck];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailEastLabel", _availEastLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailGuerCheck", _availGuerCheck];
        _disp setVariable ["WaldoEcoBuild_ConfigAvailGuerLabel", _availGuerLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigEffectsLabel", _effectsLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigProduceResourceLabel", _produceResourceLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigProduceResourceEdit", _produceResourceEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigProduceAmountLabel", _produceAmountLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigProduceAmountEdit", _produceAmountEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigProduceIntervalLabel", _produceIntervalLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigProduceIntervalEdit", _produceIntervalEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigUpkeepCostsLabel", _upkeepCostsLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigUpkeepCostsEdit", _upkeepCostsEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigUpkeepIntervalLabel", _upkeepIntervalLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigUpkeepIntervalEdit", _upkeepIntervalEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigStorageLabel", _storageLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigStorageEdit", _storageEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigUpgradeToLabel", _upgradeToLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigUpgradeToEdit", _upgradeToEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigResearchSpeedLabel", _researchSpeedLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigResearchSpeedEdit", _researchSpeedEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigBuildSpeedLabel", _buildSpeedLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigBuildSpeedEdit", _buildSpeedEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigDetectorRangeLabel", _detectorRangeLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigDetectorRangeEdit", _detectorRangeEdit];
        _disp setVariable ["WaldoEcoBuild_ConfigIconLabel", _iconLabel];
        _disp setVariable ["WaldoEcoBuild_ConfigIconPrev", _iconPrev];
        _disp setVariable ["WaldoEcoBuild_ConfigIconValue", _iconValue];
        _disp setVariable ["WaldoEcoBuild_ConfigIconNext", _iconNext];
        _disp setVariable ["WaldoEcoBuild_ConfigAdd", _add];
        _disp setVariable ["WaldoEcoBuild_ConfigRemove", _remove];
        _disp setVariable ["WaldoEcoBuild_ConfigSave", _save];
        _disp setVariable ["WaldoEcoBuild_ConfigOk", _ok];
        _disp setVariable ["WaldoEcoBuild_ConfigIconIndex", 0];
        _disp setVariable ["WaldoEcoBuild_ConfigSelectedIndex", -1];
        _disp setVariable ["WaldoEcoBuild_ConfigCurrentTab", "definitions"];
        {
            _x setVariable ["WaldoEcoBuild_ZeusDisplay", _disp];
        } forEach [_tabDefinitions, _tabEffects, _iconPrev, _iconNext, _add, _remove, _save, _ok];

        _iconPrev setVariable ["WaldoEcoBuild_Delta", -1];
        _iconNext setVariable ["WaldoEcoBuild_Delta", 1];
        _tabDefinitions setVariable ["WaldoEcoBuild_TabName", "definitions"];
        _tabEffects setVariable ["WaldoEcoBuild_TabName", "effects"];

        _list ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_index"];
            private _disp = ctrlParent _ctrl;
            [_disp, _index] call Waldo_fnc_EcoBuild_loadBuildIntoPrompt;
        }];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuild_Delta", 0]] call Waldo_fnc_EcoBuild_cycleBuildConfigIcon;
            }];
        } forEach [_iconPrev, _iconNext];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuild_TabName", "definitions"]] call Waldo_fnc_EcoBuild_setBuildConfigTab;
            }];
        } forEach [_tabDefinitions, _tabEffects];

        _add ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoBuild_collectBuildFormData;
            if ((count _entry) <= 0) exitWith {};

            private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
            if ((_catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))}) >= 0) exitWith {};

            _catalog pushBack _entry;
            _catalog = [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog;

            [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalogLocal;
            [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalog;

            private _newIndex = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))};
            _disp setVariable ["WaldoEcoBuild_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoBuild_populateBuildConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoBuild_loadBuildIntoPrompt;
        }];

        _remove ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _index = _disp getVariable ["WaldoEcoBuild_ConfigSelectedIndex", -1];
            private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
            if (_index < 0 || {_index >= count _catalog}) exitWith {};

            _catalog deleteAt _index;
            _catalog = [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog;

            [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalogLocal;
            [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalog;

            if (_index >= count _catalog) then {
                _index = (count _catalog) - 1;
            };

            _disp setVariable ["WaldoEcoBuild_ConfigSelectedIndex", _index];
            [_disp] call Waldo_fnc_EcoBuild_populateBuildConfigList;
            [_disp, _index] call Waldo_fnc_EcoBuild_loadBuildIntoPrompt;
        }];

        _save ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _index = _disp getVariable ["WaldoEcoBuild_ConfigSelectedIndex", -1];
            private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
            if (_index < 0 || {_index >= count _catalog}) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoBuild_collectBuildFormData;
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
            _catalog = [_catalog] call Waldo_fnc_EcoBuild_normalizeBuildCatalog;

            [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalogLocal;
            [_catalog] call Waldo_fnc_EcoBuild_setBuildCatalog;

            private _newIndex = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))};
            _disp setVariable ["WaldoEcoBuild_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoBuild_populateBuildConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoBuild_loadBuildIntoPrompt;
        }];

        _ok ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt;
            };
        }];

        [_disp, [_nameEdit, _descEdit, _costsEdit, _reqsEdit, _classEdit, _timeEdit, _colorEdit, _categoryEdit, _buildLimitEdit, _produceResourceEdit, _produceAmountEdit, _produceIntervalEdit, _upkeepCostsEdit, _upkeepIntervalEdit, _storageEdit, _upgradeToEdit, _researchSpeedEdit, _buildSpeedEdit, _detectorRangeEdit], _nameEdit] call Waldo_fnc_EcoBuild_setPromptInputTargets;
        [_disp] call Waldo_fnc_EcoBuild_populateBuildConfigList;
        [_disp, -1] call Waldo_fnc_EcoBuild_loadBuildIntoPrompt;
        [_disp, "definitions"] call Waldo_fnc_EcoBuild_setBuildConfigTab;

