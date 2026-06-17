/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - promptUnifiedPurgeSystem
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_promptUnifiedPurgeSystem via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _disp) exitWith {};

    [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSaveContext;

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.22, 0.08, 0.56, 0.72];
    _bg ctrlSetBackgroundColor [0.06, 0.02, 0.02, 0.90];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.24, 0.10, 0.50, 0.035];
    _title ctrlSetText "Save System - Purge";
    _title ctrlSetTextColor [1, 0.72, 0.72, 1];
    _title ctrlCommit 0;

    private _configHeader = _disp ctrlCreate ["RscText", -1];
    _configHeader ctrlSetPosition [0.24, 0.15, 0.22, 0.03];
    _configHeader ctrlSetText "Configurations";
    _configHeader ctrlCommit 0;

    private _configCheckAll = _disp ctrlCreate ["RscButtonMenu", -1];
    _configCheckAll ctrlSetPosition [0.61, 0.146, 0.13, 0.035];
    _configCheckAll ctrlSetText "Check All";
    _configCheckAll ctrlCommit 0;

    private _configResourcesCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _configResourcesCheck ctrlSetPosition [0.25, 0.19, 0.03, 0.03];
    _configResourcesCheck cbSetChecked false;
    _configResourcesCheck ctrlCommit 0;

    private _configResourcesLabel = _disp ctrlCreate ["RscText", -1];
    _configResourcesLabel ctrlSetPosition [0.285, 0.192, 0.16, 0.025];
    _configResourcesLabel ctrlSetText "Resources";
    _configResourcesLabel ctrlCommit 0;

    private _configBuildingsCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _configBuildingsCheck ctrlSetPosition [0.25, 0.23, 0.03, 0.03];
    _configBuildingsCheck cbSetChecked false;
    _configBuildingsCheck ctrlCommit 0;

    private _configBuildingsLabel = _disp ctrlCreate ["RscText", -1];
    _configBuildingsLabel ctrlSetPosition [0.285, 0.232, 0.16, 0.025];
    _configBuildingsLabel ctrlSetText "Buildings";
    _configBuildingsLabel ctrlCommit 0;

    private _configResearchCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _configResearchCheck ctrlSetPosition [0.25, 0.27, 0.03, 0.03];
    _configResearchCheck cbSetChecked false;
    _configResearchCheck ctrlCommit 0;

    private _configResearchLabel = _disp ctrlCreate ["RscText", -1];
    _configResearchLabel ctrlSetPosition [0.285, 0.272, 0.16, 0.025];
    _configResearchLabel ctrlSetText "Research";
    _configResearchLabel ctrlCommit 0;

    private _configBuyCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _configBuyCheck ctrlSetPosition [0.25, 0.31, 0.03, 0.03];
    _configBuyCheck cbSetChecked false;
    _configBuyCheck ctrlCommit 0;

    private _configBuyLabel = _disp ctrlCreate ["RscText", -1];
    _configBuyLabel ctrlSetPosition [0.285, 0.312, 0.16, 0.025];
    _configBuyLabel ctrlSetText "Buy";
    _configBuyLabel ctrlCommit 0;

    private _valuesHeader = _disp ctrlCreate ["RscText", -1];
    _valuesHeader ctrlSetPosition [0.24, 0.38, 0.22, 0.03];
    _valuesHeader ctrlSetText "Values";
    _valuesHeader ctrlCommit 0;

    private _valuesCheckAll = _disp ctrlCreate ["RscButtonMenu", -1];
    _valuesCheckAll ctrlSetPosition [0.61, 0.376, 0.13, 0.035];
    _valuesCheckAll ctrlSetText "Check All";
    _valuesCheckAll ctrlCommit 0;

    private _valuesBuildingsCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _valuesBuildingsCheck ctrlSetPosition [0.25, 0.42, 0.03, 0.03];
    _valuesBuildingsCheck cbSetChecked false;
    _valuesBuildingsCheck ctrlCommit 0;

    private _valuesBuildingsLabel = _disp ctrlCreate ["RscText", -1];
    _valuesBuildingsLabel ctrlSetPosition [0.285, 0.422, 0.20, 0.025];
    _valuesBuildingsLabel ctrlSetText "Buildings";
    _valuesBuildingsLabel ctrlCommit 0;

    private _valuesResourcesCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _valuesResourcesCheck ctrlSetPosition [0.25, 0.46, 0.03, 0.03];
    _valuesResourcesCheck cbSetChecked false;
    _valuesResourcesCheck ctrlCommit 0;

    private _valuesResourcesLabel = _disp ctrlCreate ["RscText", -1];
    _valuesResourcesLabel ctrlSetPosition [0.285, 0.462, 0.22, 0.025];
    _valuesResourcesLabel ctrlSetText "Side Resources";
    _valuesResourcesLabel ctrlCommit 0;

    private _valuesContainersCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _valuesContainersCheck ctrlSetPosition [0.25, 0.50, 0.03, 0.03];
    _valuesContainersCheck cbSetChecked false;
    _valuesContainersCheck ctrlCommit 0;

    private _valuesContainersLabel = _disp ctrlCreate ["RscText", -1];
    _valuesContainersLabel ctrlSetPosition [0.285, 0.502, 0.24, 0.025];
    _valuesContainersLabel ctrlSetText "Resource Containers";
    _valuesContainersLabel ctrlCommit 0;

    private _valuesGroundCommandCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _valuesGroundCommandCheck ctrlSetPosition [0.25, 0.54, 0.03, 0.03];
    _valuesGroundCommandCheck cbSetChecked false;
    _valuesGroundCommandCheck ctrlCommit 0;

    private _valuesGroundCommandLabel = _disp ctrlCreate ["RscText", -1];
    _valuesGroundCommandLabel ctrlSetPosition [0.285, 0.542, 0.24, 0.025];
    _valuesGroundCommandLabel ctrlSetText "Ground Command";
    _valuesGroundCommandLabel ctrlCommit 0;

    private _moduleCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _moduleCheck ctrlSetPosition [0.25, 0.62, 0.03, 0.03];
    _moduleCheck cbSetChecked false;
    _moduleCheck ctrlCommit 0;

    private _moduleLabel = _disp ctrlCreate ["RscText", -1];
    _moduleLabel ctrlSetPosition [0.285, 0.622, 0.40, 0.025];
    _moduleLabel ctrlSetText "Purge Waldos Economy Systems Module";
    _moduleLabel ctrlSetTextColor [1, 0.72, 0.72, 1];
    _moduleLabel ctrlCommit 0;

    private _warning = _disp ctrlCreate ["RscText", -1];
    _warning ctrlSetPosition [0.24, 0.67, 0.50, 0.07];
    _warning ctrlSetText "Danger zone. Select what to purge, then press Purge to arm the confirmation.";
    _warning ctrlCommit 0;

    private _purge = _disp ctrlCreate ["RscButtonMenu", -1];
    _purge ctrlSetPosition [0.24, 0.75, 0.18, 0.04];
    _purge ctrlSetText "Purge";
    _purge ctrlCommit 0;

    private _cancel = _disp ctrlCreate ["RscButtonMenu", -1];
    _cancel ctrlSetPosition [0.56, 0.75, 0.18, 0.04];
    _cancel ctrlSetText "Cancel";
    _cancel ctrlCommit 0;

    _disp setVariable ["WaldoEcoCore_PurgeBG", _bg];
    _disp setVariable ["WaldoEcoCore_PurgeTitle", _title];
    _disp setVariable ["WaldoEcoCore_PurgeConfigHeader", _configHeader];
    _disp setVariable ["WaldoEcoCore_PurgeConfigCheckAll", _configCheckAll];
    _disp setVariable ["WaldoEcoCore_PurgeConfigResourcesCheck", _configResourcesCheck];
    _disp setVariable ["WaldoEcoCore_PurgeConfigResourcesLabel", _configResourcesLabel];
    _disp setVariable ["WaldoEcoCore_PurgeConfigBuildingsCheck", _configBuildingsCheck];
    _disp setVariable ["WaldoEcoCore_PurgeConfigBuildingsLabel", _configBuildingsLabel];
    _disp setVariable ["WaldoEcoCore_PurgeConfigResearchCheck", _configResearchCheck];
    _disp setVariable ["WaldoEcoCore_PurgeConfigResearchLabel", _configResearchLabel];
    _disp setVariable ["WaldoEcoCore_PurgeConfigBuyCheck", _configBuyCheck];
    _disp setVariable ["WaldoEcoCore_PurgeConfigBuyLabel", _configBuyLabel];
    _disp setVariable ["WaldoEcoCore_PurgeValuesHeader", _valuesHeader];
    _disp setVariable ["WaldoEcoCore_PurgeValuesCheckAll", _valuesCheckAll];
    _disp setVariable ["WaldoEcoCore_PurgeValuesBuildingsCheck", _valuesBuildingsCheck];
    _disp setVariable ["WaldoEcoCore_PurgeValuesBuildingsLabel", _valuesBuildingsLabel];
    _disp setVariable ["WaldoEcoCore_PurgeValuesResourcesCheck", _valuesResourcesCheck];
    _disp setVariable ["WaldoEcoCore_PurgeValuesResourcesLabel", _valuesResourcesLabel];
    _disp setVariable ["WaldoEcoCore_PurgeValuesContainersCheck", _valuesContainersCheck];
    _disp setVariable ["WaldoEcoCore_PurgeValuesContainersLabel", _valuesContainersLabel];
    _disp setVariable ["WaldoEcoCore_PurgeValuesGroundCommandCheck", _valuesGroundCommandCheck];
    _disp setVariable ["WaldoEcoCore_PurgeValuesGroundCommandLabel", _valuesGroundCommandLabel];
    _disp setVariable ["WaldoEcoCore_PurgeModuleCheck", _moduleCheck];
    _disp setVariable ["WaldoEcoCore_PurgeModuleLabel", _moduleLabel];
    _disp setVariable ["WaldoEcoCore_PurgeWarning", _warning];
    _disp setVariable ["WaldoEcoCore_PurgeButton", _purge];
    _disp setVariable ["WaldoEcoCore_PurgeCancel", _cancel];
    {
        _x setVariable ["WaldoEcoCore_PurgeDisplay", _disp];
    } forEach [_configCheckAll, _valuesCheckAll, _purge, _cancel];

    _disp setVariable ["WaldoEcoCore_PurgeConfirmRemaining", 0];

    _configCheckAll ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_PurgeDisplay", displayNull];
        if (isNull _disp) exitWith {};

        [
            [
                _disp getVariable ["WaldoEcoCore_PurgeConfigResourcesCheck", controlNull],
                _disp getVariable ["WaldoEcoCore_PurgeConfigBuildingsCheck", controlNull],
                _disp getVariable ["WaldoEcoCore_PurgeConfigResearchCheck", controlNull],
                _disp getVariable ["WaldoEcoCore_PurgeConfigBuyCheck", controlNull]
            ],
            true
        ] call Waldo_fnc_EcoCore_setUnifiedPurgeSectionChecked;
    }];

    _valuesCheckAll ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_PurgeDisplay", displayNull];
        if (isNull _disp) exitWith {};

        [
            [
                _disp getVariable ["WaldoEcoCore_PurgeValuesBuildingsCheck", controlNull],
                _disp getVariable ["WaldoEcoCore_PurgeValuesResourcesCheck", controlNull],
                _disp getVariable ["WaldoEcoCore_PurgeValuesContainersCheck", controlNull],
                _disp getVariable ["WaldoEcoCore_PurgeValuesGroundCommandCheck", controlNull]
            ],
            true
        ] call Waldo_fnc_EcoCore_setUnifiedPurgeSectionChecked;
    }];

    _purge ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_PurgeDisplay", displayNull];
        if (isNull _disp) exitWith {};

        if !([_disp] call Waldo_fnc_EcoCore_hasUnifiedPurgeSelection) exitWith {
            private _warning = _disp getVariable ["WaldoEcoCore_PurgeWarning", controlNull];
            if (!isNull _warning) then {
                _warning ctrlSetText "Select at least one purge target before arming the purge.";
                _warning ctrlCommit 0;
            };
        };

        private _remaining = 0 max (_disp getVariable ["WaldoEcoCore_PurgeConfirmRemaining", 0]);
        if (_remaining <= 0) exitWith {
            _disp setVariable ["WaldoEcoCore_PurgeConfirmRemaining", 3];
            [_disp] call Waldo_fnc_EcoCore_refreshUnifiedPurgePrompt;
        };

        _remaining = _remaining - 1;
        _disp setVariable ["WaldoEcoCore_PurgeConfirmRemaining", _remaining];
        [_disp] call Waldo_fnc_EcoCore_refreshUnifiedPurgePrompt;

        if (_remaining > 0) exitWith {};

        private _moduleCheck = _disp getVariable ["WaldoEcoCore_PurgeModuleCheck", controlNull];
        private _purgeModule = (!isNull _moduleCheck) && {cbChecked _moduleCheck};

        if (_purgeModule) then {
            [] call Waldo_fnc_EcoCore_purgeGrandResourceSystemModule;
        } else {
            [
                [
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeConfigResourcesCheck", controlNull]),
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeConfigBuildingsCheck", controlNull]),
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeConfigResearchCheck", controlNull]),
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeConfigBuyCheck", controlNull])
                ],
                [
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeValuesBuildingsCheck", controlNull]),
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeValuesResourcesCheck", controlNull]),
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeValuesContainersCheck", controlNull]),
                    cbChecked (_disp getVariable ["WaldoEcoCore_PurgeValuesGroundCommandCheck", controlNull])
                ]
            ] call Waldo_fnc_EcoCore_executeUnifiedPurge;
        };

        if (!isNull _disp) then {
            [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPurgePrompt;
        };
    }];

    _cancel ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_PurgeDisplay", displayNull];
        if (!isNull _disp) then {
            [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPurgePrompt;
        };
    }];

    [_disp] call Waldo_fnc_EcoCore_refreshUnifiedPurgePrompt;
