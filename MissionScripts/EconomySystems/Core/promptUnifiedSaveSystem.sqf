/*
 * Author: Waldo
 * Prompt unified save system.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_ctrl] call Waldo_fnc_EcoCore_promptUnifiedSaveSystem;
 */

    if (!hasInterface) exitWith {};

    private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _zeusDisp) exitWith {};

    [_zeusDisp] call Waldo_fnc_EcoCore_cleanupUnifiedSaveContext;

    private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
    if (isNull _disp) exitWith {};

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.23, 0.09, 0.54, 0.56];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.82];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.25, 0.11, 0.48, 0.03];
    _title ctrlSetText "Save System - Import / Export";
    _title ctrlCommit 0;

    private _resourcesCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _resourcesCheck ctrlSetPosition [0.25, 0.155, 0.03, 0.03];
    _resourcesCheck cbSetChecked true;
    _resourcesCheck ctrlCommit 0;

    private _resourcesLabel = _disp ctrlCreate ["RscText", -1];
    _resourcesLabel ctrlSetPosition [0.285, 0.157, 0.10, 0.025];
    _resourcesLabel ctrlSetText "RESOURCES";
    _resourcesLabel ctrlCommit 0;

    private _researchCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _researchCheck ctrlSetPosition [0.39, 0.155, 0.03, 0.03];
    _researchCheck cbSetChecked true;
    _researchCheck ctrlCommit 0;

    private _researchLabel = _disp ctrlCreate ["RscText", -1];
    _researchLabel ctrlSetPosition [0.425, 0.157, 0.09, 0.025];
    _researchLabel ctrlSetText "RESEARCH";
    _researchLabel ctrlCommit 0;

    private _buildingsCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _buildingsCheck ctrlSetPosition [0.525, 0.155, 0.03, 0.03];
    _buildingsCheck cbSetChecked true;
    _buildingsCheck ctrlCommit 0;

    private _buildingsLabel = _disp ctrlCreate ["RscText", -1];
    _buildingsLabel ctrlSetPosition [0.56, 0.157, 0.09, 0.025];
    _buildingsLabel ctrlSetText "BUILDINGS";
    _buildingsLabel ctrlCommit 0;

    private _buyCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _buyCheck ctrlSetPosition [0.655, 0.155, 0.03, 0.03];
    _buyCheck cbSetChecked true;
    _buyCheck ctrlCommit 0;

    private _buyLabel = _disp ctrlCreate ["RscText", -1];
    _buyLabel ctrlSetPosition [0.69, 0.157, 0.05, 0.025];
    _buyLabel ctrlSetText "BUY";
    _buyLabel ctrlCommit 0;

    private _additiveCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _additiveCheck ctrlSetPosition [0.25, 0.187, 0.03, 0.03];
    _additiveCheck cbSetChecked false;
    _additiveCheck ctrlCommit 0;

    private _additiveLabel = _disp ctrlCreate ["RscText", -1];
    _additiveLabel ctrlSetPosition [0.285, 0.189, 0.14, 0.025];
    _additiveLabel ctrlSetText "Additive Import";
    _additiveLabel ctrlCommit 0;

    private _text = _disp ctrlCreate ["RscEditMulti", -1];
    _text ctrlSetPosition [0.25, 0.225, 0.48, 0.32];
    _text ctrlSetText "";
    _text ctrlCommit 0;

    private _import = _disp ctrlCreate ["RscButtonMenu", -1];
    _import ctrlSetPosition [0.25, 0.58, 0.13, 0.04];
    _import ctrlSetText "Import";
    _import ctrlCommit 0;

    private _export = _disp ctrlCreate ["RscButtonMenu", -1];
    _export ctrlSetPosition [0.425, 0.58, 0.13, 0.04];
    _export ctrlSetText "Export";
    _export ctrlCommit 0;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [0.60, 0.58, 0.13, 0.04];
    _close ctrlSetText "Close";
    _close ctrlCommit 0;

    _disp setVariable ["WaldoEcoCore_SaveBG", _bg];
    _disp setVariable ["WaldoEcoCore_SaveTitle", _title];
    _disp setVariable ["WaldoEcoCore_SaveResourcesCheck", _resourcesCheck];
    _disp setVariable ["WaldoEcoCore_SaveResourcesLabel", _resourcesLabel];
    _disp setVariable ["WaldoEcoCore_SaveResearchCheck", _researchCheck];
    _disp setVariable ["WaldoEcoCore_SaveResearchLabel", _researchLabel];
    _disp setVariable ["WaldoEcoCore_SaveBuildingsCheck", _buildingsCheck];
    _disp setVariable ["WaldoEcoCore_SaveBuildingsLabel", _buildingsLabel];
    _disp setVariable ["WaldoEcoCore_SaveBuyCheck", _buyCheck];
    _disp setVariable ["WaldoEcoCore_SaveBuyLabel", _buyLabel];
    _disp setVariable ["WaldoEcoCore_SaveAdditiveCheck", _additiveCheck];
    _disp setVariable ["WaldoEcoCore_SaveAdditiveLabel", _additiveLabel];
    _disp setVariable ["WaldoEcoCore_SaveText", _text];
    _disp setVariable ["WaldoEcoCore_SaveImport", _import];
    _disp setVariable ["WaldoEcoCore_SaveExport", _export];
    _disp setVariable ["WaldoEcoCore_SaveClose", _close];
    {
        _x setVariable ["WaldoEcoCore_SaveDisplay", _disp];
    } forEach [_import, _export, _close];

    _export ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _textCtrl = _disp getVariable ["WaldoEcoCore_SaveText", controlNull];
        private _resourcesCheck = _disp getVariable ["WaldoEcoCore_SaveResourcesCheck", controlNull];
        private _researchCheck = _disp getVariable ["WaldoEcoCore_SaveResearchCheck", controlNull];
        private _buildingsCheck = _disp getVariable ["WaldoEcoCore_SaveBuildingsCheck", controlNull];
        private _buyCheck = _disp getVariable ["WaldoEcoCore_SaveBuyCheck", controlNull];
        if (isNull _textCtrl || isNull _resourcesCheck || isNull _researchCheck || isNull _buildingsCheck || isNull _buyCheck) exitWith {};

        private _payload = [
            cbChecked _resourcesCheck,
            cbChecked _researchCheck,
            cbChecked _buildingsCheck,
            cbChecked _buyCheck
        ] call Waldo_fnc_EcoCore_buildUnifiedSaveExportPayload;

        _textCtrl ctrlSetText _payload;
        _textCtrl ctrlCommit 0;
    }];

    _import ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _textCtrl = _disp getVariable ["WaldoEcoCore_SaveText", controlNull];
        private _additiveCheck = _disp getVariable ["WaldoEcoCore_SaveAdditiveCheck", controlNull];
        if (isNull _textCtrl) exitWith {};

        private _raw = ctrlText _textCtrl;
        if (_raw isEqualTo "") exitWith {};

        private _payload = [];
        if (isNil { _payload = parseSimpleArray _raw; false }) exitWith {};

        [_payload, name player, (!isNull _additiveCheck) && {cbChecked _additiveCheck}] call Waldo_fnc_EcoCore_importUnifiedSavePayload;
    }];

    _close ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (!isNull _disp) then {
            [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSavePrompt;
        };
    }];

    [_disp, [_text], _text, "WaldoEcoCore_SaveInputTargets", [14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;
