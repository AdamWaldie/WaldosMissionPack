/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - collectBuildFormData
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_collectBuildFormData via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp"];

        if (isNull _disp) exitWith {[]};

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

        if (
            isNull _nameCtrl
            || isNull _descCtrl
            || isNull _costsCtrl
            || isNull _reqsCtrl
            || isNull _classCtrl
            || isNull _timeCtrl
            || isNull _colorCtrl
            || isNull _categoryCtrl
            || isNull _buildLimitCtrl
            || isNull _availAllCtrl
            || isNull _availWestCtrl
            || isNull _availEastCtrl
            || isNull _availGuerCtrl
            || isNull _produceResourceCtrl
            || isNull _produceAmountCtrl
            || isNull _produceIntervalCtrl
            || isNull _upkeepCostsCtrl
            || isNull _upkeepIntervalCtrl
            || isNull _storageCtrl
            || isNull _upgradeToCtrl
            || isNull _researchSpeedCtrl
            || isNull _buildSpeedCtrl
            || isNull _detectorRangeCtrl
        ) exitWith {[]};

        private _availability = [];
        if (cbChecked _availAllCtrl) then {
            _availability = ["ALL"];
        } else {
            if (cbChecked _availWestCtrl) then {_availability pushBack "WEST";};
            if (cbChecked _availEastCtrl) then {_availability pushBack "EAST";};
            if (cbChecked _availGuerCtrl) then {_availability pushBack "GUER";};
        };

        private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _iconIndex = _disp getVariable ["WaldoEcoBuild_ConfigIconIndex", 0];
        if (_iconIndex < 0) then {_iconIndex = 0;};
        if (_iconIndex >= count _choices) then {_iconIndex = 0;};

        [[
            [ctrlText _nameCtrl] call Waldo_fnc_EcoCore_trimString,
            [ctrlText _descCtrl] call Waldo_fnc_EcoCore_trimString,
            [ctrlText _costsCtrl] call Waldo_fnc_EcoCore_parseNameValueText,
            [ctrlText _reqsCtrl] call Waldo_fnc_EcoCore_parseNameListText,
            1 max (floor (parseNumber (ctrlText _timeCtrl))),
            (_choices select _iconIndex) param [1, call Waldo_fnc_EcoResource_getDefaultResourceIcon],
            [ctrlText _colorCtrl] call Waldo_fnc_EcoResource_normalizeResourceColor,
            false,
            [ctrlText _classCtrl] call Waldo_fnc_EcoCore_trimString,
            [ctrlText _produceResourceCtrl] call Waldo_fnc_EcoCore_trimString,
            0 max (floor (parseNumber (ctrlText _produceAmountCtrl))),
            0 max (floor (parseNumber (ctrlText _produceIntervalCtrl))),
            0 max (parseNumber (ctrlText _researchSpeedCtrl)),
            0 max (parseNumber (ctrlText _buildSpeedCtrl)),
            0 max (parseNumber (ctrlText _detectorRangeCtrl)),
            [ctrlText _upkeepCostsCtrl] call Waldo_fnc_EcoCore_parseNameValueText,
            0 max (floor (parseNumber (ctrlText _upkeepIntervalCtrl))),
            [ctrlText _storageCtrl] call Waldo_fnc_EcoCore_parseNameValueText,
            [ctrlText _upgradeToCtrl] call Waldo_fnc_EcoCore_trimString,
            0 max (floor (parseNumber (ctrlText _buildLimitCtrl))),
            _availability,
            [ctrlText _categoryCtrl] call Waldo_fnc_EcoCore_trimString
        ]] call Waldo_fnc_EcoBuild_normalizeBuildEntry

