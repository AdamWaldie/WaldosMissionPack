/*
 * Author: Waldo
 * Set build config tab.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 * 1: _tab <STRING> - tab (optional, default: "definitions")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _tab] call Waldo_fnc_EcoBuild_setBuildConfigTab;
 */

        params [["_disp", displayNull], ["_tab", "definitions"]];

        if (isNull _disp) exitWith {};

        private _safeTab = if (_tab isEqualType "") then {
            toLower _tab
        } else {
            toLower (str _tab)
        };
        if !(_safeTab in ["definitions", "effects"]) then {
            _safeTab = "definitions";
        };

        private _definitionControls = [
            "WaldoEcoBuild_ConfigNameLabel",
            "WaldoEcoBuild_ConfigNameEdit",
            "WaldoEcoBuild_ConfigDescLabel",
            "WaldoEcoBuild_ConfigDescEdit",
            "WaldoEcoBuild_ConfigCostsLabel",
            "WaldoEcoBuild_ConfigCostsEdit",
            "WaldoEcoBuild_ConfigReqsLabel",
            "WaldoEcoBuild_ConfigReqsEdit",
            "WaldoEcoBuild_ConfigClassLabel",
            "WaldoEcoBuild_ConfigClassEdit",
            "WaldoEcoBuild_ConfigTimeLabel",
            "WaldoEcoBuild_ConfigTimeEdit",
            "WaldoEcoBuild_ConfigColorLabel",
            "WaldoEcoBuild_ConfigColorEdit",
            "WaldoEcoBuild_ConfigCategoryLabel",
            "WaldoEcoBuild_ConfigCategoryEdit",
            "WaldoEcoBuild_ConfigBuildLimitLabel",
            "WaldoEcoBuild_ConfigBuildLimitEdit",
            "WaldoEcoBuild_ConfigAvailLabel",
            "WaldoEcoBuild_ConfigAvailAllCheck",
            "WaldoEcoBuild_ConfigAvailAllLabel",
            "WaldoEcoBuild_ConfigAvailWestCheck",
            "WaldoEcoBuild_ConfigAvailWestLabel",
            "WaldoEcoBuild_ConfigAvailEastCheck",
            "WaldoEcoBuild_ConfigAvailEastLabel",
            "WaldoEcoBuild_ConfigAvailGuerCheck",
            "WaldoEcoBuild_ConfigAvailGuerLabel",
            "WaldoEcoBuild_ConfigIconLabel",
            "WaldoEcoBuild_ConfigIconPrev",
            "WaldoEcoBuild_ConfigIconValue",
            "WaldoEcoBuild_ConfigIconNext"
        ];

        private _effectControls = [
            "WaldoEcoBuild_ConfigProduceResourceLabel",
            "WaldoEcoBuild_ConfigProduceResourceEdit",
            "WaldoEcoBuild_ConfigProduceAmountLabel",
            "WaldoEcoBuild_ConfigProduceAmountEdit",
            "WaldoEcoBuild_ConfigProduceIntervalLabel",
            "WaldoEcoBuild_ConfigProduceIntervalEdit",
            "WaldoEcoBuild_ConfigUpkeepCostsLabel",
            "WaldoEcoBuild_ConfigUpkeepCostsEdit",
            "WaldoEcoBuild_ConfigUpkeepIntervalLabel",
            "WaldoEcoBuild_ConfigUpkeepIntervalEdit",
            "WaldoEcoBuild_ConfigStorageLabel",
            "WaldoEcoBuild_ConfigStorageEdit",
            "WaldoEcoBuild_ConfigUpgradeToLabel",
            "WaldoEcoBuild_ConfigUpgradeToEdit",
            "WaldoEcoBuild_ConfigResearchSpeedLabel",
            "WaldoEcoBuild_ConfigResearchSpeedEdit",
            "WaldoEcoBuild_ConfigBuildSpeedLabel",
            "WaldoEcoBuild_ConfigBuildSpeedEdit",
            "WaldoEcoBuild_ConfigDetectorRangeLabel",
            "WaldoEcoBuild_ConfigDetectorRangeEdit"
        ];

        {
            private _ctrl = _disp getVariable [_x, controlNull];
            if (!isNull _ctrl) then {
                _ctrl ctrlShow (_safeTab isEqualTo "definitions");
            };
        } forEach _definitionControls;

        {
            private _ctrl = _disp getVariable [_x, controlNull];
            if (!isNull _ctrl) then {
                _ctrl ctrlShow (_safeTab isEqualTo "effects");
            };
        } forEach _effectControls;

        private _definitionsButton = _disp getVariable ["WaldoEcoBuild_ConfigTabDefinitions", controlNull];
        private _effectsButton = _disp getVariable ["WaldoEcoBuild_ConfigTabEffects", controlNull];

        if (!isNull _definitionsButton) then {
            _definitionsButton ctrlSetBackgroundColor (
                [[0.18, 0.18, 0.18, 0.95], [0, 0, 0, 0.70]] select (_safeTab isEqualTo "effects")
            );
            _definitionsButton ctrlCommit 0;
        };

        if (!isNull _effectsButton) then {
            _effectsButton ctrlSetBackgroundColor (
                [[0.18, 0.18, 0.18, 0.95], [0, 0, 0, 0.70]] select (_safeTab isEqualTo "definitions")
            );
            _effectsButton ctrlCommit 0;
        };

        _disp setVariable ["WaldoEcoBuild_ConfigCurrentTab", _safeTab];

