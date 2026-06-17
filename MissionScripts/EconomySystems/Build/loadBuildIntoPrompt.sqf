/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - loadBuildIntoPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_loadBuildIntoPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp", ["_index", -1]];

        if (isNull _disp) exitWith {};

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _nameCtrl = _disp getVariable ["WaldoEcoBuild_ConfigNameEdit", controlNull];
        private _descCtrl = _disp getVariable ["WaldoEcoBuild_ConfigDescEdit", controlNull];
        private _costsCtrl = _disp getVariable ["WaldoEcoBuild_ConfigCostsEdit", controlNull];
        private _reqsCtrl = _disp getVariable ["WaldoEcoBuild_ConfigReqsEdit", controlNull];
        private _classCtrl = _disp getVariable ["WaldoEcoBuild_ConfigClassEdit", controlNull];
        private _timeCtrl = _disp getVariable ["WaldoEcoBuild_ConfigTimeEdit", controlNull];
        private _colorCtrl = _disp getVariable ["WaldoEcoBuild_ConfigColorEdit", controlNull];
        private _categoryCtrl = _disp getVariable ["WaldoEcoBuild_ConfigCategoryEdit", controlNull];
        private _buildLimitCtrl = _disp getVariable ["WaldoEcoBuild_ConfigBuildLimitEdit", controlNull];
        private _availAllCtrl = _disp getVariable ["WaldoEcoBuild_ConfigAvailAllCheck", controlNull];
        private _availWestCtrl = _disp getVariable ["WaldoEcoBuild_ConfigAvailWestCheck", controlNull];
        private _availEastCtrl = _disp getVariable ["WaldoEcoBuild_ConfigAvailEastCheck", controlNull];
        private _availGuerCtrl = _disp getVariable ["WaldoEcoBuild_ConfigAvailGuerCheck", controlNull];
        private _produceResourceCtrl = _disp getVariable ["WaldoEcoBuild_ConfigProduceResourceEdit", controlNull];
        private _produceAmountCtrl = _disp getVariable ["WaldoEcoBuild_ConfigProduceAmountEdit", controlNull];
        private _produceIntervalCtrl = _disp getVariable ["WaldoEcoBuild_ConfigProduceIntervalEdit", controlNull];
        private _upkeepCostsCtrl = _disp getVariable ["WaldoEcoBuild_ConfigUpkeepCostsEdit", controlNull];
        private _upkeepIntervalCtrl = _disp getVariable ["WaldoEcoBuild_ConfigUpkeepIntervalEdit", controlNull];
        private _storageCtrl = _disp getVariable ["WaldoEcoBuild_ConfigStorageEdit", controlNull];
        private _upgradeToCtrl = _disp getVariable ["WaldoEcoBuild_ConfigUpgradeToEdit", controlNull];
        private _researchSpeedCtrl = _disp getVariable ["WaldoEcoBuild_ConfigResearchSpeedEdit", controlNull];
        private _buildSpeedCtrl = _disp getVariable ["WaldoEcoBuild_ConfigBuildSpeedEdit", controlNull];
        private _detectorRangeCtrl = _disp getVariable ["WaldoEcoBuild_ConfigDetectorRangeEdit", controlNull];

        if (_index < 0 || {_index >= count _catalog}) exitWith {
            _disp setVariable ["WaldoEcoBuild_ConfigSelectedIndex", -1];
            if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText ""; _nameCtrl ctrlCommit 0;};
            if (!isNull _descCtrl) then {_descCtrl ctrlSetText ""; _descCtrl ctrlCommit 0;};
            if (!isNull _costsCtrl) then {_costsCtrl ctrlSetText ""; _costsCtrl ctrlCommit 0;};
            if (!isNull _reqsCtrl) then {_reqsCtrl ctrlSetText ""; _reqsCtrl ctrlCommit 0;};
            if (!isNull _classCtrl) then {_classCtrl ctrlSetText ""; _classCtrl ctrlCommit 0;};
            if (!isNull _timeCtrl) then {_timeCtrl ctrlSetText "60"; _timeCtrl ctrlCommit 0;};
            if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText "#FFFFFF"; _colorCtrl ctrlCommit 0;};
            if (!isNull _categoryCtrl) then {_categoryCtrl ctrlSetText ""; _categoryCtrl ctrlCommit 0;};
            if (!isNull _buildLimitCtrl) then {_buildLimitCtrl ctrlSetText "0"; _buildLimitCtrl ctrlCommit 0;};
            if (!isNull _availAllCtrl) then {_availAllCtrl cbSetChecked true;};
            if (!isNull _availWestCtrl) then {_availWestCtrl cbSetChecked false;};
            if (!isNull _availEastCtrl) then {_availEastCtrl cbSetChecked false;};
            if (!isNull _availGuerCtrl) then {_availGuerCtrl cbSetChecked false;};
            if (!isNull _produceResourceCtrl) then {_produceResourceCtrl ctrlSetText ""; _produceResourceCtrl ctrlCommit 0;};
            if (!isNull _produceAmountCtrl) then {_produceAmountCtrl ctrlSetText "0"; _produceAmountCtrl ctrlCommit 0;};
            if (!isNull _produceIntervalCtrl) then {_produceIntervalCtrl ctrlSetText "0"; _produceIntervalCtrl ctrlCommit 0;};
            if (!isNull _upkeepCostsCtrl) then {_upkeepCostsCtrl ctrlSetText ""; _upkeepCostsCtrl ctrlCommit 0;};
            if (!isNull _upkeepIntervalCtrl) then {_upkeepIntervalCtrl ctrlSetText "0"; _upkeepIntervalCtrl ctrlCommit 0;};
            if (!isNull _storageCtrl) then {_storageCtrl ctrlSetText ""; _storageCtrl ctrlCommit 0;};
            if (!isNull _upgradeToCtrl) then {_upgradeToCtrl ctrlSetText ""; _upgradeToCtrl ctrlCommit 0;};
            if (!isNull _researchSpeedCtrl) then {_researchSpeedCtrl ctrlSetText "0"; _researchSpeedCtrl ctrlCommit 0;};
            if (!isNull _buildSpeedCtrl) then {_buildSpeedCtrl ctrlSetText "0"; _buildSpeedCtrl ctrlCommit 0;};
            if (!isNull _detectorRangeCtrl) then {_detectorRangeCtrl ctrlSetText "0"; _detectorRangeCtrl ctrlCommit 0;};
            _disp setVariable ["WaldoEcoBuild_ConfigIconIndex", 0];
            [_disp] call Waldo_fnc_EcoBuild_refreshBuildConfigIcon;
        };

        private _entry = _catalog select _index;
        _disp setVariable ["WaldoEcoBuild_ConfigSelectedIndex", _index];

        if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText (_entry param [0, ""]); _nameCtrl ctrlCommit 0;};
        if (!isNull _descCtrl) then {_descCtrl ctrlSetText (_entry param [1, ""]); _descCtrl ctrlCommit 0;};
        if (!isNull _costsCtrl) then {_costsCtrl ctrlSetText ([(_entry param [2, []])] call Waldo_fnc_EcoCore_formatNameValueText); _costsCtrl ctrlCommit 0;};
        if (!isNull _reqsCtrl) then {_reqsCtrl ctrlSetText ([(_entry param [3, []])] call Waldo_fnc_EcoCore_formatNameListText); _reqsCtrl ctrlCommit 0;};
        if (!isNull _classCtrl) then {_classCtrl ctrlSetText (_entry param [8, ""]); _classCtrl ctrlCommit 0;};
        if (!isNull _timeCtrl) then {_timeCtrl ctrlSetText str (_entry param [4, 60]); _timeCtrl ctrlCommit 0;};
        if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText (_entry param [6, "#FFFFFF"]); _colorCtrl ctrlCommit 0;};
        if (!isNull _categoryCtrl) then {_categoryCtrl ctrlSetText (_entry param [21, ""]); _categoryCtrl ctrlCommit 0;};
        if (!isNull _buildLimitCtrl) then {_buildLimitCtrl ctrlSetText str (_entry param [19, 0]); _buildLimitCtrl ctrlCommit 0;};
        if (!isNull _produceResourceCtrl) then {_produceResourceCtrl ctrlSetText (_entry param [9, ""]); _produceResourceCtrl ctrlCommit 0;};
        if (!isNull _produceAmountCtrl) then {_produceAmountCtrl ctrlSetText str (_entry param [10, 0]); _produceAmountCtrl ctrlCommit 0;};
        if (!isNull _produceIntervalCtrl) then {_produceIntervalCtrl ctrlSetText str (_entry param [11, 0]); _produceIntervalCtrl ctrlCommit 0;};
        if (!isNull _upkeepCostsCtrl) then {_upkeepCostsCtrl ctrlSetText ([(_entry param [15, []])] call Waldo_fnc_EcoCore_formatNameValueText); _upkeepCostsCtrl ctrlCommit 0;};
        if (!isNull _upkeepIntervalCtrl) then {_upkeepIntervalCtrl ctrlSetText str (_entry param [16, 0]); _upkeepIntervalCtrl ctrlCommit 0;};
        if (!isNull _storageCtrl) then {_storageCtrl ctrlSetText (([_entry] call Waldo_fnc_EcoBuild_getBuildStorageRows) call Waldo_fnc_EcoCore_formatNameValueText); _storageCtrl ctrlCommit 0;};
        if (!isNull _upgradeToCtrl) then {_upgradeToCtrl ctrlSetText (_entry param [18, ""]); _upgradeToCtrl ctrlCommit 0;};
        if (!isNull _researchSpeedCtrl) then {_researchSpeedCtrl ctrlSetText str (_entry param [12, 0]); _researchSpeedCtrl ctrlCommit 0;};
        if (!isNull _buildSpeedCtrl) then {_buildSpeedCtrl ctrlSetText str (_entry param [13, 0]); _buildSpeedCtrl ctrlCommit 0;};
        if (!isNull _detectorRangeCtrl) then {_detectorRangeCtrl ctrlSetText str (_entry param [14, 0]); _detectorRangeCtrl ctrlCommit 0;};

        private _availability = [_entry param [20, ["ALL"]]] call Waldo_fnc_EcoBuild_normalizeBuildAvailability;
        private _isAll = (_availability find "ALL") >= 0;
        if (!isNull _availAllCtrl) then {_availAllCtrl cbSetChecked _isAll;};
        if (!isNull _availWestCtrl) then {_availWestCtrl cbSetChecked (!_isAll && {(_availability find "WEST") >= 0});};
        if (!isNull _availEastCtrl) then {_availEastCtrl cbSetChecked (!_isAll && {(_availability find "EAST") >= 0});};
        if (!isNull _availGuerCtrl) then {_availGuerCtrl cbSetChecked (!_isAll && {(_availability find "GUER") >= 0});};

        _disp setVariable ["WaldoEcoBuild_ConfigIconIndex", [(_entry param [5, ""])] call Waldo_fnc_EcoCore_findMarkerIconIndex];
        [_disp] call Waldo_fnc_EcoBuild_refreshBuildConfigIcon;

