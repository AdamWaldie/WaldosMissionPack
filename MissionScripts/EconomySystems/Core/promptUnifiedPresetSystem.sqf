/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - promptUnifiedPresetSystem
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_promptUnifiedPresetSystem via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _disp) exitWith {};

    [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSaveContext;

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.24, 0.11, 0.52, 0.56];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.84];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.26, 0.13, 0.46, 0.03];
    _title ctrlSetText "Save System - Preset Configurations";
    _title ctrlCommit 0;

    private _complexityLabel = _disp ctrlCreate ["RscText", -1];
    _complexityLabel ctrlSetPosition [0.26, 0.18, 0.18, 0.025];
    _complexityLabel ctrlSetText "Complexity";
    _complexityLabel ctrlCommit 0;

    private _complexityCombo = _disp ctrlCreate ["RscCombo", -1];
    _complexityCombo ctrlSetPosition [0.26, 0.21, 0.20, 0.04];
    _complexityCombo ctrlCommit 0;

    private _bluforLabel = _disp ctrlCreate ["RscText", -1];
    _bluforLabel ctrlSetPosition [0.26, 0.28, 0.18, 0.025];
    _bluforLabel ctrlSetText "BLUFOR";
    _bluforLabel ctrlCommit 0;

    private _bluforCombo = _disp ctrlCreate ["RscCombo", -1];
    _bluforCombo ctrlSetPosition [0.26, 0.31, 0.20, 0.04];
    _bluforCombo ctrlCommit 0;

    private _opforLabel = _disp ctrlCreate ["RscText", -1];
    _opforLabel ctrlSetPosition [0.26, 0.38, 0.18, 0.025];
    _opforLabel ctrlSetText "OPFOR";
    _opforLabel ctrlCommit 0;

    private _opforCombo = _disp ctrlCreate ["RscCombo", -1];
    _opforCombo ctrlSetPosition [0.26, 0.41, 0.20, 0.04];
    _opforCombo ctrlCommit 0;

    private _indepLabel = _disp ctrlCreate ["RscText", -1];
    _indepLabel ctrlSetPosition [0.26, 0.48, 0.18, 0.025];
    _indepLabel ctrlSetText "INDEP";
    _indepLabel ctrlCommit 0;

    private _indepCombo = _disp ctrlCreate ["RscCombo", -1];
    _indepCombo ctrlSetPosition [0.26, 0.51, 0.20, 0.04];
    _indepCombo ctrlCommit 0;

    private _note = _disp ctrlCreate ["RscText", -1];
    _note ctrlSetPosition [0.50, 0.21, 0.22, 0.26];
    _note ctrlSetText "Preset packs are curated defaults embedded into the system build. Once a side receives a preset, that side cannot receive another preset until the configuration state is purged.";
    _note ctrlCommit 0;

    private _status = _disp ctrlCreate ["RscEditMulti", -1];
    _status ctrlSetPosition [0.50, 0.49, 0.22, 0.10];
    _status ctrlSetText "Select a complexity, then choose the catalogue for each side.";
    _status ctrlEnable false;
    _status ctrlCommit 0;

    private _set = _disp ctrlCreate ["RscButtonMenu", -1];
    _set ctrlSetPosition [0.26, 0.60, 0.18, 0.04];
    _set ctrlSetText "Set Preset";
    _set ctrlCommit 0;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [0.54, 0.60, 0.18, 0.04];
    _close ctrlSetText "Close";
    _close ctrlCommit 0;

    _disp setVariable ["WaldoEcoCore_PresetBG", _bg];
    _disp setVariable ["WaldoEcoCore_PresetTitle", _title];
    _disp setVariable ["WaldoEcoCore_PresetComplexityLabel", _complexityLabel];
    _disp setVariable ["WaldoEcoCore_PresetComplexityCombo", _complexityCombo];
    _disp setVariable ["WaldoEcoCore_PresetBluforLabel", _bluforLabel];
    _disp setVariable ["WaldoEcoCore_PresetBluforCombo", _bluforCombo];
    _disp setVariable ["WaldoEcoCore_PresetOpforLabel", _opforLabel];
    _disp setVariable ["WaldoEcoCore_PresetOpforCombo", _opforCombo];
    _disp setVariable ["WaldoEcoCore_PresetIndepLabel", _indepLabel];
    _disp setVariable ["WaldoEcoCore_PresetIndepCombo", _indepCombo];
    _disp setVariable ["WaldoEcoCore_PresetNote", _note];
    _disp setVariable ["WaldoEcoCore_PresetStatus", _status];
    _disp setVariable ["WaldoEcoCore_PresetSet", _set];
    _disp setVariable ["WaldoEcoCore_PresetClose", _close];
    {
        _x setVariable ["WaldoEcoCore_PresetDisplay", _disp];
    } forEach [_set, _close];

    [_complexityCombo, call Waldo_fnc_EcoCore_getPresetComplexityChoices, "MEDIUM"] call Waldo_fnc_EcoCore_populatePresetCombo;
    [_bluforCombo, call Waldo_fnc_EcoCore_getPresetCatalogChoices, "NONE"] call Waldo_fnc_EcoCore_populatePresetCombo;
    [_opforCombo, call Waldo_fnc_EcoCore_getPresetCatalogChoices, "NONE"] call Waldo_fnc_EcoCore_populatePresetCombo;
    [_indepCombo, call Waldo_fnc_EcoCore_getPresetCatalogChoices, "NONE"] call Waldo_fnc_EcoCore_populatePresetCombo;

    _set ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_PresetDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _statusCtrl = _disp getVariable ["WaldoEcoCore_PresetStatus", controlNull];
        private _complexityCombo = _disp getVariable ["WaldoEcoCore_PresetComplexityCombo", controlNull];
        private _bluforCombo = _disp getVariable ["WaldoEcoCore_PresetBluforCombo", controlNull];
        private _opforCombo = _disp getVariable ["WaldoEcoCore_PresetOpforCombo", controlNull];
        private _indepCombo = _disp getVariable ["WaldoEcoCore_PresetIndepCombo", controlNull];
        if (isNull _statusCtrl || isNull _complexityCombo || isNull _bluforCombo || isNull _opforCombo || isNull _indepCombo) exitWith {};

        private _complexityKey = [_complexityCombo] call Waldo_fnc_EcoCore_getPresetComboSelection;
        private _selections = [
            ["WEST", [_bluforCombo] call Waldo_fnc_EcoCore_getPresetComboSelection],
            ["EAST", [_opforCombo] call Waldo_fnc_EcoCore_getPresetComboSelection],
            ["GUER", [_indepCombo] call Waldo_fnc_EcoCore_getPresetComboSelection]
        ];

        if ((_selections findIf {toUpper (_x param [1, "NONE"]) isNotEqualTo "NONE"}) < 0) exitWith {
            _statusCtrl ctrlSetText "Pick at least one side catalogue before setting a preset.";
            _statusCtrl ctrlCommit 0;
        };

        private _result = [_complexityKey, _selections, name player] call Waldo_fnc_EcoCore_applyPresetSelections;
        private _successCount = _result param [0, 0];
        private _message = _result param [1, ""];
        if (_message isEqualTo "") then {
            _message = "No preset work was performed.";
        };

        _statusCtrl ctrlSetText _message;
        _statusCtrl ctrlCommit 0;

        if (_successCount > 0) then {
            hint _message;
        };
    }];

    _close ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_PresetDisplay", displayNull];
        if (!isNull _disp) then {
            [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedPresetPrompt;
        };
    }];
