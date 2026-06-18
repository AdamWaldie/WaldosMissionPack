/*
 * Author: Waldo
 * Prompt resource settings.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_ctrl] call Waldo_fnc_EcoResource_promptResourceSettings;
 */

    if (!hasInterface) exitWith {};

    private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _zeusDisp) exitWith {};

    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    [_zeusDisp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;

    private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
    if (isNull _disp) exitWith {};

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.50, 0.08, 0.45, 0.56];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.82];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.53, 0.11, 0.39, 0.03];
    _title ctrlSetText "Set Resources";
    _title ctrlCommit 0;

    private _sideLabel = _disp ctrlCreate ["RscText", -1];
    _sideLabel ctrlSetPosition [0.53, 0.16, 0.39, 0.03];
    _sideLabel ctrlSetText "Select side";
    _sideLabel ctrlCommit 0;

    private _blufor = _disp ctrlCreate ["RscButtonMenu", -1];
    _blufor ctrlSetPosition [0.53, 0.20, 0.11, 0.05];
    _blufor ctrlSetText "BLUFOR";
    _blufor ctrlCommit 0;

    private _opfor = _disp ctrlCreate ["RscButtonMenu", -1];
    _opfor ctrlSetPosition [0.67, 0.20, 0.11, 0.05];
    _opfor ctrlSetText "OPFOR";
    _opfor ctrlCommit 0;

    private _indfor = _disp ctrlCreate ["RscButtonMenu", -1];
    _indfor ctrlSetPosition [0.81, 0.20, 0.11, 0.05];
    _indfor ctrlSetText "INDEP";
    _indfor ctrlCommit 0;

    private _typeLabel = _disp ctrlCreate ["RscText", -1];
    _typeLabel ctrlSetPosition [0.53, 0.27, 0.39, 0.03];
    _typeLabel ctrlSetText "Resource type";
    _typeLabel ctrlCommit 0;

    private _typePrev = _disp ctrlCreate ["RscButtonMenu", -1];
    _typePrev ctrlSetPosition [0.53, 0.31, 0.06, 0.04];
    _typePrev ctrlSetText "<";
    _typePrev ctrlCommit 0;

    private _typeValue = _disp ctrlCreate ["RscStructuredText", -1];
    _typeValue ctrlSetPosition [0.61, 0.31, 0.23, 0.04];
    _typeValue ctrlSetStructuredText parseText "";
    _typeValue ctrlCommit 0;

    private _typeNext = _disp ctrlCreate ["RscButtonMenu", -1];
    _typeNext ctrlSetPosition [0.86, 0.31, 0.06, 0.04];
    _typeNext ctrlSetText ">";
    _typeNext ctrlCommit 0;

    private _amountLabel = _disp ctrlCreate ["RscText", -1];
    _amountLabel ctrlSetPosition [0.53, 0.37, 0.39, 0.03];
    _amountLabel ctrlSetText "Resources";
    _amountLabel ctrlCommit 0;

    private _currentLabel = _disp ctrlCreate ["RscText", -1];
    _currentLabel ctrlSetPosition [0.53, 0.41, 0.39, 0.025];
    _currentLabel ctrlSetText "Current amount";
    _currentLabel ctrlCommit 0;

    private _currentValue = _disp ctrlCreate ["RscText", -1];
    _currentValue ctrlSetPosition [0.53, 0.44, 0.39, 0.03];
    _currentValue ctrlSetText "Current: 0";
    _currentValue ctrlCommit 0;

    private _amountEdit = _disp ctrlCreate ["RscEdit", -1];
    _amountEdit ctrlSetPosition [0.53, 0.48, 0.39, 0.05];
    _amountEdit ctrlSetText "0";
    _amountEdit ctrlCommit 0;

    private _apply = _disp ctrlCreate ["RscButtonMenu", -1];
    _apply ctrlSetPosition [0.53, 0.55, 0.16, 0.05];
    _apply ctrlSetText "Apply";
    _apply ctrlCommit 0;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [0.76, 0.55, 0.16, 0.05];
    _close ctrlSetText "Close";
    _close ctrlCommit 0;

    _disp setVariable ["WaldoEcoResource_SettingsBG", _bg];
    _disp setVariable ["WaldoEcoResource_SettingsTitle", _title];
    _disp setVariable ["WaldoEcoResource_SettingsSideLabel", _sideLabel];
    _disp setVariable ["WaldoEcoResource_SettingsBLUFOR", _blufor];
    _disp setVariable ["WaldoEcoResource_SettingsOPFOR", _opfor];
    _disp setVariable ["WaldoEcoResource_SettingsINDFOR", _indfor];
    _disp setVariable ["WaldoEcoResource_SettingsTypeLabel", _typeLabel];
    _disp setVariable ["WaldoEcoResource_SettingsTypePrev", _typePrev];
    _disp setVariable ["WaldoEcoResource_SettingsTypeValue", _typeValue];
    _disp setVariable ["WaldoEcoResource_SettingsTypeNext", _typeNext];
    _disp setVariable ["WaldoEcoResource_SettingsAmountLabel", _amountLabel];
    _disp setVariable ["WaldoEcoResource_SettingsCurrentLabel", _currentLabel];
    _disp setVariable ["WaldoEcoResource_SettingsCurrentValue", _currentValue];
    _disp setVariable ["WaldoEcoResource_SettingsAmountEdit", _amountEdit];
    _disp setVariable ["WaldoEcoResource_SettingsApply", _apply];
    _disp setVariable ["WaldoEcoResource_SettingsClose", _close];
    _disp setVariable ["WaldoEcoResource_SettingsTypeIndex", 0];
    {
        _x setVariable ["WaldoEcoResource_ZeusDisplay", _disp];
    } forEach [_blufor, _opfor, _indfor, _typePrev, _typeNext, _apply, _close];

    _blufor setVariable ["WaldoEcoResource_SettingsSideKey", "WEST"];
    _opfor setVariable ["WaldoEcoResource_SettingsSideKey", "EAST"];
    _indfor setVariable ["WaldoEcoResource_SettingsSideKey", "GUER"];
    _typePrev setVariable ["WaldoEcoResource_Delta", -1];
    _typeNext setVariable ["WaldoEcoResource_Delta", 1];

    {
        _x ctrlAddEventHandler [
            "ButtonClick",
            {
                params ["_ctrl"];

                private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
                private _sideKey = _ctrl getVariable ["WaldoEcoResource_SettingsSideKey", ""];
                if (_sideKey isEqualTo "") exitWith {};

                [_disp, _sideKey] call Waldo_fnc_EcoResource_selectResourceSettingsSide;
            }
        ];
    } forEach [_blufor, _opfor, _indfor];

    {
        _x ctrlAddEventHandler [
            "ButtonClick",
            {
                params ["_ctrl"];

                private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};

                private _delta = _ctrl getVariable ["WaldoEcoResource_Delta", 0];
                [_disp, _delta] call Waldo_fnc_EcoResource_cycleResourceSettingsType;
            }
        ];
    } forEach [_typePrev, _typeNext];

    _apply ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _sideKey = _disp getVariable ["WaldoEcoResource_SettingsSelectedSide", "WEST"];
            private _types = call Waldo_fnc_EcoResource_getResourceTypes;
            if ((count _types) <= 0) exitWith {};

            private _index = _disp getVariable ["WaldoEcoResource_SettingsTypeIndex", 0];
            if (_index < 0) then {_index = 0;};
            if (_index >= count _types) then {_index = 0;};

            private _resourceType = _types select _index;
            private _edit = _disp getVariable ["WaldoEcoResource_SettingsAmountEdit", controlNull];
            if (isNull _edit) exitWith {};

            private _value = floor (parseNumber (ctrlText _edit));
            if (_value < 0) then {
                _value = 0;
            };

            [_sideKey, _resourceType, _value, name player] call Waldo_fnc_EcoResource_setSideResourceAmount;
            [_disp] call Waldo_fnc_EcoResource_refreshResourceSettings;
        }
    ];

    _close ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
            };
        }
    ];

    [_disp, [_amountEdit], _amountEdit] call Waldo_fnc_EcoResource_setPromptInputTargets;
    [_disp, "WEST"] call Waldo_fnc_EcoResource_selectResourceSettingsSide;
